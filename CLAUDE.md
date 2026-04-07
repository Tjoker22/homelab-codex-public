# CLAUDE.md — JXStudios Home Lab
> This file is the primary context document for Claude Code working on the JXStudios home lab project.
> Read this file completely before taking any action on any task.
> The architect for this project is Claude (claude.ai conversation). Claude Code is the engineer.
> When in doubt about design decisions, refer to the architecture documents before acting.

---

## Current State — 06/04/2026

**Active work:** helios (Project Helios) — OS and ZFS pool complete. Service installs (Forgejo, Samba, Jellyfin, code-server) are next. Genesis2 Proxmox install (Phase 1b) in progress at 192.168.0.152.

**New devices since last CLAUDE.md review:**
- **eos** — HP Pavilion (i5-9400, 12 GB DDR4), Proxmox VE 9.x installed, ZFS `eospool` created. Flat IP: 192.168.0.154. Final LAB VLAN IP and role split with genesis2 **pending architect decision** (see flags below).
- **hestia** — Raspberry Pi 5 8GB, hostname `hestia`. Pi-hole and Tailscale confirmed active on flat network at 192.168.0.153. Final MGMT VLAN IP: 192.168.99.5 (unchanged).
- **thoth** — HP Laptop (i5-7200U), rebuilt as Debian 13 Trixie + i3 desktop (was Fedora admin laptop).

**Network:** Flat 192.168.0.0/24. Phase 1 maintenance window deferred — admin device setup incomplete. All Omada VLAN/DHCP/ACL config is staged and intact. No network changes needed until the window is rescheduled.

**CCNA study:** In progress. Phase 2 (3750G) work directly covers CCNA switching content — VLANs, SVIs, trunking, inter-VLAN routing, ACLs.

**⚠️ Architect decisions needed:**
1. **Eos role and final IP** — Eos (192.168.0.154) is running Proxmox and has a build guide assigning LXC services (NPM, Prometheus, Grafana, Loki, Homepage, jxstudios.dev) using the same VMIDs and .20.x IPs originally planned for Genesis2. Does Eos take the always-on services role? What is its final LAB VLAN IP (e.g., 192.168.20.x)?
2. **VMID conflict** — VMIDs 220, 221, 222, 250, 261, 262 are assigned in both the genesis2 plan and the eos build guide. Need a clear split before any LXCs are created.
3. **thoth hostname in admin environment** — HP Laptop is now `thoth` running Debian 13. Should it remain an admin console or is it a separate lab device?

---

## Architect / Engineer Split

This project uses two Claude instances with distinct roles:

```
Architect — claude.ai conversation:
  → Makes all architecture and design decisions
  → Changes VLAN design, IP addressing, ACL policy
  → Plans new phases and defines scope
  → Updates CLAUDE.md with new context and decisions
  → Troubleshoots design-level problems

Engineer — Claude Code (this instance):
  → Implements what the architect specifies
  → Writes and runs scripts, playbooks, config files
  → Keeps documentation accurate and up to date
  → Manages git commits and repo structure
  → Asks questions rather than guessing on design decisions
```

If a task requires a design decision not covered in this file or the architecture docs — stop, state the question clearly, describe the options, and wait for direction. Do not guess or assume.

---

## Architecture Overview

### Network Hardware Stack

| Device | Model | Role | Mgmt IP |
|--------|-------|------|---------|
| WAN Gateway | TP-Link ER605 v2 | ACL enforcement, VLAN routing, DHCP | 192.168.10.1 |
| Managed Switch | TP-Link TL-SG2008P | PoE switch | 192.168.99.10 |
| Controller | TP-Link OC200 | Omada controller | 192.168.99.2 |
| WAP | TP-Link EAP653 (US) | Wireless access point | 192.168.99.x |
| hestia | Raspberry Pi 5 8GB | Pi-hole primary, Tailscale primary, MGMT device | 192.168.0.153 (temp) → 192.168.99.5 |
| helios | OR PC — Debian 13 Trixie (Sandy Bridge i3-2120) | Forgejo, NAS, Jellyfin, code-server | 192.168.0.151 (temp) → 192.168.20.11 |
| eos | HP Pavilion — Proxmox VE 9.x (i5-9400) | Proxmox hypervisor — role TBD (architect) | 192.168.0.154 (temp) → TBD |
| L3 Core Switch | Cisco Catalyst 3750G | Inter-VLAN routing (Phase 2) | 192.168.99.3 |
| L2 Access Switch | Cisco Catalyst 2960G | Lab access layer (Phase 3) | 192.168.99.4 |
| Hypervisor | Proxmox — genesis2 | VM and LXC host | 192.168.0.152 (temp) → 192.168.20.10 (Phase 2) |
| Reverse Proxy | Nginx Proxy Manager | Service proxy LXC (Phase 2) | 192.168.20.50 |
| Remote Access | Tailscale LXC | Subnet router co-advertiser (Phase 2) | 192.168.20.51 |

