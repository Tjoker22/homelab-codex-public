# Network Settings Register
**Site Name:** `JXStudios`
**Owner:** `[OWNER]`  
**Storage:** `[https://github.com/[USERNAME]/proxmox_homelab]`  
**Version:** `1.0`  
**Created:** `2026/03/09`  
**Last Updated:** `2026/03/15`  
**Switch Stack:** `[X] Option A — Single Switch (3750G only)  [ ] Option B — Dual Switch (3750G + 2960G)`

---

> **How to use this document**  
> Update the relevant section immediately after every network change.  
> Write a Git commit message describing what changed when you save.  
> Format: `Updated [section] — [what changed] — [reason]`

---

## Table of Contents

1. [Hardware Inventory](#1-hardware-inventory)
2. [VLAN Register](#2-vlan-register)
3. [DHCP Range Rationale](#3-dhcp-range-rationale)
4. [IP Register](#4-ip-register)
5. [DHCP Reservations](#5-dhcp-reservations)
6. [Switch Port Profiles](#6-switch-port-profiles)
7. [Port Assignments](#7-port-assignments)
8. [Firewall — Gateway ACL Rules](#8-firewall--gateway-acl-rules)
9. [SSID Configuration](#9-ssid-configuration)
10. [VM and Services Register](#10-vm-and-services-register)
11. [Reverse Proxy Services](#11-reverse-proxy-services)
12. [Change Log](#12-change-log)

---

## 1. Hardware Inventory

> Update when a device is added, removed, replaced, or its firmware changes.

| # | Device | Model / Version | Firmware | Rack / Location | Role | Management IP | Status |
|---|--------|----------------|----------|-----------------|------|---------------|--------|
| 1 | WAN Router | TP-Link ER605 v2 | `[Version]` | ISP Rack | WAN Gateway | 192.168.10.1 | Active |
| 2 | PoE Switch | TP-Link TL-SG2008P | `[Version]` | ISP Rack | Managed Switch | 192.168.99.10 | Active |
| 3 | Controller | TP-Link OC200 | `[Version]` | ISP Rack | Omada Controller | 192.168.99.2 | Active |
| 4 | L3 Core Switch | Cisco Catalyst 3750G | `[IOS Version]` | Server Rack | L3 Core | 192.168.99.3 | Planned — Phase 2 |
| 5 | L2 Access Switch | Cisco Catalyst 2960G | `[IOS Version]` | Server Rack / Lab | Access / Lab | 192.168.99.4 | Option B only / Lab |
| 6 | Hypervisor | `[Server model — Proxmox]` | `[Version]` | Server Rack | Hypervisor | 192.168.20.10 | Planned — Phase 4 |
| 7 | Router #1 | Cisco 1921 | `[IOS Version]` | Server Rack | Lab Edge | 192.168.20.254 | Planned — Phase 7 |
| 8 | Router #2 | Cisco 1921 | `[IOS Version]` | Server Rack | VPN / Lab | 192.168.20.253 | Planned — Phase 7 |
| 9 | WAP | TP-Link EAP `[model]` | `[Version]` | ISP Rack area | Wireless AP | 192.168.99.`[x]` | Active |
| 10 | Raspberry Pi | Raspberry Pi `[model]` | `[OS Version]` | `[Location]` | Pi-hole DNS | 192.168.10.15 | Active — Phase 1 |
| 11 | mac-server | 2008 MacBook — Debian 12 | `[Version]` | Server Rack / Lab | Forgejo, NAS, code-server | 192.168.20.11 | Active — Phase 1c |

---

## 2. VLAN Register

> Update when a VLAN is added, removed, or any of its parameters change.

| VLAN ID | Name | Subnet | Gateway IP | Static Range | DHCP Range | DNS Primary | DNS Secondary | DHCP | Lease | Purpose |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 10 | HOME | 192.168.10.0/24 | 192.168.10.1 | .1 – .29 | .100 – .200 | 1.1.1.1 | 8.8.8.8 | ON | 1 day | Home PCs, phones, TVs, consoles. Pi-hole DNS for VLAN 10 only when brought online. |
| 20 | LAB | 192.168.20.0/24 | 192.168.20.1 | .1 – .99 | .100 – .200 | 1.1.1.1 | 1.0.0.1 | ON | 1 day | Servers, VMs, Proxmox. Large static block .1–.99 for infrastructure. |
| 30 | IOT | 192.168.30.0/24 | 192.168.30.1 | .1 – .19 | .20 – .254 | 9.9.9.9 | 149.112.112.112 | ON | 1 day | Smart devices — fully isolated. Quad9 DNS blocks malicious domains. |
| 99 | MGMT | 192.168.99.0/24 | 192.168.99.1 | All | N/A | 1.1.1.1 | — | OFF | N/A | Network device management only. All static IPs. No DHCP. |

> **DNS note:** VLAN 10 DNS primary will be Pi-hole at 192.168.10.15 (Phase 1 — HOME VLAN only).  
> Phase 2+: Pi moves to MGMT 192.168.99.5 and becomes network-wide DNS. All VLAN DNS entries update at that point.

---

## 3. DHCP Range Rationale

> Document the reasoning behind each VLAN's range. Update if ranges change.

| VLAN | Static Reserved | DHCP Pool | Rationale |
|------|----------------|-----------|-----------|
| HOME 10 | .1 – .29 | .100 – .200 | Mostly dynamic home devices. Static block .1–.29 for infrastructure and reserved devices (Pi-hole, admin PCs). |
| LAB 20 | .1 – .99 | .100 – .200 | Many servers and VMs need fixed IPs. Large static block reserved for infrastructure. DHCP pool for any dynamic lab devices. |
| IOT 30 | .1 – .19 | .20 – .254 | Almost all IoT devices are dynamic. Minimal static block. Wide DHCP pool. |
| MGMT 99 | All addresses | DHCP disabled | Every MGMT device has a manually assigned static IP. No dynamic assignment ever. |

---

## 4. IP Register

> Authoritative IP reference. Update immediately when any device IP changes.  
> **Type:** Static = hardcoded on device | Reservation = DHCP reservation by MAC

| Device / Hostname | IP Address | VLAN | MAC Address | Type | Phase | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| ER605 — WAN Gateway | 192.168.10.1 | 10 | N/A | Static | 1 | WAN gateway — do not change |
| ER605 — LAB SVI | 192.168.20.1 | 20 | N/A | Static | 1 | LAB VLAN gateway |
| ER605 — IOT SVI | 192.168.30.1 | 30 | N/A | Static | 1 | IOT VLAN gateway |
| ER605 — MGMT SVI | 192.168.99.1 | 99 | N/A | Static | 1 | Also OC200 address — ER605 handles MGMT routing |
| OC200 — Omada Controller | 192.168.99.2 | 99 | [MAC_REDACTED] | Reservation | 1 | Fixed via DHCP reservation — MGMT VLAN |
| TL-SG2008P | 192.168.99.10 | 99 | [MAC_REDACTED] | Static | 1 | Omada managed switch |
| 3750G — SVI MGMT (Vlan99) | 192.168.99.3 | 99 | N/A | Static | 2 | Core switch MGMT SVI |
| 3750G — SVI HOME (Vlan10) | 192.168.10.2 | 10 | N/A | Static | 2 | Home VLAN SVI |
| 3750G — SVI LAB (Vlan20) | 192.168.20.1 | 20 | N/A | Static | 2 | Lab VLAN gateway — takes over from ER605 |
| 3750G — SVI IOT (Vlan30) | 192.168.30.1 | 30 | N/A | Static | 2 | IoT VLAN gateway |
| 2960G — Option B only | 192.168.99.4 | 99 | `[MAC]` | Static | 2 | Access switch MGMT — Option B only |
| Proxmox Host | 192.168.20.10 | 20 | `[MAC]` | Static | 4 | Hypervisor — web UI port 8006 |
| Nginx Proxy Manager VM | 192.168.20.50 | 20 | N/A (VM) | Static | 5 | Reverse proxy — used in ACL rules |
| Tailscale LXC | 192.168.20.51 | 20 | N/A (LXC) | Static | 6 | Subnet router — used in ACL permit |
| Admin PC — daily driver | 192.168.10.10 | 10 | [MAC_REDACTED] | Reservation | 1 | In ACL rules — reservation must be set first |
| Admin Laptop | 192.168.10.11 | 10 | [MAC_REDACTED] | Reservation | 1 | In ACL rules — reservation must be set first |
| Xavier PC | 192.168.10.12 | 10 | [MAC_REDACTED] | Reservation | 1 | Reservation set for potential future admin access |
| Raspberry Pi — Pi-hole | 192.168.10.15 | 10 | [MAC_REDACTED] | Reservation | 1 | Phase 1: HOME DNS only. Phase 2: move to MGMT 192.168.99.5 for network-wide DNS |
| Raspberry Pi — Pi-hole (Phase 2+) | 192.168.99.5 | 99 | [MAC_REDACTED] | Reservation | 2+ | Planned MGMT DNS — reserve when migrating Pi from HOME. See NDD §6.2 for transition steps. |
| mac-server (temp flat) | 192.168.0.11 | flat | `[MAC — after install]` | Static | 1c | Temporary — flat network during setup |
| mac-server (permanent) | 192.168.20.11 | 20 | `[MAC — after install]` | Static | 2 | Infrastructure zone — physical host |
| Forgejo LXC (genesis2) | RETIRED | 20 | N/A | — | — | Moved to mac-server 192.168.20.11:3000 — VMID 240 retired |
| Cisco 1921 #1 | 192.168.20.254 | 20 | `[MAC]` | Static | 7 | Lab edge — optional Phase 7 |
| Cisco 1921 #2 | 192.168.20.253 | 20 | `[MAC]` | Static | 7 | VPN / lab — optional Phase 7 |
| Philips Hue Bridge | `[192.168.30.5 — set when moved to IoT]` | 30 | [MAC_REDACTED] | Reservation | 1+ | Currently on HOME. Move to IOT VLAN 30 when 3750G live. Set static via Hue app after move. |
| PS5 | `[DHCP .100–.200]` | 10 | `[MAC]` | DHCP | 1 | Home device |
| TV (viziocastdisplay) | `[DHCP .100–.200]` | 10 | [MAC_REDACTED] | DHCP | 1 | Home device |

---

## 5. DHCP Reservations

> Set in Omada: Settings > Wired Networks > LAN > select VLAN > DHCP Reservation.  
> **Must be set before writing any ACL rules that reference these IPs.**

| Device Name | MAC Address | Reserved IP | VLAN | Date Set | ACL Reference | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Admin PC — daily driver | [MAC_REDACTED] | 192.168.10.10 | HOME — VLAN 10 | 2026/03/15 | ACL Rule 1 (Home-to-MGMT source) | Set before ACL rules |
| Admin Laptop | [MAC_REDACTED] | 192.168.10.11 | HOME — VLAN 10 | 2026/03/15 | ACL Rule 1 (Home-to-MGMT source) | Set before ACL rules |
| Xavier PC | [MAC_REDACTED] | 192.168.10.12 | 10 | 2026/03/15 | N/A | Reserved for potential future admin access |
| Raspberry Pi — Pi-hole | [MAC_REDACTED] | 192.168.10.15 | HOME — VLAN 10 | 2026/03/15 | DNS target — no ACL rule needed while on HOME | Phase 1 only — update when moved to MGMT |
| OC200 — Omada Controller | [MAC_REDACTED] | 192.168.99.2 | MGMT — VLAN 99 | 2026/03/15 | ACL Rule 1 destination | DHCP briefly enabled on MGMT to assign — disable after |
| Philips Hue Bridge | [MAC_REDACTED] | 192.168.30.5 | IOT — VLAN 30 | `[Date — when moved]` | None needed | Set when moving to IOT VLAN |
| Raspberry Pi — Pi-hole (Phase 2+) | [MAC_REDACTED] | 192.168.99.5 | MGMT — VLAN 99 | `[Date — Phase 2 migration]` | IoT→Pi, Lab→Pi, MGMT→Pi port 53 | Set when migrating Pi to MGMT VLAN — see NDD §6.2 |

---

## 6. Switch Port Profiles

> Omada: Settings > Profiles > Switch Profiles.  
> Update when a profile is created, modified, or deleted.

| Profile Name | Untagged VLAN | Tagged VLANs | Native VLAN | Used On Ports | Notes |
|--------------|---------------|--------------|-------------|---------------|-------|
| HOME | 10 | None | 10 | Ports 2,3,4,5,6 | Home device access ports |
| MGMT | 99 | None | 99 | Port 1 | Management VLAN only |
| TRUNK-ALL | None | 10,20,30,99 | 99 | Port 7 | Inter-rack trunk — native VLAN 99 prevents VLAN hopping |
| LAN-Uplink | 10 | None | 10 | Port 8 | ER605 LAN uplink |
| WAP-TRUNK | 10 | 10,20,30 | 10 | Port 6 (future) | For VLAN-aware SSIDs — create when WAP supports multi-SSID VLAN tagging |

---

## 7. Port Assignments

> Update when a device is connected, moved, or a port config changes.

### TL-SG2008P

| Port | Profile | Untagged VLAN | Tagged VLANs | Native VLAN | Connected Device | Last Updated | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Port 1 | MGMT | 99 | None | 99 | OC200 — Omada Controller | `[Date]` | Change last — after all other ports confirmed |
| Port 2 | HOME | 10 | None | 10 | WAP — TP-Link EAP | 16/03/2026 | Future: change to WAP-TRUNK for VLAN-aware SSIDs |
| Port 3 | HOME | 10 | None | 10 | Uplink to GS208 (port 8) | `[Date]` | Admin PC — 192.168.10.10 |
| Port 4 | HOME | 10 | None | 10 | Partner PC (DESKTOP-CE1DDUF) — 192.168.10.12 | 16/03/2026 |  |
| Port 5 | HOME | 10 | None | 10 | Philips HUE Bridge | 16/03/2026 | Current location |
| Port 6 | HOME | 10 | None | 10 | Downlink to GS305G | 16/03/2026 | Unmanaged switch connectiong Media |
| Port 7 | TRUNK-ALL | None | 10,20,30,99 | 99 | 3750G Gi0/1 — inter-rack trunk | `[Date]` | Phase 2 — not connected yet |
| Port 8 | LAN-Uplink | 10 | None | 10 | ER605 LAN port | `[Date]` |  |

### Netgear GS308

| Port | Profile | Untagged VLAN | Tagged VLANs | Native VLAN | Connected Device | Last Updated | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Port 1 | HOME | None | None |  |  | `[Date]` |  |
| Port 2 | HOME |  | None |  |  | `[Date]` |  |
| Port 3 | HOME | 10 | None | 10 | Raspberry Pi - 192.168.10.15 | 03/09/2026 |  |
| Port 4 | HOME |  | None |  |  | `[Date]` |  |
| Port 5 | HOME |  | None |  |  | `[Date]` |  |
| Port 6 | HOME |  | None |  |  | `[Date]` |  |
| Port 7 | HOME | 10 | None | 10 | Admin PC — 192.168.10.10 | 03/09/2026 |  |
| Port 8 | HOME | 10 | None | 10 | Uplink from TL-SG2008P (port 3) | 03/09/2026 |  |


### Catalyst 3750G *(Phase 2 — not configured yet)*

| Port | Mode | VLAN | Connected Device | Notes |
|------|------|------|------------------|-------|
| Gi0/1 | Trunk | 10,20,30,99 | TL-SG2008P Port 7 | Inter-rack trunk — native VLAN 99 |
| Gi0/2 (Option A) | Access | 20 | Proxmox NIC | Option A only |
| Gi0/2 (Option B) | Trunk | 20,30,99 | 2960G Gi0/1 | Option B cascade trunk |
| Gi0/3–12 (Option A) | Access | 20 | Lab servers | Option A only |
| Gi0/13–22 (Option A) | Access | 30 | IoT devices | Option A only |
| Gi0/23 | Access | 20 | Cisco 1921 #1 (optional) | Phase 7 |
| Gi0/24 | Access | 99 | Management / console only | |

### Catalyst 2960G *(Option B only / Lab use in Option A)*

| Port | Mode | VLAN | Connected Device | Notes |
|------|------|------|------------------|-------|
| Gi0/1 | Trunk | 20,30,99 | 3750G Gi0/2 | Cascade uplink — Option B only |
| Gi0/2 | Access | 20 | Proxmox NIC | Option B only |
| Gi0/3–12 | Access | 20 | Lab servers | Option B only |
| Gi0/13–22 | Access | 30 | IoT devices | Option B only |

---

## 8. Firewall — Gateway ACL Rules

> Omada: Settings > Network Security > ACL > Gateway ACL  
> **Direction: LAN→LAN for all rules below.**  
> **Rules are first-match top-down — order is critical.**  
> Update immediately when a rule is added, changed, reordered, or toggled.

> ⚠️ A misplaced permit above a block can silently allow unintended traffic. Always test after changes.

### Active Rules — Phase 1

> **Note:** All 7 rules are created and enabled in Omada. VLANs are configured but devices are not yet migrated — backend setup is being completed ahead of a planned maintenance window. Rules will enforce once devices are moved to their respective VLANs.

| # | Rule Name | Source | Destination | Protocol | Port | Policy | Status | Date Added | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Home-to-MGMT | HOME (network) | MGMT (network) | TCP | All | Permit | ✅ Enabled | `[Date]` | Broad permit for now — all HOME to MGMT. Tighten to specific IPs using IP Groups in Phase 2. |
| 2 | Block-Home-to-Lab | HOME (network) | LAB (network) | All | All | Deny | ✅ Enabled | `[Date]` | Blocks home devices from direct lab access |
| 3 | Block-Home-to-IoT | HOME (network) | IOT (network) | All | All | Deny | ✅ Enabled | `[Date]` | No home to IoT lateral movement |
| 4 | Block-IoT-to-Home | IOT (network) | HOME (network) | All | All | Deny | ✅ Enabled | `[Date]` | IoT cannot reach home devices |
| 5 | Block-IoT-to-Lab | IOT (network) | LAB (network) | All | All | Deny | ✅ Enabled | `[Date]` | IoT cannot reach lab |
| 6 | Block-IoT-to-MGMT | IOT (network) | MGMT (network) | All | All | Deny | ✅ Enabled | `[Date]` | IoT cannot reach management devices |
| 7 | MGMT-Full-Access | MGMT (network) | HOME, LAB, IOT | All | All | Permit | ✅ Enabled | `[Date]` | Management VLAN has unrestricted internal access |

### Pending Rules — Add when service is live

| # | Rule Name | Source | Destination | Protocol | Port | Policy | Waiting On |
|---|-----------|--------|-------------|----------|------|--------|------------|
| — | Admin-PC-to-Proxmox | IP Group: Admin-PC (10.10) | IP Group: Proxmox (20.10) | TCP | 8006 | Permit | Phase 4 — Proxmox live |
| — | Admin-Laptop-to-Proxmox | IP Group: Admin-Laptop (10.11) | IP Group: Proxmox (20.10) | TCP | 8006 | Permit | Phase 4 — Proxmox live |
| — | Admin-PC-SSH-Lab | IP Group: Admin-PC (10.10) | LAB (network) | TCP | 22 | Permit | Phase 4 — Lab live |
| — | Admin-Laptop-SSH-Lab | IP Group: Admin-Laptop (10.11) | LAB (network) | TCP | 22 | Permit | Phase 4 — Lab live |
| — | Home-to-Proxy-HTTP | HOME (network) | IP Group: Proxy-VM (20.50) | TCP | 80 | Permit | Phase 5 — Proxy live |
| — | Home-to-Proxy-HTTPS | HOME (network) | IP Group: Proxy-VM (20.50) | TCP | 443 | Permit | Phase 5 — Proxy live |
| — | Lab-to-Home | LAB (network) | HOME (network) | All | All | Permit | Phase 4 — Lab live |
| — | IoT-DNS-to-Pihole | IOT (network) | IP Group: Pi-hole (99.5) | UDP+TCP | 53 | Permit | Phase 2+ — Pi moved to MGMT |
| — | Lab-DNS-to-Pihole | LAB (network) | IP Group: Pi-hole (99.5) | UDP+TCP | 53 | Permit | Phase 2+ — Pi moved to MGMT |

### IP Groups to Pre-create in Omada
> Settings > Profiles > IP Groups — create these now so they are ready when pending rules are built.

| Group Name | IP / Subnet | Used In |
|------------|-------------|---------|
| Admin-PC | 192.168.10.10/32 | Proxmox and SSH rules |
| Admin-Laptop | 192.168.10.11/32 | Proxmox and SSH rules |
| Proxmox | 192.168.20.10/32 | Proxmox access rules |
| Proxy-VM | 192.168.20.50/32 | Home to proxy rules |
| Pi-hole | 192.168.99.5/32 | DNS permit rules (Phase 2+) |

---

## 9. SSID Configuration

> Omada: Wireless > Wi-Fi  
> Update when an SSID is added, removed, or its config changes.  
> Note: WAP port must be changed to WAP-TRUNK profile to support multiple VLAN-tagged SSIDs.  
> Verify EAP model supports VLAN-tagged SSIDs before planning multi-SSID setup.

| SSID Name | VLAN Tag | Band | Security | WAP Device | WAP Port | Enabled | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `[Current SSID name]` | 10 | 2.4 + 5GHz | WPA2/WPA3 | EAP-`[model]` | TL-SG2008P Port 2 | Y | Current home SSID — all devices on VLAN 10 |
| IoT-Net (planned) | 30 | 2.4GHz | WPA2 | EAP-`[model]` | TL-SG2008P Port 2 | N | Add when IoT VLAN is active — requires WAP-TRUNK port profile |
| LabWiFi (planned) | 20 | 5GHz | WPA2 | EAP-`[model]` | TL-SG2008P Port 2 | N | Add when lab is active — admin devices only |

---

## 10. VM and Services Register

> Update when a VM or LXC is created, removed, or its network config changes.

| VM/LXC ID | Hostname | Type | IP Address | VLAN Tag | OS | Purpose | Phase | Notes |
|-----------|----------|------|------------|----------|----|---------|-------|-------|
| 100 | nginx-proxy | LXC | 192.168.20.50 | 20 | Debian 12 | Nginx Proxy Manager — reverse proxy | 5 | Fixed IP — used in ACL rules. Never proxy Proxmox. |
| 101 | tailscale | LXC | 192.168.20.51 | 20 | Debian 12 | Tailscale subnet router | 6 | Advertises 10/20/30 subnets. Fixed IP used in ACL. |
| 102 | `[hostname]` | VM/LXC | `[IP]` | `[VLAN]` | `[OS]` | `[Purpose]` | `[Phase]` | `[Notes]` |

---

## 11. Reverse Proxy Services

> Update when a service is added, removed, or its target changes.  
> ⚠️ **Never add Proxmox (port 8006) as a proxy target — admin access via ACL only.**

| Domain / Hostname | Forward Host | Port | SSL | ACL Rule | Enabled | Notes |
|-------------------|--------------|------|-----|----------|---------|-------|
| `[hostname.lab]` | `[IP]` | `[Port]` | `[Y/N]` | Pending Phase 5 rules | N | Add when proxy is live |
| ~~Proxmox :8006~~ | ~~192.168.20.10~~ | ~~8006~~ | — | ACL only | — | **NEVER proxy — admin PC/laptop via ACL rules only** |

---

## 12. Change Log

> Record every change after initial setup — no matter how small.  
> Fill in **before** making the change — record the previous value first.  
> **A change without a log entry is a change that cannot be safely undone.**

| Date | Time | Device | Section | What Changed | Previous Value | New Value | Tested OK | Reason |
|------|------|--------|---------|--------------|----------------|-----------|-----------|--------|
| 09/03/26 | `[Time]` | OC200 / ER605 | Setup | Initial VLAN creation — HOME, LAB, IOT, MGMT | Flat network — no VLANs | VLANs 10,20,30,99 defined on ER605 | `[Y/N]` | Phase 1 network segmentation |
| 09/03/26 | `[Time]` | ER605 | DHCP Reservations | Admin PC reservation set | No reservation | 192.168.10.10 reserved for Admin PC MAC | `[Y/N]` | Required before ACL rules referencing this IP |
| 09/03/26 | `[Time]` | ER605 | DHCP Reservations | Admin Laptop reservation set | No reservation | 192.168.10.11 reserved for Admin Laptop MAC | `[Y/N]` | Required before ACL rules referencing this IP |
| 09/03/26 | `[Time]` | ER605 | Gateway ACL | 7 Phase 1 ACL rules created | No ACL rules | Rules 1–7 created and enabled | `[Y/N]` | Phase 1 VLAN isolation policy |
| 09/03/26 | `[Time]` | OC200 | Controller Settings | Controller IP changed | `[Old IP]` | 192.168.99.2 | `[Y/N]` | Move controller to MGMT VLAN |
| 16/03/2026 | `[Time]` | TL-SG2008P | Port Profiles | Port 2 (EAP) changed to HOME profile | Flat/default | HOME — VLAN 10 | Y | Phase 1 port migration |
| 16/03/2026 | `[Time]` | TL-SG2008P | Port Profiles | Port 4 (Partner PC / DESKTOP-CE1DDUF) changed to HOME profile | Flat/default | HOME — VLAN 10 | Y | Phase 1 port migration — device identified |
| 16/03/2026 | `[Time]` | TL-SG2008P | Port Profiles | Port 5 (Philips Hue Bridge) changed to HOME profile | Flat/default | HOME — VLAN 10 | Y | Phase 1 port migration |
| 16/03/2026 | `[Time]` | TL-SG2008P | Port Profiles | Port 6 (Vizio TV) changed to HOME profile | Flat/default | HOME — VLAN 10 | Y | Phase 1 port migration |
| 16/03/2026 | `[Time]` | ER605 / Omada | VLAN 10 DHCP | Pi-hole DNS set as primary DNS for VLAN 10 | 1.1.1.1 | 192.168.10.15 | Y | Phase 1 Step 3 |
| 16/03/2026 | `[Time]` | TL-SG2008P | VLAN Interface | Management VLAN changed from Default (1) to MGMT (99) | VLAN 1 (default) | VLAN 99 (MGMT) | Y | Phase 1 Step 4 |
| 16/03/2026 | `[Time]` | OC200 | Port 1 / Recovery | Port 1 changed to MGMT profile — OC200 unreachable, no DHCP on MGMT. Factory reset + config restore performed. | HOME/flat | Reset — config restored | N | Incident — DHCP missing on MGMT VLAN |
| 16/03/2026 | `[Time]` | ER605 | Adoption | ER605 not re-adopting post-restore — internet functional, management plane issue | Adopted | Not adopted | N | Pending resolution next session |
| `[Date]` | `[Time]` | TL-SG2008P | Port Profiles | Port 1 changed to MGMT profile | HOME / flat | MGMT — VLAN 99 | `[Y/N]` | Phase 1 port migration |
| `[Date]` | `[Time]` | TL-SG2008P | Port Profiles | Port 3 changed to HOME profile | Flat network | HOME — VLAN 10 | `[Y/N]` | Phase 1 port migration — admin PC |
| 22/03/26 | `[Time]` | Project | Planning | mac-server added to project | Not planned | mac-server confirmed as always-on utility node — Forgejo, Samba, code-server, SSH jump | N/A | Architecture decision |
| 22/03/26 | `[Time]` | genesis2 | VM Register | VMID 240 Forgejo LXC retired | VMID 240 planned | Forgejo moved to mac-server native Debian service | N/A | mac-server architecture decision |
| `[Date]` | `[Time]` | `[Device]` | `[Section]` | `[Description]` | `[Old value]` | `[New value]` | `[Y/N]` | `[Reason]` |

---

## Phase Completion Checklist

### Phase 1 — Omada Stack ✳️ In Progress
- [x] VLANs 10, 20, 30, 99 created on ER605
- [x] DHCP pools configured per VLAN
- [x] DHCP reservations set — Admin PC, Admin Laptop, Xavier PC, Pi-hole, OC200
- [x] 7 Gateway ACL rules created and enabled
- [x] OC200 static IP set to 192.168.99.2
- [x] TL-SG2008P management IP set to 192.168.99.10
- [x] Port profiles created in Omada

> ⬇️ Items below require the active maintenance window — VLANs configured but not yet live.

- [x] Media devices (TV, PS5) moved to VLAN 10 and tested — TV confirmed ✅ | PS5 pending
- [x] Raspberry Pi static IP removed — DHCP reservation set to 192.168.10.15
- [x] Pi-hole confirmed working on VLAN 10 — DNS updated in DHCP settings (Pi moves to VLAN 10 in Step 6)
- [ ] Remaining home devices moved to VLAN 10
- [ ] Admin laptop moved to VLAN 10 — confirmed 192.168.10.11
- [ ] OC200 Port 1 and Admin PC Port 3 switched last — back to back
- [ ] Dashboard confirmed accessible at https://192.168.99.2:8043

### Phase 2 — Catalyst 3750G 🔲 Not started
### Phase 3 — Catalyst 2960G (Option B only) 🔲 Not started
### Phase 4 — Proxmox Setup 🔲 Not started
### Phase 5 — Nginx Proxy Manager 🔲 Not started
### Phase 6 — Tailscale 🔲 Not started
### Phase 7 — Cisco 1921 Routers (optional) 🔲 Not started

---

*Last commit: `"[Docs] Update — Phase 1 mid-window — Steps 1–3 complete, Partner PC MAC confirmed"`*
*Previous commit: `"Phase 1 prep - Updates to MACs / IPs. Added GS308 to Sec.7: Port Assignments"`*

