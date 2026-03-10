# Network Settings Register
**Site Name:** `[Site Name]`  
**Owner:** `[Your Name]`  
**Storage:** `[Git repo URL or folder path]`  
**Version:** `1.0`  
**Created:** `DD/MM/YYYY`  
**Last Updated:** `DD/MM/YYYY`  
**Switch Stack:** `[ ] Option A — Single Switch (3750G only)  [ ] Option B — Dual Switch (3750G + 2960G)`

---

> **How to use this document**  
> Each section below corresponds to a tab from the Excel register.  
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
| 1 | WAN Router | `[Model]` | `[Version]` | `[Location]` | WAN Gateway | `[IP]` | Active |
| 2 | PoE Switch | `[Model]` | `[Version]` | `[Location]` | Managed Switch | `[IP]` | Active |
| 3 | Controller | `[Model]` | `[Version]` | `[Location]` | Omada Controller | `[IP]` | Active |
| 4 | L3 Core Switch | `[Model]` | `[IOS Version]` | `[Location]` | L3 Core | `[IP]` | `[Active/Standby/Lab]` |
| 5 | L2 Access Switch | `[Model]` | `[IOS Version]` | `[Location]` | Access / Lab | `[IP]` | `[Active/Lab]` |
| 6 | Hypervisor | `[Model — Proxmox vX.X]` | `[Version]` | `[Location]` | Hypervisor | `[IP]` | `[Active/Planned]` |
| 7 | Router #1 | `[Model]` | `[IOS Version]` | `[Location]` | Lab Edge | `[IP]` | `[Active/Lab]` |
| 8 | Router #2 | `[Model]` | `[IOS Version]` | `[Location]` | VPN / Lab | `[IP]` | `[Active/Lab]` |
| 9 | WAP | `[Model]` | `[Version]` | `[Location]` | Wireless AP | `[IP]` | Active |
| 10 | `[Device]` | `[Model]` | `[Version]` | `[Location]` | `[Role]` | `[IP]` | `[Status]` |

---

## 2. VLAN Register

> Update when a VLAN is added, removed, or any of its parameters change.

| VLAN ID | Name | Subnet | Gateway IP | Static Range | DHCP Range | DNS Primary | DNS Secondary | DHCP | Lease | Purpose |
|---------|------|--------|------------|--------------|------------|-------------|---------------|------|-------|---------|
| 10 | HOME | `[x.x.x.0/24]` | `[x.x.x.1]` | `.1 – .xx` | `.xx – .xx` | `[DNS]` | `[DNS]` | ON | 1 day | `[Purpose]` |
| 20 | LAB | `[x.x.x.0/24]` | `[x.x.x.1]` | `.1 – .xx` | `.xx – .xx` | `[DNS]` | `[DNS]` | ON | 1 day | `[Purpose]` |
| 30 | IOT | `[x.x.x.0/24]` | `[x.x.x.1]` | `.1 – .xx` | `.xx – .xx` | `[DNS]` | `[DNS]` | ON | 1 day | `[Purpose]` |
| 99 | MGMT | `[x.x.x.0/24]` | `[x.x.x.1]` | All | N/A | `[DNS]` | — | OFF | N/A | `[Purpose]` |

---

## 3. DHCP Range Rationale

> Document the reasoning behind each VLAN's range. Update if ranges change.

| VLAN | Static Reserved | DHCP Pool | Rationale |
|------|----------------|-----------|-----------|
| HOME 10 | `.1 – .xx` | `.xx – .xx` | `[Reasoning]` |
| LAB 20 | `.1 – .xx` | `.xx – .xx` | `[Reasoning]` |
| IOT 30 | `.1 – .xx` | `.xx – .xx` | `[Reasoning]` |
| MGMT 99 | All addresses | DHCP disabled | `[Reasoning]` |

---

## 4. IP Register

> Authoritative IP reference. Update immediately when any device IP changes.  
> **Type:** Static = hardcoded on device | Reservation = DHCP reservation by MAC