### Genesis2 Hardware

| Component | Spec |
|-----------|------|
| Hostname | genesis2 |
| Chassis | NZXT |
| CPU | AMD Ryzen 7 5700X @ 3.4 GHz (8c/16t) |
| GPU | NVIDIA MSI GeForce RTX 2060 6GB — passthrough Phase 6 |
| RAM | 64 GB DDR4-3600 MHz (expandable to 128 GB) |
| Boot Drive | 256 GB 2.5" SSD — Proxmox OS and ISO storage |
| Data Drives | 3× 500 GB 2.5" HDD — RAIDZ1 pool (1 TB usable) |
| Current IP | 192.168.0.152 — flat network temporary |
| Final IP | 192.168.20.10 — VLAN 20 LAB |

### Eos Hardware

| Component | Spec |
|-----------|------|
| Hostname | eos |
| Chassis | HP Pavilion desktop |
| CPU | Intel Core i5-9400 (6c/6t) — Coffee Lake |
| RAM | 12 GB DDR4 |
| Boot Drive | 256 GB NVMe — Proxmox OS |
| Data Drive | 1 TB SATA HDD — ZFS `eospool` (single, no redundancy — Phase 2 adds mirror) |
| Current IP | 192.168.0.154 — flat network temporary |
| Final IP | TBD — pending architect decision |

### VLAN Scheme

| VLAN | Name | Subnet | Gateway | Purpose |
|------|------|--------|---------|---------|
| 10 | HOME | 192.168.10.0/24 | 192.168.10.1 | Home devices, personal PCs, Pi-hole Phase 1 |
| 20 | LAB | 192.168.20.0/24 | 192.168.20.1 | Servers, VMs, infrastructure |
| 30 | IOT | 192.168.30.0/24 | 192.168.30.1 | Smart home — fully isolated |
| 99 | MGMT | 192.168.99.0/24 | 192.168.99.1 | Network management only |

### Security Model
- Home devices reach lab services only via Nginx Proxy Manager (192.168.20.50)
- IoT is fully isolated — no cross-VLAN access in any direction
- Admin-only ACLs gate direct management access to Proxmox and SSH
- Proxmox (192.168.20.10) is never a reverse proxy target — no exceptions

---

## Two-Tier Access Rule

```
Tier 1 — Services (home devices):
  HOME VLAN → Nginx Proxy Manager 192.168.20.50 :80/:443 ONLY
  Never bypass the proxy for service access from home devices

Tier 2 — Management (admin devices only):
  192.168.10.10 (Admin PC)     → Proxmox :8006 direct — ACL permit
  192.168.10.11 (Admin Laptop) → Proxmox :8006 direct — ACL permit
  Same two IPs only for SSH direct access to lab

  ★  Proxmox is NEVER added as a proxy target — ever
```

---

## IP and MAC Register

### Network Devices

| Device | IP | VLAN | MAC |
|--------|-----|------|-----|
| ER605 — WAN Gateway | 192.168.10.1 | 10 | [MAC_REDACTED] |
| OC200 — Omada Controller | 192.168.99.2 | 99 | [MAC_REDACTED] |
| TL-SG2008P — Switch | 192.168.99.10 | 99 | [MAC_REDACTED] |
| EAP653 — WAP | 192.168.99.x | 99 | [MAC_REDACTED] |
| hestia — Raspberry Pi 5 MGMT/DNS | 192.168.0.153 (temp) → 192.168.99.5 | 99 | [MAC_REDACTED] |
| Admin PC | 192.168.10.10 | 10 | [MAC_REDACTED] |
| Admin Laptop | 192.168.10.11 | 10 | [MAC_REDACTED] |
| Partner PC | 192.168.10.12 | 10 | [MAC_REDACTED] |
| helios | 192.168.0.151 (temp) → 192.168.20.11 | 20 | [MAC_REDACTED] |
| eos | 192.168.0.154 (temp) → TBD | 20 | [MAC_REDACTED] |
| genesis2 | 192.168.0.152 (temp) → 192.168.20.10 | 20 | `[MAC — record after install]` |
| Philips Hue Bridge | 192.168.30.5 | 30 | [MAC_REDACTED] |

