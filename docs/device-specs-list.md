# Device Specifications List
**Site Name:** `JXStudios`
**Owner:** `[OWNER]`
**Storage:** `https://github.com/[USERNAME]/proxmox_homelab`
**Version:** `1.4`
**Created:** `09/03/2026`
**Last Updated:** `23/03/2026`
**Companion Files:** `network_settings_register_populated.md` | `genesis2-project-genesis-plan.md`

---

> **How to use this document**
> This is the authoritative hardware reference for all JXStudios lab devices. It records confirmed specs sourced from Intel ARK, manufacturer documentation, and the project planning documents.
> Update when a device is added, removed, repurposed, or has a hardware change (RAM upgrade, drive swap, OS change).
> IP addresses, MAC addresses, and DHCP reservations are maintained in `network_settings_register_populated.md` — not here.

---

## Table of Contents

1. [Hardware Specifications](#1-hardware-specifications)
2. [Operational Context](#2-operational-context)
3. [Platform Notes](#3-platform-notes)
4. [Upgrade Candidates](#4-upgrade-candidates)

---

## 1. Hardware Specifications

> Sources: Intel ARK for confirmed CPU specs. Storage and RAM maximums sourced from manufacturer documentation.
> Fields marked `[TBC]` require physical verification and should be updated on next access.

| # | Name | CPU Model | Architecture | Cores / Threads | Base Clock | Boost Clock | RAM (Current) | RAM (Max) | Storage | GPU / iGPU |
|---|------|-----------|--------------|-----------------|------------|-------------|---------------|-----------|---------|------------|
| 1 | Alival | AMD Ryzen 5 5600X | Zen 3 | 6 / 12 | 3.70 GHz | 4.60 GHz | 32 GB DDR4 | 128 GB DDR4 | `[TBC]` | NVIDIA GeForce RTX 3070 8GB |
| 2 | Genesis2 | AMD Ryzen 7 5700X | Zen 3 | 8 / 16 | 3.40 GHz | 4.60 GHz | 64 GB DDR4-3600 | 128 GB DDR4 | 256 GB 2.5" SSD (boot) + 3× 500 GB 2.5" HDD (RAIDZ1 — data pool) | NVIDIA GeForce RTX 2060 6GB |
| 3 | RasPi5 | Broadcom BCM2712 Cortex-A76 | ARMv8.2-A | 4 / 4 | 2.40 GHz | — | 8 GB LPDDR4X | 8 GB (max model) | 256 GB SSD (USB-connected) | VideoCore VII |
| 4 | Helios | Intel Core i3-2120 | Sandy Bridge | 2 / 4 | 3.30 GHz | — | 16 GB DDR3-1600 (2× 8 GB) | 32 GB DDR3 | 3× 500 GB HDD | NVIDIA GeForce GT 220 1GB DDR2 (PCIe 2.0 x16) |
| 5 | eMachine | Intel Celeron 450 | Conroe-L | 1 / 1 | 2.20 GHz | — | 4 GB DDR2 | 4 GB DDR2 | `[TBC]` | Intel GMA (Intel 4 Series chipset — board-dependent) |
| 6 | MacBook (2008) | Intel Core 2 Duo | Penryn | 2 / 2 | 2.40 GHz | — | 8 GB DDR2 | 8 GB DDR2 | 256 GB SSD | Intel GMA X3100 (integrated) |
| 7 | MacBook Pro (2015) | Intel Core i7-4770HQ | Haswell | 4 / 8 | 2.20 GHz | 3.40 GHz | 16 GB DDR3L | 16 GB DDR3L | `[TBC]` | Intel Iris Pro 1536 MB |
| 8 | HP Laptop | Intel Core i5-7200U | Kaby Lake | 2 / 4 | 2.50 GHz | 3.10 GHz | 8 GB DDR4 | 32 GB DDR4 | 1 TB SSD | Intel HD Graphics 620 |
| 9 | ASUS R503U | AMD E2-1800 | Bobcat | 2 / 2 | 1.70 GHz | — | 8 GB DDR3 | 8 GB DDR3 | `[TBC]` | AMD Radeon HD 7340 |
| 10 | Lenovo B50 Touch | Intel Celeron N2840 | Bay Trail | 2 / 2 | 2.16 GHz | 2.58 GHz | 8 GB DDR3L | 8 GB DDR3L | `[TBC]` | Intel HD Graphics (Bay Trail) |

---

## 2. Operational Context

| # | Name | OS | Role | Status | Location | Notes |
|---|------|----|------|--------|----------|-------|
| 1 | Alival | Windows 11 / Fedora 43 (dual boot) | Primary admin workstation | 🟢 Active | `[Location TBC]` | Daily driver. Admin PC — 192.168.10.10 in register. |
| 2 | Genesis2 | Proxmox VE | Primary lab server — hypervisor | 🟡 Active — install in progress | Server rack | Running on flat 192.168.0.20 — migrates to 192.168.20.10 at Phase 2. Full VM/LXC register in `genesis2-project-genesis-plan.md`. |
| 3 | RasPi5 | Raspberry Pi OS 12 (Bookworm) | MGMT infrastructure — Pi-hole primary, Tailscale primary | 🟢 Active | `[Location TBC — planned: rack-mounted]` | Phase 1: 192.168.10.15 (HOME). Phase 2+: 192.168.99.5 (MGMT). PoE HAT planned — verify 3750G PoE standard first (`show power inline`). |
| 4 | Helios | Proxmox VE → Debian 12 (planned) | Home server — Project Helios | 🔵 Planned | Server rack | GPU confirmed GT 220 (no hardware transcode — direct play strategy). VLAN placement decision pending — see helios-home-server-build-guide.md §3.2. Full build guide: `helios-home-server-build-guide.md`. |
| 5 | eMachine | Ubuntu 22.04 LTS | Unassigned — network test endpoint | ⚪ Spare | `[Location TBC]` | Celeron 450 is single-core, no hyperthreading, max 4 GB DDR2 — not suitable for any server role. Best use: static end-host for Phase 7 Cisco 1921 routing labs, or VLAN segmentation test target. See §3 Platform Notes. |
| 6 | MacBook (2008) | Debian 12 | Spare — repurposed from home server plan | ⚪ Spare | `[Location TBC]` | Home server role now assigned to Helios. MacBook retains Debian 12 — keep as a portable dev/travel machine or secondary lab endpoint. No further configuration investment recommended. See §3 Platform Notes. |
| 7 | MacBook Pro (2015) | macOS | Admin laptop | 🟢 Active | `[Location TBC]` | Backup admin console for maintenance windows. Must have Discovery Utility and Java 17 FX (Zulu) installed before window day. |
| 8 | HP Laptop | Fedora | Admin laptop | 🟢 Active | `[Location TBC]` | Admin Laptop — IP TBC in register. |
| 9 | ASUS R503U | Windows 10 | Spare / Windows test machine | ⚪ Spare | `[Location TBC]` | E2-1800 (Bobcat) is low-power — no server roles. Useful for Windows-specific testing or as a wireless client during lab experiments. |
| 10 | Lenovo B50 Touch | Fedora `[version TBC]` | Spare / Linux laptop | ⚪ Spare | `[Location TBC]` | Bay Trail Celeron — adequate for light Linux use. No server roles. Touchscreen potentially useful as a portable dashboard terminal. |

**Status key:**
- 🟢 Active — device is online and in use
- 🟡 Active — in progress / deployment ongoing
- 🔵 Planned — defined role, not yet deployed
- ⚪ Spare — available, no current role assigned

---

## 3. Platform Notes

### Helios — Home Server (Confirmed — Replaces MacBook Plan)

Helios is confirmed as the home server with 16 GB DDR3-1600 already installed and 3× 500 GB HDDs ready for a RAIDZ1 pool — the exact same storage layout as Genesis2. This is a straight upgrade over the MacBook 2008 in every dimension: better IPC, more RAM with headroom to expand, a real PCIe slot with a discrete GPU, and the same usable storage.

**Recommended service stack (from macbook-server-idea.md, adapted):**

| Service | Purpose | Notes |
|---------|---------|-------|
| Samba + RAIDZ1 pool | Network file storage / NAS | RAIDZ1 protects against single-drive failure. ZFS checksumming catches silent corruption. |
| Forgejo or Gitea | Self-hosted Git | Lightweight — works fine on i3-2120 |
| WireGuard | Remote access VPN | Low CPU overhead even on older hardware |
| Vaultwarden | Self-hosted password manager | Very lightweight Bitwarden-compatible server |
| Jellyfin | Local media streaming | See Jellyfin vs Plex note below |
| rsync + cron or BorgBackup | Automated backups | Pull backups from other machines to RAIDZ1 pool |

**OS decision:** Re-install as Debian 12 headless. Proxmox is overkill for a single-purpose home server and adds unnecessary overhead. A clean Debian 12 base with Docker Compose (or native installs) is simpler to maintain and better suited to this role.

**GPU — GT 220 confirmed (1 GB DDR2, PCIe 2.0 x16):**
The GT 220 is a Tesla-architecture GPU from 2009. It has no NVENC or NVDEC support — there is no hardware video encode or decode available. Jellyfin will use **software transcoding only** on this machine. This is fine given the usage profile:

| Scenario | CPU load | Notes |
|----------|----------|-------|
| Direct play (H.264 MP4/MKV) | Near zero | Client decodes — server just streams bytes. No transcode occurs. |
| 1× software transcode to H.264 1080p | ~60–80% one core | Manageable on i3-2120 for occasional use |
| 2× simultaneous software transcodes | Heavy — may stutter | Not recommended as a regular pattern |

**Strategy:** Ensure media is stored in H.264 MP4 or MKV format where possible. Modern clients (browsers, smart TVs, phones, Kodi, Jellyfin apps) all direct-play H.264 natively. If you have HEVC/H.265 or AV1 files that older clients can't play, you'll hit the software transcode ceiling. Remuxing to H.264 on Alival before copying to the server is a better long-term approach than relying on real-time transcoding. Jellyfin is still the correct choice — Plex would charge for hardware transcoding that isn't available anyway.

**Jellyfin vs Plex:**

Jellyfin is the better choice for this hardware. It is entirely free and open source — no subscription required for hardware transcoding, no account required, no phone-home. Plex's hardware transcoding is locked behind Plex Pass (~$5/month or ~$120 lifetime), and on a GT 710/220, you'd be paying for a feature that barely works on hardware this old. Jellyfin handles software transcoding well on the i3-2120 for one or two streams and takes full advantage of hardware decode if the GPU supports it without requiring any subscription. The macbook-server-idea.md already listed Jellyfin — that decision stands and is correct for this hardware.

**Power draw estimate — Dallas, TX:**

Estimated Helios system draw for a lightly-loaded home server:

| Component | Estimated Draw |
|-----------|---------------|
| i3-2120 (idle/light load) | 30–45 W |
| 3× 500 GB HDD (spin) | 12–18 W |
| GT 710 / GT 220 (idle) | 10–20 W |
| Motherboard + RAM + PSU loss | 15–20 W |
| **System total (typical)** | **~70–90 W** |

Dallas residential electricity averages around 16 cents per kWh, though the cheapest fixed-rate plans in the Oncor service territory currently start around 8.4 cents/kWh, with the average across all plans at about 13.8 cents/kWh. Using the broadly-cited average of ~$0.14/kWh as a working figure:

| Scenario | Monthly | Annual |
|----------|---------|--------|
| 70 W average (very light load) | ~$7.10 | ~$86 |
| 80 W average (typical) | ~$8.10 | ~$97 |
| 90 W average (busier periods) | ~$9.10 | ~$110 |

**Verdict:** A home server running 24/7 at this draw adds roughly **$7–9/month to the electricity bill at average Dallas rates**. This is low enough that it's not a meaningful operating cost concern. The actual figure depends on your specific plan rate — if you're on a cheaper fixed-rate plan, the cost will be proportionally lower.

HDD spin-down during overnight hours (via `hdparm` or Samba's `min receivefile size`) can reduce the average draw further if energy cost becomes a consideration later.

---

### MacBook (2008) — Repurposed from Home Server Plan

With the Helios confirmed as the home server, the MacBook 2008 has no remaining planned role. Options in order of usefulness:

- **Keep as a portable Debian 12 machine** — already set up, useful as a travel dev machine or a self-contained environment you can physically take somewhere
- **Secondary lab endpoint** — if you ever need a third machine on the bench alongside the 1921 router labs or need a device on a specific VLAN, it works fine for this
- **Retire it** — it's a 17-year-old machine. If you don't have a use for it in 6 months, pass it on

No further configuration investment is recommended. Do not reinstall or reconfigure it — it's already usable on Debian 12. Just update `macbook-server-idea.md` to note the role has moved to Helios.

---

### eMachine (Celeron 450)
The Celeron 450 is a single-core Conroe-L chip from 2008 running at 2.2 GHz with no hyperthreading and a maximum of 4 GB DDR2 RAM — it cannot be expanded further. Ubuntu 22.04 reaches end of standard support in April 2027, giving it a short useful life even for its current OS. It is not a candidate for any service role in this lab.

**Viable uses within this project:**
- **Phase 7 Cisco 1921 routing lab** — The 1921 routing experiments only need an end-host on each side of a route to generate traffic and verify routing tables. The eMachine is adequate for this (ping, iperf, traceroute) without consuming a more useful machine.
- **VLAN segmentation test endpoint** — Connect it to a specific VLAN port and use it to verify ACL rules are enforced correctly. A real device testing reachability is more reliable than relying on ping from a managed switch alone.
- **Disposable Linux scratch machine** — Safe to experiment on, break, reinstall. No risk to production data or configuration.

**Verdict:** Keep powered off. Connect when needed for Cisco lab sessions or ACL testing. Do not invest time configuring it as a service host.

---

### HP Laptop — Core Count Correction
The original document listed the i5-7200U as 4 cores / 8 threads. This is incorrect — confirmed against Intel ARK. The i5-7200U is a dual-core (2 cores / 4 threads) Kaby Lake mobile processor at 2.5 GHz base / 3.1 GHz boost. The 4-core designation belongs to the i5-8250U (8th Gen) and later. No hardware change — documentation correction only.

---

## 4. Upgrade Candidates

> Devices where a cost-effective hardware upgrade would meaningfully change their role options.

| Device | Current Bottleneck | Recommended Upgrade | Estimated Cost | Impact |
|--------|--------------------|---------------------|----------------|--------|
| Helios | GT 220 has no hardware transcode | No upgrade needed — direct play strategy avoids transcode. Long-term: if H.265 media accumulates, remux to H.264 on Alival rather than relying on real-time CPU transcode. | $0 | Jellyfin fully functional for direct play |
| HP Laptop | 8 GB RAM for Debian dev workstation | 16 GB DDR4 (2× 8 GB, SO-DIMM) if RAM becomes a bottleneck | ~$30–50 used | More headroom for dev tooling and browser-heavy work |
| eMachine | Single-core CPU, DDR2 platform | Not upgradeable within budget | — | Platform is end-of-life — no upgrade path worth pursuing |

---

*Last updated: 23/03/2026 — v1.4: OR PC renamed to Helios (Project Helios). Operational context updated — GPU confirmed GT 220, build guide reference added.*
*Previous version: 1.3 — 23/03/2026 — GT 220 confirmed, HP Laptop storage confirmed 1 TB SSD*
*Previous version: 1.2 — 23/03/2026 — Helios confirmed as home server, added power draw and Plex vs Jellyfin analysis*
*Previous version: 1.1 — 23/03/2026 — Full restructure, corrected HP Laptop core count*
*Previous version: 1.0 — 09/03/2026 — Initial spec list*
