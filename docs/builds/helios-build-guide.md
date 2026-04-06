# Helios Build Guide
**Site:** JXStudios
**Hostname:** `helios`
**Project:** Project Helios
**Document Version:** 1.2
**Created:** 23/03/2026
**Last Updated:** 30/03/2026
**Status:** Active build — flat network phase (192.168.0.151)
**Companion Files:** `helios-plan.md` | `CLAUDE.md` | `network-settings-register-populated.md` | `device-specs-list.md`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Pre-Install Preparation](#2-pre-install-preparation)
3. [Identify the Boot Drive](#3-identify-the-boot-drive)
4. [Debian 12 Installation](#4-debian-12-installation)
5. [Post-Install Baseline](#5-post-install-baseline)
6. [ZFS RAIDZ1 Pool](#6-zfs-raidz1-pool)
7. [Forgejo](#7-forgejo)
8. [Samba](#8-samba)
9. [Jellyfin](#9-jellyfin)
10. [code-server](#10-code-server)
11. [Final Validation](#11-final-validation)
12. [What Comes Next](#12-what-comes-next)

---

## 1. Overview

This guide walks through the complete Helios build from bare metal to five confirmed services. It is designed for the flat network phase — everything runs on 192.168.0.0/24 with no VLAN complexity. When the network window happens later, only the static IP and gateway need updating; service configs stay the same.

Follow each section in order. Every section ends with checkpoint boxes — do not move to the next section until all boxes are ticked.

### Target Configuration

| Parameter | Value |
|-----------|-------|
| Hostname | `helios` |
| IP Address | `192.168.0.151` (static — outside DHCP range) |
| Subnet | `255.255.255.0` |
| Gateway | `192.168.0.1` (ER605) |
| DNS | `192.168.0.1` (ER605 — flat network default) |
| OS | Debian 12 (headless, no desktop) |

### Service Stack

| Service | Port | User | Purpose |
|---------|------|------|---------|
| Forgejo | 3000 | `forgejo` | Internal Git — push mirror to GitHub |
| Samba | 445 | `root` / share mapping | Always-on NAS — ZFS RAIDZ1 pool |
| Jellyfin | 8096 | `jellyfin` | Local media server — direct play |
| code-server | 8080 | `codeserver` | VS Code in browser — remote dev |
| OpenSSH | 22 | system | SSH jump host — backup to Pi |

> All services run as native systemd units. No Docker, no containers. Each service gets its own dedicated system user.

---

## 2. Pre-Install Preparation

Before touching the machine, gather everything needed so the install is uninterrupted.

### What You Need

- **USB flash drive** — 8 GB minimum, for the Debian installer ISO
- **Debian 12 netinst ISO** — download from debian.org/distro/netinst (amd64)
- **A second device** — laptop or phone to read this guide while installing
- **Ethernet cable** — Helios must be wired, not wireless
- **Monitor and keyboard** — temporary, for the install only
- **Password manager open** — credentials will be created during this build

### Flash the Installer

**Linux/macOS:**

```bash
sudo dd if=debian-12-amd64-netinst.iso of=/dev/sdX bs=4M status=progress
```

**Windows:**

Use Rufus or balenaEtcher. Select the ISO, target the USB drive, write in DD mode if prompted.

> ⚠️ Double-check the target device letter. `dd` will overwrite without confirmation.

### Confirm ER605 DHCP Range

Before assigning 192.168.0.151, verify it is outside the ER605 DHCP pool. Log into the ER605 admin panel and check the DHCP server settings for the LAN. The static IP must not overlap with the DHCP range.

### Checkpoints

- [X] Debian 12 netinst ISO downloaded
- [X] USB installer flashed and verified
- [X] ER605 DHCP range confirmed — 192.168.0.151 is outside the pool
- [X] Ethernet cable connected from Helios to switch
- [X] Monitor and keyboard attached temporarily

---

## 3. Identify the Boot Drive

Helios has four drives: one boot drive and three 500 GB HDDs for the ZFS pool. Debian must be installed on the boot drive only. The three data HDDs must be left completely unpartitioned — ZFS will claim them later.

> ⚠️ This is the most critical step. Installing Debian on a data HDD by mistake means you lose a pool drive and have to start over.

### Step 1 — Boot from the USB installer

Insert the USB drive and power on Helios. Enter the BIOS/boot menu (usually F2, F12, or DEL at POST) and select the USB drive as the boot device.

### Step 2 — Drop to a shell before installing

At the Debian installer menu, choose Advanced options, then select rescue mode or press Alt+F2 to drop to a shell. A command prompt is needed before the installer partitions anything.

### Step 3 — List all block devices

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL
```

Four drives should be visible. Identify the three that are approximately 500 GB each — those are the data HDDs. The remaining drive is the boot target. Write down its device name (e.g., `/dev/sda`).

> ℹ️ If drive model names are visible, note them. The boot drive is typically a different model or size from the three matching 500 GB HDDs.

### Step 4 — Record findings

Write these down on paper before proceeding:

| Item | Your Value |
|------|-----------|
| Boot drive device | /dev/sdb |
| Boot drive size | 256 GB |
| Data HDD 1 | /dev/sda |
| Data HDD 2 | /dev/sdc |
| Data HDD 3 | /dev/sdd |

### Checkpoints

- [X] Boot drive identified and written down
- [X] Three 500 GB data HDDs identified and noted
- [X] Confident which device to install Debian on

---

## 4. Debian 12 Installation

Run the Debian installer targeting only the boot drive identified above.

### Step 1 — Start the installer

Reboot from USB and select **Install** (not Graphical Install). The text installer is reliable and works with any hardware.

### Step 2 — Basic settings

| Setting | Value |
|---------|-------|
| Language | English |
| Location | Your location |
| Keyboard | Your layout |
| Hostname | `helios` |
| Domain name | (leave blank) |
| Root password | Set one — store in password manager |
| New user | Create your admin user account |

### Step 3 — Disk partitioning — CRITICAL

When the installer asks about disk partitioning:

- **Select:** Guided — use entire disk
- **Target:** Select ONLY the boot drive (the one identified in §3)

> ⚠️ Do NOT select any of the 500 GB HDDs. Do NOT select "use entire disk with LVM" unless there is a specific reason. Simple ext4 on the boot drive is sufficient.

Accept the default partition layout (root partition and swap). Confirm and write changes.

### Step 4 — Software selection

At the tasksel screen, select only:

- **SSH server** — check this
- **Standard system utilities** — check this

Deselect the desktop environment if it is checked. Helios runs headless — no GUI.

### Step 5 — Network configuration

The installer picks up an IP via DHCP from the ER605. Let it. The static IP is set manually after the first boot.

### Step 6 — GRUB bootloader

Install GRUB to the boot drive. Confirm the device matches the boot drive from §3.

### Step 7 — Reboot

Remove the USB drive when prompted and let the machine boot into Debian for the first time.

### Checkpoints

- [X] Debian installed on boot drive only
- [X] No desktop environment selected
- [X] SSH server selected
- [X] Machine boots to a login prompt

---

## 5. Post-Install Baseline

Log in at the console. The first steps are done as **root** to set up sudo access, then everything else is done as the admin user.

### Step 1 — Install sudo and add admin user to sudo group

Debian minimal does not add the first user to the sudo group by default — this must be done manually as root. At this stage SSH password auth is still enabled (key auth is set up later in Step 9), so you can either work at the console or connect remotely.

#### Connect as root

**Windows — PowerShell:**

```powershell
ssh root@<dhcp-ip>
```

> ℹ️ The DHCP IP was assigned during install. If you don't know it, check the ER605 admin panel for DHCP leases, or read it off the console at login (`ip addr show`).

**Linux / macOS — terminal:**

```bash
ssh root@<dhcp-ip>
```

**At the console (no network needed):**

Log in directly at the machine using the root password set during install.

#### Install sudo and add the user

Once logged in as root (by any method above):

```bash
apt install -y sudo
usermod -aG sudo <your-user>
```

> ⚠️ Replace `<your-user>` with the admin username created during installation.

#### Verify sudo access

Log out of root, then log back in as the admin user — either at the console or via SSH:

**Windows — PowerShell:**

```powershell
ssh <your-user>@<dhcp-ip>
```

**Linux / macOS — terminal:**

```bash
ssh <your-user>@<dhcp-ip>
```

Then test:

```bash
sudo whoami
```

This should return `root`. If it returns a permission error, the session still has the old group membership — log out and log back in. Group changes require a fresh login to take effect.

> ℹ️ From this point forward, all commands are run as the admin user with `sudo`. Do not log in as root again.

### Step 2 — Update all packages

```bash
sudo apt update && sudo apt full-upgrade -y
```

### Step 3 — Install essential tools

```bash
sudo apt install -y curl wget git htop vim net-tools
```

### Step 4 — Record the NIC interface name

```bash
ip link show
```

Look for the Ethernet interface — something like `enp0s25`, `eno1`, or `eth0`. Write it down.

**Your interface name:** eno1 alt-name: enp0s25

### Step 5 — Detect the active network manager

Before editing any network config, identify which stack is managing the interface. Debian minimal installs typically use `ifupdown` (via `/etc/network/interfaces`), but some systems — or installs where a desktop was briefly selected then deselected — may have NetworkManager active instead. Editing the wrong file will have no effect.

```bash
# Check which service is active
systemctl is-active networking       # ifupdown / /etc/network/interfaces
systemctl is-active NetworkManager   # NetworkManager
```

If both return `inactive` or `unknown`, run:

```bash
systemctl list-units --type=service --state=running | grep -E 'network|NetworkManager'
```

---

**If `networking` is active (ifupdown — most likely on Debian minimal):**

Proceed to Step 6 — the static IP is set via `/etc/network/interfaces`.

---

**If `NetworkManager` is active:**

Do not edit `/etc/network/interfaces`. Instead, use `nmcli`:

```bash
# Find the connection name (usually "Wired connection 1" or the interface name)
nmcli connection show

# Set the static IP (replace values and connection name as needed)
nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.0.151/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns 192.168.0.1

# Bring the connection down and back up to apply
nmcli connection down "Wired connection 1"
nmcli connection up "Wired connection 1"

# Verify
ip addr show
```

> ℹ️ If NetworkManager is active, skip Step 6 and resume at Step 7 (test connectivity).

---

### Step 6 — Set the static IP (ifupdown only)

> ⚠️ Only follow this step if `networking` was the active service in Step 5. If NetworkManager is managing the interface, you already set the static IP above — skip to Step 7.

```bash
sudo vim /etc/network/interfaces
```

Replace the DHCP block for the Ethernet interface with:

```
auto <interface-name>
iface <interface-name> inet static
    address 192.168.0.151
    netmask 255.255.255.0
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1
```

> ⚠️ Replace `<interface-name>` with the actual name recorded above (e.g., `enp0s25`).

Apply and verify:

```bash
sudo systemctl restart networking
ip addr show <interface-name>
```

192.168.0.151/24 should appear on the interface.

### Step 7 — Test connectivity

```bash
ping -c 3 192.168.0.1     # gateway
ping -c 3 8.8.8.8         # internet
ping -c 3 google.com      # DNS resolution
```

All three must succeed.

### Step 8 — Record the MAC address

```bash
ip link show <interface-name> | grep ether
```

Update `network-settings-register-populated.md` with the Helios entry at 192.168.0.151.

### Step 9 — Set up SSH key authentication

**Windows — PowerShell:**

```powershell
# Copy your public key to Helios
ssh-copy-id <your-user>@192.168.0.151

# Verify key login works
ssh <your-user>@192.168.0.151
```

> ℹ️ If `ssh-copy-id` is not available on older PowerShell versions, use this alternative:
> ```powershell
> type $env:USERPROFILE\.ssh\id_rsa.pub | ssh <your-user>@192.168.0.151 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
> ```

**Linux / macOS — terminal:**

```bash
ssh-copy-id <your-user>@192.168.0.151
ssh <your-user>@192.168.0.151
```

Once key login works from your admin PC, disable password auth on Helios:
> this will be run once all admin devices have passed thier ssh keys

```bash
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

> ⚠️ From this point forward, disconnect the monitor and keyboard. All remaining work is over SSH.

### Step 10 — Set the hostname

```bash
hostnamectl set-hostname helios
```

Verify `/etc/hosts` contains: `127.0.1.1    helios`

### Checkpoints

- [X] sudo installed and admin user added to sudo group
- [X] All packages updated
- [X] Static IP 192.168.0.151 confirmed working
- [X] Gateway, internet, and DNS all reachable
- [X] MAC address recorded
- [X] SSH key auth working, *password auth disabled
- [X] Monitor and keyboard disconnected — working over SSH

---

## 6. ZFS RAIDZ1 Pool

The three 500 GB HDDs form a RAIDZ1 pool giving approximately 1 TB usable space with single-drive fault tolerance and checksumming.

### Step 1 — Install ZFS utilities

```bash
sudo apt install -y zfsutils-linux
sudo zpool status
```

Should say "no pools available" — correct at this point.

### Step 2 — Identify drives by stable paths

```bash
ls -la /dev/disk/by-id/ | grep -v part
```

Find the three data drives by serial/model. Use the `ata-` or `scsi-` prefixed paths — these persist across reboots even if drive letters change.

### Step 3 — Create the RAIDZ1 pool

```bash
sudo zpool create heliospool raidz1 \
  /dev/disk/by-id/<drive1-id> \
  /dev/disk/by-id/<drive2-id> \
  /dev/disk/by-id/<drive3-id>
```

> ⚠️ Replace with actual by-id paths. Triple-check these are NOT the boot drive.

### Step 4 — Enable LZ4 compression

```bash
sudo zfs set compression=lz4 heliospool
```

### Step 5 — Create datasets

```bash
sudo zfs create -o mountpoint=/srv/forgejo heliospool/forgejo
sudo zfs create -o mountpoint=/srv/samba/shared heliospool/shared
sudo zfs create -o mountpoint=/srv/samba/media heliospool/media
sudo zfs create -o mountpoint=/srv/backups heliospool/backups
```

### Step 6 — Verify

```bash
sudo zpool status heliospool
sudo zfs list
df -h /srv/forgejo /srv/samba/shared /srv/samba/media /srv/backups
```

Pool should be ONLINE, all drives healthy, all datasets mounted at their correct paths.

### Checkpoints

- [ ] ZFS utilities installed and module loaded
- [ ] RAIDZ1 pool created — `heliospool` — all ONLINE
- [ ] LZ4 compression enabled
- [ ] All four datasets created and mounted

---

## 7. Forgejo

Forgejo is installed first because all subsequent work should be committed to version control immediately. It is a single Go binary with no runtime dependencies.

> ℹ️ Steps below follow the [official Forgejo binary installation guide](https://forgejo.org/docs/latest/admin/installation/binary). The official docs recommend a `git` user, but this guide uses `forgejo` to avoid ambiguity with the `git` command. Both approaches work.

### Step 1 — Create the forgejo system user

```bash
sudo adduser --system --shell /bin/bash --gecos 'Forgejo' --group --home /srv/forgejo forgejo
```

### Step 2 — Install prerequisites and download the binary

The Forgejo binary requires `git` and `git-lfs` to be present on the system. Install them first:

```bash
sudo apt install -y git git-lfs
```

Check https://codeberg.org/forgejo/forgejo/releases for the latest stable version:

```bash
FORGEJO_VER="x.x.x"  # replace with latest stable
sudo wget -O /usr/local/bin/forgejo \
  https://codeberg.org/forgejo/forgejo/releases/download/v${FORGEJO_VER}/forgejo-${FORGEJO_VER}-linux-amd64
sudo chmod 755 /usr/local/bin/forgejo
```

Verify the binary runs:

```bash
forgejo --version
```

### Step 3 — Create directories

Per the [official docs](https://forgejo.org/docs/latest/admin/installation/binary), the config directory should be owned by `root:forgejo` with `770` so that the Forgejo process can read but not write its own config at rest:

```bash
sudo mkdir -p /etc/forgejo
sudo chown root:forgejo /etc/forgejo && sudo chmod 770 /etc/forgejo
sudo chown -R forgejo:forgejo /srv/forgejo
```

### Step 4 — Download the official systemd service file

The Forgejo project maintains a premade systemd unit file. Download it rather than writing one by hand — this ensures it stays in line with upstream expectations:

```bash
sudo wget -O /etc/systemd/system/forgejo.service \
  https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/contrib/systemd/forgejo.service
```

After downloading, review and edit the service file to match the Helios setup:

```bash
sudo vim /etc/systemd/system/forgejo.service
```

Confirm or update these values:

| Setting | Expected Value |
|---------|---------------|
| `User` | `forgejo` |
| `Group` | `forgejo` |
| `WorkingDirectory` | `/srv/forgejo` |
| `ExecStart` | `/usr/local/bin/forgejo web --config /etc/forgejo/app.ini` |

> ℹ️ The official service file defaults to `User=git`. Change this to `forgejo` to match the user created in Step 1. Also confirm `HOME` and `WorkingDirectory` point to `/srv/forgejo`.

### Step 5 — Start Forgejo

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now forgejo
sudo systemctl status forgejo
```

### Step 6 — Complete web setup

Browse to `http://192.168.0.151:3000` from the admin PC. Complete the first-run wizard:

| Setting | Value |
|---------|-------|
| Database | SQLite3 (default) |
| Site Title | JXStudios Forgejo |
| Repository Root | `/srv/forgejo/forgejo-repositories` |
| Server Domain | `192.168.0.151` |
| SSH Server Port | `22` |
| Base URL | `http://192.168.0.151:3000/` |
| Admin Account | Create now — save to password manager |

> ⚠️ Store the admin credentials in the password manager immediately. Do not commit them to any repository.

After the first run completes, lock down the config directory permissions:

```bash
sudo chmod 750 /etc/forgejo
```

### Step 7 — Migrate the lab repo

```bash
cd /path/to/jxstudios-homelab
git remote rename origin github
git remote add origin http://192.168.0.151:3000/<user>/jxstudios-homelab.git
git push -u origin main
```

### Step 8 — Set up GitHub push mirror

In Forgejo: repository **Settings → Mirror Settings**. Add GitHub as a push mirror using a personal access token (`repo` scope). Store the token in the password manager.

### Checkpoints

- [ ] Forgejo binary installed — `forgejo --version` returns current version
- [ ] Official systemd service file downloaded and edited for `forgejo` user
- [ ] Web UI accessible at `http://192.168.0.151:3000`
- [ ] Admin account created — credentials saved
- [ ] Config directory locked down to `750` after first run
- [ ] Lab repo migrated from GitHub
- [ ] GitHub push mirror configured
- [ ] Git commit: `"Phase 1c — helios Forgejo baseline"`

---

## 8. Samba

Samba provides SMB file shares accessible from Windows, macOS, and Linux. Two shares: `shared` (general files) and `media` (Jellyfin library). Both backed by ZFS datasets.

### Step 1 — Install Samba

```bash
sudo apt install -y samba
```

### Step 2 — Configure shares

Add to the bottom of `/etc/samba/smb.conf`:

```bash
sudo tee -a /etc/samba/smb.conf > /dev/null << 'EOF'

[shared]
    path = /srv/samba/shared
    browseable = yes
    read only = no
    valid users = @sambashare

[media]
    path = /srv/samba/media
    browseable = yes
    read only = no
    valid users = @sambashare
EOF
```

### Step 3 — Create Samba user

```bash
sudo groupadd sambashare
sudo usermod -aG sambashare <your-user>
sudo smbpasswd -a <your-user>
```

Set the Samba password when prompted. This is separate from the Linux login password.

### Step 4 — Set permissions

```bash
sudo chown -R root:sambashare /srv/samba/shared /srv/samba/media
sudo chmod 2775 /srv/samba/shared /srv/samba/media
```

### Step 5 — Start Samba

```bash
sudo systemctl enable --now smbd
sudo systemctl status smbd
```

### Step 6 — Test from admin PC

- **Windows:** File Explorer → `\\192.168.0.151\shared`
- **macOS:** Finder → Go → Connect to Server → `smb://192.168.0.151/shared`
- **Linux:** File manager → `smb://192.168.0.151/shared`

Create a test file, then delete it. Repeat for the media share.

### Checkpoints

- [ ] Samba installed and configured
- [ ] Shares accessible from admin PC
- [ ] Can read and write on both shares
- [ ] Git commit: `"Phase 1c — helios Samba shares"`

---

## 9. Jellyfin

Jellyfin reads from `/srv/samba/media` and streams to clients. No hardware transcode is available (GT 220 has no NVENC). Store media as H.264 MP4/MKV for direct play.

### Step 1 — Install Jellyfin

Per the [official Jellyfin docs](https://jellyfin.org/docs/general/installation/linux), the recommended method for Debian is the install script. Optionally verify the script integrity first:

```bash
sudo apt install -y curl gnupg

# Optional — verify script integrity before running
curl -s https://repo.jellyfin.org/install-debuntu.sh -o install-debuntu.sh
diff <( sha256sum install-debuntu.sh ) <( curl -s https://repo.jellyfin.org/install-debuntu.sh.sha256sum )
```

An empty diff output means the script is intact. Inspect it if you want (`less install-debuntu.sh`), then install:

```bash
sudo bash install-debuntu.sh
rm install-debuntu.sh
```

### Step 2 — Give Jellyfin media access

```bash
sudo usermod -aG sambashare jellyfin
```

### Step 3 — Start Jellyfin

```bash
sudo systemctl enable --now jellyfin
sudo systemctl status jellyfin
```

### Step 4 — Complete web setup

Browse to `http://192.168.0.151:8096`. Walk through the wizard:

- **Admin account:** Create and save to password manager
- **Media library:** Add library, point at `/srv/samba/media`

> ℹ️ The media folder will be empty at first. Drop a test video via the Samba share to confirm Jellyfin picks it up after a library scan.

Subdirectories can be created later as the library grows (e.g., `/srv/samba/media/movies`, `/srv/samba/media/shows`).

### Step 5 — Disable hardware transcoding

In Jellyfin dashboard → **Playback**, set hardware acceleration to **None**. The GT 220 cannot transcode — attempting it will cause playback failures.

### Checkpoints

- [ ] Jellyfin installed and running
- [ ] Web UI accessible at `http://192.168.0.151:8096`
- [ ] Admin account created — credentials saved
- [ ] Media library pointed at `/srv/samba/media`
- [ ] Hardware transcoding confirmed disabled
- [ ] Git commit: `"Phase 1c — helios Jellyfin"`

---

## 10. code-server

VS Code in the browser. Runs as its own user and pairs naturally with the local Forgejo instance.

> ℹ️ Steps below follow the [official code-server install docs](https://github.com/coder/code-server/blob/main/docs/install.md). The recommended method for Debian is the `.deb` package, which ships with a built-in systemd template unit (`code-server@`).

### Step 1 — Create codeserver user

```bash
sudo adduser --system --shell /bin/bash --gecos 'code-server' --group --home /home/codeserver codeserver
```

### Step 2 — Install code-server via .deb package

Check https://github.com/coder/code-server/releases for the latest stable version:

```bash
CS_VERSION="4.109.5"  # replace with latest stable
curl -fOL https://github.com/coder/code-server/releases/download/v${CS_VERSION}/code-server_${CS_VERSION}_amd64.deb
sudo dpkg -i code-server_${CS_VERSION}_amd64.deb
rm code-server_${CS_VERSION}_amd64.deb
```

Verify:

```bash
code-server --version
```

### Step 3 — Configure

The built-in systemd template expects the config at the user's home directory. Create it:

```bash
sudo mkdir -p /home/codeserver/.config/code-server

sudo tee /home/codeserver/.config/code-server/config.yaml > /dev/null << 'EOF'
bind-addr: 0.0.0.0:8080
auth: password
password: <your-chosen-password>
cert: false
EOF

sudo chown -R codeserver:codeserver /home/codeserver
```

> ⚠️ Store this password in the password manager. Do not commit it to any repository.

### Step 4 — Enable the built-in systemd service

code-server's `.deb` package ships with a systemd template unit `code-server@`. Enable it for the `codeserver` user:

```bash
sudo systemctl enable --now code-server@codeserver
sudo systemctl status code-server@codeserver
```

> ℹ️ The `@codeserver` suffix tells systemd to run the service as the `codeserver` user. No custom service file is needed — the `.deb` package provides it.

### Step 5 — Test

Browse to `http://192.168.0.151:8080`, enter the password. Accept the self-signed cert warning if shown.

> ℹ️ code-server can open any path on the machine, including `/srv/forgejo` repos. This makes it a natural remote development companion to the local Forgejo instance.

### Checkpoints

- [ ] code-server installed via `.deb` — `code-server --version` returns current version
- [ ] Built-in systemd service `code-server@codeserver` enabled and running
- [ ] Accessible at `http://192.168.0.151:8080`
- [ ] Password saved in password manager
- [ ] Git commit: `"Phase 1c — helios code-server"`

---

## 11. Final Validation

All five services are installed. Confirm everything survives a reboot and document the final state.

### Step 1 — Reboot

```bash
sudo reboot
```

Wait approximately 60 seconds, then SSH back in:

```bash
ssh <your-user>@192.168.0.151
```

### Step 2 — Check all services

```bash
sudo systemctl status forgejo smbd jellyfin code-server@codeserver sshd
```

All five should show `active (running)`. If any failed, check its journal:

```bash
sudo journalctl -u <service-name> --no-pager -n 50
```

### Step 3 — Verify ZFS

```bash
sudo zpool status heliospool
```

Pool should be ONLINE, all three drives healthy, no errors.

### Step 4 — Test every service from admin PC

| Service | URL / Method | Expected Result |
|---------|-------------|-----------------|
| Forgejo | `http://192.168.0.151:3000` | Login page loads |
| Samba | `\\192.168.0.151\shared` | Browse files |
| Jellyfin | `http://192.168.0.151:8096` | Dashboard loads |
| code-server | `http://192.168.0.151:8080` | VS Code loads |
| SSH | `ssh user@192.168.0.151` | Shell prompt |

### Step 5 — Screenshot and commit

```bash
sudo systemctl status forgejo smbd jellyfin code-server@codeserver sshd
```

Take a screenshot of the output. Then:

```bash
git add -A
git commit -m "Phase 1c — helios baseline complete"
git push
```

### Checkpoints

- [ ] All services survived reboot
- [ ] ZFS pool healthy after reboot
- [ ] Forgejo accessible, repos intact
- [ ] Samba shares mountable from admin PC
- [ ] Jellyfin dashboard loads
- [ ] code-server loads in browser
- [ ] SSH key auth working
- [ ] Screenshot taken of all services running
- [ ] Final git commit pushed
- [ ] MAC address recorded in network register

---

## 12. What Comes Next

### Immediate

- **Update documentation:** Record MAC address, NIC interface name, and confirmed static IP in `network-settings-register-populated.md`. Mark Helios as Active in `device-specs-list.md`.
- **Close MacBook plan:** Update `macbook-server-idea.md` noting that the home server role has been absorbed by Helios.

### VLAN Migration (Phase 2+)

When the 3750G is configured and the maintenance window runs, migrating Helios to VLAN 20 requires only two changes:

1. Update `/etc/network/interfaces` — IP to `192.168.20.11`, gateway to `192.168.20.1`, DNS to `192.168.99.5`
2. Add ACL permits — `HOME → 192.168.20.11:445` (Samba) and `HOME → 192.168.20.11:8096` (Jellyfin)

Service configs do not change. Hostnames and port numbers stay the same.

### Storage Notes

RAIDZ1 gives approximately 1 TB usable with single-drive fault tolerance. ZFS checksumming catches silent bit rot. Run a periodic scrub to verify data integrity:

```bash
sudo zpool scrub heliospool
```

Consider setting up a cron job to scrub monthly.

### Media Strategy

Store all media as H.264 MP4 or MKV. The GT 220 GPU cannot hardware transcode, and the i3-2120 can only handle one occasional software transcode stream. Direct play is the strategy — every modern client handles H.264 natively.

---

*Document version 1.2 — Updated 30/03/2026 — Added sudo setup with PowerShell/Linux CLI options, network stack detection before static IP, git-lfs prerequisite for Forgejo, fixed Jellyfin integrity check command*
*Companion to: `helios-plan.md` (planning and decisions) | This file (build procedure)*
*Next update: After Debian install — record MAC address, NIC interface name, confirm static IP*