### Genesis2 VM and LXC Register — LAB VLAN 192.168.20.0/24

> Full register with zone rationale: `docs/builds/genesis-build-guide.md`
> During flat network phase: containers use temporary IPs on 192.168.0.0/24. Final IPs are in the .20.x range and should be used in all service configs.
> ⚠️ VMID assignments for genesis2 vs eos are pending architect clarification — do not create LXCs until resolved.

| VMID | IP | Hostname | Type | Role | Phase |
|------|-----|----------|------|------|-------|
| — | .10 | genesis2 | Physical | Proxmox host | 1b |
| 220 | .20 | prometheus | LXC | Prometheus + pve_exporter + Node Exporter | 1b |
| 221 | .21 | grafana | LXC | Grafana dashboards | 1b |
| 222 | .22 | loki | LXC | Loki log aggregation | 1b |
| 230 | .30 | pihole2 | LXC | Pi-hole secondary DNS | 2 |
| 240 | — | forgejo | RETIRED | Moved to helios (native) | — |
| 250 | .50 | npm | LXC | Nginx Proxy Manager | 2 |
| 251 | .51 | tailscale | LXC | Tailscale subnet router | 2 |
| 360 | .60 | nextcloud | VM | Nextcloud — multi-user | 4 |
| 261 | .61 | homepage | LXC | Homepage dashboard | 4 |
| 262 | .62 | jxstudios | LXC | jxstudios.dev website | 5 |
| 380 | .80 | ollama | VM | Ollama + Open WebUI — GPU passthrough | 6 |

### VMID Convention

| Hundreds Digit | Type |
|---|---|
| 2xx | LXC container |
| 3xx | Virtual Machine (VM) |

Last two digits mirror the IP last octet. Example: VMID 251 = LXC at 192.168.20.51.
Scratch containers (IPs .90–.99) use VMIDs 290–299 (LXC) or 390–399 (VM).
Never reuse a VMID after a container is deleted — retire it.

---

## Phase Status

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Omada ISP rack — port migrations, OC200 cutover | ⏸️ Deferred — admin device setup pending |
| 1b | Genesis2 — Proxmox install, ZFS pool, observability stack | 🔄 In progress — Proxmox install at 192.168.0.152 |
| 1c | helios — Forgejo + Samba + Jellyfin + code-server | 🔄 Active — OS and ZFS complete, services not yet started |
| 2 | Cisco Catalyst 3750G — L3 core switch | 🔲 Not started |
| 3 | Cisco Catalyst 2960G — L2 access switch (optional) | 🔲 Not started |
| 4 | Nextcloud, Homepage dashboard | 🔲 Not started |
| 5 | jxstudios.dev website | 🔲 Not started |
| 6 | Ollama + Open WebUI — GPU passthrough | 🔲 Not started |
| 7 | Cisco 1921 edge routers (optional) | 🔲 Not started |

> Note: NPM and Tailscale (previously labelled Phase 5/6) are Phase 2 — they are infrastructure services, not applications.

---

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | This file — primary context for Claude Code |
| `docs/plans/project-summary.md` | Current project state, remaining steps, phase checklists |
| `docs/builds/genesis-build-guide.md` | Genesis2 server planning — hardware, storage, VM register, service stack |
| `docs/builds/helios-build-guide.md` | Helios build procedure — Debian 13 Trixie, ZFS, service installs |
| `docs/builds/eos-build-guide.md` | Eos build procedure — Proxmox VE 9.x, ZFS eospool, LXC stack |
| `docs/builds/hestia-build-guide.md` | Hestia (Pi 5) build procedure — Pi-hole, Tailscale, flat network setup |
| `docs/builds/thoth-build-guide.md` | Thoth (HP Laptop) build procedure — Debian 13 Trixie + i3 desktop |
| `docs/plans/helios-plan.md` | Helios planning document — hardware, services, decisions |
| `docs/network/device-specs.md` | Hardware specifications for all lab devices |
| `docs/plans/maintenance-window.md` | Phase 1 window procedure — Discovery Utility, Auto Refresh IP, all OS coverage |
| `docs/notes/project-helios-build.md` | Live helios build session notes |
| `docs/notes/project-hestia-build.md` | Live hestia build session notes |
| `docs/notes/project-eos-build.md` | Live eos build session notes |
| `network/network-design-populated.md` | Primary network architecture document |
| `network/network-settings-populated.md` | Live IP/MAC/DHCP register — authoritative source of truth |
| `network/flat-network-settings-register.md` | Current flat network living register — active device and service IPs |
| `network/network-inventory.csv` | Switch port assignment history |
| `network/network-map.drawio` | Network diagram source |
| `docs/network/network-setup-guide.md` | Phase 1 ER605 configuration guide |
| `scripts/host-setup.md` | Proxmox post-install configuration guide (template — not yet filled) |
| `configs/` | TP-Link Omada controller backups and Cisco IOS running configs |
| `docs/templates/universal-prox-instance-template.md` | Template for documenting new VMs and LXCs |

