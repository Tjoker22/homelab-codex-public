# JXStudio Home Lab — Project Summary & Remaining Steps
**Site:** JXStudios  
**Date:** 18/03/2026  
**Status:** Phase 1 — Network maintenance window scheduled Monday. Genesis2 planning complete.  
**Companion Files:** `network_design_document_populated.md` | `network_settings_register_populated.md` | `genesis2-project-genesis-plan.md`

---

## ⚠️ Credentials — Write These Down On Paper Now

> These must be written on paper before the maintenance window begins.  
> Do not rely on digital access only — you may lose network access during the window.

| Item | Value |
|------|-------|
| Omada dashboard URL | https://192.168.99.2:8043 |
| Omada local username | `[your chosen username]` |
| Omada local password | `[your chosen password]` |
| Admin PC reserved IP | 192.168.10.10 |
| Admin Laptop reserved IP | 192.168.10.11 |
| Pi-hole reserved IP | 192.168.10.15 |
| Pi-hole admin page | http://192.168.10.15/admin |
| OC200 reserved IP | 192.168.99.2 |
| SG2008P management IP | 192.168.99.10 |
| Emergency direct access URL | https://192.168.99.2:8043 via patch cable to OC200 ETH2 |
| Emergency laptop static IP | 192.168.99.10/24 — GW 192.168.99.2 |

---

## Conversation Summary

This document summarises the full planning and build sessions for the JXStudios home lab network. It covers every major decision made, every issue encountered, and the current state of the project.

---

### What Was Built — Network Architecture

A four-VLAN segmented home lab network designed around an ISP rack (TP-Link Omada) and a server rack (Cisco). The design separates home devices, lab infrastructure, IoT devices, and network management into isolated networks with explicit inter-VLAN policy enforcement.

**VLAN Structure:**

| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 10 | HOME | 192.168.10.0/24 | Home PCs, phones, TVs, consoles, Pi-hole |
| 20 | LAB | 192.168.20.0/24 | Servers, VMs, Proxmox infrastructure |
| 30 | IOT | 192.168.30.0/24 | Smart devices — fully isolated |
| 99 | MGMT | 192.168.99.0/24 | Network device management only |

**Hardware:**

| Device | Model | Role | Mgmt IP | Status |
|--------|-------|------|---------|--------|
| TP-Link ER605 v2.20 | ER605 | WAN Gateway | 192.168.10.1 | Active |
| TP-Link SG2008P v3.20 | SG2008BP | Managed PoE Switch | 192.168.99.10 | Active |
| TP-Link OC200 | OC200 | Omada Controller | 192.168.99.2 | Active |
| TP-Link EAP653 (US) v1.0 | EAP653 | Wireless AP | 192.168.99.x | Active |
| Raspberry Pi 5 8GB | Pi 5 | MGMT device / Pi-hole / Tailscale | 192.168.99.5 | Active — Phase 2 MGMT migration |
| Proxmox Server — genesis2 | Custom | Hypervisor | 192.168.20.10 | Planning complete — install pending |
| Cisco Catalyst 3750G | 3750G | L3 Core Switch | 192.168.99.3 | Planned — Phase 2 |
| Cisco Catalyst 2960G | 2960G | L2 Access / Lab | 192.168.99.4 | Planned — Phase 2/3 |
| Cisco 1921 x2 | 1921 | Lab Edge / VPN | .20.254 / .20.253 | Planned — Phase 7 |

---

### What Was Built — Genesis2 Server (Project Genesis)

A Proxmox-based home lab server planned and designed in Session 2. Full detail in `docs/genesis2-project-genesis-plan.md`.

**Hardware:**

| Component | Spec |
|-----------|------|
| CPU | AMD Ryzen 7 5700X @ 3.4 GHz |
| GPU | NVIDIA MSI GeForce RTX 2060 6GB — passthrough Phase 6 |
| RAM | 64 GB DDR4-3600 MHz |
| Boot | 256 GB 2.5" SSD |
| Data | 3× 500 GB 2.5" HDD — RAIDZ1 (1 TB usable) |

**VM/LXC Register Summary:**

