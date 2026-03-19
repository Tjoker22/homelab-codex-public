# CLAUDE.md — JXStudios Home Lab
> This file is the primary context document for Claude Code working on the JXStudios home lab project.
> Read this file completely before taking any action on any task.
> The architect for this project is Claude (claude.ai conversation). Claude Code is the engineer.
> When in doubt about design decisions, refer to the architecture documents before acting.

---

## Repository Purpose

This is a **documentation-first** home lab repository. Current content is Markdown documentation, network configuration files, and network diagrams tracking the design and phased deployment of a Proxmox-based home lab. Scripts, playbooks, and automation will be added as each phase goes live.

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
| DNS / MGMT | Raspberry Pi 5 8GB | Pi-hole primary, Tailscale primary, MGMT device | 192.168.99.5 |
| L3 Core Switch | Cisco Catalyst 3750G | Inter-VLAN routing (Phase 2) | 192.168.99.3 |
| L2 Access Switch | Cisco Catalyst 2960G | Lab access layer (Phase 3) | 192.168.99.4 |
| Hypervisor | Proxmox — genesis2 | VM and LXC host (Phase 1) | 192.168.20.10 |
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
| Final IP | 192.168.20.10 — VLAN 20 LAB |

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
| Raspberry Pi 5 — MGMT/DNS | 192.168.99.5 | 99 | [MAC_REDACTED] |
| Admin PC | 192.168.10.10 | 10 | [MAC_REDACTED] |
| Admin Laptop | 192.168.10.11 | 10 | [MAC_REDACTED] |
| Partner PC | 192.168.10.12 | 10 | `[MAC pending]` |
| Philips Hue Bridge | 192.168.30.5 | 30 | [MAC_REDACTED] |

### Genesis2 VM and LXC Register — LAB VLAN 192.168.20.0/24

> Full register with zone rationale: `docs/genesis2-project-genesis-plan.md`

| VMID | IP | Hostname | Type | Role | Phase |
|------|-----|----------|------|------|-------|
| — | .10 | genesis2 | Physical | Proxmox host | 1 |
| 220 | .20 | prometheus | LXC | Prometheus + pve_exporter + Node Exporter | 1 |
| 221 | .21 | grafana | LXC | Grafana dashboards | 1 |
| 222 | .22 | loki | LXC | Loki log aggregation | 1 |
| 230 | .30 | pihole2 | LXC | Pi-hole secondary DNS | 2 |
| 240 | .40 | forgejo | LXC | Forgejo internal Git | 3 |
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
| 1 | Omada ISP rack — VLANs, DHCP, ACL, Pi-hole DNS | ✳️ In progress — maintenance window Monday |
| 1b | Genesis2 — Proxmox install, ZFS pool, observability stack | 🔲 Planning complete — install session pending |
| 2 | Cisco Catalyst 3750G — L3 core switch | 🔲 Not started |
| 3 | Cisco Catalyst 2960G — L2 access switch (optional) | 🔲 Not started |
| 4 | Nextcloud, Homepage dashboard | 🔲 Not started |
| 5 | jxstudios.dev website | 🔲 Not started |
| 6 | Ollama + Open WebUI — GPU passthrough | 🔲 Not started |
| 7 | Cisco 1921 edge routers (optional) | 🔲 Not started |

> Note: NPM and Tailscale (previously labelled Phase 5/6) are now Phase 2 — they are infrastructure services, not applications.

---

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | This file — primary context for Claude Code |
| `docs/project-summary-and-remaining-steps.md` | Current project state, remaining steps, maintenance window checklist |
| `docs/genesis2-project-genesis-plan.md` | Genesis2 server planning — hardware, storage, VM register, service stack |
| `network/network_design_document_populated.md` | Primary network architecture document |
| `network/network_settings_register_populated.md` | Live IP/MAC/DHCP register — authoritative source of truth |
| `network/network_inventory.csv` | Switch port assignment history |
| `network/network_map_3_1_26.drawio` | Network diagram source |
| `docs/network_setup_quick_guide.md` | Phase 1 ER605 configuration guide |
| `host_setup.md` | Proxmox post-install configuration guide — to be updated for Genesis2 |
| `configs/` | TP-Link Omada controller backups and Cisco IOS running configs |
| `vms/universal_prox_instance_template.md` | Template for documenting new VMs and LXCs |

