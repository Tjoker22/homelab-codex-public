# Project Genesis — Genesis2 Server Planning Document
**Site:** JXStudios  
**Server Hostname:** `genesis2`  
**Document Version:** 1.0  
**Created:** 18/03/2026  
**Last Updated:** 18/03/2026  
**Status:** Planning complete — pending Proxmox installation session  
**Companion Files:** `CLAUDE.md` | `project-summary-and-remaining-steps.md` | `network_settings_register_populated.md`

---

## Table of Contents

1. [Hardware Specification](#1-hardware-specification)
2. [Storage Architecture](#2-storage-architecture)
3. [Network Placement](#3-network-placement)
4. [VM and LXC Register — LAB VLAN](#4-vm-and-lxc-register--lab-vlan)
5. [VMID Convention](#5-vmid-convention)
6. [Service Stack — By Phase](#6-service-stack--by-phase)
7. [MGMT Pi Architecture](#7-mgmt-pi-architecture)
8. [Pi-hole Primary / Secondary Architecture](#8-pi-hole-primary--secondary-architecture)
9. [Tailscale Architecture](#9-tailscale-architecture)
10. [Decisions Log](#10-decisions-log)
11. [Pending Items](#11-pending-items)

---

## 1. Hardware Specification

| Component | Spec | Notes |
|-----------|------|-------|
| Chassis | NZXT | — |
| CPU | AMD Ryzen 7 5700X @ 3.4 GHz | 8 cores / 16 threads |
| GPU | NVIDIA MSI GeForce RTX 2060 6GB VRAM | GPU passthrough planned — Phase 6 (Ollama) |
| RAM | 64 GB DDR4-3600 MHz | Expandable to 128 GB |
| Boot Drive | 1× 256 GB 2.5" SSD | Proxmox OS and ISO storage |
| Data Drives | 3× 500 GB 2.5" HDD | RAIDZ1 pool — 1 TB usable |

---

## 2. Storage Architecture

### 2.1 — Boot Drive

The 256 GB SSD is dedicated to the Proxmox OS installation and ISO/template storage. It is not part of any ZFS pool. During Proxmox installation, the installer will manage this drive directly.

Recommended Proxmox installer storage selection:
- **Filesystem:** ext4 (Proxmox default) — sufficient for the boot volume
- **ZFS on root is not required** — ZFS benefits are applied to the data pool below

### 2.2 — Data Pool (RAIDZ1)

The three 500 GB HDDs are configured as a RAIDZ1 pool post-install. This is **not done by the Proxmox installer** — it is configured after first boot via the web UI or shell.

| Parameter | Value |
|-----------|-------|
| Pool type | RAIDZ1 |
| Drives | 3× 500 GB HDD |
| Usable capacity | ~1 TB |
| Fault tolerance | 1 drive failure |
| ZFS features | Checksumming, self-healing, snapshotting |

**Why RAIDZ1 over independent disks:**
- Single disk failure is survivable without data loss
- ZFS checksumming detects and corrects silent data corruption
- Snapshotting enables VM-level backups and rollbacks
- Industry-relevant skill — used on TrueNAS, enterprise NAS, and production Proxmox environments
- The 500 GB capacity cost is justified by operational discipline and skill development

**Post-install ZFS pool creation (shell):**
```bash
# Identify drive IDs — always use /dev/disk/by-id/ paths, not /dev/sdX
ls /dev/disk/by-id/

# Create RAIDZ1 pool — replace with actual drive IDs
zpool create -f \
  -o ashift=12 \
  datapool raidz1 \
  /dev/disk/by-id/[disk1-id] \
  /dev/disk/by-id/[disk2-id] \
  /dev/disk/by-id/[disk3-id]

# Verify
zpool status datapool
zpool list
```

> ⚠️ Always use `/dev/disk/by-id/` paths — `/dev/sdX` identifiers are not stable across reboots and can cause the pool to fail to import.

**Add pool to Proxmox web UI after creation:**
Datacenter → Storage → Add → ZFS → select `datapool` → set content types (Disk image, Container).

### 2.3 — Storage Allocation Summary

| Storage | Location | Content | Notes |
|---------|----------|---------|-------|
| local (SSD) | /dev/sda | ISO images, Proxmox OS | Default Proxmox local storage |
| local-lvm (SSD) | LVM on SSD | VM disks, LXC rootfs | Default thin-provisioned |
| datapool (HDDs) | RAIDZ1 | VM disks, LXC data, Nextcloud data | Add post-install |

> **Note:** For Nextcloud (Phase 4), the data directory should be on `datapool` — not on the SSD — to take advantage of RAIDZ1 protection for user data.

---

## 3. Network Placement

### 3.1 — Phased Network Migration

Genesis2 will change network addresses across phases as the network buildout progresses. Plan all service IPs for their final LAB VLAN addresses from day one — do not create configurations around temporary addresses.

| Phase | Network | Genesis2 IP | Notes |
|-------|---------|-------------|-------|
| Pre-Phase 1 (current) | Flat 192.168.0.0/24 | 192.168.0.20 (temporary) | Use during initial OS setup only |
| Phase 1 post-window | VLAN 10 HOME | 192.168.10.x (temporary) | After Monday's maintenance window |
| Phase 2+ | VLAN 20 LAB | 192.168.20.10 (permanent) | After 3750G is configured |

### 3.2 — Final Network Configuration (Target)

| Parameter | Value |
|-----------|-------|
| Hostname | genesis2 |
| IP Address | 192.168.20.10 |
| Subnet | 255.255.255.0 |
| Gateway | 192.168.20.1 (3750G SVI) |
| DNS | 192.168.99.5 (Pi-hole primary) |
| VLAN | 20 — LAB |
| MAC | `[Record after installation]` |

### 3.3 — Proxmox Network Bridge

Configure VLAN-aware bridge from day one — set `bridge-vlan-aware yes` during initial Proxmox network setup. This allows VMs and LXCs to be assigned VLAN tags without bridge reconfiguration later.

```
# /etc/network/interfaces target config (Phase 2+ final)
auto lo
iface lo inet loopback

auto enp[X]s0
iface enp[X]s0 inet manual

auto vmbr0
iface vmbr0 inet static
    address 192.168.20.10/24
    gateway 192.168.20.1
    bridge-ports enp[X]s0
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
```

> Set `bridge-vlan-aware yes` on day one. Zero impact to add early, potentially disruptive to change after VMs are running.

---

## 4. VM and LXC Register — LAB VLAN

**Subnet:** 192.168.20.0/24  
**Static Block:** .1–.99  
**DHCP Pool:** .100–.200  

### Zone Allocation Philosophy

Addresses are grouped in zones of ten by service category. This keeps the register readable and leaves deliberate expansion room within each zone.

| Zone | Range | Category |
|------|-------|----------|
| Infrastructure | .1–.19 | Gateways, physical hosts, future nodes |
| Monitoring | .20–.29 | Prometheus, Grafana, Loki, exporters |
| Network Services | .30–.39 | DNS, DHCP-adjacent services |
| Developer Tooling | .40–.49 | Forgejo, CI/CD |
| Access Layer | .50–.59 | NPM, Tailscale, VPN |
| Applications | .60–.79 | Nextcloud, Homepage, website, general apps |
| AI / ML | .80–.89 | Ollama, Open WebUI, GPU workloads |
| Scratch / Lab | .90–.99 | Temporary VMs, experiments — no permanent register entries |

### Full Register

| VMID | IP | Hostname | Type | Role | Phase | Notes |
|------|----|----|------|------|-------|-------|
| — | .1 | — | Gateway | ER605 SVI (Phase 1) → 3750G SVI (Phase 2+) | 1 | Do not assign |
| — | .2–.9 | — | Reserved | Network infrastructure | — | Future SVIs, nodes |
| — | .10 | genesis2 | Physical | Proxmox host | 1 | Management interface — no VMID |
| — | .11–.19 | — | Reserved | Future Proxmox nodes / physical servers | — | Leave clear |
| 220 | .20 | prometheus | LXC | Prometheus + pve_exporter + Node Exporter | 1 | First service deployed |
| 221 | .21 | grafana | LXC | Grafana dashboards | 1 | Connects to Prometheus + Loki |
| 222 | .22 | loki | LXC | Loki log aggregation | 1 | Promtail agents on all hosts |
| — | .23–.29 | — | Reserved | Monitoring expansion | — | Alertmanager, additional exporters |
| 230 | .30 | pihole2 | LXC | Pi-hole secondary DNS | 2 | Gravity Sync pulls from Pi at 192.168.99.5 |
| — | .31–.39 | — | Reserved | Network services expansion | — | |
| ~~240~~ | ~~.40~~ | ~~forgejo~~ | RETIRED — LXC | Moved to mac-server as native Debian service | — |
| — | .41–.49 | — | Reserved | Developer tooling expansion | — | CI/CD if added later |
| 250 | .50 | npm | LXC | Nginx Proxy Manager | 2 | All external service traffic — already committed |
| 251 | .51 | tailscale | LXC | Tailscale subnet router | 2 | Co-advertiser with Pi — already committed |
| — | .52–.59 | — | Reserved | Access layer expansion | — | |
| 360 | .60 | nextcloud | VM | Nextcloud — multi-user ready | 4 | VM for OS-level isolation. Data on datapool. |
| 261 | .61 | homepage | LXC | Homepage dashboard | 4 | Internal service dashboard |
| 262 | .62 | jxstudios | LXC | jxstudios.dev website | 5 | Behind NPM — Astro static site |
| — | .63–.79 | — | Reserved | Application expansion | — | |
| 380 | .80 | ollama | VM | Ollama + Open WebUI — GPU passthrough | 6 | VM required for PCIe passthrough |
| — | .81–.89 | — | Reserved | AI/ML expansion | — | |
| — | .90–.99 | — | Scratch | Experimental / temporary | — | No permanent register entries |

---

## 5. VMID Convention

Proxmox VMs and LXCs share a single ID namespace. The following convention is enforced across all Genesis2 containers and VMs.

| Hundreds Digit | Type | Example |
|---|---|---|
| 2xx | LXC container | pihole2 = 230 |
| 3xx | Virtual machine (VM) | nextcloud = 360 |

**Reading an ID:** VMID 251 = LXC, IP ends in .51. VMID 360 = VM, IP ends in .60. The type and the IP are immediately readable from the ID alone without opening the Proxmox web UI.

**Rules:**
- IDs must be unique across all VMs and LXCs
- Never reuse an ID even after a container is deleted — retire it
- Scratch/temporary containers in the .90–.99 range use IDs 290–299 (LXC) or 390–399 (VM)
- IDs below 200 are reserved (Proxmox internal use starts at 100)

---

## 6. Service Stack — By Phase

Services are deployed in layers. No layer begins until the previous layer is stable and documented.

### Phase 1 — Observability (Deploy First)

> Instrument the host before running any other services. Baseline data and monitoring tooling should exist before complexity is added.

| VMID | Service | IP | Notes |
|------|---------|----|----|
| 220 | Prometheus | 192.168.20.20 | Scrapes Node Exporter and pve_exporter |
| 221 | Grafana | 192.168.20.21 | Dashboards — connects to Prometheus and Loki |
| 222 | Loki | 192.168.20.22 | Log aggregation — Promtail on all hosts |

**Why observability first:** Starting with monitoring before services means you have baseline metrics and understand the tooling before the environment gets complex. It also demonstrates a professional instinct for portfolio purposes — infrastructure should be observable from day one.

### Phase 2 — Infrastructure Services

| VMID | Service | IP | Notes |
|------|---------|-----|-------|
| 230 | Pi-hole secondary | 192.168.20.30 | Gravity Sync from Pi primary |
| 250 | Nginx Proxy Manager | 192.168.20.50 | All service traffic — configure before exposing anything |
| 251 | Tailscale | 192.168.20.51 | Subnet router — co-advertises with Pi |

### Phase 3 — Developer Tooling

| VMID | Service | IP | Notes |
|------|---------|-----|-------|
| — | Forgejo | mac-server 192.168.20.11:3000 | Moved to mac-server — native Debian service. See mac-server-plan.md. VMID 240 retired. |

### Phase 4 — Applications

| VMID | Service | IP | Notes |
|------|---------|-----|-------|
| 360 | Nextcloud | 192.168.20.60 | VM — built for multi-user. Data directory on datapool (RAIDZ1). |
| 261 | Homepage | 192.168.20.61 | Service dashboard — useful once multiple services are running |

### Phase 5 — Presentation

| VMID | Service | IP | Notes |
|------|---------|-----|-------|
| 262 | jxstudios.dev | 192.168.20.62 | Astro static site — public-facing portfolio. Behind NPM. |

### Phase 6 — AI / GPU

| VMID | Service | IP | Notes |
|------|---------|-----|-------|
| 380 | Ollama + Open WebUI | 192.168.20.80 | VM with RTX 2060 GPU passthrough. Separate planning session required before this phase. |

---

## 7. MGMT Pi Architecture

The Raspberry Pi 5 8GB serves as a dedicated MGMT infrastructure device, permanently housed in the rack and managed through the MGMT VLAN (192.168.99.0/24).

### Hardware

| Component | Spec / Status |
|-----------|---------------|
| Model | Raspberry Pi 5 8GB |
| Boot Media | 256 GB SSD (USB-connected) |
| Cooling | Active cooler — to be installed |
| Power | PoE HAT planned — **verify 3750G PoE standard before purchase** (see §11 Pending Items) |
| MGMT IP | 192.168.99.5 |
| VLAN | 99 — MGMT |

### Service Stack — Phased

| Service | Phase | Role | Notes |
|---------|-------|------|-------|
| Pi-hole primary DNS | 2 | Network-wide DNS at 192.168.99.5 | Replaces 192.168.10.15 HOME-only instance |
| Tailscale primary node | 2 | Subnet router, mobile DNS override | Primary — lighter and more reliable than Genesis2 |
| TFTP server | 2 | Cisco config backup and IOS image hosting | `copy running-config tftp:` from switch console |
| Syslog server | 2 | Receives syslog from 3750G and 2960G | Rsyslog or Syslog-ng — pairs with Loki on Genesis2 |
| Ansible control node | 3+ | Playbooks pushed from Forgejo, run from Pi | Industry-relevant tooling — on job descriptions |
| Serial console server | 3 | ser2net — console access to Cisco gear over SSH | Out-of-band management — production datacenter concept |
| Gravity Sync source | 4 | Pushes Pi-hole config to Genesis2 secondary | Manages sync schedule |
| Wake-on-LAN | 4+ | Boot Genesis2 remotely | Optional utility |

### Why Pi as Primary for DNS and Tailscale

Genesis2 requires planned maintenance: reboots for updates, ZFS scrubs, kernel changes, phase migrations. If DNS and Tailscale are primary on Genesis2, every maintenance event takes down DNS and remote access. The Pi is purpose-built always-on infrastructure with no planned downtime. Genesis2 serves as the secondary and backup — not the anchor.

---

## 8. Pi-hole Primary / Secondary Architecture

### Configuration

| Instance | Device | IP | VLAN | Role |
|----------|--------|----|------|------|
| Primary | Raspberry Pi 5 | 192.168.99.5 | 99 MGMT | Authoritative — all configuration managed here |
| Secondary | Genesis2 LXC (pihole2) | 192.168.20.30 | 20 LAB | Failover — config replicated from primary via Gravity Sync |

### DHCP DNS Configuration (Phase 2+)

Each VLAN's DHCP DNS entries in Omada:

| VLAN | DNS Primary | DNS Secondary |
|------|-------------|---------------|
| HOME 10 | 192.168.99.5 | 192.168.20.30 |
| LAB 20 | 192.168.99.5 | 192.168.20.30 |
| IOT 30 | 192.168.99.5 | 192.168.20.30 |
| MGMT 99 | 192.168.99.5 | 192.168.20.30 |

Clients try primary first. If no response within timeout, they fall back to secondary automatically. The failover is transparent.

### Gravity Sync

Gravity Sync runs on the secondary (pihole2 LXC on Genesis2) and pulls configuration from the primary Pi on a schedule. It replicates blocklists, allowlists, custom DNS entries, and Pi-hole configuration. Without Gravity Sync, two independent instances would require manual synchronisation after every blocklist update or custom entry change.

- **Install on:** pihole2 LXC (192.168.20.30)
- **Pulls from:** Pi at 192.168.99.5
- **Transport:** SSH between the two hosts
- **Frequency:** Configurable — recommended every 30 minutes

---

## 9. Tailscale Architecture

### Node Layout

| Node | Device | Type | Role |
|------|--------|------|------|
| Primary | Raspberry Pi 5 | Subnet router | Advertises 192.168.99.0/24, later all VLANs |
| Co-advertiser | Genesis2 LXC (tailscale) | Subnet router | Advertises 192.168.20.0/24 — LAB VLAN |

### Mobile Ad-blocking

Tailscale DNS override routes mobile DNS through Pi-hole when connected to the Tailscale network, without routing all traffic through the home uplink (no exit node required).

**Configuration path:**
1. Tailscale subnet router on Pi advertises relevant subnets
2. In Tailscale admin console: DNS → Nameservers → add Pi-hole IP → enable Override local DNS
3. Mobile device connects to Tailscale → DNS queries go to Pi-hole → ad-blocking applies
4. All other traffic routes normally — no home uplink bandwidth consumed

### External Access

Tailscale is the primary remote access path for personal external access to the lab. Not intended for public-facing service exposure — that path goes through NPM and the jxstudios.dev DNS records.

---

## 10. Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data storage | RAIDZ1 across 3× 500 GB HDDs | Industry-relevant ZFS skill, single-drive fault tolerance, checksumming. 1 TB usable accepted over 1.5 TB independent. |
| GPU passthrough | Planned Phase 6 — RTX 2060 to Ollama VM | 6 GB VRAM suitable for quantized 7B models. VM required — LXC cannot own GPU exclusively. |
| Pi-hole topology | Pi as primary (99.5), Genesis2 as secondary (20.30) | Pi is always-on infrastructure. Genesis2 requires maintenance windows. DNS anchor should have no planned downtime. |
| Tailscale topology | Pi as primary subnet router, Genesis2 as co-advertiser | Same reasoning as Pi-hole — lighter, more reliable primary. Genesis2 covers LAB VLAN. |
| Nextcloud type | VM (not LXC) | PHP application stack, background jobs, real user data. OS-level isolation appropriate. Data on RAIDZ1 pool. |
| Nextcloud scope | Build for multi-user from day one | Migration from single-user later is painful. Cost of building ahead is minimal. |
| Ollama type | VM | GPU passthrough requires KVM/QEMU VM. LXC shares host kernel and cannot own PCIe device exclusively. |
| VMID convention | 2xx = LXC, 3xx = VM, last two digits = IP octet | Type and IP readable from ID alone. Enforced from first container. |
| jxstudios.dev stack | Astro | Modern static site generator, strong portfolio signal, component-based, fast output. No CMS overhead needed for this use case. |
| Monitoring stack | PLG — Prometheus + Loki + Grafana | Industry standard, appears in job descriptions, three independent LXCs for clean update/rebuild paths. |
| Internal Git | Forgejo over Gitea | Better community trajectory post-Gitea Inc. fork. API-compatible — no functional difference. Push mirror to GitHub supported natively. |
| Forgejo placement | mac-server (native), not genesis2 LXC | genesis2 has planned maintenance windows. Internal Git must be reachable during those windows. Core 2 Duo handles Go binary without issue. VMID 240 retired. |
| Dashboard | Homepage | Actively maintained, YAML config (infrastructure-as-code discipline), clean integrations. |
| MGMT Pi boot media | USB SSD (256 GB, already connected) | SD card wear under constant DNS query logging is an avoidable failure mode. SSD resolved. |

---

## 11. Pending Items

| Item | Owner | Priority | Notes |
|------|-------|----------|-------|
| Verify 3750G PoE standard | JXH | High — before PoE HAT purchase | Run `show power inline` on 3750G. Confirm 802.3af (15.4W) vs 802.3at PoE+ (25W). Pi 5 under full load can approach 15.4W ceiling. If 802.3af only, use USB-C power supply or check SG2008P PoE spec as alternative. |
| Record Genesis2 MAC address | JXH | After OS install | Update network_settings_register_populated.md — Phase 4 entry |
| Proxmox installation planning session | Architect | Next session | Installer decisions, post-install steps, ZFS pool creation procedure |
| GPU passthrough planning session | Architect | Phase 6 | Dedicated session — IOMMU groups, VFIO config, VM layout for Ollama |
| Forgejo → GitHub mirror setup | Claude Code | Phase 3 | Document mirror configuration in forgejo LXC setup notes |

---

*Document version 1.0 — Created 18/03/2026 — Session 1 planning complete*  
*Next update: After Proxmox installation session*
