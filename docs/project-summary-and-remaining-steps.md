# JXStudios Home Lab — Project Summary & Remaining Steps
**Site:** JXStudios  
**Date:** 22/03/2026  
**Status:** Network window deferred — admin device setup pending. Genesis2 install active on flat network. CCNA study in progress.  
**Companion Files:** `network_design_document_populated.md` | `network_settings_register_populated.md` | `genesis2-project-genesis-plan.md`

---

## Current Focus — 22/03/2026

The Phase 1 network maintenance window has been intentionally deferred. All Omada backend configuration is complete and staged — nothing needs to be redone. The window is paused, not abandoned.

**Active work:**
- Genesis2 Proxmox install and observability stack — running on flat network 192.168.0.0/24
- CCNA exam preparation — directly relevant to Phase 2 (3750G configuration)

**Blocked on:**
- Admin device setup (Windows/Mac admin laptops) — needs to be fully configured before the window
- Discovery Utility firewall issue on Windows — documented below, needs to be resolved before window day

**Network state:** Flat 192.168.0.0/24. All VLAN, DHCP, ACL, and reservation config is staged in Omada and intact. No live changes needed. Safe to leave as-is indefinitely.

---

## ⚠️ Credentials — Write These Down On Paper Before Any Window

| Item | Value |
|------|-------|
| Omada dashboard URL | https://192.168.99.2:8043 |
| Omada local username | `[your chosen username]` |
| Omada local password | `[your chosen password]` |
| ER605 device account username | `[Settings → Site → Device Account]` |
| ER605 device account password | `[Settings → Site → Device Account]` |
| Admin PC reserved IP | 192.168.10.10 |
| Admin Laptop reserved IP | 192.168.10.11 |
| Pi-hole reserved IP | 192.168.10.15 |
| Pi-hole admin page | http://192.168.10.15/admin |
| OC200 reserved IP | 192.168.99.2 |
| SG2008P management IP | 192.168.99.10 |
| Emergency direct access | https://192.168.99.2:8043 via patch cable to OC200 ETH2 |
| Emergency laptop static IP | 192.168.99.10/24 — GW 192.168.99.2 |

---

## Conversation Summary

This document summarises the full planning and build sessions for the JXStudios home lab. It covers every major decision made, every issue encountered, and the current state of the project.

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
| Proxmox Server — genesis2 | Custom | Hypervisor | 192.168.20.10 | 🔄 Install in progress — flat network |
| helios | OR PC — Debian 12 (Sandy Bridge i3-2120) | Forgejo, NAS, Jellyfin, code-server | 192.168.20.11 | Active — Phase 1c |
| Cisco Catalyst 3750G | 3750G | L3 Core Switch | 192.168.99.3 | Planned — Phase 2 |
| Cisco Catalyst 2960G | 2960G | L2 Access / Lab | 192.168.99.4 | Planned — Phase 2/3 |
| Cisco 1921 x2 | 1921 | Lab Edge / VPN | .20.254 / .20.253 | Planned — Phase 7 |

---

### What Was Built — Genesis2 Server (Project Genesis)

A Proxmox-based home lab server planned and designed in Session 2. Full detail in `genesis2-project-genesis-plan.md`. Install now active on flat network.

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

> **Flat network note:** All containers and VMs during this phase use temporary IPs on 192.168.0.0/24. Configure everything with final LAB VLAN IPs (192.168.20.x) in mind — do not hardcode temporary addresses into service configs.

---

### Key Decisions Made — Network

**Switch Stack — Option A Confirmed**
3750G only in production. 2960G free for lab experiments with 1921 routers.

**DNS Architecture — Two Phase**
- Phase 1: Pi-hole at 192.168.10.15 serves VLAN 10 only
- Phase 2+: Pi moves to MGMT at 192.168.99.5. Serves all VLANs. Genesis2 pihole2 LXC is secondary via Gravity Sync

