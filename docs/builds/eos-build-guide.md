# Eos Build Guide
**Site:** JXStudios
**Hostname:** `eos`
**Project:** Project Eos
**Document Version:** 1.1
**Created:** 04/04/2026
**Last Updated:** 04/05/2026
**Status:** In Progress
**PVE Version:** Proxmox VE 9.x (Debian 13 Trixie)
**Companion Files:** `flat_network_settings_register.md` | `CLAUDE.md` | `network_settings_register_populated.md` | `device_specs_list.md`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Pre-Install Preparation](#2-pre-install-preparation)
3. [Proxmox VE Installation](#3-proxmox-ve-installation)
4. [Post-Install Baseline](#4-post-install-baseline)
5. [ZFS Data Pool — Single Disk](#5-zfs-data-pool--single-disk)
6. [LXC Template Download](#6-lxc-template-download)
7. [Nginx Proxy Manager LXC](#7-nginx-proxy-manager-lxc)
8. [Monitoring Stack — Prometheus, Grafana, Loki](#8-monitoring-stack--prometheus-grafana-loki)
9. [Homepage LXC](#9-homepage-lxc)
10. [jxstudios.dev LXC](#10-jxstudiosdev-lxc)
11. [Final Validation](#11-final-validation)
12. [Future — Second HDD and ZFS Mirror Conversion](#12-future--second-hdd-and-zfs-mirror-conversion)
13. [What Comes Next](#13-what-comes-next)

---

## 1. Overview

This guide walks through the complete Eos build from bare metal to a running Proxmox hypervisor with the full always-on service stack. It is scoped to the flat network phase — everything runs on `192.168.0.0/24`. When the VLAN migration window runs, only IP and gateway references change; container configs are written with final LAB VLAN IPs from day one wherever possible.

Follow each section in order. Every section ends with checkpoint boxes — do not move to the next section until all boxes are ticked.

### Target Configuration

| Parameter | Value |
|-----------|-------|
| Hostname | `eos` |
| IP Address | `192.168.0.154` (static — outside DHCP range) |
| Subnet | `255.255.255.0` |
| Gateway | `192.168.0.1` (ER605) |
| DNS | `192.168.0.153` (Pi-hole — hestia) |
| OS | Proxmox VE 9.x (Debian 13 Trixie) |
| Proxmox Web UI | `https://192.168.0.154:8006` |

### Hardware Summary

| Component | Spec | Role |
|-----------|------|------|
| CPU | Intel Core i5-9400 — 6c/6t, 2.9 / 4.1 GHz | Hypervisor host |
| RAM | 12 GB DDR4-2666 | Sufficient for initial LXC stack — upgrade to 32 GB deferred |
| Boot drive | 256 GB NVMe PCIe M.2 SSD | Proxmox OS, ISO storage, LXC rootfs |
| Data drive | 1 TB SATA HDD (single — Phase 1) | ZFS single-disk pool for container data |
| GPU | Intel UHD Graphics 630 | No passthrough planned — unused by Proxmox |
| Network | Gigabit Ethernet (wired) | 1 GbE NIC — standard desktop |

### LXC Service Stack

| Service | VMID | Flat IP | VLAN IP (Future) | Purpose |
|---------|------|---------|------------------|---------|
| Nginx Proxy Manager | 250 | 192.168.0.160 | 192.168.20.50 | Reverse proxy — HTTP services across all always-on nodes |
| Prometheus | 220 | 192.168.0.161 | 192.168.20.20 | Metrics collection |
| Grafana | 221 | 192.168.0.162 | 192.168.20.21 | Dashboards |
| Loki | 222 | 192.168.0.163 | 192.168.20.22 | Log aggregation |
| Homepage | 261 | 192.168.0.164 | 192.168.20.61 | Service dashboard |
| jxstudios.dev | 262 | 192.168.0.165 | 192.168.20.62 | Astro static site |

> **VMID convention inherited from Genesis2:** 2xx = LXC, 3xx = VM. Last two digits mirror the IP last octet where possible. Flat network IPs above are assigned sequentially above the Eos host IP — update the flat network register when these containers are created.

> **Flat network LXC IPs** (160–165) are temporary. Do not hardcode them into service configs that will persist. Where a config accepts a hostname or environment variable, prefer that over a raw IP.

### Storage Architecture — Phased

| Phase | State | Layout | Notes |
|-------|-------|--------|-------|
| Phase 1 (now) | 1 HDD | Single-disk ZFS pool (`eospool`) | No redundancy — but ZFS-native from day one |
| Phase 2 (future) | 2 HDDs | ZFS mirror (`eospool`) | Non-destructive conversion via `zpool attach` — data preserved |

> **Why ZFS from day one on a single disk?** A single-disk ZFS pool cannot protect against drive failure, but it provides checksumming (silent corruption detection), snapshots, compression, and — critically — a clean, non-destructive path to a mirror when the second HDD arrives. If the drive were formatted as ext4, migrating to ZFS later would require a full backup/wipe/restore cycle.

---

## 2. Pre-Install Preparation

### What You Need

- USB drive (4 GB minimum) — for Proxmox installer
- Admin PC or laptop with internet access
- Physical access to Eos (monitor + keyboard for install only)
- Proxmox VE ISO — download from `https://www.proxmox.com/en/downloads`
- Balena Etcher or `dd` to write the ISO to USB

### Write the ISO

**Windows/macOS (Balena Etcher):**
1. Download and open Balena Etcher
2. Select the Proxmox VE ISO
3. Select the USB drive — verify it is the correct device
4. Flash

**Linux (`dd`):**
```bash
# Identify USB device — check with lsblk before running
sudo dd if=proxmox-ve_*.iso of=/dev/sdX bs=1M status=progress
sync
```

> ⚠️ Replace `/dev/sdX` with the actual USB device path. Double-check with `lsblk` — writing to the wrong device is not recoverable.

### Identify the Drives Before Installing

Before booting the installer, know what you are working with. Boot from a live USB (or the Proxmox installer itself — it shows drives in the selection step) and note:

- The **NVMe SSD** — this is the Proxmox boot target. It will appear as `/dev/nvme0n1` or similar.
- The **SATA HDD** — this is the data pool drive. It will appear as `/dev/sda` or `/dev/sdb`.

The NVMe and SATA drives are typically distinguishable by path prefix (`nvme` vs `sd`) and size (256 GB vs 1 TB). Confirm before proceeding.

### Checkpoints

- [X] Proxmox VE ISO downloaded and verified
- [X] USB installer written successfully
- [X] NVMe SSD and SATA HDD identified — note which is which

---

## 3. Proxmox VE Installation

### Step 1 — Boot from USB

1. Connect monitor and keyboard to Eos
2. Power on and enter BIOS/UEFI (typically F10 on HP Pavilion at POST)
3. Set USB as first boot device, or select it from the boot menu
4. Boot the Proxmox VE installer

### Step 2 — Installer Target Drive

At the **Target Harddisk** screen:

- Click **Options**
- Set **Filesystem:** `ext4`
- Select the **256 GB NVMe SSD** as the target
- Do **not** select the SATA HDD — it is reserved for the ZFS data pool

> ZFS on the root/boot volume is not required and adds unnecessary complexity. `ext4` is the correct choice for the Proxmox OS drive. ZFS benefits are applied to the data pool only.

### Step 3 — Location and Timezone

| Setting | Value |
|---------|-------|
| Country | United States |
| Timezone | America/Chicago |
| Keyboard | en-us |

### Step 4 — Root Password and Email

- Set a strong root password — save it in your password manager
- Email field: enter a local address (e.g. `root@eos.local`) — this is used for system alerts and does not need to be a real address at this stage

### Step 5 — Network Configuration

| Setting | Value |
|---------|-------|
| Management Interface | Select the Gigabit Ethernet NIC (not Wi-Fi) |
| Hostname (FQDN) | `eos.local` |
| IP Address | `192.168.0.154/24` |
| Gateway | `192.168.0.1` |
| DNS Server | `192.168.0.153` |

> The management interface must be the wired Ethernet NIC. If multiple NICs appear, select the one connected to the GS308. The HP Pavilion TP01-0050 has both a Realtek GbE NIC and Wi-Fi — the GbE will appear as `enp*` or `eth0` style naming; Wi-Fi usually shows as `wlp*`. Choose the wired one.

### Step 6 — Confirm and Install

Review the summary screen. Verify:
- Target disk is the NVMe SSD
- IP is `192.168.0.154`
- Gateway is `192.168.0.1`

Click **Install**. Installation takes approximately 5–10 minutes.

### Step 7 — First Boot

When installation completes, remove the USB drive and allow Eos to reboot. The console will display:

```
Welcome to the Proxmox Virtual Environment.
Please use your web browser to configure this server -
connect to: https://192.168.0.154:8006/
```

All remaining work is done through the web UI and SSH — the monitor and keyboard can be disconnected.

### Checkpoints

- [X] Proxmox installed to NVMe SSD only — SATA HDD untouched
- [X] IP `192.168.0.154` confirmed on console after first boot
- [X] Web UI accessible at `https://192.168.0.154:8006` from admin PC
- [X] Root login working in web UI
- [X] Monitor and keyboard disconnected — working over web UI and SSH

---

## 4. Post-Install Baseline

All steps in this section are run from the Proxmox web UI shell (**Eos → Shell**) or via SSH:

```bash
ssh root@192.168.0.154
```

### Step 1 — Configure Repositories (No Subscription)

> **PVE 9 / Trixie change:** Proxmox VE 9 uses the **deb822 format** (`.sources` files) for all repositories. The legacy single-line `.list` format still works but generates warnings on Debian Trixie — do not create new `.list` files. All PVE 9 repo files use `.sources` extension with `Enabled: no` to disable (not overwriting with a comment).

Proxmox defaults to the enterprise repositories which require a paid subscription. Disable them and add the free no-subscription repositories.

**Option A — Via the Web UI (recommended):**
1. Navigate to **Eos → Updates → Repositories**
2. Select the `pve-enterprise` entry → click **Disable**
3. Select the `ceph-enterprise` entry → click **Disable**
4. Click **Add** → select `No-Subscription` → **Add**
5. Click **Add** → select `Ceph Squid No-Subscription` → **Add**

**Option B — Via Shell:**
```bash
# Disable enterprise PVE repo — add Enabled: no to the existing .sources file
sed -i '/^Types:/i Enabled: no' /etc/apt/sources.list.d/pve-enterprise.sources 2>/dev/null || \
cat > /etc/apt/sources.list.d/pve-enterprise.sources << 'EOF'
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Enabled: no
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Disable Ceph enterprise repo
cat > /etc/apt/sources.list.d/ceph.sources << 'EOF'
Types: deb
URIs: https://enterprise.proxmox.com/debian/ceph-squid
Suites: trixie
Components: enterprise
Enabled: no
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Add no-subscription repos (PVE + Ceph Squid) in deb822 format
cat > /etc/apt/sources.list.d/proxmox.sources << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg

Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
```

Verify the enterprise repos are disabled before updating:
```bash
grep -i "enabled" /etc/apt/sources.list.d/pve-enterprise.sources
grep -i "enabled" /etc/apt/sources.list.d/ceph.sources
# Both should show: Enabled: no
```

### Step 2 — Update All Packages

```bash
apt update && apt full-upgrade -y
```

> **PVE 9 / Trixie note:** If you see warnings about deprecated single-line format repositories, run `apt modernize-sources` to automatically migrate any remaining `.list` files to the deb822 `.sources` format. This is safe and recommended.

Reboot after updating if a new kernel was installed:

```bash
reboot
```

Reconnect via web UI shell or SSH after ~60 seconds.

### Step 3 — Dismiss the No-Subscription Nag (Optional)

The web UI shows a subscription nag dialog on every login. This can be suppressed by patching the frontend JavaScript:

```bash
sed -Ei 's/(data\.status !== .Active.)/false/g' \
  /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy
```

> This is a cosmetic change only — it does not affect any functionality. The patch targets a specific string in `proxmoxlib.js` that may move between PVE releases. If the nag persists after patching, the string has changed — check the file manually with `grep -n "Active" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js` to locate the new target. Note that PVE package updates will revert this patch — it may need to be reapplied after upgrades.

### Step 4 — SSH Key Auth

Copy your admin public key to Eos for passwordless SSH:

```bash
# Run from admin PC
ssh-copy-id root@192.168.0.154
```

Verify key auth works:
```bash
ssh root@192.168.0.154
```

Password auth can remain enabled for now — restrict it later during the VLAN hardening phase.

### Step 5 — Record MAC Address

```bash
ip link show
```

Find the entry for the active Ethernet interface (e.g. `enp3s0`) and note the MAC address. Update the flat network register (`flat_network_settings_register.md`) §1 and §2 with:
- Eos MAC address
- Confirmed interface name

### Step 6 — Set Hostname in /etc/hosts

Verify `/etc/hosts` contains a correct entry:

```bash
cat /etc/hosts
```

It should include:
```
127.0.1.1    eos.local eos
192.168.0.154  eos.local eos
```

If not, edit it:
```bash
nano /etc/hosts
```

### Checkpoints

- [X] Enterprise PVE repo disabled (`Enabled: no` in `pve-enterprise.sources`)
- [X] Enterprise Ceph repo disabled (`Enabled: no` in `ceph.sources`)
- [X] No-subscription PVE + Ceph Squid repos added to `proxmox.sources`
- [X] `apt update` runs clean — no 401 errors
- [X] All packages updated — reboot completed if kernel updated
- [X] `apt modernize-sources` run if legacy `.list` warnings appeared
- [X] Subscription nag dismissed (optional)
- [X] SSH key auth working from admin PC
- [X] MAC address recorded in flat network register
- [X] Interface name recorded (e.g. `enp3s0`)
- [X] `/etc/hosts` correct

---

## 5. ZFS Data Pool — Single Disk

The 1 TB SATA HDD is configured as a single-disk ZFS pool. It will be extended to a mirror when the second HDD arrives — see §12 for that procedure.

### Step 1 — Install ZFS Utilities

Proxmox ships with ZFS support built in. Verify it is available:

```bash
zpool status
# Should return: no pools available
```

### Step 2 — Identify the HDD by Stable Path

Always use `/dev/disk/by-id/` paths — `/dev/sdX` letter assignments are not stable across reboots.

```bash
ls -la /dev/disk/by-id/ | grep -v part
```

Identify the 1 TB SATA HDD by model/serial. It will have an `ata-` prefix. Note the full path, for example:
```
ata-WDC_WD10EZEX-08WN4A0_WD-WCC6Y4RUHVPN
```

### Step 3 — Create the Single-Disk Pool

```bash
zpool create -f \
  -o ashift=12 \
  eospool \
  /dev/disk/by-id/<your-hdd-id>
```

> `ashift=12` sets 4K sector alignment — correct for all modern HDDs regardless of what the drive reports. Always set this at pool creation — it cannot be changed after.

Verify:
```bash
zpool status eospool
zpool list
```

Expected output:
```
  pool: eospool
 state: ONLINE
config:
      NAME        STATE     READ WRITE CKSUM
      eospool     ONLINE       0     0     0
        ata-...   ONLINE       0     0     0
```

### Step 4 — Enable LZ4 Compression

```bash
zfs set compression=lz4 eospool
```

LZ4 compression is fast enough to be CPU-neutral in most workloads and typically reduces storage usage by 20–40% on text-heavy data.

### Step 5 — Create Datasets

```bash
# Container data — general purpose
zfs create -o mountpoint=/eospool/data eospool/data

# Reserved for Nextcloud user data (future — when RAM upgraded)
zfs create -o mountpoint=/eospool/nextcloud eospool/nextcloud
```

Verify:
```bash
zfs list
df -h /eospool/data
```

### Step 6 — Add Pool to Proxmox Web UI

1. Log into the Proxmox web UI at `https://192.168.0.154:8006`
2. Navigate to **Datacenter → Storage → Add → ZFS**
3. Select `eospool`
4. Set **Content:** `Disk image, Container` (check both)
5. Click **Add**

The pool will now appear as `eospool` in the storage list and can be selected when creating containers.

### Checkpoints

- [X] ZFS module confirmed loaded (`zpool status` responds)
- [X] HDD identified via `/dev/disk/by-id/` path — noted
- [X] `eospool` created — ONLINE, single disk
- [X] `ashift=12` set at creation
- [X] LZ4 compression enabled
- [X] Datasets created: `eospool/data`, `eospool/nextcloud`
- [X] `eospool` visible in Proxmox web UI storage list
- [X] Git commit: `"eos baseline — Proxmox install + ZFS eospool single disk"`

---

## 6. LXC Template Download

All services on Eos run as LXC containers. Download the Debian 12 template before creating any containers.

> **Template choice on PVE 9:** Although the Proxmox VE 9 host runs Debian 13 Trixie, LXC containers are independent and can run any supported Debian release. **Debian 12 (Bookworm) is still the recommended template** for all service containers in this build — it is the current stable LTS, has the widest package compatibility, and is what all service install procedures below are written against. Debian 13 (Trixie) templates are available but are not yet LTS and have less tested support across third-party software. Stick with Debian 12 for all containers until this guide is explicitly revised.

### Via Web UI

1. **Eos → local (eos) → CT Templates → Templates**
2. Search for `debian-12`
3. Select `debian-12-standard_*.tar.zst`
4. Click **Download**

### Via Shell

```bash
pveam update
# Check current available version — do not hardcode the version number
pveam available | grep debian-12-standard
# Download whichever version is listed, e.g.:
pveam download local debian-12-standard_12.7-1_amd64.tar.zst
```

> Always check `pveam available` first — the exact version string changes with Debian point releases. Copy the exact filename from the output rather than guessing.

Verify the template is downloaded:
```bash
pveam list local
```

### Checkpoints

- [ ] Debian 12 standard template downloaded to `local`
- [ ] Template visible in web UI under CT Templates

---

## 7. Nginx Proxy Manager LXC

Nginx Proxy Manager (NPM) is deployed first. It will serve as the reverse proxy for all HTTP services across Eos and Helios once they are up.

### Create the Container

**Web UI: Eos → Create CT**

| Setting | Value |
|---------|-------|
| VMID | `250` |
| Hostname | `npm` |
| Password | Set a root password — save in password manager |
| Template | `debian-12-standard` |
| Disk | `eospool` — 8 GB |
| CPU | 1 core |
| RAM | 512 MB |
| Swap | 512 MB |
| Network | Bridge: `vmbr0`, IPv4: `192.168.0.160/24`, GW: `192.168.0.1` |
| DNS | `192.168.0.153` |
| Start after creation | No — configure first |

> **Features tab — required for Docker:** NPM runs Docker inside the LXC. On PVE 9, Docker inside an unprivileged LXC requires **nesting** to be enabled. In the **Features** tab of the container creation wizard, check **Nesting**. Without this, Docker will fail to start. The container must be unprivileged (the default) — do not use a privileged container.

Start the container:
```bash
pct start 250
```

### Install Nginx Proxy Manager

Enter the container shell:
```bash
pct enter 250
```

Update and install dependencies:
```bash
apt update && apt upgrade -y
apt install -y curl gnupg2 ca-certificates lsb-release
```

Install Docker (NPM runs in Docker inside the LXC):
```bash
curl -fsSL https://get.docker.com | sh
```

Create NPM working directory and config:
```bash
mkdir -p /opt/npm
cat > /opt/npm/docker-compose.yml << 'EOF'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF
```

Install Docker Compose and start NPM:
```bash
apt install -y docker-compose-plugin
cd /opt/npm
docker compose up -d
```

Verify NPM is running:
```bash
docker compose ps
# Should show npm-app-1 as running
```

### First Login

From your admin PC browser, navigate to `http://192.168.0.160:81`

Default credentials:
- Email: `admin@example.com`
- Password: `changeme`

You will be immediately prompted to change both. Set a strong password and save to your password manager.

> NPM is now running but has no proxy hosts configured yet. Hosts are added as each service comes online.

### Checkpoints

- [ ] Container 250 `npm` created — **Nesting feature enabled** in container options
- [ ] Container started
- [ ] Docker installed inside the LXC — `docker run hello-world` passes
- [ ] NPM `docker compose up -d` running — both containers healthy
- [ ] NPM admin UI accessible at `http://192.168.0.160:81`
- [ ] Default credentials changed — new credentials in password manager
- [ ] Git commit: `"eos — VMID 250 npm baseline"`

---

## 8. Monitoring Stack — Prometheus, Grafana, Loki

The PLG stack (Prometheus + Loki + Grafana) is deployed as three separate LXC containers, matching the VMID convention from the Genesis2 plan. Three separate containers keeps update and rebuild paths clean — each service can be restarted or rebuilt without affecting the others.

### 8.1 — Prometheus LXC (VMID 220)

**Create the container:**

| Setting | Value |
|---------|-------|
| VMID | `220` |
| Hostname | `prometheus` |
| Template | `debian-12-standard` |
| Disk | `eospool` — 8 GB |
| CPU | 1 core |
| RAM | 512 MB |
| Swap | 512 MB |
| Network | Bridge: `vmbr0`, IPv4: `192.168.0.161/24`, GW: `192.168.0.1` |
| DNS | `192.168.0.153` |

**Install Prometheus:**
```bash
pct start 220
pct enter 220

apt update && apt upgrade -y
apt install -y prometheus

# Enable and start
systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus
```

Default Prometheus port is `9090`. Confirm it is listening:
```bash
ss -tlnp | grep 9090
```

**Basic Prometheus config** is at `/etc/prometheus/prometheus.yml`. The default config scrapes Prometheus itself. Additional scrape targets (node exporters on Helios, Eos host, Genesis) are added as those exporters are deployed. Do not modify the config yet — leave default.

### 8.2 — Grafana LXC (VMID 221)

**Create the container:**

| Setting | Value |
|---------|-------|
| VMID | `221` |
| Hostname | `grafana` |
| Template | `debian-12-standard` |
| Disk | `eospool` — 8 GB |
| CPU | 1 core |
| RAM | 512 MB |
| Swap | 512 MB |
| Network | Bridge: `vmbr0`, IPv4: `192.168.0.162/24`, GW: `192.168.0.1` |
| DNS | `192.168.0.153` |

**Install Grafana:**
```bash
pct start 221
pct enter 221

apt update && apt upgrade -y
apt install -y curl gnupg2 ca-certificates

# Add Grafana repo (deb822 format — avoids apt legacy format warnings on Debian 12)
curl -fsSL https://packages.grafana.com/gpg.key | gpg --dearmor \
  -o /usr/share/keyrings/grafana.gpg

cat > /etc/apt/sources.list.d/grafana.sources << 'EOF'
Types: deb
URIs: https://packages.grafana.com/oss/deb
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/grafana.gpg
EOF

apt update
apt install -y grafana

systemctl enable grafana-server
systemctl start grafana-server
systemctl status grafana-server
```

Grafana runs on port `3000`. Confirm:
```bash
ss -tlnp | grep 3000
```

**First login:** `http://192.168.0.162:3000`
- Default credentials: `admin` / `admin`
- Change password on first login — save to password manager

**Add Prometheus as a data source:**
1. Grafana → Connections → Data sources → Add data source
2. Select **Prometheus**
3. URL: `http://192.168.0.161:9090`
4. Click **Save & Test** — should show green

### 8.3 — Loki LXC (VMID 222)

**Create the container:**

| Setting | Value |
|---------|-------|
| VMID | `222` |
| Hostname | `loki` |
| Template | `debian-12-standard` |
| Disk | `eospool` — 10 GB |
| CPU | 1 core |
| RAM | 512 MB |
| Swap | 512 MB |
| Network | Bridge: `vmbr0`, IPv4: `192.168.0.163/24`, GW: `192.168.0.1` |
| DNS | `192.168.0.153` |

**Install Loki:**
```bash
pct start 222
pct enter 222

apt update && apt upgrade -y
apt install -y curl unzip

# Download latest Loki binary
LOKI_VERSION=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4 | tr -d v)
curl -LO "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip"
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki
chmod +x /usr/local/bin/loki
```

Create Loki config:
```bash
mkdir -p /etc/loki /var/lib/loki

cat > /etc/loki/config.yml << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
EOF
```

Create systemd unit:
```bash
cat > /etc/systemd/system/loki.service << 'EOF'
[Unit]
Description=Grafana Loki
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable loki
systemctl start loki
systemctl status loki
```

Loki runs on port `3100`. Confirm:
```bash
ss -tlnp | grep 3100
```

**Add Loki as a data source in Grafana:**
1. Grafana → Connections → Data sources → Add data source
2. Select **Loki**
3. URL: `http://192.168.0.163:3100`
4. Click **Save & Test** — should show green

### Monitoring Stack Checkpoints

- [ ] VMID 220 `prometheus` created, started, accessible at port 9090
- [ ] VMID 221 `grafana` created, started, accessible at `http://192.168.0.162:3000`
- [ ] Grafana default credentials changed — saved to password manager
- [ ] Prometheus added as Grafana data source — test passes
- [ ] VMID 222 `loki` created, started, accessible at port 3100
- [ ] Loki added as Grafana data source — test passes
- [ ] Git commit: `"eos — VMIDs 220/221/222 PLG stack baseline"`

---

## 9. Homepage LXC

Homepage is a self-hosted service dashboard. It reads from a YAML config and provides a clean overview of all running services across the lab.

### Create the Container

| Setting | Value |
|---------|-------|
| VMID | `261` |
| Hostname | `homepage` |
| Template | `debian-12-standard` |
| Disk | `eospool` — 4 GB |
| CPU | 1 core |
| RAM | 256 MB |
| Swap | 256 MB |
| Network | Bridge: `vmbr0`, IPv4: `192.168.0.164/24`, GW: `192.168.0.1` |
| DNS | `192.168.0.153` |

### Install Homepage

```bash
pct start 261
pct enter 261

apt update && apt upgrade -y
apt install -y curl git

# Install Node.js 20 LTS via NodeSource (Debian 12 container)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Create homepage working directory
mkdir -p /opt/homepage
cd /opt/homepage

# Install homepage
npm install -g pnpm
git clone https://github.com/gethomepage/homepage.git .
pnpm install
pnpm build
```

Create the systemd unit:
```bash
cat > /etc/systemd/system/homepage.service << 'EOF'
[Unit]
Description=Homepage Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/homepage
ExecStart=/usr/bin/node node_modules/.bin/next start -p 3000
Restart=on-failure
RestartSec=5s
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable homepage
systemctl start homepage
systemctl status homepage
```

Homepage runs on port `3000`. Confirm:
```bash
ss -tlnp | grep 3000
```

Access at: `http://192.168.0.164:3000`

Homepage config files live in `/opt/homepage/config/`. Initial configuration (services.yaml, settings.yaml, bookmarks.yaml) is edited directly in those YAML files. Add services and links as other containers come online.

### Checkpoints

- [ ] VMID 261 `homepage` created and started
- [ ] Homepage accessible at `http://192.168.0.164:3000`
- [ ] Config directory at `/opt/homepage/config/` confirmed
- [ ] Git commit: `"eos — VMID 261 homepage baseline"`

---

## 10. jxstudios.dev LXC

The jxstudios.dev static site (Astro) runs in a lightweight container. At this stage the container is created and baseline-configured, ready for the Astro build to be deployed into it. The site build itself is a separate session.

### Create the Container

| Setting | Value |
|---------|-------|
| VMID | `262` |
| Hostname | `jxstudios` |
| Template | `debian-12-standard` |
| Disk | `eospool` — 4 GB |
| CPU | 1 core |
| RAM | 256 MB |
| Swap | 256 MB |
| Network | Bridge: `vmbr0`, IPv4: `192.168.0.165/24`, GW: `192.168.0.1` |
| DNS | `192.168.0.153` |

### Install Node.js and Serve Tooling

```bash
pct start 262
pct enter 262

apt update && apt upgrade -y
apt install -y curl git

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install a static file server for serving built Astro output
npm install -g serve
```

### Placeholder Service Unit

Create a systemd unit that will serve the Astro build output once deployed. For now it will start but serve an empty directory:

```bash
mkdir -p /srv/jxstudios/dist

cat > /etc/systemd/system/jxstudios.service << 'EOF'
[Unit]
Description=jxstudios.dev Static Site
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/serve -s /srv/jxstudios/dist -l 3000
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable jxstudios
systemctl start jxstudios
```

Access at: `http://192.168.0.165:3000` — currently serves an empty index until the Astro site is built and deployed.

### Checkpoints

- [ ] VMID 262 `jxstudios` created and started
- [ ] Node.js 20 installed — `node --version` returns v20.x
- [ ] `serve` installed globally
- [ ] Service unit enabled — container survives reboot
- [ ] Git commit: `"eos — VMID 262 jxstudios placeholder baseline"`

---

## 11. Final Validation

All six services are deployed. Confirm everything survives a full Eos host reboot.

### Step 1 — Reboot Eos

From the Proxmox web UI: **Eos → Reboot**

Or via shell:
```bash
reboot
```

Wait approximately 90 seconds, then access the Proxmox web UI at `https://192.168.0.154:8006`.

### Step 2 — Confirm All Containers Auto-Started

In the web UI, all containers should show **running** status. If any are stopped, check their **Options → Start at boot** setting is enabled, then start them manually and fix the setting.

Enable start at boot for each container via web UI or shell:
```bash
for vmid in 220 221 222 250 261 262; do
  pct set $vmid --onboot 1
done
```

### Step 3 — Verify Each Service

| Service | URL / Method | Expected Result |
|---------|-------------|-----------------|
| Proxmox Web UI | `https://192.168.0.154:8006` | Login page loads |
| Nginx Proxy Manager | `http://192.168.0.160:81` | Admin UI loads |
| Prometheus | `http://192.168.0.161:9090` | Targets page accessible |
| Grafana | `http://192.168.0.162:3000` | Dashboard loads — data sources connected |
| Loki | `http://192.168.0.163:3100/ready` | Returns `ready` |
| Homepage | `http://192.168.0.164:3000` | Dashboard loads |
| jxstudios | `http://192.168.0.165:3000` | Serves (empty or placeholder) |

### Step 4 — Verify ZFS Pool

```bash
zpool status eospool
```

Pool should show ONLINE, single disk, no errors.

### Step 5 — Update the Flat Network Register

Add all confirmed container IPs to `flat_network_settings_register.md` §7 (Services Running on Flat Network) and record Eos host MAC and interface name in §1 and §2 if not already done.

### Step 6 — Screenshot and Commit

Take a screenshot of the Proxmox web UI showing all containers running. Then from Helios or admin PC:
```bash
git add -A
git commit -m "eos baseline complete — Proxmox + eospool + all 6 LXCs running"
git push
```

### Final Checkpoints

- [ ] All containers survived reboot and are running
- [ ] `onboot=1` confirmed for all six VMIDs
- [ ] All six services reachable from admin PC
- [ ] ZFS pool ONLINE after reboot
- [ ] Flat network register updated with all Eos container IPs
- [ ] Screenshot taken
- [ ] Final git commit pushed

---

## 12. Future — Second HDD and ZFS Mirror Conversion

> This section documents the procedure for when the second HDD is physically installed. Do not perform these steps now.

When the second HDD arrives and is installed in Eos, the single-disk `eospool` is converted to a two-disk ZFS mirror using `zpool attach`. This is a **non-destructive, online operation** — data is preserved and the pool remains accessible during the conversion. Proxmox does not need to be shut down.

### Overview of the Procedure

1. **Physically install the second HDD** into Eos and power on
2. **Identify the new drive** via `ls -la /dev/disk/by-id/` — find the new `ata-` entry
3. **Attach the new drive to the pool as a mirror:**
   ```bash
   zpool attach eospool \
     /dev/disk/by-id/<existing-hdd-id> \
     /dev/disk/by-id/<new-hdd-id>
   ```
4. **Monitor resilver progress** — ZFS copies existing data to the new drive:
   ```bash
   zpool status eospool
   # Shows: resilver in progress — X% done
   ```
5. **Wait for resilver to complete** — do not reboot or remove power during this process. Duration depends on data volume; a mostly empty 1 TB pool may take 30–60 minutes.
6. **Verify mirror is healthy:**
   ```bash
   zpool status eospool
   # Expected: mirror-0 ONLINE, both drives ONLINE
   ```
7. **Update documentation** — record both HDD IDs in `device_specs_list.md` and update this build guide to reflect the mirror state.

> After this conversion, `eospool` will have full single-drive fault tolerance. A subsequent RAM upgrade to 32 GB and the Nextcloud VM deployment follow in the same phase.

---

## 13. What Comes Next

### Immediate After This Build

- **Update flat network register:** Add Eos host to §1, MAC + interface to §2, all container IPs to §7
- **Update device_specs_list.md:** Add Eos as a new entry — status 🟡 In Progress → 🟢 Active
- **Node exporters:** Install Prometheus node_exporter on Helios and Eos host so the PLG stack has metrics from all always-on machines
- **NPM proxy hosts:** Add reverse proxy entries for each service in Nginx Proxy Manager as subdomains are decided
- **Homepage config:** Fill in `services.yaml` with all running services across Eos and Helios

### VLAN Migration (Phase 2+)

When the 3750G is configured and the maintenance window runs, each Eos container needs its IP updated from the flat range to its VLAN 20 LAB IP:

| Container | Flat IP | VLAN IP |
|-----------|---------|---------|
| npm | 192.168.0.160 | 192.168.20.50 |
| prometheus | 192.168.0.161 | 192.168.20.20 |
| grafana | 192.168.0.162 | 192.168.20.21 |
| loki | 192.168.0.163 | 192.168.20.22 |
| homepage | 192.168.0.164 | 192.168.20.61 |
| jxstudios | 192.168.0.165 | 192.168.20.62 |

Each container IP change:
```bash
pct set <vmid> --net0 name=eth0,bridge=vmbr0,ip=192.168.20.XX/24,gw=192.168.20.1
pct reboot <vmid>
```

The Eos host itself also migrates: `192.168.0.154` → `192.168.20.12`.

### Deferred (Future Phase)

- **Second HDD installation** → ZFS mirror conversion (see §12)
- **RAM upgrade to 32 GB** → opens headroom for heavier workloads
- **Nextcloud VM** (VMID 360) → after both RAM upgrade and ZFS mirror are in place
- **Astro site build and deployment** → populate the jxstudios LXC with actual site content

---

*Document version 1.1 — Updated 04/05/2026 — Revised for Proxmox VE 9.x / Debian 13 Trixie*
*Changes from v1.0: Repository setup rewritten for deb822 format and trixie codename; Ceph no-subscription repo added; apt modernize-sources guidance added; nag dismissal caveats added; Docker nesting requirement documented; Grafana repo converted to deb822 format; LXC template section updated with Debian 12 vs 13 guidance.*
*Companion files: `flat_network_settings_register.md` | `device_specs_list.md` | `helios-build-guide.md` | `genesis2-project-genesis-plan.md`*