---

## Conventions

- **Network settings register** is the authoritative source for IP addresses, MACs, and DHCP reservations. Update it whenever any device is added or changed.
- **VM/LXC register** for Genesis2 is maintained in both this file (summary table) and `docs/genesis2-project-genesis-plan.md` (full detail).
- **VMID convention:** 2xx = LXC, 3xx = VM. Last two digits mirror IP last octet. Enforced from first container — no exceptions.
- **Omada backups** use format `omada_backup_<version>_<date>_<description>.cfg`. Always add new file — never overwrite.
- **Cisco configs** stored as plain text in `configs/cisco/`.
- **Site name:** `JXStudios` — **Domain:** `jxstudios.dev` — **Proxmox host:** `192.168.20.10`

---

## What Claude Code Should Do

- Keep `network_settings_register_populated.md` accurate after any network change
- Keep `genesis2-project-genesis-plan.md` accurate after any Genesis2 service change
- Update phase checklists in `project-summary-and-remaining-steps.md` as tasks complete
- Add change log entries to the register when network changes are made
- Write utility scripts for network tasks — ping sweeps, connectivity tests, lease checks
- Write Proxmox setup scripts for VMs and LXCs
- Write service deployment scripts and compose files
- Store all Cisco IOS running configs in `configs/cisco/` as plain text
- Never commit secrets, passwords, or API keys — use `.env` files in `.gitignore`

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
[Phase 1] Add — network ping sweep script — verify device connectivity post-cutover
[Phase 1b] Add — ZFS pool creation procedure — Genesis2 post-install
[Phase 4] Update — Proxmox LXC deploy script — add VLAN tag parameter
[Docs] Update — settings register — post-window Phase 1 completion
[Config] Add — 3750G initial running config — Phase 2 baseline
```

---

## Environment

### Admin PC (Primary Workstation)
- OS: Windows 11 / Fedora dual boot — **Fedora is primary for Claude Code**
- IDE: VSCode (primary) — WSL available on Windows side
- Claude Code: Installed — proxmox-homelab directory open
- Git: Active — connected to GitHub
- Why Fedora: native bash, SSH, Python, nmcli — same environment as lab servers

### Admin Laptop
- OS: Fedora — Claude Code setup pending
- Role: Backup admin console during maintenance windows

### Admin Laptop 2
- OS: macOS — Claude Code setup pending

---

## Section Ownership

Claude Code may freely update these sections as the repo evolves:
- Key Files table — add new files as they are created
- Phase Status — mark phases complete, do not add new phases
- IP and MAC Register — add MACs when devices come online
- VM/LXC Register — update status as containers are created

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
1. Update network_settings_register_populated.md
   → Add change log entry
   → Update relevant section

2. Update genesis2-project-genesis-plan.md (if Genesis2 change)
   → Update VM/LXC register
   → Update service stack status

3. Update project-summary-and-remaining-steps.md
   → Mark completed checklist items
   → Note any new issues or decisions

4. Commit together:
   git add [changed files]
   git commit -m "[Docs] Update — [what changed]"
   git push
```

---

## Recovery Reference

If the Omada controller becomes unreachable:

```bash
# Connect patch cable: Laptop ETH → OC200 ETH2 (not ETH1)
sudo nmcli con add type ethernet \
  ifname [iface] \
  con-name direct-oc200 \
  ip4 192.168.99.10/24 \
  gw4 192.168.99.2
sudo nmcli con up direct-oc200
ping 192.168.99.2
# Access https://192.168.99.2:8043

# Cleanup after recovery
sudo nmcli con delete direct-oc200
```

Config backups location: `configs/`  
Last known good backup: taken after VLANs, DHCP, reservations, ACL rules, IP Groups — pre-port-profile baseline.

---

*CLAUDE.md version: 3.0 — 18/03/2026 — Added Genesis2 hardware, VM register, VMID convention, MGMT Pi role*  
*Next review: After Phase 1 maintenance window complete and Genesis2 Proxmox install session*