| VMID | IP | Hostname | Type | Role | Phase |
|------|-----|----------|------|------|-------|
| 220 | .20 | prometheus | LXC | Prometheus + exporters | 1b |
| 221 | .21 | grafana | LXC | Grafana dashboards | 1b |
| 222 | .22 | loki | LXC | Loki log aggregation | 1b |
| 230 | .30 | pihole2 | LXC | Pi-hole secondary DNS | 2 |
| 240 | .40 | forgejo | LXC | Forgejo internal Git | 3 |
| 250 | .50 | npm | LXC | Nginx Proxy Manager | 2 |
| 251 | .51 | tailscale | LXC | Tailscale subnet router | 2 |
| 360 | .60 | nextcloud | VM | Nextcloud | 4 |
| 261 | .61 | homepage | LXC | Homepage dashboard | 4 |
| 262 | .62 | jxstudios | LXC | jxstudios.dev website | 5 |
| 380 | .80 | ollama | VM | Ollama + Open WebUI — GPU passthrough | 6 |

---

### Key Decisions Made — Network

**Switch Stack — Option A Confirmed**
3750G only in production. 2960G free for lab experiments with 1921 routers.

**DNS Architecture — Two Phase**
- Phase 1: Pi-hole at 192.168.10.15 serves VLAN 10 only
- Phase 2+: Pi moves to MGMT at 192.168.99.5. Serves all VLANs. Genesis2 pihole2 LXC is secondary via Gravity Sync

**Controller IP — DHCP Reservation Approach**
OC200 MAC reserved to 192.168.99.2. Picks up address automatically when Port 1 switches to MGMT profile.

**ACL Enforcement — Two Layer**
- Omada Gateway ACL: broad VLAN-to-VLAN policy (Phase 1 active)
- Cisco 3750G IOS ACLs: host-level fine-grained rules (Phase 2+)

**Two-Tier Access Architecture**
- Tier 1: Home devices → Reverse Proxy (192.168.20.50) only
- Tier 2: Admin IPs → Proxmox :8006 / SSH direct only
- Proxmox is never a reverse proxy target

**Network Rollback — 18/03/2026**
MGMT VLAN configuration encountered issues during previous attempt. Network rolled back to flat 192.168.0.0/24. All backend VLAN structure, DHCP pools, reservations, and ACL rules remain intact in Omada. Maintenance window rescheduled to Monday. Genesis2 planning session used the intervening time productively.

### Key Decisions Made — Genesis2

**Storage: RAIDZ1**
Three 500 GB HDDs as RAIDZ1 pool. 1 TB usable. Industry-relevant ZFS skill, checksumming, single-drive fault tolerance. SSD for Proxmox OS and ISOs.

**VMID Convention: 2xx LXC / 3xx VM**
Last two digits mirror IP last octet. Type and IP readable from ID alone.

**Pi as Primary DNS and Tailscale**
Pi 5 is always-on, no planned maintenance. Genesis2 is secondary/backup for DNS. Same for Tailscale subnet routing.

**Observability First**
PLG stack (Prometheus, Loki, Grafana) deployed before any application services.

**Nextcloud as VM, Multi-user from Day One**
OS-level isolation appropriate for real user data. Migration from single-user later is painful — building ahead costs little.

**Forgejo over Gitea**
Better community trajectory post-fork. API-compatible. Push mirror to GitHub supported natively.

**jxstudios.dev: Astro**
Modern static site generator. Strong portfolio signal. No CMS overhead needed.

---

### Issues Encountered and Resolved

**OC200 Controller Access Loss — Twice**
Root cause: Manually changing controller IP caused auth failure state.
Resolution: Factory reset with config backup restore. IP via DHCP reservation during maintenance window.

**MGMT VLAN Window Rollback**
Root cause: Issues encountered during MGMT VLAN configuration.
Resolution: Rolled back to flat network. Pre-window prep remains complete. Monday window replanned.

**ER605 Login Lockout**
Caused by login attempts on wrong device. 2 hour timer. Resolution: wait.

**Direct Access Recovery Procedure — For Reference**
```bash
sudo nmcli con add type ethernet \
  ifname [iface] \
  con-name direct-oc200 \
  ip4 192.168.99.10/24 \
  gw4 192.168.99.2
sudo nmcli con up direct-oc200
ping 192.168.99.2
# Access https://192.168.99.2:8043
sudo nmcli con delete direct-oc200
```

---

### Static IP and MAC Register