| Device / Hostname | IP Address | VLAN | MAC Address | Type | Phase | Notes |
|-------------------|------------|------|-------------|------|-------|-------|
| `[Device]` | `[IP]` | `[VLAN]` | `[MAC]` | `[Static/Reservation]` | `[Phase]` | `[Notes]` |
| `[Device]` | `[IP]` | `[VLAN]` | `[MAC]` | `[Static/Reservation]` | `[Phase]` | `[Notes]` |
| `[Device]` | `[IP]` | `[VLAN]` | `[MAC]` | `[Static/Reservation]` | `[Phase]` | `[Notes]` |
| `[Device]` | `[IP]` | `[VLAN]` | `[MAC]` | `[Static/Reservation]` | `[Phase]` | `[Notes]` |
| `[Device]` | `[IP]` | `[VLAN]` | `[MAC]` | `[Static/Reservation]` | `[Phase]` | `[Notes]` |

---

## 5. DHCP Reservations

> Set in Omada: Settings > Wired Networks > LAN > select VLAN > DHCP Reservation.  
> **Must be set before writing any ACL rules that reference these IPs.**

| Device Name | MAC Address | Reserved IP | VLAN | Date Set | ACL Reference | Notes |
|-------------|-------------|-------------|------|----------|---------------|-------|
| `[Device]` | `[MAC]` | `[IP]` | `[VLAN]` | `[Date]` | `[Rule #]` | `[Notes]` |
| `[Device]` | `[MAC]` | `[IP]` | `[VLAN]` | `[Date]` | `[Rule #]` | `[Notes]` |
| `[Device]` | `[MAC]` | `[IP]` | `[VLAN]` | `[Date]` | `[Rule #]` | `[Notes]` |

---

## 6. Switch Port Profiles

> Omada: Settings > Profiles > Switch Profiles.  
> Update when a profile is created, modified, or deleted.

| Profile Name | Untagged VLAN | Tagged VLANs | Native VLAN | Used On Ports | Notes |
|--------------|---------------|--------------|-------------|---------------|-------|
| `[Name]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Ports]` | `[Notes]` |
| `[Name]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Ports]` | `[Notes]` |
| `[Name]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Ports]` | `[Notes]` |

---

## 7. Port Assignments

> Update when a device is connected, moved, or a port config changes.

### TL-SG2008P

| Port | Profile | Untagged VLAN | Tagged VLANs | Native VLAN | Connected Device | Last Updated | Notes |
|------|---------|---------------|--------------|-------------|------------------|--------------|-------|
| Port 1 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 2 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 3 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 4 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 5 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 6 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 7 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |
| Port 8 | `[Profile]` | `[VLAN]` | `[VLANs]` | `[VLAN]` | `[Device]` | `[Date]` | `[Notes]` |

### Catalyst 3750G

| Port | Mode | VLAN | Connected Device | Notes |
|------|------|------|------------------|-------|
| Gi0/1 | Trunk | 10,20,30,99 | `[Device]` | Inter-rack trunk |
| Gi0/2 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/3–12 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/13–22 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/23 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/24 | Access | 99 | Management only | `[Notes]` |

### Catalyst 2960G *(Option B only / Lab use in Option A)*

| Port | Mode | VLAN | Connected Device | Notes |
|------|------|------|------------------|-------|
| Gi0/1 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/2 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/3–12 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |
| Gi0/13–22 | `[Mode]` | `[VLAN]` | `[Device]` | `[Notes]` |

---

## 8. Firewall — Gateway ACL Rules

> Omada: Settings > Network Security > ACL > Gateway ACL  
> **Direction: LAN→LAN for all rules below.**  
> **Rules are first-match top-down — order is critical.**  
> Update immediately when a rule is added, changed, reordered, or toggled.

> ⚠️ A misplaced permit above a block can silently allow unintended traffic. Always test after changes.