---

## Known Issues — Network Window

Before the Phase 1 window can be rescheduled, these must be resolved:

**1. Admin laptop setup**
Three admin laptops: Windows, Mac (MacBook Pro 2015), and thoth (HP Laptop, now Debian 13). Must be fully configured and confirmed able to reach the Omada dashboard before the window runs. MacBook Pro requires Discovery Utility and Java 17 FX (Zulu) installed before window day.

**2. Discovery Utility — empty device table on Windows**
The utility launches but shows no devices. Root cause: Windows Firewall blocking Java UDP broadcasts on ports 29810–29814.
Fix:
- Run start-discovery-utility-windows.bat as Administrator
- Add `C:\Program Files\Java\jdk-17\bin\javaw.exe` to Windows Firewall allowed apps (Private + Public)
- If ER605 still doesn't appear: use Batch Setting by IP (192.168.10.1) directly — bypasses broadcast discovery

**3. OC200 reservation and Auto Refresh IP**
Before the window: verify the OC200 DHCP reservation has Network field set to MGMT VLAN 99 (not default LAN). Enable Auto Refresh IP on OC200 (Devices → OC200 → Config → Services).

Full corrected procedure: `docs/plans/maintenance-window.md`

**4. hestia — known issues from build**
- Pi-hole blocking ads via Wi-Fi but not fully via wired ethernet — under investigation
- sysctl.d config for Tailscale subnet advertising used `/etc/sysctl.conf` rather than `sysctl.d` — cleanup pending

---

## Conventions

- **Network settings register** is the authoritative source for IP addresses, MACs, and DHCP reservations. Update it whenever any device is added or changed. For flat network current state, also update `network/flat-network-settings-register.md`.
- **VM/LXC register** for Genesis2 is maintained in both this file (summary table) and `docs/builds/genesis-build-guide.md` (full detail).
- **VMID convention:** 2xx = LXC, 3xx = VM. Last two digits mirror IP last octet. Enforced from first container — no exceptions.
- **Omada backups** use format `omada_backup_<version>_<date>_<description>.cfg`. Always add new file — never overwrite.
- **Cisco configs** stored as plain text in `configs/cisco/`.
- **Site name:** `JXStudios` — **Domain:** `jxstudios.dev` — **Proxmox host:** `192.168.20.10`
- **Flat network temporary IPs:** genesis2 at 192.168.0.152, helios at 192.168.0.151, hestia at 192.168.0.153, eos at 192.168.0.154. Never hardcode these into service configs.

---

## What Claude Code Should Do

- Keep `network/network-settings-populated.md` and `network/flat-network-settings-register.md` accurate after any network change
- Keep `docs/builds/genesis-build-guide.md` accurate after any Genesis2 service change
- Update phase checklists in `docs/plans/project-summary.md` as tasks complete
- Add change log entries to the register when network changes are made
- Write utility scripts for network tasks — ping sweeps, connectivity tests, lease checks
- Write Proxmox setup scripts for VMs and LXCs
- Write service deployment scripts and compose files
- Store all Cisco IOS running configs in `configs/cisco/` as plain text
- Never commit secrets, passwords, or API keys — use `.env` files in `.gitignore`
- Cover Windows, macOS, and Linux in all scripts and procedures

## What Claude Code Should NOT Do

```
✘  Change network architecture decisions — refer to architect
✘  Modify VLAN numbering, IP addressing, or ACL policy
✘  Change VMID convention or VM/LXC IP assignments
✘  Create Proxmox VMs or LXCs outside the defined IP ranges
✘  Add Proxmox to the reverse proxy — ever
✘  Skip phases or implement ahead of the current phase
✘  Commit .env files, passwords, or credentials
✘  Run destructive commands without explicit confirmation
✘  Modify CLAUDE.md without explicit instruction
✘  Guess on design decisions — ask instead
✘  Hardcode flat network temporary IPs into service configs
✘  Create LXCs on eos or genesis2 until VMID conflict is resolved by architect
```

---

## Coding Standards

