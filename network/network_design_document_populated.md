# Network Design Document
**Site Name:** `JXStudio`  
**Owner:** `[OWNER]`  
**Storage:** `https://github.com/[USERNAME]/proxmox_homelab`  
**Version:** `1.0`  
**Created:** `09/03/2026`  
**Last Updated:** `09/03/2026`  
**Switch Stack:** `[X] Option A — Single Switch (3750G only)  [ ] Option B — Dual Switch (3750G + 2960G)`  
**Companion File:** `network-settings-register-populated.md`

---

> **How to use this document**  
> This document captures the design rationale, architecture decisions, procedures, and configuration records for the JXStudio home lab network.  
> The companion register (`network-settings-register-POPULATED.md`) holds the living settings tables — IPs, ACL rules, port assignments, and the change log.  
> Update this document when architecture decisions change, new phases are completed, or procedures are revised.  
> Both documents should be committed to the same Git repository together.

---

## Table of Contents

1. [Document Control](#1-document-control)
2. [Environment Overview](#2-environment-overview)
3. [Network Architecture](#3-network-architecture)
4. [VLAN Design & Policy](#4-vlan-design--policy)
5. [Two-Tier Access Architecture](#5-two-tier-access-architecture)
6. [DNS Architecture](#6-dns-architecture)
7. [Physical Topology](#7-physical-topology)
8. [Phased Deployment Plan](#8-phased-deployment-plan)
9. [Omada Configuration Record](#9-omada-configuration-record)
10. [Cisco Device Configuration Record](#10-cisco-device-configuration-record)
11. [Proxmox & Services Record](#11-proxmox--services-record)
12. [Remote Access — Tailscale](#12-remote-access--tailscale)
13. [Screenshot & Backup Reference Log](#13-screenshot--backup-reference-log)

---

## 1. Document Control

| Field | Value |
| --- | --- |
| Site Name | JXStudio |
| Owner | [OWNER] |
| Storage Location | https://github.com/[USERNAME]/proxmox_homelab |
| Current Version | 1.0 |
| Date Created | 09/03/2026 |
| Date Last Updated | 09/03/2026 |
| Switch Stack Option | `[X] Option A — Single Switch (3750G only)` / `[ ] Option B — Dual Switch (3750G + 2960G)` |
| Companion Register | network-settings-register-POPULATED.md |
| Config Backup Location | `[Git repo /configs folder]` |

---

## 2. Environment Overview

### 2.1 — Site Summary

| Field | Value |
| --- | --- |
| ISP / WAN Type | Specrum 1G Cable |
| WAN IP Type | [X] Dynamic (DHCP from ISP)  [ ] Static — IP: ___________ |
| Physical Racks | 2 racks — ISP Rack and Server Rack |
| Inter-rack Cable | Cat6A Xm — TL-SG2008P Port 7 to 3750G Gi0/1] |

### 2.2 — Rack Layout

**ISP Rack**

| U Position | Device | Role |
| --- | --- | --- |
| `[U]` | TP-Link ER605 v2 | WAN Gateway / Router |
| `[U]` | TP-Link TL-SG2008P | Managed PoE Switch |
| `[U]` | TP-Link OC200 | Omada Hardware Controller |
| `[U]` | TP-Link EAP653 | Wireless Access Point |

**Server Rack**

| U Position | Device | Role |
|------------|--------|------|
| `[U]` | `[Server]` | Proxmox Hypervisor |
| `[U]` | Cisco Catalyst 3750G | L3 Core Switch |
| `[U]` | Cisco Catalyst 2960G | L2 Access Switch (Option B) / Lab (Option A) |
| `[U]` | Cisco 1921 #1 | Lab Edge Router (Phase 7) |
| `[U]` | Cisco 1921 #2 | VPN / Lab Router (Phase 7) |

### 2.3 — Hardware Inventory Summary

> Full details including firmware versions and management IPs are maintained in the companion register — Section 1: Hardware Inventory.

| # | Device | Model | Rack | Status |
|---|--------|-------|------|--------|
| 1 | WAN Router | TP-Link ER605 v2 | ISP Rack | Active |
| 2 | PoE Switch | TP-Link TL-SG2008P | ISP Rack | Active |
| 3 | Omada Controller | TP-Link OC200 | ISP Rack | Active |
| 4 | L3 Core Switch | Cisco Catalyst 3750G | Server Rack | Planned — Phase 2 |
| 5 | L2 Access Switch | Cisco Catalyst 2960G | Server Rack / Lab | Option B / Lab |
| 6 | Hypervisor | `[Model]` — Proxmox | Server Rack | Planned — Phase 4 |
| 7 | Router #1 | Cisco 1921 | Server Rack | Planned — Phase 7 |
| 8 | Router #2 | Cisco 1921 | Server Rack | Planned — Phase 7 |
| 9 | WAP | TP-Link EAP `[model]` | ISP Rack area | Active |
| 10 | Pi-hole DNS | Raspberry Pi `[model]` | `[Location]` | Active — Phase 1 |

---

## 3. Network Architecture

### 3.1 — Design Goals

The network is designed around four principles:

1. **Segmentation** — home, lab, IoT, and management traffic are fully isolated from each other by default. Cross-VLAN access is explicitly permitted only where required and documented.
2. **Least privilege** — home devices can only reach services through the reverse proxy. Direct access to lab infrastructure is restricted to specific admin devices.
3. **Manageability** — all network devices are managed through a dedicated MGMT VLAN that is not reachable from home or IoT devices.
4. **Phased buildout** — the network is built in discrete phases. Each phase is fully tested and documented before the next begins. Rules and configurations for future phases are pre-created but disabled until needed.

### 3.2 — Architecture Summary

```
[WAN / Internet]
       |
  [ER605 v2] — WAN gateway, DHCP server, VLAN routing, ACL enforcement
       |
  [TL-SG2008P] — ISP rack managed switch
       |  (Port 7 — 802.1Q Trunk — VLANs 10,20,30,99 — native 99)
  [3750G] — Server rack L3 core switch (Phase 2)
       |
  [2960G] — Access layer (Option B) / Lab device (Option A)
       |
  [Proxmox] — Hypervisor running VMs and LXCs (Phase 4)
```

### 3.3 — Switch Stack Decision

> **Decision required — update this section and the document header once confirmed.**

| | Option A — Single Switch | Option B — Dual Switch |
|--|--------------------------|------------------------|
| Production switches | 3750G only | 3750G + 2960G |
| 2960G use | Unplugged — available for lab experiments with 1921s | Tied up in production |
| Complexity | Simpler — one switch config | Two switch configs to maintain |
| Port count | Limited to 3750G port count | More ports available |
| Lab use | 2960G free alongside 1921s | 2960G unavailable |
| **Recommendation** | **Home lab — preferred** | Enterprise-style learning |

---

## 4. VLAN Design & Policy

### 4.1 — VLAN Summary

> Full VLAN parameters including DHCP ranges and DNS are maintained in the companion register — Section 2: VLAN Register and Section 3: DHCP Range Rationale.

| VLAN | Name | Subnet | Gateway | Purpose |
|------|------|--------|---------|---------|
| 10 | HOME | 192.168.10.0/24 | 192.168.10.1 | Home PCs, phones, TVs, consoles, Pi-hole |
| 20 | LAB | 192.168.20.0/24 | 192.168.20.1 | Servers, VMs, Proxmox infrastructure |
| 30 | IOT | 192.168.30.0/24 | 192.168.30.1 | Smart devices — fully isolated |
| 99 | MGMT | 192.168.99.0/24 | 192.168.99.1 | Network device management only |

### 4.2 — DHCP Range Philosophy

Ranges are intentionally zoned within each subnet:

- **Below the DHCP pool** — static infrastructure IPs. Set manually or via reservation. Never change without updating the register.
- **The DHCP pool** — dynamic devices. Pool starts high enough to leave room for static devices below it.
- **Above the DHCP pool** — reserved for future static devices. Not assigned, not pooled.

LAB keeps .1–.99 as a large static block because servers and VMs typically need fixed IPs. HOME and IOT use wider DHCP ranges because almost all devices are dynamic.

### 4.3 — Inter-VLAN Traffic Policy

> The ACL rules implementing this policy are maintained in the companion register — Section 8: Firewall — Gateway ACL Rules.

| Source | Destination | Action | Reason |
|--------|-------------|--------|--------|
| HOME — admin IPs | Proxmox :8006 | Permit | Daily driver admin access — specific IPs only |
| HOME — admin IPs | Lab :22 (SSH) | Permit | Admin SSH to lab servers |
| HOME — any | Proxy VM :80/:443 | Permit | All home devices reach services via reverse proxy only |
| HOME — any | LAB — direct | Block | Home devices cannot directly access lab infrastructure |
| HOME — any | IOT | Block | No lateral movement from home to IoT |
| IOT — any | HOME | Block | IoT fully isolated from home devices |
| IOT — any | LAB | Block | IoT fully isolated from lab |
| IOT — any | MGMT | Block | IoT cannot reach management devices |
| LAB — any | HOME | Permit | Lab machines can reach home resources |
| MGMT — any | All | Permit | Management VLAN has unrestricted internal access |

### 4.4 — Current Phase 1 ACL State

> ⚠️ Rules are enforced at the ER605 Gateway ACL (Omada: Settings > Network Security > ACL > Gateway ACL). Direction: LAN→LAN for all rules.

**Active rules — Phase 1:**

| # | Rule Name | Source → Destination | Policy | Notes |
|---|-----------|----------------------|--------|-------|
| 1 | Home-to-MGMT | HOME → MGMT | Permit | Broad — tighten to IP Groups in Phase 2 |
| 2 | Block-Home-to-Lab | HOME → LAB | Deny | |
| 3 | Block-Home-to-IoT | HOME → IOT | Deny | |
| 4 | Block-IoT-to-Home | IOT → HOME | Deny | |
| 5 | Block-IoT-to-Lab | IOT → LAB | Deny | |
| 6 | Block-IoT-to-MGMT | IOT → MGMT | Deny | |
| 7 | MGMT-Full-Access | MGMT → HOME, LAB, IOT | Permit | |

**Pending rules — created when each phase goes live:**  
Full pending rule details are in the companion register — Section 8: Pending Rules.

---

## 5. Two-Tier Access Architecture

Services running on the lab network are accessed through two distinct tiers. This architecture keeps Proxmox itself off the public-facing access path.

```
Tier 1 — Services (any home device)
  HOME device → Reverse Proxy VM (192.168.20.50) :80/:443 only
  Proxy forwards to individual service containers/VMs
  All service traffic filtered through one entry point

Tier 2 — Management (specific admin IPs only)
  Admin PC (192.168.10.10) → Proxmox :8006 directly
  Admin Laptop (192.168.10.11) → Proxmox :8006 directly
  Admin PC/Laptop → Lab :22 SSH directly
  Proxmox is NEVER a reverse proxy target
```

> **Rule:** If a service needs to be accessible from home devices, it goes through the proxy. If it needs to be managed, it is accessed directly from a registered admin IP only. These two paths never overlap.

---

## 6. DNS Architecture

### 6.1 — Phase 1 — Pi-hole on HOME VLAN

Pi-hole runs on the Raspberry Pi at 192.168.10.15 on VLAN 10. It serves DNS for VLAN 10 (HOME) only. All other VLANs use public DNS resolvers directly.

| VLAN | DNS Primary | DNS Secondary | Notes |
|------|-------------|---------------|-------|
| HOME 10 | 192.168.10.15 (Pi-hole) | 1.1.1.1 | Pi-hole filters and logs all VLAN 10 DNS queries |
| LAB 20 | 1.1.1.1 | 1.0.0.1 | Public DNS — no Pi-hole until Phase 2+ |
| IOT 30 | 9.9.9.9 | 149.112.112.112 | Quad9 — blocks malicious domains at resolver level |
| MGMT 99 | 1.1.1.1 | — | Public DNS — controller and switch queries only |

**No cross-VLAN ACL rules are needed for DNS in Phase 1.** DNS queries from VLAN 10 devices to 192.168.10.15 stay entirely within VLAN 10. Inter-VLAN ACL rules only apply when traffic crosses a VLAN boundary.

### 6.2 — Phase 2+ — Pi-hole on MGMT VLAN (Network-Wide)

When the Pi is repurposed as a MGMT utility device, it moves to 192.168.99.5 and serves DNS for all VLANs. At that point:

- All VLAN DHCP DNS entries update to 192.168.99.5
- Three new ACL permit rules are added for DNS port 53 from VLANs 20, 30, and 99 to 192.168.99.5
- Pi-hole is configured to listen on all interfaces

**Transition steps when ready:**

```
1. Set DHCP reservation on MGMT for Pi MAC → 192.168.99.5
2. SSH into Pi (still at 192.168.10.15 at this point)
3. Confirm Pi is using DHCP (not static) — no config change needed
   if Phase 1 steps were followed
4. Change Pi's switch port to MGMT profile
5. Pi comes up on 192.168.99.5
6. Update Pi-hole to listen on all interfaces
7. Add ACL permit rules for IoT→Pi, Lab→Pi, MGMT→Pi on port 53
8. Update DHCP DNS for VLANs 20, 30, 99 to 192.168.99.5
9. Update VLAN 10 DNS from 192.168.10.15 to 192.168.99.5
```

---

## 7. Physical Topology

### 7.1 — Option A — Single Switch (3750G Only)

```
[WAN / Internet]
      |
  [ER605 v2]
  192.168.10.1 / .20.1 / .30.1 / .99.1
      |
  [TL-SG2008P]          ISP Rack
  Mgmt: 192.168.99.10
      |
  Port 1  → OC200 (MGMT profile — VLAN 99)
  Port 2  → WAP — TP-Link EAP (HOME profile → WAP-TRUNK future)
  Port 3  → Admin PC 192.168.10.10 (HOME profile)
  Port 4  → Home device
  Port 5  → Home device
  Port 6  → Home Device
  Port 7  → [TRUNK: VLANs 10,20,30,99 native 99] → 3750G Gi0/1
  Port 8  → ER605 LAN port (LAN-Uplink profile)
      |
  [3750G]               Server Rack
  SVI99: 192.168.99.2
  SVI10: 192.168.10.2
  SVI20: 192.168.20.1
  SVI30: 192.168.30.1
      |
  Gi0/1   → TL-SG2008P Port 7 (inter-rack trunk)
  Gi0/2   → Proxmox NIC (VLAN 20 access)
  Gi0/3–12  → Lab servers (VLAN 20 access)
  Gi0/13–22 → IoT devices (VLAN 30 access)
  Gi0/23  → Cisco 1921 #1 (optional — Phase 7)
  Gi0/24  → Management / console only (VLAN 99)

  [2960G] → UNPLUGGED — available for lab experiments with 1921s
```

### 7.2 — Option B — Dual Switch (3750G + 2960G)

```
[WAN / Internet]
      |
  [ER605 v2]
      |
  [TL-SG2008P]          ISP Rack
      |
  Port 7 → [TRUNK: VLANs 10,20,30,99] → 3750G Gi0/1
      |
  [3750G]               Server Rack
      |
  Gi0/1  → TL-SG2008P Port 7 (inter-rack trunk)
  Gi0/2  → 2960G Gi0/1 (cascade trunk VLANs 20,30,99)
  Gi0/3  → Cisco 1921 #1 (optional)
  Gi0/4  → Cisco 1921 #2 (optional)
      |
  [2960G]               Server Rack
      |
  Gi0/1  → 3750G Gi0/2 (uplink trunk)
  Gi0/2  → Proxmox NIC (VLAN 20 access)
  Gi0/3–12  → Lab servers (VLAN 20 access)
  Gi0/13–22 → IoT devices (VLAN 30 access)
```

### 7.3 — Cable Plan

> Update as cables are run. Label both ends of every cable.

| Cable | From | Port | To | Port | Type | Length | VLAN / Notes |
|-------|------|------|----|------|------|--------|--------------|
| ISP WAN | ISP modem/ONT | — | ER605 | WAN | `[Cat6/Fibre]` | `[Length]` | WAN uplink |
| ER605 to Switch | ER605 | LAN | TL-SG2008P | Port 8 | `[Cat6]` | `[Length]` | LAN uplink |
| OC200 to Switch | OC200 | ETH | TL-SG2008P | Port 1 | `[Cat6]` | `[Length]` | MGMT VLAN 99 |
| WAP to Switch | EAP `[model]` | ETH | TL-SG2008P | Port 6 | `[Cat6]` | `[Length]` | HOME / WAP-TRUNK future |
| Inter-rack trunk | TL-SG2008P | Port 7 | 3750G | Gi0/1 | `[Cat6A]` | `[Length]` | Trunk all VLANs — Phase 2 |
| Proxmox to Switch | Proxmox NIC | — | 3750G / 2960G | `[Port]` | `[Cat6]` | `[Length]` | VLAN 20 — Phase 4 |

---

## 8. Phased Deployment Plan

> Update the status column as each phase is completed.  
> Do not begin a phase until the previous phase is fully tested and the change log is up to date.

| Phase | Focus | Key Tasks | Est. Time | Status |
|-------|-------|-----------|-----------|--------|
| 1 | Omada ISP Rack | VLANs, DHCP, ACL rules, port profiles, Pi-hole on HOME | 2–3 hrs | ✳️ In Progress |
| 2 | Catalyst 3750G | IOS config, SVIs, ACLs, inter-rack trunk | 2–3 hrs | 🔲 Not started |
| 3 | Catalyst 2960G | Option B only — cascade config | 1–1.5 hrs | 🔲 Not started |
| 4 | Proxmox | Install, VLAN-aware bridge, VM network config | 2–3 hrs | 🔲 Not started |
| 5 | Nginx Proxy Manager | Reverse proxy setup, service entries | 1–2 hrs | 🔲 Not started |
| 6 | Tailscale | Subnet router LXC, route advertisement | 1–2 hrs | 🔲 Not started |
| 7 | Cisco 1921 Routers | Optional lab edge / VPN config | 2–5 hrs | 🔲 Optional |
| — | Cabling & Labeling | Label all cables both ends | 1–2 hrs | 🔲 Ongoing |
| **Total** | | | **12–17 hrs** | |

### Phase 1 — Detailed Checklist

- [ ] VLANs 10, 20, 30, 99 created on ER605
- [ ] DHCP pools configured per VLAN
- [ ] DHCP reservations set — Admin PC (.10.10), Admin Laptop (.10.11)
- [ ] 7 Gateway ACL rules created and enabled
- [ ] IP Groups pre-created in Omada Profiles (Admin-PC, Admin-Laptop, Proxmox, Proxy-VM, Pi-hole)
- [ ] OC200 static IP set to 192.168.99.1
- [ ] TL-SG2008P management IP set to 192.168.99.10
- [ ] Port profiles created — HOME, MGMT, TRUNK-ALL, LAN-Uplink
- [ ] Media devices (TV, PS5) moved to VLAN 10 — tested, internet confirmed
- [ ] Raspberry Pi static IP removed, DHCP reservation set to 192.168.10.15
- [ ] Pi-hole confirmed working on VLAN 10, DHCP DNS updated to 192.168.10.15
- [ ] Remaining home devices moved to VLAN 10
- [ ] Admin Laptop moved to VLAN 10 — confirmed 192.168.10.11
- [ ] OC200 Port 1 and Admin PC Port 3 switched last — back to back
- [ ] Dashboard confirmed accessible at https://192.168.99.1:8043
- [ ] All devices shown as adopted in Omada
- [ ] Phase 1 change log entries completed in register

### Phase 2 — 3750G Key Config Notes

> Full IOS configuration commands will be added here when Phase 2 begins.

```
! Verify IOS feature set before starting
show version
show license

! Required for inter-VLAN routing
ip routing

! VLAN database
vlan 10
 name HOME
vlan 20
 name LAB
vlan 30
 name IOT
vlan 99
 name MGMT

! SVIs
interface Vlan99
 ip address 192.168.99.2 255.255.255.0
interface Vlan10
 ip address 192.168.10.2 255.255.255.0
interface Vlan20
 ip address 192.168.20.1 255.255.255.0
interface Vlan30
 ip address 192.168.30.1 255.255.255.0

! Default route back to ER605
ip route 0.0.0.0 0.0.0.0 192.168.10.1

! Inter-rack trunk to TL-SG2008P
interface GigabitEthernet0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,30,99
```

> ⚠️ Once the 3750G is routing VLANs 20 and 30, the ER605 SVIs for those VLANs should be removed or the 3750G default route updated to avoid asymmetric routing. Document this transition in the change log.

---

## 9. Omada Configuration Record

> This section records every setting configured in the Omada GUI.  
> It is the rebuild reference if the OC200 needs to be factory reset.  
> Update immediately after any change is applied in the UI.  
> Attach screenshots to the companion folder — see Section 13.

> ⚠️ The OC200 has been factory reset once during Phase 1 (09/03/2026) due to a login lockout during IP migration. All settings below reflect the post-reset target configuration.

### 9.1 — ER605 VLAN / LAN Definitions

> Omada: Settings > Wired & Wireless Networks > LAN. One row per VLAN.

| VLAN ID | Name | IP / Mask | DHCP Range | DNS Primary | DNS Secondary | DHCP | Lease |
|---------|------|-----------|------------|-------------|---------------|------|-------|
| 10 | HOME | 192.168.10.1/24 | .100–.200 | 192.168.10.15 | 1.1.1.1 | ON | 1 day |
| 20 | LAB | 192.168.20.1/24 | .100–.200 | 1.1.1.1 | 1.0.0.1 | ON | 1 day |
| 30 | IOT | 192.168.30.1/24 | .20–.254 | 9.9.9.9 | 149.112.112.112 | ON | 1 day |
| 99 | MGMT | 192.168.99.1/24 | N/A | 1.1.1.1 | — | OFF | N/A |

> **Note:** VLAN 10 DNS primary will be 1.1.1.1 until the Pi-hole is confirmed live at 192.168.10.15. Update this entry and the register when Pi-hole is confirmed working.

### 9.2 — OC200 Controller Static IP

> OC200 system settings — accessed via controller management page, not the site dashboard.

| Field | Value |
|-------|-------|
| IP Address | 192.168.99.1 |
| Subnet Mask | 255.255.255.0 |
| Gateway | 192.168.99.1 |
| DNS | 1.1.1.1 |
| Dashboard URL | https://192.168.99.1:8043 |

### 9.3 — TL-SG2008P Management IP

> Omada: Devices > TL-SG2008P > Config > Advanced

| Field | Value |
|-------|-------|
| IP Address | 192.168.99.10 |
| Subnet Mask | 255.255.255.0 |
| Gateway | 192.168.99.1 |
| Management VLAN | 99 |

### 9.4 — DHCP Reservations

> Omada: Settings > Services > DHCP Reservation (or via LAN VLAN settings).

| Device | MAC | Reserved IP | VLAN | Notes |
|--------|-----|-------------|------|-------|
| Admin PC | [MAC_REDACTED] | 192.168.10.10 | HOME 10 | Must be set before ACL rules |
| Admin Laptop | [MAC_REDACTED] | 192.168.10.11 | HOME 10 | Must be set before ACL rules |
| Raspberry Pi | [MAC_REDACTED] | 192.168.10.15 | HOME 10 | Pi-hole DNS — Phase 1 |
| OC200 | [MAC_REDACTED] | 192.168.99.1 | MGMT 99 | Assigned via DHCP reservation — DHCP briefly enabled on MGMT then disabled |
| Philips Hue Bridge | `[MAC]` | `[192.168.30.x]` | IOT 30 | Set when moved to IoT VLAN — currently on HOME |

### 9.5 — Switch Port Profiles

> Omada: Settings > Profiles > Switch Profiles.

| Profile Name | Untagged VLAN | Tagged VLANs | Native VLAN | Currently Used On | Notes |
|--------------|---------------|--------------|-------------|-------------------|-------|
| HOME | 10 | None | 10 | Ports 2,3,4,5,6 | Home device access ports |
| MGMT | 99 | None | 99 | Port 1 | OC200 only |
| TRUNK-ALL | None | 10,20,30,99 | 99 | Port 7 | Inter-rack trunk — native VLAN 99 prevents VLAN hopping |
| LAN-Uplink | 10 | None | 10 | Port 8 | ER605 LAN uplink |
| WAP-TRUNK | 10 | 10,20,30 | 10 | Not yet created | For VLAN-aware SSIDs — create when WAP model confirmed |

### 9.6 — TL-SG2008P Port Assignments

> Full port assignment table maintained in companion register — Section 7: Port Assignments.

| Port | Profile | Connected Device | Phase | Notes |
|------|---------|------------------|-------|-------|
| Port 1 | MGMT | OC200 — Omada Controller | 1 | Change last — after all other ports confirmed |
| Port 2 | HOME | `[Device]` | 1 | |
| Port 3 | HOME | Admin PC — 192.168.10.10 | 1 | Change last alongside Port 1 |
| Port 4 | HOME | `[Device]` | 1 | |
| Port 5 | HOME | `[Device]` | 1 | |
| Port 6 | HOME | WAP — TP-Link EAP | 1 | Future: WAP-TRUNK for VLAN-aware SSIDs |
| Port 7 | TRUNK-ALL | 3750G Gi0/1 | 2 | Not connected until Phase 2 |
| Port 8 | LAN-Uplink | ER605 LAN port | 1 | |

### 9.7 — Gateway ACL Rules (Omada)

> Omada: Settings > Network Security > ACL > Gateway ACL — Direction: LAN→LAN.  
> Full rule detail and pending rules in companion register — Section 8.

| # | Rule Name | Source → Destination | Policy | Status |
|---|-----------|----------------------|--------|--------|
| 1 | Home-to-MGMT | HOME → MGMT | Permit | ✅ Enabled |
| 2 | Block-Home-to-Lab | HOME → LAB | Deny | ✅ Enabled |
| 3 | Block-Home-to-IoT | HOME → IOT | Deny | ✅ Enabled |
| 4 | Block-IoT-to-Home | IOT → HOME | Deny | ✅ Enabled |
| 5 | Block-IoT-to-Lab | IOT → LAB | Deny | ✅ Enabled |
| 6 | Block-IoT-to-MGMT | IOT → MGMT | Deny | ✅ Enabled |
| 7 | MGMT-Full-Access | MGMT → HOME, LAB, IOT | Permit | ✅ Enabled |

### 9.8 — Omada ACL vs Cisco ACL — Role Split

| Layer | Device | Scope | Phase |
|-------|--------|-------|-------|
| Gateway ACL | ER605 via Omada | VLAN-to-VLAN policy — broad network rules | Phase 1 active |
| Switch ACL | Cisco 3750G IOS | Host-level rules — specific IPs, specific ports | Phase 2+ |
| EAP ACL | Omada wireless | Wireless client specific rules | Not needed currently |

> Once the 3750G is online it handles fine-grained ACLs (admin IP to Proxmox :8006, admin IP to SSH, etc.) natively in IOS. The Omada Gateway ACL handles the broad VLAN isolation policy. The two layers complement rather than duplicate each other.

### 9.9 — WAP SSID Configuration

> Omada: Wireless > Wi-Fi. Verify EAP model supports VLAN-tagged SSIDs before creating IoT-Net and LabWiFi SSIDs.

| SSID | VLAN | Band | Security | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| Analingus | 10 | 2.4 + 5GHz | WPA2/WPA3 | ✅ Active | All devices currently on HOME VLAN 10 |
| IoT-Net | 30 | 2.4GHz | WPA2 | 🔲 Planned | Requires WAP-TRUNK port profile and VLAN-capable EAP |
| LabWiFi | 20 | 5GHz | WPA2 | 🔲 Planned | Admin devices only |

---

## 10. Cisco Device Configuration Record

> After completing initial configuration on each Cisco device, record the key details below and store the full running config in the Git repository under `/configs`.

### 10.1 — Catalyst 3750G

| Field | Value |
|-------|-------|
| Hostname | `[e.g. SW-CORE-3750G]` |
| IOS Version | `[run: show version]` |
| Feature Set | `[IP Base / IP Services — run: show license]` |
| Stack Option | `[ ] Option A — L3 core + access  [ ] Option B — L3 core only` |
| Management IP | 192.168.99.2 (Vlan99 SVI) |
| Default Route | ip route 0.0.0.0 0.0.0.0 192.168.10.1 |
| Active SVIs | Vlan10 → .10.2 / Vlan20 → .20.1 / Vlan30 → .30.1 / Vlan99 → .99.2 |
| VLANs | 10 HOME, 20 LAB, 30 IOT, 99 MGMT — VLAN 1 shutdown |
| ACLs Applied | VLAN10-IN on Vlan10 in / VLAN30-IN on Vlan30 in |
| SSH / Auth | SSH v2, RSA 2048, local auth, VTY transport input ssh |
| Last Config Backup | `[DD/MM/YYYY — filename or Git commit]` |
| Phase | 2 — Not started |

### 10.2 — Catalyst 2960G *(Option B only)*

| Field | Value |
|-------|-------|
| Hostname | `[e.g. SW-ACCESS-2960G]` |
| IOS Version | `[run: show version]` |
| Management IP | 192.168.99.3 (Vlan99) |
| Default Gateway | 192.168.99.2 (3750G SVI) |
| Uplink | Gi0/1 → trunk to 3750G Gi0/2 |
| Last Config Backup | `[DD/MM/YYYY — filename or Git commit]` |
| Phase | 3 — Not started (Option B only) |

### 10.3 — Cisco 1921 Routers *(Phase 7 — Optional)*

| Field | Router #1 | Router #2 |
|-------|-----------|-----------|
| Hostname | `[e.g. RTR-LAB-01]` | `[e.g. RTR-VPN-02]` |
| IOS Version | `[show version]` | `[show version]` |
| Planned IP | 192.168.20.254 | 192.168.20.253 |
| Role | Lab Edge | VPN / Lab |
| Phase | 7 — Optional | 7 — Optional |

---

## 11. Proxmox & Services Record

> Update when VMs or LXCs are created, removed, or have their network config changed.

### 11.1 — Proxmox Host Configuration

| Field | Value |
|-------|-------|
| Host IP | 192.168.20.10 |
| VLAN | 20 — LAB |
| Web UI | https://192.168.20.10:8006 |
| Access | Admin PC and Admin Laptop via ACL rules only — never via reverse proxy |
| Bridge config | vmbr0 — VLAN-aware bridge (set bridge-vlan-aware yes from day one) |
| Phase | 4 — Not started |

> **VLAN-aware bridge — set this on day one:**
> ```
> # /etc/network/interfaces
> iface vmbr0 inet static
>   bridge-vlan-aware yes
>   bridge-vids 2-4094
> ```
> Setting this from day one means VMs can be assigned VLAN tags without any bridge reconfiguration later. Zero impact to add early, potentially disruptive to change after VMs are running.

### 11.2 — VM / LXC Register

> Full register maintained in companion register — Section 10.

| ID | Hostname | Type | IP | VLAN | Purpose | Phase |
|----|----------|------|----|------|---------|-------|
| 100 | nginx-proxy | LXC | 192.168.20.50 | 20 | Nginx Proxy Manager | 5 |
| 101 | tailscale | LXC | 192.168.20.51 | 20 | Tailscale subnet router | 6 |

### 11.3 — Reverse Proxy Architecture

All home-accessible services are accessed exclusively through Nginx Proxy Manager at 192.168.20.50.

```
Home device (192.168.10.x)
  → Nginx Proxy Manager (192.168.20.50) :80/:443
    → Service A (192.168.20.x:port)
    → Service B (192.168.20.x:port)
    → Service C (192.168.20.x:port)

Proxmox (192.168.20.10:8006) — NEVER a proxy target
  → Admin PC (192.168.10.10) direct only — ACL permit
  → Admin Laptop (192.168.10.11) direct only — ACL permit
```

> Full service register maintained in companion register — Section 11: Reverse Proxy Services.

---

## 12. Remote Access — Tailscale

> Phase 6. Tailscale LXC at 192.168.20.51 acts as a subnet router, advertising all three internal subnets to authorised Tailscale devices.

### 12.1 — Subnet Router Configuration

```bash
# Enable IP forwarding (add to /etc/sysctl.conf)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Bring up Tailscale as subnet router and exit node
tailscale up \
  --advertise-routes=192.168.10.0/24,192.168.20.0/24,192.168.30.0/24 \
  --advertise-exit-node
```

After running the command, approve the advertised routes in the Tailscale admin console at https://login.tailscale.com/admin/machines.

### 12.2 — ACL Rule Required

When Tailscale is live, add an ACL permit for the Tailscale LXC to reach all internal VLANs. This is handled in the Cisco 3750G ACL in Phase 2+ rather than in Omada, as the 3750G will be routing those VLANs by then.

---

## 13. Screenshot & Backup Reference Log

> Screenshots are not stored in this document. Store them in the companion folder and reference them here.  
> Cisco running configs are stored as plain text in the Git repository — they are fully diffable.

### 13.1 — Recommended Folder Structure

```
/HomeLab-Docs/                          ← Git repository root
  network-design-document.md            ← this file
  network-settings-register.md          ← companion register
  README.md                             ← site summary and repo index
  /screenshots/
    /omada/
      VLAN-Definitions-YYYYMMDD.png
      Port-Profiles-YYYYMMDD.png
      ACL-Rules-YYYYMMDD.png
      DHCP-Reservations-YYYYMMDD.png
      SSID-Config-YYYYMMDD.png
    /proxmox/
      VM-List-YYYYMMDD.png
      Network-Bridge-Config-YYYYMMDD.png
    /nginx-proxy-manager/
      Proxy-Hosts-YYYYMMDD.png
  /configs/
    3750G-running-config-YYYYMMDD.txt
    2960G-running-config-YYYYMMDD.txt
    1921A-running-config-YYYYMMDD.txt
    1921B-running-config-YYYYMMDD.txt
```

### 13.2 — Screenshot Log

> Take a screenshot of every Omada GUI page after it is configured. Name with YYYYMMDD suffix.

| Date | Device / Section | Filename | Notes |
|------|-----------------|----------|-------|
| `[Date]` | Omada — VLAN Definitions | VLAN-Definitions-`[YYYYMMDD]`.png | After all 4 VLANs created |
| `[Date]` | Omada — ACL Rules | ACL-Rules-`[YYYYMMDD]`.png | After all 7 Phase 1 rules created |
| `[Date]` | Omada — Port Profiles | Port-Profiles-`[YYYYMMDD]`.png | After all profiles created |
| `[Date]` | Omada — DHCP Reservations | DHCP-Reservations-`[YYYYMMDD]`.png | After all reservations set |
| `[Date]` | Omada — Port Assignments | Port-Assignments-`[YYYYMMDD]`.png | After Phase 1 port changes complete |
| `[Date]` | `[Device / Section]` | `[Filename]` | `[Notes]` |

### 13.3 — Config Backup Log

| Date | Device | Filename / Git Commit | Notes |
|------|--------|----------------------|-------|
| `[Date]` | 3750G | 3750G-initial-`[YYYYMMDD]`.txt | Initial config after Phase 2 complete |
| `[Date]` | 2960G | 2960G-initial-`[YYYYMMDD]`.txt | Initial config after Phase 3 complete |
| `[Date]` | 1921 #1 | 1921A-initial-`[YYYYMMDD]`.txt | Initial config after Phase 7 |
| `[Date]` | 1921 #2 | 1921B-initial-`[YYYYMMDD]`.txt | Initial config after Phase 7 |

---

> **Firewall rule description standard**  
> When naming ACL rules in Omada or IOS, use the format:  
> `[Source context] → [Destination context]: [reason]`  
> Example: `Admin-PC (10.10) → Proxmox-mgmt (20.10:8006): daily driver admin access`  
> Populate the description/notes field on every object — VLAN, ACL rule, port profile, SSID — at creation time, not later.

---

*Last commit: `"Added NDD v1.0 — Phase 1 prep"`*