| Device | IP | VLAN | MAC |
|--------|-----|------|-----|
| ER605 — WAN Gateway | 192.168.10.1 | 10 | [MAC_REDACTED] |
| OC200 — Omada Controller | 192.168.99.2 | 99 | [MAC_REDACTED] |
| TL-SG2008P | 192.168.99.10 | 99 | [MAC_REDACTED] |
| EAP653 | 192.168.99.x | 99 | [MAC_REDACTED] |
| Admin PC | 192.168.10.10 | 10 | [MAC_REDACTED] |
| Admin Laptop | 192.168.10.11 | 10 | [MAC_REDACTED] |
| Partner PC | 192.168.10.12 | 10 | `[MAC]` |
| Raspberry Pi 5 — Pi-hole / MGMT | 192.168.10.15 (Phase 1) → 192.168.99.5 (Phase 2+) | 10 → 99 | [MAC_REDACTED] |
| Philips Hue Bridge | 192.168.30.5 | 30 | [MAC_REDACTED] |
| genesis2 — Proxmox Host | 192.168.20.10 | 20 | `[MAC — after install]` |
| Nginx Proxy Manager | 192.168.20.50 | 20 | N/A — LXC |
| Tailscale LXC | 192.168.20.51 | 20 | N/A — LXC |
| 3750G SVI MGMT | 192.168.99.3 | 99 | N/A |
| 2960G MGMT | 192.168.99.4 | 99 | N/A |

---

### ACL Rules — Current State

**Active — Phase 1 (Gateway ACL — LAN→LAN)**

| # | Name | Source → Destination | Policy | Status |
|---|------|----------------------|--------|--------|
| 1 | Home-to-MGMT | HOME → MGMT | Permit | ✅ Enabled |
| 2 | Block-Home-to-Lab | HOME → LAB | Deny | ✅ Enabled |
| 3 | Block-Home-to-IoT | HOME → IOT | Deny | ✅ Enabled |
| 4 | Block-IoT-to-Home | IOT → HOME | Deny | ✅ Enabled |
| 5 | Block-IoT-to-Lab | IOT → LAB | Deny | ✅ Enabled |
| 6 | Block-IoT-to-MGMT | IOT → MGMT | Deny | ✅ Enabled |
| 7 | MGMT-Full-Access | MGMT → HOME, LAB, IOT | Permit | ✅ Enabled |

---

## Pre-Window Prep — Status

| Task | Status |
|------|--------|
| VLANs 10, 20, 30, 99 created on ER605 | ✅ Complete |
| DHCP pools configured per VLAN | ✅ Complete |
| DHCP reservations set — all devices | ✅ Complete |
| 7 Gateway ACL rules created and enabled | ✅ Complete |
| IP Groups created — all 5 | ✅ Complete |
| OC200 reset and config restored | ✅ Complete |
| Port profiles created — HOME, MGMT, TRUNK-ALL, LAN-Uplink | ✅ Complete |
| Raspberry Pi static IP removed — Pi back up on DHCP | ✅ Complete |
| Fresh config backup saved to Git repo | ✅ Complete |
| SG2008P management VLAN | ⏩ Maintenance window — Step 6 |
| Credentials written on paper | ☐ Do this before starting the window |

> **Pre-window prep is complete. Write credentials on paper then begin the window.**

---

## Maintenance Window — Full Order of Operations

> Inform household of planned disruption before starting.  
> Keep Admin Laptop on Wi-Fi connected throughout — backup admin console.  
> One port at a time. Verify before moving to the next step.  
> Do not begin a step until the previous step is fully verified.

---

### Step 1 — Media Devices (TV, PS5)

```
Where: Devices → SG2008P → Ports → Port Settings

Action:
  Change each media device port to HOME profile — one at a time
  Wait 60 seconds after each change

Verify after each device:
  ☐  Device shows 192.168.10.x in Omada → Clients
  ☐  Internet works on the device
  ☐  No other devices lost connectivity

If device does not get new IP after 60 seconds:
  → Power cycle the device → wait 60 seconds → check Clients
```

---

### Step 2 — Remaining Home Devices

```
Action:
  Change remaining home device ports to HOME profile — one at a time

Verify after each:
  ☐  Device shows 192.168.10.x address
  ☐  Internet works
  ☐  No unexpected devices lost connectivity
```

---

### Step 3 — EAP Port → HOME Profile

