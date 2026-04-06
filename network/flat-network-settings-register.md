# Flat Network Settings Register
**Site Name:** `JXStudios`
**Owner:** `[OWNER]`
**Storage:** `https://github.com/[USERNAME]/proxmox_homelab`
**Version:** `1.0`
**Created:** `2026/04/03`
**Last Updated:** `2026/04/03`
**Network:** `192.168.0.0/24 — Flat (pre-VLAN, temporary)`
**Status:** Active — in use until Phase 1 maintenance window is completed

> **Purpose of this document**
> Temporary living register for the flat `192.168.0.0/24` network. Mirrors the structure of
> `network_settings_register_populated.md` but scoped to what is actually deployed right now.
> When the Phase 1 maintenance window completes and VLANs go live, this document is retired —
> the main register becomes the authoritative source again.
>
> Update immediately when any device IP or connection changes.
> Format: `Updated [section] — [what changed] — [reason]`

---

## Table of Contents

1. [Hardware Inventory](#1-hardware-inventory)
2. [IP Register](#2-ip-register)
3. [DHCP Configuration](#3-dhcp-configuration)
4. [Physical Port Assignments](#4-physical-port-assignments)
5. [DNS — Pi-hole](#5-dns--pi-hole)
6. [SSID Configuration](#6-ssid-configuration)
7. [Services Running on Flat Network](#7-services-running-on-flat-network)
8. [Change Log](#8-change-log)

---

## 1. Hardware Inventory

> Update when a device is added, removed, replaced, or its firmware/OS changes.

| # | Device / Hostname | Model | Role | Location | Flat IP | Status |
|---|-------------------|-------|------|----------|---------|--------|
| 1 | ER605 | TP-Link ER605 v2 | WAN Router / DHCP server | ISP Rack | 192.168.0.1 | ✅ Active |
| 2 | TL-SG2008P | TP-Link TL-SG2008P | Managed PoE switch (running untagged / flat) | ISP Rack | `[TBC — check Omada or DHCP leases]` | ✅ Active |
| 3 | OC200 | TP-Link OC200 | Omada Controller | ISP Rack | 192.168.0.102 | ✅ Active |
| 4 | WAP | TP-Link EAP653 | Wireless AP | ISP Rack area | 192.168.0.103 | ✅ Active |
| 5 | hestia | Raspberry Pi 5 (8 GB) | Pi-hole DNS + Tailscale subnet router | `[Location TBC]` | 192.168.0.153 | ✅ Active |
| 6 | Genesis2 | Custom — AMD Ryzen 7 5700X, 64 GB DDR4 | Proxmox hypervisor (Phase 1b — install in progress) | Server Rack | 192.168.0.152 | 🟡 In progress |
| 7 | Helios | OR PC — Intel i3-2120, 16 GB DDR3 | Home server — Forgejo, Samba, Jellyfin, code-server | Server Rack | 192.168.0.151 | ✅ Active |
| 8 | Alival | Custom — AMD Ryzen 5 5600X, 32 GB DDR4 | Primary admin workstation (Windows 11 / Fedora dual boot) | Office | 192.168.0.62 - DHCP | ✅ Active |
| 9 | MacBook Pro 2015 | Intel Core i7-4770HQ, 16 GB | Admin laptop (macOS) | `[Location TBC]` | `[TBC — DHCP]` | ✅ Active |
| 10 | HP Laptop | Intel Core i5-7200U, 8 GB | Admin laptop (Fedora) | `[Location TBC]` | `[TBC — DHCP]` | ✅ Active |
| 11 | Xavier PC | `[Specs TBC]` | Household PC | Office | `[TBC — DHCP]` | ✅ Active |
| 12 | Vizio TV | — | Media / streaming | Living room | `[TBC — DHCP]` | ✅ Active |
| 13 | PS5 | Sony PlayStation 5 | Gaming console | Living room |  — DHCP | ✅ Active |
| 14 | Philips Hue Bridge | Philips Hue Bridge v2 | Smart lighting controller | `[Location TBC]` | `[TBC — DHCP]` | ✅ Active |
| 15 | GS308 | Netgear GS308 (unmanaged) | 8-port unmanaged switch — server/admin side | Server Rack | N/A (unmanaged) | ✅ Active |
| 16 | GS305 | Netgear GS305 (unmanaged) | 5-port unmanaged switch — media devices | Living room | N/A (unmanaged) | ✅ Active |

---

## 2. IP Register

> Authoritative IP reference for the flat `192.168.0.0/24` network.
> **Type:** Static = hardcoded on device | Reservation = DHCP reservation by MAC | DHCP = dynamic, no reservation
> Update immediately when any device IP changes.

| Device / Hostname | IP Address | MAC Address | Type | Notes |
|-------------------|------------|-------------|------|-------|
| ER605 — Gateway | 192.168.0.1 | N/A | Static | WAN gateway and DHCP server — do not change |
| hestia (RPi 5 — Pi-hole) | 192.168.0.153 | [MAC_REDACTED] | Static | Set on device — Pi-hole and Tailscale subnet router |
| Genesis2 (Proxmox) | 192.168.0.152 | `[TBC — record after install]` | Static | Set during Proxmox installer. Temp address — never hardcode into service configs. Migrates to 192.168.20.10 at Phase 2. |
| Helios | 192.168.0.151 | `[TBC — record MAC]` | Static | Set on Debian 12 host. Migrates to 192.168.20.11 at Phase 2. |
| TL-SG2008P | 192.168.0.101 | [MAC_REDACTED] | DHCP / Reservation | Check Omada or ER605 DHCP leases to confirm current IP |
| OC200 — Omada Controller | `[TBC]` | [MAC_REDACTED] | DHCP | Currently on flat net DHCP. Set to reservation 192.168.99.2 once VLAN window runs. |
| WAP — TP-Link EAP | `[TBC]` | `[TBC]` | DHCP | Check Omada for current IP |
| Alival (Admin PC) | `[TBC]` | [MAC_REDACTED] | DHCP | Set reservation once Phase 1 window runs. Future: 192.168.10.10 on HOME VLAN. |
| MacBook Pro 2015 (Admin) | `[TBC]` | [MAC_REDACTED] | DHCP | Future: 192.168.10.11 on HOME VLAN. |
| HP Laptop / Fedora (Admin) | `[TBC]` | `[TBC]` | DHCP | Future admin laptop. Future: HOME VLAN. |
| Xavier PC | `[TBC]` | [MAC_REDACTED] | DHCP | Future: 192.168.10.12 on HOME VLAN. |
| Vizio TV | `[TBC]` | [MAC_REDACTED] | DHCP | Future: HOME VLAN 10. |
| PS5 | `[TBC]` | `[TBC — record MAC]` | DHCP | Future: HOME VLAN 10. |
| Philips Hue Bridge | 192.168.0.100 | [MAC_REDACTED] | DHCP | Future: IOT VLAN 30 (set static via Hue app after move). |
| Eos | 192.168.0.154 | [MAC_REDACTED] | Static | `[Notes]` |
| `[Device / Hostname]` | `[IP Address]` | `[MAC Address]` | `[Type]` | `[Notes]` |

---

## 3. DHCP Configuration

> ER605 is currently running DHCP for the entire flat `192.168.0.0/24` subnet.
> No VLAN segmentation — all devices are on the same broadcast domain.

| Setting | Value |
|---------|-------|
| DHCP Server | ER605 |
| Subnet | 192.168.0.0/24 |
| Gateway | 192.168.0.1 |
| DHCP Pool | 192.168.0.1 - 192.168.0.150 |
| DNS Primary | 192.168.0.153 (Pi-hole — hestia) |
| DNS Secondary | 1.1.1.1 (Cloudflare — fallback) |
| Lease Time | 120 minutes |

> **DNS note:** Pi-hole is set as primary DNS via the ER605 DHCP settings.
> All devices picking up DHCP will have Pi-hole as their DNS server automatically.
> Force a lease renewal on any device that predates this change:
> - Linux: `sudo dhclient -r && sudo dhclient`
> - macOS: disconnect / reconnect Wi-Fi
> - Windows: `ipconfig /release && ipconfig /renew`

### DHCP Reservations — Flat Network

> Set in ER605: LAN > DHCP Server > Address Reservation.
> Record here when any reservation is set.

| Device | MAC Address | Reserved IP | Date Set | Notes |
|--------|-------------|-------------|----------|-------|
| hestia (RPi 5) | [MAC_REDACTED] | 192.168.0.153 | `[TBC — or confirm static on device]` | Pi-hole host — critical, must not change |
| Genesis2 | `[TBC]` | 192.168.0.152 | `[TBC]` | Set if using DHCP reservation rather than static on host |
| Helios | `[TBC]` | 192.168.0.151 | `[TBC]` | Set if using DHCP reservation rather than static on host |
| Eos | [MAC_REDACTED] | 192.168.0.154 | `[Date]` | `[Notes]` |
| `[Device]` | `[MAC]` | `[IP]` | `[Date]` | `[Notes]` |

---

## 4. Physical Port Assignments

> Unmanaged switches have no VLAN config — all ports are flat.
> Update when a device is connected to a different port.

### TL-SG2008P (Managed — running flat / all ports untagged)

| Port | Connected Device | MAC | Notes |
|------|-----------------|-----|-------|
| Port 1 | OC200 — Omada Controller | [MAC_REDACTED] | Management port — will change to MGMT profile at Phase 1 window |
| Port 2 | WAP — TP-Link EAP | 40:AE:30:25;5D:44 | Currently flat — will change to WAP-TRUNK at Phase 1 window |
| Port 3 | GS308 (uplink, port 8) | N/A | Server / admin side downlink |
| Port 4 | Xavier PC | [MAC_REDACTED] | Will change to HOME profile at Phase 1 window |
| Port 5 | Philips Hue Bridge | [MAC_REDACTED] | Will change to HOME (then IOT) at Phase 1 window |
| Port 6 | GS305 (uplink) | N/A | Media devices downlink |
| Port 7 | TL-SG605 (uplink) | — | Server rack devices downlink |
| Port 8 | ER605 LAN port | N/A | WAN uplink |

### Netgear GS308 (Unmanaged — flat)

| Port | Connected Device | MAC | Notes |
|------|-----------------|-----|-------|
| Port 1 | `[TBC]` | — | |
| Port 2 | `[TBC]` | — | |
| Port 3 | hestia (RPi 5 — Pi-hole) | [MAC_REDACTED] | |
| Port 4 | `[TBC]` | — | |
| Port 5 | availiable hotswap cable | — | |
| Port 6 | `[TBC]` | — | |
| Port 7 | Alival (Admin PC) | [MAC_REDACTED] | |
| Port 8 | Uplink from TL-SG2008P Port 3 | N/A | |

### Netgear GS305 (Unmanaged — flat)

| Port | Connected Device | MAC | Notes |
|------|-----------------|-----|-------|
| Port 1 | Uplink from TL-SG2008P Port 6 | N/A | |
| Port 2 | Vizio TV | [MAC_REDACTED] | |
| Port 3 | PS5 | `[TBC — record MAC]` | |
| Port 4 | `[TBC]` | — | |
| Port 5 | `[TBC]` | — | |

---

## 5. DNS — Pi-hole

> Pi-hole is running on hestia at `192.168.0.153`.
> All flat network devices use this as their DNS server via the ER605 DHCP settings.

| Setting | Value |
|---------|-------|
| Host | hestia (RPi 5) |
| IP | 192.168.0.153 |
| Admin dashboard | http://192.168.0.153/admin |
| Upstream DNS | Cloudflare — 1.1.1.1 / 1.0.0.1 |
| Listening mode | ALL (required for Tailscale remote DNS) |
| Tailscale subnet router | Enabled — advertises 192.168.0.0/24 |

> **Remote DNS:** Tailscale is configured on hestia as a subnet router (not an exit node).
> When connected to Tailscale remotely, phone/laptop DNS resolves through Pi-hole.
> Only DNS traffic routes via home — regular internet traffic is unaffected.

### Pi-hole Blocklists

| List | Source | Status |
|------|--------|--------|
| StevenBlack Unified | Default | ✅ Active |
| `[Additional lists TBC]` | — | — |

---

## 6. SSID Configuration

> Update when SSID name, password, or band config changes.

| SSID Name | Band | Security | WAP Device | Status | Notes |
|-----------|------|----------|------------|--------|-------|
| Analingus | 2.4 + 5 GHz | WPA2/WPA3 | TP-Link EAP `[model]` | ✅ Active | Single flat SSID — all wireless devices on 192.168.0.0/24 |

---

## 7. Services Running on Flat Network

> Services that are live and reachable on the flat network right now.
> Update when a service is deployed, changed, or taken offline.

| Service | Host | Address | Port | Notes |
|---------|------|---------|------|-------|
| Pi-hole Admin | hestia | http://192.168.0.153/admin | 80 | Ad-blocking + DNS |
| Pi-hole DNS | hestia | 192.168.0.153 | 53 | Network-wide DNS |
| Tailscale subnet router | hestia | (Tailscale IP) | — | Advertises 192.168.0.0/24 — remote access and DNS |
| Proxmox Web UI | Genesis2 | https://192.168.0.20:8006 | 8006 | Install in progress — Phase 1b |
| Forgejo | Helios | http://192.168.0.11:3000 | 3000 | Self-hosted Git |
| SSH | Helios | 192.168.0.11 | 22 | Key auth only |
| Jellyfin | Helios | http://192.168.0.11:`[port TBC]` | `[TBC]` | Media server — confirm port |
| Samba / NAS | Helios | \\\\192.168.0.11\\`[share]` | 445 | Network file storage |
| code-server | Helios | http://192.168.0.11:`[port TBC]` | `[TBC]` | Browser-based VS Code — confirm port |
| Omada Controller | OC200 | https://`[OC200 flat IP]`:8043 | 8043 | Network management — confirm current flat IP |

---

## 8. Change Log

> Record every change — no matter how small.
> **A change without a log entry is a change that cannot be safely undone.**

| Date | Time | Device | Section | What Changed | Previous Value | New Value | Tested OK | Reason |
|------|------|--------|---------|--------------|----------------|-----------|-----------|--------|
| 03/04/26 | — | All | Doc created | Flat network register created | No flat-specific register | This document | N/A | Tracking current state during pre-VLAN phase |
| 03/04/26 | 8:20 am | ALL | Doc updated | `[Description]` | No flat-specific register | ip/mac updates to register | N/A | Updateing mac & ip to the flat network register|
| `[Date]` | `[Time]` | `[Device]` | `[Section]` | `[Description]` | `[Old value]` | `[New value]` | `[Y/N]` | `[Reason]` |


---

## Flat-to-VLAN Migration Reference

> When the Phase 1 maintenance window runs, these are the IPs that change.
> Cross-reference with `maintenance-window-updated.md` for the full procedure.

| Device | Current Flat IP | Post-Window IP | VLAN |
|--------|----------------|----------------|------|
| hestia (RPi 5 — Phase 1) | 192.168.0.153 | 192.168.10.15 | HOME 10 |
| hestia (RPi 5 — Phase 2+) | 192.168.0.153 | 192.168.99.5 | MGMT 99 |
| Alival (Admin PC) | `[TBC]` | 192.168.10.10 | HOME 10 |
| MacBook Pro Admin | `[TBC]` | 192.168.10.11 | HOME 10 |
| Xavier PC | `[TBC]` | 192.168.10.12 | HOME 10 |
| OC200 | `[TBC]` | 192.168.99.2 | MGMT 99 |
| TL-SG2008P | `[TBC]` | 192.168.99.10 | MGMT 99 |
| Helios | 192.168.0.11 | 192.168.20.11 | LAB 20 |
| Genesis2 (Proxmox) | 192.168.0.20 | 192.168.20.10 | LAB 20 |
| Philips Hue Bridge | `[TBC]` | 192.168.30.5 | IOT 30 |
| Vizio TV | `[TBC]` | DHCP pool | HOME 10 |
| PS5 | `[TBC]` | DHCP pool | HOME 10 |

---

*This document is temporary. It is retired when Phase 1 VLAN migration is complete.*
*Companion files: `network_settings_register_populated.md` | `maintenance-window-updated.md`*
*Created: 2026/04/03 — v1.0*