**Controller IP — DHCP Reservation Approach**
OC200 MAC reserved to 192.168.99.2. Picks up address automatically when Port 1 switches to MGMT profile. Requires Auto Refresh IP enabled on OC200 and the correct MGMT VLAN network field set on the reservation.

**ACL Enforcement — Two Layer**
- Omada Gateway ACL: broad VLAN-to-VLAN policy (Phase 1 active)
- Cisco 3750G IOS ACLs: host-level fine-grained rules (Phase 2+)

**Two-Tier Access Architecture**
- Tier 1: Home devices → Reverse Proxy (192.168.20.50) only
- Tier 2: Admin IPs → Proxmox :8006 / SSH direct only
- Proxmox is never a reverse proxy target

**Admin Laptop OS**
Three admin laptops: Windows, Mac (MacBook Pro 2015), and Fedora (HP Laptop). All window procedures cover Windows, macOS, and Linux. Omarchy (Arch Linux) also available — uses pacman, otherwise identical commands.

---

### Key Decisions Made — Helios (Project Helios)

**Helios as always-on utility tier**
OR PC (Sandy Bridge i3-2120, 16 GB DDR3) running Debian 12 headless. Sits between the Pi (lightweight anchor) and genesis2 (heavy compute) as a permanent always-on utility node at 192.168.20.11. No Docker — all services native systemd. Replaces MacBook 2008 (mac-server plan) — same architecture, better hardware.

**Services: Forgejo, Samba, Jellyfin, code-server, SSH jump**
Five native systemd services. Forgejo replaces genesis2 VMID 240 (retired). NAS via Samba on ZFS RAIDZ1 pool (heliospool — 3× 500 GB HDD). Jellyfin for local media — direct play strategy (GT 220 has no hardware transcode). code-server for always-on browser-based VS Code access. SSH jump as Pi backup.

**Portfolio: part of wider JXStudios lab project**
Helios is documented as one node in the multi-host segmented lab, not a standalone project. The tier separation reasoning, architecture decisions, and documentation discipline are the portfolio narrative.

---

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

**MGMT VLAN Window Rollback — 18/03/2026**
Root cause: Issues encountered during MGMT VLAN configuration.
Resolution: Rolled back to flat network. Pre-window prep remains complete. Window deferred pending admin device setup.

**ER605 Login Lockout**
Caused by login attempts on wrong device. 2 hour timer. Resolution: wait.

**Phase 1 Window Deferred — 22/03/2026**
Root cause: Admin device setup incomplete, admin laptop OS changed (Fedora repurposed). Discovery Utility firewall issue on Windows unresolved.
Resolution: Window paused. Genesis2 work continues on flat network. Window to be rescheduled once admin devices are fully configured.

**Discovery Utility — Empty Device Table on Windows**
Root cause: Windows Defender Firewall blocking Java UDP broadcast packets on ports 29810–29814. Adopted devices may also not broadcast the same way unadopted devices do.
Resolution — two steps:
1. Run start-discovery-utility-windows.bat as Administrator
2. Add javaw.exe to Windows Firewall allowed apps (both Private and Public) — path: `C:\Program Files\Java\jdk-17\bin\javaw.exe`
If ER605 still does not appear in the device list after firewall fix, use Batch Setting by IP (type 192.168.10.1 directly) rather than selecting from the discovered device table. This bypasses broadcast discovery entirely.

**Direct Access Recovery Procedure (Windows/Mac/Linux)**

*Windows:*
```
Settings → Network & Internet → ethernet → IP assignment → Edit → Manual
IP: 192.168.99.10  Subnet prefix: 24  Gateway: 192.168.99.2
Browser → https://192.168.99.2:8043
When done: set back to Automatic (DHCP)
```

*macOS:*
```
System Settings → Network → ethernet → Details → TCP/IP → Manually
IP: 192.168.99.10  Mask: 255.255.255.0  Router: 192.168.99.2
Browser → https://192.168.99.2:8043
When done: set back to Using DHCP
```