```
Action:
  Change EAP port on SG2008P to HOME profile

What happens automatically:
  Admin Laptop (Wi-Fi) gets DHCP lease on VLAN 10 → 192.168.10.11
  All wireless clients reconnect on VLAN 10

Verify:
  ☐  Admin Laptop shows 192.168.10.11
  ☐  Internet works on Admin Laptop
  ☐  Omada dashboard still reachable from Admin Laptop
  ☐  Other wireless devices show 192.168.10.x

  ★  Admin Laptop is now confirmed backup admin console
     Keep it on Wi-Fi for the rest of the window
```

---

### Step 4 — Update Pi-hole DNS in Omada

```
Where: Settings → Wired Networks → LAN → HOME (VLAN 10)

Action:
  Change DNS Primary from 1.1.1.1 to 192.168.10.15
  Save

Note: Pi is not yet on VLAN 10 — takes effect after Step 5.

Verify:
  ☐  DNS entry saved as 192.168.10.15 in VLAN 10 config
```

---

### Step 5 — Shared Port (Admin PC + Raspberry Pi) → HOME Profile

```
Note: Admin PC and Pi share one port via an unmanaged switch.
Both devices move simultaneously when this port changes.

Action:
  Change shared unmanaged switch port to HOME profile

What happens:
  Admin PC  → DHCP → 192.168.10.10 (reservation)
  Pi        → DHCP → 192.168.10.15 (reservation)

Verify Admin PC:
  ☐  Shows 192.168.10.10 — run ipconfig in terminal
  ☐  Internet works from Admin PC
  ☐  Omada dashboard reachable from Admin PC

Verify Pi via KVM:
  ☐  Shows 192.168.10.15 — run hostname -I
  ☐  Pi-hole admin loads: http://192.168.10.15/admin
  ☐  Pi-hole query log shows DNS activity

If Admin PC gets wrong IP:
  → ipconfig /release then ipconfig /renew
  → If still wrong — use Admin Laptop as primary, continue

If Pi gets wrong IP:
  → sudo dhclient -r then sudo dhclient
  → Verify reservation MAC matches exactly
```

---

### Step 6 — SG2008P Management VLAN → 99

```
Note: This was moved from pre-window prep. Safe to apply now
that home device ports are confirmed on VLAN 10.

Where: Devices → SG2008P → Config → VLAN Interface

Action:
  Set Management VLAN to 99 (MGMT)
  Apply

Verify:
  ☐  Switch still shows Connected in Omada Devices
  ☐  Switch config still accessible
```

---

### Step 7 — OC200 Port → MGMT Profile (Point of No Return)

```
Pre-flight — confirm ALL of these before touching Port 1:
  ☐  Admin Laptop confirmed 192.168.10.11 with internet
  ☐  Admin PC confirmed 192.168.10.10 with internet
  ☐  Pi confirmed 192.168.10.15 — Pi-hole working
  ☐  SG2008P management VLAN confirmed on 99
  ☐  Dashboard URL on paper: https://192.168.99.2:8043
  ☐  Login credentials on paper

Action:
  Change Port 1 (OC200) to MGMT profile via Port Settings
  Dashboard goes offline immediately — expected
  OC200 picks up 192.168.99.2 from DHCP reservation

Reconnect:
  Open new browser tab on Admin Laptop or Admin PC
  Go to https://192.168.99.2:8043
  Accept certificate warning
  Log in

Verify:
  ☐  Dashboard loads at https://192.168.99.2:8043
  ☐  All devices adopted — none disconnected or pending
  ☐  Clients page shows all devices on correct VLANs
  ☐  SG2008P online in Devices
  ☐  ER605 online in Devices
  ☐  EAP online in Devices
```

---

### Final Verification — Before Closing the Window

```
Network:
  ☐  Every home device shows 192.168.10.x
  ☐  Internet works on all devices — wired and wireless
  ☐  No devices stuck on old flat network addresses

Pi-hole:
  ☐  Pi at 192.168.10.15 confirmed via KVM
  ☐  Pi-hole admin: http://192.168.10.15/admin loads
  ☐  Query log shows active DNS traffic
  ☐  VLAN 10 DNS shows 192.168.10.15 in Omada

Admin access:
  ☐  Dashboard at https://192.168.99.2:8043
  ☐  Admin PC reaches dashboard — 192.168.10.10 confirmed
  ☐  Admin Laptop reaches dashboard — 192.168.10.11 confirmed

Documentation:
  ☐  Change log entries completed in register
  ☐  Screenshot — Omada Clients — all devices on VLAN 10
  ☐  Screenshot — Port Settings — all profiles applied
  ☐  Post-window config backup taken
  ☐  Git commit — "Phase 1 complete — post-window baseline"
  ☐  Phase 1 checklist marked complete in NDD and register
```

