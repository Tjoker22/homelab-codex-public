# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **documentation-only** home lab repository — there are no build systems, tests, or deployable code. All content is Markdown documentation, network configuration files, and network diagrams tracking the design and phased deployment of a Proxmox-based home lab.

## Architecture Overview

The repository documents a four-VLAN segmented home network with a phased deployment plan:

**Hardware Stack:**
- WAN Gateway: TP-Link ER605 v2 (ACL enforcement, VLAN routing, DHCP)
- Managed Switch: TP-Link TL-SG2008P + Omada OC200 controller
- L3 Core Switch: Cisco Catalyst 3750G (Phase 2)
- Hypervisor: Proxmox (Phase 4)
- DNS: Raspberry Pi running Pi-hole

**VLAN Scheme:**
| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 10 | HOME | 192.168.10.0/24 | Home devices, personal PCs |
| 20 | LAB | 192.168.20.0/24 | Servers, VMs, infrastructure |
| 30 | IOT | 192.168.30.0/24 | Smart home (fully isolated) |
| 99 | MGMT | 192.168.99.0/24 | Network management only |

**Security Model:** Home devices reach lab services only via Nginx Proxy Manager (192.168.20.50). IoT is fully isolated. Admin-only ACLs gate direct management access.

**Phased Deployment:**
1. Phase 1 (In Progress): Omada ISP rack — VLANs, DHCP, ACL, Pi-hole DNS
2. Phase 2: Cisco 3750G L3 core switch
3. Phase 3: Cisco 2960G L2 access switch (optional)
4. Phase 4: Proxmox hypervisor
5. Phase 5: Nginx Proxy Manager reverse proxy
6. Phase 6: Tailscale subnet router
7. Phase 7: Cisco 1921 edge routers (optional)

## Key Files

| File | Purpose |
|------|---------|
| `network/network_design_document_populated.md` | Primary architecture document — design decisions, ACL rules, config procedures |
| `network/network_settings_register_populated.md` | Live IP/MAC/DHCP register — source of truth for current assignments |
| `network/network_inventory.csv` | Switch port assignment history |
| `network/network_map_3_1_26.drawio` | Network diagram source (edit with draw.io) |
| `docs/network_setup_quick_guide.md` | Step-by-step Phase 1 ER605 configuration |
| `docs/network_setup_quick_guide_part_2` | Phase 1 continued (Omada switch, Pi-hole) |
| `host_setup.md` | Proxmox post-install configuration guide |
| `configs/` | TP-Link Omada controller backup `.cfg` files |
| `vms/universal_prox_instance_template.md` | Template for documenting new VMs/LXCs |

## Conventions

- **Network settings register** (`network_settings_register_populated.md`) is the authoritative source for IP addresses, MAC addresses, and DHCP reservations. Update it when adding or changing any device.
- **Omada backups** in `configs/` are named with the format `omada_backup_<version>_<date>_<description>.cfg`. Add a new backup file rather than overwriting existing ones.
- VM/LXC instances are documented using the template in `vms/universal_prox_instance_template.md`.
- Domain: `jxstudios.dev`; Proxmox host: `192.168.20.10`; Nginx Proxy Manager: `192.168.20.50`.