| # | Rule Name | Source | Destination | Protocol | Port | Policy | Status | Date Added | Notes |
|---|-----------|--------|-------------|----------|------|--------|--------|------------|-------|
| 1 | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[On/Off]` | `[Date]` | `[Notes]` |
| 2 | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[On/Off]` | `[Date]` | `[Notes]` |
| 3 | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[On/Off]` | `[Date]` | `[Notes]` |
| 4 | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[On/Off]` | `[Date]` | `[Notes]` |
| 5 | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[On/Off]` | `[Date]` | `[Notes]` |

### Pending Rules — Create when service is live

| # | Rule Name | Source | Destination | Protocol | Port | Policy | Waiting On |
|---|-----------|--------|-------------|----------|------|--------|------------|
| — | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[Phase/Service]` |
| — | `[Name]` | `[Source]` | `[Destination]` | `[Proto]` | `[Port]` | `[Permit/Deny]` | `[Phase/Service]` |

---

## 9. SSID Configuration

> Omada: Wireless > Wi-Fi  
> Update when an SSID is added, removed, or its config changes.  
> Note: WAP port must be set to a trunk profile to support multiple VLAN-tagged SSIDs.

| SSID Name | VLAN Tag | Band | Security | WAP Device | WAP Port | Enabled | Notes |
|-----------|----------|------|----------|------------|----------|---------|-------|
| `[SSID]` | `[VLAN]` | `[Band]` | `[Security]` | `[Device]` | `[Port]` | `[Y/N]` | `[Notes]` |
| `[SSID]` | `[VLAN]` | `[Band]` | `[Security]` | `[Device]` | `[Port]` | `[Y/N]` | `[Notes]` |
| `[SSID]` | `[VLAN]` | `[Band]` | `[Security]` | `[Device]` | `[Port]` | `[Y/N]` | `[Notes]` |

---

## 10. VM and Services Register

> Update when a VM or LXC is created, removed, or its network config changes.

| VM/LXC ID | Hostname | Type | IP Address | VLAN Tag | OS | Purpose | Phase | Notes |
|-----------|----------|------|------------|----------|----|---------|-------|-------|
| `[ID]` | `[Name]` | `[VM/LXC]` | `[IP]` | `[VLAN]` | `[OS]` | `[Purpose]` | `[Phase]` | `[Notes]` |
| `[ID]` | `[Name]` | `[VM/LXC]` | `[IP]` | `[VLAN]` | `[OS]` | `[Purpose]` | `[Phase]` | `[Notes]` |

---

## 11. Reverse Proxy Services

> Update when a service is added, removed, or its target changes.  
> ⚠️ **Never add Proxmox (port 8006) as a proxy target — admin access via ACL only.**

| Domain / Hostname | Forward Host | Port | SSL | ACL Rule | Enabled | Notes |
|-------------------|--------------|------|-----|----------|---------|-------|
| `[hostname.lab]` | `[IP]` | `[Port]` | `[Y/N]` | `[Rule #]` | `[Y/N]` | `[Notes]` |
| `[hostname.lab]` | `[IP]` | `[Port]` | `[Y/N]` | `[Rule #]` | `[Y/N]` | `[Notes]` |
| ~~Proxmox :8006~~ | ~~DO NOT ADD~~ | ~~8006~~ | — | ACL only | — | Admin access via ACL rules only |

---

## 12. Change Log

> Record every change after initial setup — no matter how small.  
> Fill in **before** making the change — record the previous value first.  
> **A change without a log entry is a change that cannot be safely undone.**

| Date | Time | Device | Section | What Changed | Previous Value | New Value | Tested OK | Reason |
|------|------|--------|---------|--------------|----------------|-----------|-----------|--------|
| `DD/MM/YY` | `HH:MM` | `[Device]` | `[Section]` | `[Description]` | `[Old value]` | `[New value]` | `[Y/N]` | `[Reason]` |
| `DD/MM/YY` | `HH:MM` | `[Device]` | `[Section]` | `[Description]` | `[Old value]` | `[New value]` | `[Y/N]` | `[Reason]` |

---

*Last commit: `[describe what changed in this commit]`*