---

### If Something Goes Wrong

```
Lost dashboard access:
  → Try https://192.168.99.2:8043 from Admin Laptop (Wi-Fi)
  → Try https://192.168.99.2:8043 from Admin PC
  → If neither — patch cable to OC200 ETH2 (see recovery above)

Device stuck on wrong IP:
  → Windows: ipconfig /release then ipconfig /renew
  → Linux/Pi: sudo dhclient -r then sudo dhclient
  → Last resort: power cycle the device

Pi-hole not receiving queries:
  → Confirm Pi is at 192.168.10.15 via KVM
  → Check VLAN 10 DNS in Omada shows 192.168.10.15
  → pihole restartdns

Unexpected outage on any port change:
  → Change the port back to previous profile immediately
  → Diagnose from Admin Laptop before retrying
  → Do not proceed until current step is resolved
```

---

## Genesis2 — Proxmox Installation Checklist

> Maintenance-window-independent — can be done any time after hardware is ready.
> Network config will need updating after Monday's window completes.

### Pre-Install

| Task | Status |
|------|--------|
| Verify hardware — POST, all drives detected | ☐ |
| Download Proxmox VE ISO (current stable) | ☐ |
| Flash ISO to USB installer | ☐ |
| Confirm BIOS settings — IOMMU/AMD-Vi enabled (required for future GPU passthrough) | ☐ |
| Note network interface names for bridge config | ☐ |

### Proxmox Installer Decisions

| Setting | Choice | Notes |
|---------|--------|-------|
| Target disk | 256 GB SSD | Boot drive only — HDDs configured separately post-install |
| Filesystem | ext4 | Sufficient for boot volume — ZFS on root not required |
| Management IP | Temporary — see below | Set per current network phase |
| Hostname | genesis2.jxstudios.dev | Set permanently from day one |

**Temporary IP by network phase:**

| Current network | Set installer IP to |
|-----------------|---------------------|
| Flat 192.168.0.0/24 (now) | 192.168.0.20 |
| VLAN 10 HOME (after Monday) | 192.168.10.20 (temporary — update after Phase 2) |
| VLAN 20 LAB (Phase 2+) | 192.168.20.10 (permanent) |

### Post-Install (Session Pending)

| Task | Status |
|------|--------|
| First login — web UI at https://[ip]:8006 | ☐ |
| Update all packages — `apt update && apt full-upgrade` | ☐ |
| Configure VLAN-aware bridge — set bridge-vlan-aware yes | ☐ |
| Create RAIDZ1 pool from three HDDs — document drive IDs | ☐ |
| Add datapool storage in Proxmox web UI | ☐ |
| Record genesis2 MAC address in settings register | ☐ |
| Set up SSH key authentication — disable password auth | ☐ |
| Take first config snapshot / backup | ☐ |
| Git commit — "Phase 1b — Genesis2 Proxmox baseline" | ☐ |

> Full post-install procedure will be documented in a dedicated session.

---

## Future Phases — Remaining Work

### Phase 1b — Genesis2 Proxmox Install + Observability Stack
- [ ] Proxmox installation session — dedicated planning and procedure
- [ ] ZFS RAIDZ1 pool creation — document drive IDs used
- [ ] Deploy observability stack — Prometheus, Grafana, Loki LXCs
- [ ] Verify PLG stack healthy before proceeding

### Phase 2 — Catalyst 3750G + Infrastructure Services
- [ ] Verify PoE standard on 3750G — `show power inline` — before Pi PoE HAT purchase
- [ ] Confirm Option A confirmed — update all docs
- [ ] Verify IOS version and feature set — `show version` / `show license`
- [ ] Configure VLANs, SVIs, default route, inter-rack trunk
- [ ] Configure IOS ACLs for host-level rules
- [ ] Connect inter-rack trunk — SG2008P Port 7 to 3750G Gi0/1
- [ ] Migrate genesis2 to final IP 192.168.20.10
- [ ] Deploy NPM LXC — 192.168.20.50
- [ ] Deploy Tailscale LXC — 192.168.20.51
- [ ] Deploy Pi-hole secondary LXC — 192.168.20.30
- [ ] Migrate Pi to MGMT VLAN 192.168.99.5
- [ ] Configure Gravity Sync — Pi (primary) → pihole2 (secondary)
- [ ] Configure Tailscale DNS override — Pi-hole as mobile nameserver
- [ ] Enable pending ACL rules — Proxmox :8006 and SSH

