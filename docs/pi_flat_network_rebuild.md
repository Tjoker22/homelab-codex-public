# Pi Flat Network Rebuild — Pi-hole + Tailscale
### Ad-blocking at home and remotely on your phone
> **Target:** Raspberry Pi 5 · Raspberry Pi OS Lite 64-bit · Flat network `192.168.0.x`
> **Pi IP:** `192.168.0.153` (temp) · Genesis: `.152` · Helios: `.151`

---

## What This Sets Up

```
Flat Network (192.168.0.0/24)
  All home devices → DNS → Pi-hole (192.168.0.153:53) → Ad-blocking ✅

Phone on 4G / away from home
  Phone → Tailscale VPN → Pi's Tailscale IP → Pi-hole DNS → Ad-blocking ✅

You (SSH / browser) → Tailscale → 192.168.0.153 → any home device ✅
```

**Tailscale is configured as a subnet router**, not an exit node.
This means only DNS traffic goes through the Pi when you're away — your
phone's regular internet traffic routes normally. No home bandwidth consumed.

---

## Decision: Clean Flash or Reconfigure In-Place?

Given the previous reset and broken state, **a clean flash is strongly recommended**.
It takes 10 minutes and eliminates any leftover config drift.

> **If you want to reconfigure in-place instead**, skip to [Section 3](#3--install-pi-hole)
> and follow from there — the installation commands are safe to re-run.

---

## 1 — Flash the SD... Wait, You're on SSD

Since the Pi boots from a USB SSD, you have two options:

**Option A — Flash directly to the SSD from your main machine (cleanest)**

1. Connect the SSD via USB to your main machine.
2. Open **Raspberry Pi Imager** → Choose Device: Pi 5 → Choose OS: Raspberry Pi OS Lite (64-bit) → Choose Storage: your SSD.
3. Click **Edit Settings** before writing:

**General tab:**
```
Hostname:   hestia
Username:   admin-yoyo
Password:   [strong password]
```

**Services tab:**
```
☑ Enable SSH
● Use password authentication
```

4. Save → Yes to apply → Yes to write.

**Option B — Boot from SD temporarily, wipe and reinstall to SSD**

Flash a fresh SD card the same way, boot from it, then use `rpi-clone` or
`sudo dd` to write a fresh image to the SSD. Less straightforward — Option A is easier.

---

## 2 — First Boot & Static IP

### 2.1 — Boot and Connect

Insert SSD, power on, wait ~60 seconds.

Find the Pi on your network:
```bash
ping hestia.local
# or
nmap -sn 192.168.0.0/24 | grep -A2 "Raspberry"
```

SSH in:
```bash
ssh admin-yoyo@hestia.local
```

### 2.2 — Update First

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y
```

### 2.3 — Set Static IP on the Pi

On a flat network without a managed DHCP controller, set the IP directly on the device. First check to see which service is running on the device.

```bash
systemctl status dhcpcd
systemctl status NetworkManager
```

**If running dhcpd:**
```bash
sudo nano /etc/dhcpcd.conf
```

Add at the bottom:

```
interface eth0
static ip_address=192.168.0.153/24
static routers=192.168.0.1
static domain_name_servers=127.0.0.1
```

> `domain_name_servers=127.0.0.1` points to Pi-hole on itself — set this now
> so it's in place as soon as Pi-hole is installed.

Apply and reconnect:
```bash
sudo systemctl restart dhcpcd
```

**If running NetworkManager:**
```bash
# Set the static IP
sudo nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.0.153/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns 127.0.0.1

# Bring the connection down and back up to apply
sudo nmcli con down "Wired connection 1" && sudo nmcli con up "Wired connection 1"
```

Reconnect using the new IP:
```bash
ssh admin-yoyo@192.168.0.153
```

### 2.4 — Harden SSH (Recommended)

From your **main machine**, copy your SSH key:
```bash
ssh-copy-id admin-yoyo@192.168.0.153
```

Then on the Pi, disable password auth:
```bash
sudo nano /etc/ssh/sshd_config
```
Set:
```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no (was prohibit-password)
```

```bash
sudo systemctl restart ssh
```
> ⚠️ Confirm key login works **before** closing your current session.

> From a **windows machine** 
To generate a new key:
```powershell
ssh-keygen -t ed25519 -C "windows-pc"
```
When prompted for a file location, just hit Enter to accept the default (C:\Users\YourName\.ssh\id_ed25519). Set a passphrase if you want an extra layer, or *hit Enter twice to skip it*.

PowerShell doesn't have `ssh-copy-id`, so use this instead
```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh admin-yoyo@192.168.0.153 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

It'll ask for your password one last time. After this, password won't be needed from this machine.
```powershell
ssh pi@192.168.0.153
```
It should log you straight in with no password prompt. Don't proceed to Step 3 until this works.

---

## 3 — Install Pi-hole

### 3.1 — Run the Installer

```bash
curl -sSL https://install.pi-hole.net | bash
```

Work through the installer with these choices:

| Prompt | Choice |
|---|---|
| Network interface | `eth0` |
| Upstream DNS | Cloudflare `1.1.1.1` / `1.0.0.1` |
| Block lists | Keep default (StevenBlack) |
| Admin web interface | **Yes** |
| lighttpd web server | **Yes** |
| Query logging | **Yes** |
| Privacy mode | **0 — Show everything** |

**Copy the admin password shown at the end.**

### 3.2 — Verify Pi-hole is Running

```bash
pihole status
```

Expected:
```
  [✓] FTL is listening on port 53
  [✓] Pi-hole blocking is enabled
```
Could be:
```
 [✓] FTL is listening on port 53
     [✓] UDP (IPv4)
     [✓] TCP (IPv4)
     [✓] UDP (IPv6)
     [✓] TCP (IPv6)

  [✓] Pi-hole blocking is enabled
```

### 3.3 — Change Admin Password (Optional)

```bash
pihole -a -p
```

### 3.4 — Set Pi-hole to Listen on All Interfaces

This is required so that Tailscale can route DNS queries to Pi-hole when you're remote.
By default Pi-hole only listens on `LOCAL` (local subnet queries only).

```bash
sudo pihole-FTL --config dns.listeningMode "ALL"
sudo systemctl restart pihole-FTL
```

> ⚠️ On a flat/home network this is safe. Once you move to MGMT VLAN,
> you can tighten this back to `LOCAL` with proper ACL rules in place.

Verify the change:
```bash
sudo pihole-FTL --config dns.listeningMode
# Should return: ALL
```

### 3.5 — Access the Admin Dashboard

From any browser on the network:
```
http://192.168.0.153/admin
```

---

## 4 — Point Your Router's DNS at Pi-hole

Every device on the flat network will automatically use Pi-hole for DNS
once you update the router's DHCP DNS setting.

1. Log into your router admin panel (usually `192.168.0.1`).
2. Find **DHCP Settings** or **LAN Settings**.
3. Set **DNS Primary** to `192.168.0.153`.
4. Leave **DNS Secondary** blank, or use `1.1.1.1` as a fallback.
5. Save and apply.

Devices will pick up the new DNS on their next DHCP lease renewal.
Force it immediately on a device with:
```bash
# Linux
sudo dhclient -r && sudo dhclient

# macOS — disconnect and reconnect Wi-Fi, or:
sudo ipconfig set en0 DHCP

# Windows
ipconfig /release && ipconfig /renew
```

### Verify Ad-blocking is Working

Visit [https://pi-hole.net/pages/ads-test.html](https://pi-hole.net/pages/ads-test.html)
or check the Pi-hole dashboard query log for your device's DNS activity.

```bash
pihole tail   # Live DNS query log in terminal
```

---

## 5 — Add Blocklists

The default StevenBlack list is a solid start (~180k domains), but combining
several lists significantly improves coverage. Add these via the admin dashboard:

**Pi-hole Admin → Adlists → Add one URL at a time → Save → run `pihole -g`**

### Recommended Blocklists

| List | URL | Focus | ~Domains |
|------|-----|-------|----------|
| StevenBlack Unified | `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` | Ads, malware (default) | ~180k |
| StevenBlack + Social | `https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts` | Ads + social media tracking | ~250k |
| OISD Big | `https://big.oisd.nl/domainswild` | Comprehensive — ads, tracking, malware | ~1.4M |
| HaGeZi Multi Pro | `https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt` | Ads, tracking, analytics | ~500k |
| HaGeZi Threat Intel | `https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt` | Malware, phishing, ransomware C2 | ~1M |
| URLhaus Malware | `https://urlhaus-filter.pages.dev/urlhaus-filter-domains.txt` | Active malware domains | ~20k |
| NoTrack Tracker | `https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt` | Trackers and analytics | ~15k |

> **Start with OISD Big + HaGeZi Multi Pro + HaGeZi Threat Intel** for strong all-round
> coverage without excessive false positives. Add more lists as needed.

### Add Lists via CLI (Faster)

```bash
sqlite3 /etc/pihole/gravity.db <<'EOF'
INSERT INTO adlist (address, enabled, comment) VALUES
('https://big.oisd.nl/domainswild', 1, 'OISD Big'),
('https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt', 1, 'HaGeZi Multi Pro'),
('https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt', 1, 'HaGeZi Threat Intel'),
('https://urlhaus-filter.pages.dev/urlhaus-filter-domains.txt', 1, 'URLhaus Malware');
EOF
```

Then update gravity to download and process all lists:
```bash
pihole -g
```

This will take a minute or two. When done, check the dashboard — you should
see a much higher blocked domains count.

---

## 6 — Install Tailscale

### 6.1 — Install

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 6.2 — Enable IP Forwarding

Required for Tailscale to route traffic between your devices and your home network:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### 6.3 — Authenticate and Advertise Subnet

This brings Tailscale up and advertises your flat network so you can reach
all home devices remotely:

```bash
sudo tailscale set --advertise-routes=192.168.0.0/24
sudo tailscale up
```

You'll get an authentication URL. Open it in a browser, log into your
Tailscale account, and authorise the device. It will appear in your
[Tailscale admin console](https://login.tailscale.com/admin/machines) as `hestia`.

### 6.4 — Approve Routes in the Admin Console

1. Go to [https://login.tailscale.com/admin/machines](https://login.tailscale.com/admin/machines)
2. Click **…** next to `hestia`
3. Click **Edit route settings**
4. Toggle **`192.168.0.0/24`** → on
5. Save

### 6.5 — Verify Tailscale is Up

```bash
tailscale status
# Should show hestia with a 100.x.x.x IP
tailscale ip
# Shows your Pi's Tailscale IP — note this
```

---

## 7 — Mobile Ad-blocking via Tailscale DNS Override

This is the key step that restores ad-blocking on your phone when away from home.
Tailscale routes your phone's DNS queries through Pi-hole without tunneling
all your traffic — so it's lightweight and doesn't slow anything down.

### 7.1 — Add Pi-hole as Tailscale DNS Nameserver

1. Go to [https://login.tailscale.com/admin/dns](https://login.tailscale.com/admin/dns)
2. Under **Nameservers**, click **Add nameserver → Custom**
3. Enter the **Tailscale IP of the Pi** (the `100.x.x.x` address from `tailscale ip`)
4. Click **Save**
5. Enable the **Override local DNS** toggle

> This tells every Tailscale-connected device to use your Pi-hole for DNS
> whenever they're connected to the tailnet — even on mobile data.

### 7.2 — Install Tailscale on Your Phone

- **iOS:** App Store → Tailscale → Install → Log in with your account
- **Android:** Play Store → Tailscale → Install → Log in

Once connected, all DNS queries from your phone will resolve through Pi-hole.
You don't need to select an exit node — just being connected to the tailnet is enough.

### 7.3 — Verify on Your Phone

1. Connect your phone to Tailscale (toggle it on in the app)
2. Visit a site with ads — they should be blocked
3. Check the Pi-hole dashboard query log — you should see your phone's queries appearing

---

## 8 — Service Management

### Check All Services

```bash
sudo systemctl status pihole-FTL      # Pi-hole DNS
sudo systemctl status tailscaled      # Tailscale
```

### Enable on Boot (Should Be Automatic)

```bash
sudo systemctl enable pihole-FTL
sudo systemctl enable tailscaled
```

### Reboot Test

```bash
sudo reboot
```

After ~45 seconds, SSH back in and verify both services show `active (running)`.

---

## 9 — Maintenance Commands

### Pi-hole

```bash
pihole status          # Status summary
pihole -g              # Update gravity / re-download blocklists
pihole tail            # Live DNS query log
pihole -c              # Chronometer dashboard in terminal
pihole -a -p           # Change admin password
pihole enable          # Re-enable blocking
pihole disable 5m      # Pause blocking for 5 minutes (useful for testing)
pihole -up             # Update Pi-hole itself
```

### Tailscale

```bash
tailscale status       # Show connected tailnet devices
tailscale ip           # Show Pi's Tailscale IP
tailscale ping hestia  # Test connectivity
sudo tailscale update  # Update Tailscale
```

### System

```bash
sudo apt update && sudo apt full-upgrade -y   # System updates
vcgencmd measure_temp                          # CPU temperature
df -h                                          # Disk usage (SSD)
htop                                           # Resource usage
```

---

## 10 — What Changes When You Move to the Segmented Network

When you're ready to migrate the Pi to MGMT VLAN 99 at `192.168.99.5`,
the following will need to change on the Pi:

| Item | Flat Network (now) | MGMT VLAN (later) |
|------|-------------------|-------------------|
| IP | `192.168.0.153` (DHCP static) | `192.168.99.5` (Omada reservation) |
| VLAN | Flat / untagged | VLAN 99 MGMT |
| Switch port profile | Flat | MGMT |
| Pi-hole listening mode | `ALL` | `LOCAL` (ACL rules handle cross-VLAN) |
| DNS scope | Flat network only | All 4 VLANs |
| Tailscale advertised routes | `192.168.0.0/24` | `192.168.99.0/24` + others |
| Tailscale nameserver | `100.x.x.x` (same) | `100.x.x.x` (same) |
| Additional services | None | TFTP, Syslog, Ansible, ser2net |

The Pi-hole and Tailscale installs carry over with zero reinstallation.
The migration is network plumbing only — see NDD §6.2 for the full steps.

---

*Verified against official Pi-hole and Tailscale documentation via Context7 — March 2026*
*Tailscale Pi-hole mobile ad-blocking: https://tailscale.com/docs/solutions/block-ads-all-devices-anywhere-using-raspberry-pi*