*Linux:*
```bash
sudo ip addr add 192.168.99.10/24 dev [interface]
sudo ip route add default via 192.168.99.2
# Browser → https://192.168.99.2:8043
# When done:
sudo ip addr del 192.168.99.10/24 dev [interface]
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
| genesis2 — Proxmox Host | 192.168.0.20 (temp flat) → 192.168.20.10 (Phase 2) | 20 | `[MAC — record after install]` |
| helios | 192.168.0.151 (temp flat) → 192.168.20.11 (Phase 2) | 20 | `[MAC — record after install]` |
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

All rules are staged and enabled. VLANs are configured but devices have not been migrated. Rules will enforce once the port migration window runs.

---

## Omada Config State — Staged and Intact

All of the following is configured in Omada and does not need to be redone when the window is rescheduled:

| Item | State |
|------|-------|
| VLANs 10, 20, 30, 99 | ✅ Created on ER605 |
| DHCP pools per VLAN | ✅ Configured |
| DHCP reservations — all devices | ✅ Set |
| OC200 reservation Network field | ✅ Must be MGMT VLAN 99 — verify before window |
| Auto Refresh IP on OC200 | ☐ Must be enabled before window |
| 7 Gateway ACL rules | ✅ Created and enabled |
| IP Groups — all 5 | ✅ Created |
| OC200 reset and config restored | ✅ Done |
| Port profiles — HOME, MGMT, TRUNK-ALL, LAN-Uplink | ✅ Created |
| Raspberry Pi static IP removed | ✅ Pi on DHCP |
| Config backup in Git repo | ✅ Saved — pre-port-profile baseline |
| SG2008P management VLAN → 99 | ⏩ Maintenance window — Step 6 |

> **Before rescheduling the window:** verify OC200 reservation has MGMT VLAN 99 in the Network field (Clients → Manage Client → Config → Use Fixed IP Address). Enable Auto Refresh IP (Devices → OC200 → Config → Services). See `docs/maintenance-window-updated.md` for the full corrected procedure.

---

## Pre-Window Checklist — Outstanding Items

These must be completed before rescheduling Window 2:

- [ ] Admin laptops fully configured — Windows, Mac (MacBook Pro 2015), and Fedora (HP Laptop) — at least one ready for use during window
- [ ] Discovery Utility installed and device table working (firewall fix applied, Batch Setting by IP tested)
- [ ] OC200 DHCP reservation verified — Network field set to MGMT VLAN 99
- [ ] Auto Refresh IP enabled on OC200
- [ ] ER605 device account credentials noted on paper
- [ ] Admin laptop confirmed able to reach Omada dashboard before window day
- [ ] Omada config backup taken immediately before window starts

---

## Phase 1c — Helios Build Checklist

**Debian install:**
- [ ] Run lsblk from live USB — confirm boot drive, leave 3 data HDDs unpartitioned
- [ ] Debian 12 minimal install — no desktop — boot drive only
- [ ] Static IP set to 192.168.0.151 (flat network temp)
- [ ] SSH key auth configured — password auth disabled
- [ ] All packages updated — apt update && apt full-upgrade
- [ ] Record MAC address — update network register

**ZFS pool:**
- [ ] ZFS utils installed
- [ ] RAIDZ1 pool created — heliospool — 3× 500 GB HDD
- [ ] Datasets created: heliospool/forgejo, heliospool/shared, heliospool/media, heliospool/backups
- [ ] Git commit — "Phase 1c — helios ZFS pool baseline"

**Forgejo:**
- [ ] forgejo user created
- [ ] Forgejo binary downloaded and installed
- [ ] systemd unit file written and enabled
- [ ] Forgejo confirmed accessible at http://192.168.0.151:3000
- [ ] Admin account created — credentials in password manager
- [ ] Main lab repo migrated from GitHub to internal Forgejo
- [ ] GitHub push mirror configured from Forgejo
- [ ] Git commit — "Phase 1c — helios Forgejo baseline"

**Samba:**
- [ ] Samba installed — share paths at /srv/samba/shared and /srv/samba/media (ZFS dataset mounts)
- [ ] Shares confirmed accessible from admin PC and admin laptops
- [ ] Git commit — "Phase 1c — helios Samba shares"

**Jellyfin:**
- [ ] Jellyfin installed — systemd unit enabled
- [ ] Media library pointed at /srv/samba/media
- [ ] Jellyfin confirmed accessible at http://192.168.0.151:8096
- [ ] Git commit — "Phase 1c — helios Jellyfin"

**code-server:**
- [ ] code-server installed — systemd unit written and enabled
- [ ] Password set — stored in password manager, not committed to repo
- [ ] Accessible at http://192.168.0.151:8080
- [ ] Git commit — "Phase 1c — helios code-server"

**Final:**
- [ ] All five services confirmed healthy after reboot
- [ ] Helios checklist marked complete in register
- [ ] Screenshot — all five services running (systemctl status)
- [ ] Git commit — "Phase 1c — helios baseline complete"

---

## Genesis2 — Proxmox Install Checklist

> Active phase. Running on flat network 192.168.0.0/24.  
> Set installer IP to 192.168.0.20. Final IP is 192.168.20.10 — do not hardcode temp address into service configs.

### Pre-Install

| Task | Status |
|------|--------|
| Verify hardware — POST, all drives detected | ☐ |
| Download Proxmox VE ISO (current stable) | ☐ |
| Flash ISO to USB installer | ☐ |
| Confirm BIOS settings — IOMMU/AMD-Vi enabled (required for Phase 6 GPU passthrough) | ☐ |
| Note network interface names for bridge config | ☐ |

### Proxmox Installer Decisions

| Setting | Choice | Notes |
|---------|--------|-------|
| Target disk | 256 GB SSD | Boot drive only — HDDs configured post-install |
| Filesystem | ext4 | ZFS on root not required |
| Management IP | 192.168.0.20 | Flat network temporary — update to 192.168.20.10 at Phase 2 |
| Hostname | genesis2.jxstudios.dev | Set permanently from day one |

### Post-Install

| Task | Status |
|------|--------|
| First login — web UI at https://192.168.0.20:8006 | ☐ |
| Update all packages — `apt update && apt full-upgrade` | ☐ |
| Configure VLAN-aware bridge — set bridge-vlan-aware yes | ☐ |
| Create RAIDZ1 pool from three HDDs — document drive IDs | ☐ |
| Add datapool storage in Proxmox web UI | ☐ |
| Record genesis2 MAC address in settings register | ☐ |
| Set up SSH key authentication — disable password auth | ☐ |
| Take first config backup | ☐ |
| Git commit — "Phase 1b — Genesis2 Proxmox baseline" | ☐ |

### Observability Stack (Phase 1b — deploy after baseline)

| Task | Status |
|------|--------|
| Deploy prometheus LXC — VMID 220, temp IP on flat network | ☐ |
| Deploy grafana LXC — VMID 221 | ☐ |
| Deploy loki LXC — VMID 222 | ☐ |
| Configure Prometheus to scrape pve_exporter and Node Exporter | ☐ |
| Connect Grafana to Prometheus and Loki | ☐ |
| Verify PLG stack healthy before proceeding to Phase 2 | ☐ |

---

## Future Phases — Remaining Work

> **Build sequence confirmed 23/03/2026:** Phase 1c (helios) runs first. Genesis2 Proxmox baseline (Phase 1b) follows. Service deployment on genesis2 begins only after Forgejo is confirmed live on helios. Network window and Pi migration remain an independent track.

### Phase 1 Network Window — DEFERRED
> Reschedule once admin devices are configured and pre-window checklist is complete.
> See `docs/maintenance-window-updated.md` for the full corrected procedure.

- [ ] Complete pre-window checklist above
- [ ] Port migrations — Steps 1–7 per updated window doc
- [ ] Final verification and documentation
- [ ] Git commit — "Phase 1 complete — post-window baseline"

### Phase 2 — Catalyst 3750G + Infrastructure Services
> CCNA study directly covers this phase — VLANs, SVIs, trunking, ACLs, inter-VLAN routing.

- [ ] Verify PoE standard on 3750G — `show power inline` — before Pi PoE HAT purchase
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

### Phase 3 — Developer Tooling + Cisco 2960G
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

---

## Pending Items

| Item | Priority | Notes |
|------|----------|-------|
| Admin laptop setup — Windows / Mac | High | Required before window can run |
| Discovery Utility — firewall fix and Batch Setting by IP test | High | Required before window — see Issues section above |
| OC200 reservation Network field check | High | Verify MGMT VLAN 99 selected — not default LAN |
| Auto Refresh IP on OC200 | High | Enable before window — Devices → OC200 → Config → Services |
| Verify 3750G PoE standard | High — before purchase | `show power inline` — Pi 5 may exceed 802.3af 15.4W ceiling under load |
| Record genesis2 MAC address | After install | Update network_settings_register_populated.md |
| Partner PC MAC address | When available | Update register — 192.168.10.12 |
| GPU passthrough planning session | Phase 6 | Dedicated session before Ollama VM creation |
| Pi MAC discrepancy check | Before Phase 2 | Quick guide .B5:34 vs register .B5:43 — verify on device |
| Quick guide OC200 IP fix | Low | 192.168.99.1 → 192.168.99.2 in two places |

---

## Maintenance Window Schedule

| Window | Date | Scope | Status |
|--------|------|-------|--------|
| Window 1 | ~09/03/2026 | Initial VLAN creation, DHCP, ACL rules | ✅ Complete |
| Window 2 | TBD | Phase 1 port migrations, MGMT VLAN, OC200 cutover | ⏸️ Deferred — admin setup pending |
| Window 3 | TBD | Phase 2 — 3750G + inter-rack trunk | 🔲 Not scheduled |

---

## Phase Status

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Omada ISP rack — port migrations, OC200 cutover | ⏸️ Deferred — pre-window checklist incomplete |
| 1b | Genesis2 — Proxmox install + ZFS + observability stack | 🔲 Not started — follows Phase 1c |
| 1c | helios — Debian install + services | 🔄 Active — next session |
| 2 | Catalyst 3750G + infrastructure services | 🔲 Not started |
| 3 | Developer tooling + 2960G | 🔲 Not started |
| 4 | Applications — Nextcloud, Homepage | 🔲 Not started |
| 5 | jxstudios.dev website | 🔲 Not started |
| 6 | Ollama + GPU passthrough | 🔲 Not started |
| 7 | Cisco 1921 routers (optional) | 🔲 Not started |

---

## Documentation Status

| Document | Status | Notes |
|----------|--------|-------|
| network_design_document_populated.md | Current | Update after window completes |
| network_settings_register_populated.md | Current | Update after window completes |
| genesis2-project-genesis-plan.md | Current — 18/03/2026 | Update as services are deployed |
| CLAUDE.md | Updated 22/03/2026 | v4.0 — reflects pause, admin OS change, current focus |
| project-summary-and-remaining-steps.md | This file — 22/03/2026 | Updated to reflect deferred window and genesis2 on flat network |
| docs/maintenance-window-updated.md | ✅ New — 22/03/2026 | Corrected window procedure — Discovery Utility, Auto Refresh IP, all OS coverage |
| network_setup_quick_guide.md | Needs updates | See pending items |

### Quick Guide Updates Still Needed
- [ ] OC200 IP in body text: 192.168.99.1 → 192.168.99.2 (two places)
- [ ] Add dashboard URL: https://192.168.99.2:8043
- [ ] Clean up OC200 and Hue Bridge reservation table rows
- [ ] Add note: Hue Bridge stays on HOME until Phase 2
- [ ] Mark HOME DNS 1.1.1.1 as temporary
- [ ] Verify Pi MAC discrepancy: quick guide .B5:34 vs register .B5:43 — check device

---

*Last updated: 22/03/2026 — Network window deferred. Genesis2 active on flat network. CCNA study in progress. Admin laptops now Windows/Mac — Fedora repurposed.*