### Shell Scripts (Bash)
```bash
#!/bin/bash
# Script: script-name.sh
# Purpose: [what it does]
# Usage: ./script-name.sh [args]
# Phase: [phase number]
# Last updated: [date]

set -euo pipefail
```

### Python Scripts
```python
#!/usr/bin/env python3
"""
Script: script-name.py
Purpose: [what it does]
Usage: python3 script-name.py [args]
Phase: [phase number]
"""
```

- All scripts must be idempotent where possible — safe to run more than once
- Use meaningful variable names — no single letter variables except loop counters
- Validate inputs before acting on them
- Exit with non-zero codes on failure

---

## Git Commit Message Format

```
[Phase X] Action — description — reason

Examples:
[Phase 1b] Add — Proxmox baseline install — genesis2 initial setup
[Phase 1b] Add — ZFS RAIDZ1 pool creation — genesis2 post-install
[Phase 1b] Add — Prometheus LXC deploy — observability stack Phase 1b
[Docs] Update — project summary — network window deferred, genesis2 on flat network
[Config] Add — 3750G initial running config — Phase 2 baseline
```

---

## Environment

### Admin PC (Primary Workstation)
- OS: Windows 11 / Fedora dual boot — Fedora repurposed, Windows currently primary
- IDE: VSCode
- Git: Active — connected to GitHub

### Admin Laptop — Windows
- OS: Windows
- Role: Admin console, backup during maintenance windows, Discovery Utility host

### Admin Laptop — MacBook Pro 2015
- OS: macOS
- Role: Admin console, backup during maintenance windows, Discovery Utility host

### thoth — HP Laptop
- OS: Debian 13 Trixie + i3 window manager (was Fedora)
- Hostname: `thoth`
- Role: Admin console / development machine — architect to confirm if this changes admin console designation
- Package manager: apt

### Omarchy Machine
- OS: Omarchy (Arch Linux + Hyprland) — available
- Package manager: pacman (not dnf or apt)
- Java install: `sudo pacman -S jdk17-openjdk`
- Discovery Utility: `./start-discovery-utility-linux.sh` (add `_JAVA_AWT_WM_NONREPARENTING=1` prefix if GUI renders blank under Wayland)

---

## Section Ownership

Claude Code may freely update these sections as the repo evolves:
- Key Files table — add new files as they are created
- Phase Status — mark phases complete, do not add new phases
- IP and MAC Register — add MACs when devices come online
- VM/LXC Register — update status as containers are created
- Known Issues — update as issues are resolved

Claude Code must not modify these sections without explicit architect instruction:
- Two-Tier Access Rule
- VLAN Scheme and subnets
- VMID Convention
- What Claude Code Should NOT Do
- Architecture Overview hardware roles

---

## Documentation Update Protocol

After any network change, task completion, or phase milestone:

```
1. Update network/network-settings-populated.md
   → Add change log entry
   → Update relevant section

1a. Update network/flat-network-settings-register.md
   → Update device or service entry
   → Note any new IPs or services

2. Update docs/builds/genesis-build-guide.md (if Genesis2 change)
   → Update VM/LXC register
   → Update service stack status

3. Update docs/plans/project-summary.md
   → Mark completed checklist items
   → Note any new issues or decisions

4. Commit together:
   git add [changed files]
   git commit -m "[Docs] Update — [what changed]"
   git push
```

---

## Recovery Reference

If the Omada controller becomes unreachable, connect patch cable to OC200 ETH2 (not ETH1):

*Windows:*
```
Settings → Network & Internet → ethernet → IP assignment → Edit → Manual
IP: 192.168.99.10  Subnet: 24  Gateway: 192.168.99.2
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

*Linux (including thoth / Omarchy):*
```bash
sudo ip addr add 192.168.99.10/24 dev [interface]
sudo ip route add default via 192.168.99.2
# Browser → https://192.168.99.2:8043
# When done:
sudo ip addr del 192.168.99.10/24 dev [interface]
```

Config backups location: `configs/`
Last known good backup: taken after VLANs, DHCP, reservations, ACL rules, IP Groups — pre-port-profile baseline.

---

*CLAUDE.md version: 5.0 — 06/04/2026 — Full sync after directory reorganization and three build sessions (helios, hestia, eos). All Key File paths updated. Eos and hestia added. helios MAC confirmed, OS updated to Debian 13 Trixie, ZFS complete. genesis2 flat IP corrected to 192.168.0.152. thoth hostname added. Architect decisions flagged for eos role/IP and VMID conflict.*
*Previous version: 4.1 — 23/03/2026 — mac-server replaced by helios. Admin laptops updated.*
*Next review: After architect resolves eos role and VMID assignments*