### Phase 3 — Developer Tooling + Cisco 2960G (Option A only for 2960G)
- [ ] Deploy Forgejo LXC — 192.168.20.40
- [ ] Configure GitHub push mirror from Forgejo
- [ ] Set Pi as Ansible control node
- [ ] Set Pi as serial console server — ser2net
- [ ] 2960G: configure as lab device (Option A) or access layer (Option B)

### Phase 4 — Applications
- [ ] Deploy Nextcloud VM — 192.168.20.60 — data on RAIDZ1 pool
- [ ] Deploy Homepage LXC — 192.168.20.61
- [ ] Enable pending ACL rules — Lab-to-Home, admin IPs confirmed

### Phase 5 — Presentation
- [ ] Deploy jxstudios.dev LXC — 192.168.20.62
- [ ] Build Astro site — portfolio/showcase content

### Phase 6 — GPU Passthrough (Ollama)
- [ ] Dedicated planning session — IOMMU groups, VFIO config
- [ ] Deploy Ollama VM — 192.168.20.80
- [ ] Configure RTX 2060 passthrough

### Phase 7 — Cisco 1921 Routers (Optional)
- [ ] Lab edge and VPN configuration
- [ ] Document in NDD

### Pending Items (From Sessions)

| Item | Priority | Notes |
|------|----------|-------|
| Verify 3750G PoE standard | High | `show power inline` — before PoE HAT purchase. Pi 5 may exceed 802.3af 15.4W ceiling under load. |
| Record genesis2 MAC address | After install | Update network_settings_register_populated.md |
| Partner PC MAC address | When available | Update register — 192.168.10.12 |
| Proxmox installation session | Next Genesis2 session | Full installer decisions and post-install procedure |
| GPU passthrough planning session | Phase 6 | Dedicated session before Ollama VM creation |
| Quick guide OC200 IP fix | Low | 192.168.99.1 → 192.168.99.2 in two places |
| Pi MAC discrepancy check | Before Phase 2 | Quick guide .B5:34 vs register .B5:43 — verify on device |

---

## Maintenance Window Schedule

> Major disruptions planned for Mondays.

| Window | Date | Scope | Status |
|--------|------|-------|--------|
| Window 1 | ~09/03/2026 | Initial VLAN creation, DHCP, ACL rules | ✅ Complete |
| Window 2 | Monday (next) | Phase 1 port migrations, MGMT VLAN, OC200 cutover | ☐ Scheduled |
| Window 3 | Future Monday | Phase 2 — 3750G + inter-rack trunk | 🔲 Not scheduled |

---

## Documentation Status

| Document | Status | Notes |
|----------|--------|-------|
| network_design_document_populated.md | Current | Update after window |
| network_settings_register_populated.md | Current | Update after window |
| genesis2-project-genesis-plan.md | ✅ Created 18/03/2026 | New — Genesis2 planning Session 2 |
| CLAUDE.md | ✅ Updated 18/03/2026 | v3.0 — Genesis2 added |
| project-summary-and-remaining-steps.md | This file | Update after window |
| network_setup_quick_guide.md | Needs updates | See quick guide list below |

### Quick Guide Updates Still Needed
- [ ] OC200 IP in body text: 192.168.99.1 → 192.168.99.2 (two places)
- [ ] Add dashboard URL: https://192.168.99.2:8043
- [ ] Clean up OC200 and Hue Bridge reservation table rows
- [ ] Add note: Hue Bridge stays on HOME until Phase 2
- [ ] Mark HOME DNS 1.1.1.1 as temporary
- [ ] Verify Pi MAC discrepancy: quick guide .B5:34 vs register .B5:43 — check device

---

*Last updated: 18/03/2026 — Session 2 complete. Genesis2 planning complete. Network window rescheduled to Monday.*
