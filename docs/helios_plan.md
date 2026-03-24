# Helios Planning Document
**Site:** JXStudios
**Hostname:** `helios`
**Project:** Project Helios
**Document Version:** 1.0
**Created:** 23/03/2026
**Last Updated:** 23/03/2026
**Status:** Active build — flat network phase (192.168.0.151)
**Companion Files:** `CLAUDE.md` | `network_settings_register_populated.md` | `genesis2-project-genesis-plan.md` | `device_specs_list.md`

---

## Table of Contents

1. [Hardware Specification](#1-hardware-specification)
2. [Network Placement](#2-network-placement)
3. [Service Stack](#3-service-stack)
4. [Service Architecture Notes](#4-service-architecture-notes)
5. [Role in the Wider Lab](#5-role-in-the-wider-lab)
6. [Decisions Log](#6-decisions-log)
7. [Pending Items](#7-pending-items)

---

## 1. Hardware Specification

| Component | Spec | Notes |
|-----------|------|-------|
| Machine | OR PC — Sandy Bridge desktop | Ethernet wired — no Wi-Fi dependency |
| CPU | Intel Core i3-2120 — 2c/4t | 32nm Sandy Bridge — 65W TDP |
| RAM | 16 GB DDR3-1600 (2× 8 GB) | Sufficient for all planned services with headroom |
| Boot drive | `[TBC — confirm before install]` | Debian OS only — separate from data pool |
| Data drives | 3× 500 GB HDD | RAIDZ1 pool — 1 TB usable, single-drive fault tolerance |
| GPU | NVIDIA GeForce GT 220 1GB DDR2 | No hardware transcode — Tesla architecture (2009) |
| Network | Ethernet (wired) | Standard desktop NIC — record interface name during install |
| Power draw (idle) | ~55–70 W | ~$55–65/yr at $0.14/kWh — always-on viable |
| Power draw (load) | ~80–100 W | Light server load — media serving, Samba, Forgejo |
| OS | Debian 12 headless | No desktop environment |

> **Before install:** Run `lsblk` from a live USB to confirm boot drive identifier. Do not partition a data HDD by mistake. The three data drives are left unpartitioned — ZFS will claim them as a pool post-install.

---

## 2. Network Placement

### 2.1 — Phased IP Plan

| Phase | Network | Helios IP | Status | Notes |
|-------|---------|-----------|--------|-------|
| Flat (current — active) | 192.168.0.0/24 | 192.168.0.151 | ✅ Active build phase | All services configured and tested here first |
| Phase 2+ | VLAN 20 LAB | 192.168.20.11 | 🔵 Future | After 3750G is configured and maintenance window complete |

> **All services are built and validated on the flat network.** Service configs use the flat IP during this phase. When Helios migrates to VLAN 20, only the static IP and gateway need updating — service configs do not need to change, as hostnames and port numbers remain identical.

### 2.2 — Current Configuration (Flat Network — Active)

| Parameter | Value |
|-----------|-------|
| Hostname | helios |
| IP Address | 192.168.0.151 (static — outside DHCP range) |
| Subnet | 255.255.255.0 |
| Gateway | 192.168.0.1 (ER605) |
| DNS | 192.168.0.1 (ER605 — flat network default) |

> On the flat network all devices share the same broadcast domain — no ACL rules, no VLAN permits needed. Samba, Jellyfin, Forgejo, and code-server are reachable from any device on 192.168.0.0/24 directly by IP. This is intentional for the build phase — it removes network complexity while services are being stood up and tested.

### 2.3 — Future Configuration (VLAN 20 LAB — Target)

| Parameter | Value |
|-----------|-------|
| Hostname | helios.jxstudios.dev |
| IP Address | 192.168.20.11 |
| Subnet | 255.255.255.0 |
| Gateway | 192.168.20.1 (3750G SVI) |
| DNS | 192.168.99.5 (Pi-hole primary) |
| VLAN | 20 — LAB |
| Zone | Infrastructure (.11–.19) — physical host |

> 192.168.20.11 was originally allocated to mac-server. mac-server's role has been absorbed by Helios — Helios takes .11 directly. Update the network register at migration time.

### 2.4 — Future ACL Requirements (VLAN Migration — Not Yet Needed)

Once Helios moves to VLAN 20, Samba and Jellyfin require explicit ACL permits from home devices — they cannot be proxied through Nginx Proxy Manager the way HTTP services can.

| Service | Port | Protocol | ACL Rule Required |
|---------|------|----------|------------------|
| Samba | 445 | TCP | HOME → 192.168.20.11:445 — Permit |
| Jellyfin | 8096 | TCP | HOME → 192.168.20.11:8096 — Permit |
| code-server | 8080 | TCP | Admin IPs only → 192.168.20.11:8080 — Permit |
| Forgejo | 3000 | TCP | Via NPM proxy — no direct ACL needed |

> ⚠️ These ACL rules do not exist yet and are not needed during the flat network phase. Add them to `network_settings_register_populated.md` pending rules before the Phase 2 maintenance window.

---

## 3. Service Stack

All services run as native Debian systemd units. No Docker, no containers. Each service runs as its own dedicated system user.

| Service | Port | User | Purpose | Phase |
|---------|------|------|---------|-------|
| Forgejo | 3000 | `forgejo` | Internal Git — push mirror to GitHub | 1 |
| Samba | 445 | `root` / share mapping | Always-on home NAS — ZFS RAIDZ1 pool | 1 |
| Jellyfin | 8096 | `jellyfin` | Local media server — direct play | 1 |
| code-server | 8080 | `codeserver` | VS Code in browser — remote dev access | 1 |
| OpenSSH | 22 | system | SSH jump host — backup to Pi | always |

> All five services are deployed in Phase 1 of the Helios build. There are no future phases planned for this machine — it is a utility and media node, not a growth platform.

### Storage

ZFS datasets are created on the RAIDZ1 pool at pool creation time. All service data paths live on the pool — only the OS lives on the boot drive.

| Dataset | Mount Path | Purpose | Service |
|---------|-----------|---------|---------|
| `heliospool` | `/heliospool` | Pool root | — |
| `heliospool/forgejo` | `/srv/forgejo` | Forgejo repos, config, attachments | Forgejo |
| `heliospool/shared` | `/srv/samba/shared` | General file share | Samba |
| `heliospool/media` | `/srv/samba/media` | Media library — Jellyfin source | Samba + Jellyfin |
| `heliospool/backups` | `/srv/backups` | BorgBackup target from other machines | rsync/Borg |

> Pool name is `heliospool` to distinguish it from genesis2's `datapool`. Mount paths follow the `/srv/` convention from mac-server-plan. ZFS handles the mounting — no `/etc/fstab` entries needed for pool datasets.

---

## 4. Service Architecture Notes

### Forgejo

Forgejo is a single Go binary. It requires no runtime beyond the binary itself. All lab repositories — network documentation, Ansible playbooks, config backups, scripts — are hosted here and push-mirrored to GitHub. The internal instance is the primary; GitHub is the backup.

Helios Forgejo replaces the genesis2 VMID 240 entry, which is retired. The decision to host Forgejo on the always-on utility node rather than genesis2 is the same reasoning as mac-server — internal Git must be reachable during genesis2 maintenance windows.

Forgejo should be the **first service configured and the first repo committed** before any other work on Helios continues.

```
Suggested initial repos:
  jxstudios-homelab    ← main lab repo (already on GitHub)
  configs              ← Cisco running configs, Omada backups
```

### Samba

Samba provides SMB shares accessible from Windows, macOS, and Linux devices on VLAN 10 (HOME). Two shares are exposed: `shared` for general files and `media` as the Jellyfin library path. Both are backed by ZFS datasets on the RAIDZ1 pool.

Unlike mac-server (which used an external drive mounted by UUID), there is no removable storage dependency here. The RAIDZ1 pool is always present. The `nofail` fstab consideration from mac-server does not apply — ZFS imports the pool automatically at boot.

ZFS compression (`lz4`) is enabled on the pool by default. RAIDZ1 provides single-drive fault tolerance — if one of the three 500 GB HDDs fails, the pool remains online and data is intact until the failed drive is replaced.

### Jellyfin

Jellyfin is a standalone media server. It scans the `/srv/samba/media` dataset, fetches metadata from TheMovieDB / TheTVDB / MusicBrainz, organises the library, and streams to clients (browser, smart TV apps, phones, Kodi).

**Jellyfin does not include download management.** It only serves media that already exists on disk. There are two approaches to populating the library:

| Approach | How | Best For |
|----------|-----|---------|
| Manual | Copy files to `/srv/samba/media` from any machine on the LAN | Starting out — no extra services needed |
| Automated (*arr stack) | Sonarr + Radarr + Prowlarr + qBittorrent on genesis2 write to Helios via NFS | When you want hands-off library management |

The *arr stack, if ever deployed, lives on genesis2 as LXCs — consistent with genesis2's role as the service host. Helios is the storage and serving layer; genesis2 is the management layer. Helios exposes `/srv/samba/media` as an NFS export that genesis2 LXCs mount and write to. Jellyfin on Helios reads from the same path.

**Hardware transcode is not available** — the GT 220 (Tesla architecture) has no NVENC/NVDEC. Jellyfin uses software transcode via the i3-2120 CPU when needed. The correct strategy is H.264 storage — all modern clients direct-play H.264 MP4/MKV natively and the CPU is never involved. One occasional software transcode stream is manageable; do not build a library of HEVC/H.265 files and rely on real-time transcoding.

Access paths:
- Home devices: `http://192.168.20.11:8096` (requires HOME→LAB ACL permit — see §2)
- Admin direct: `http://192.168.20.11:8096`
- Future optional: proxied via NPM as `media.jxstudios.dev` for HTTP/HTTPS access

### code-server

code-server provides a VS Code-compatible interface in the browser. It is the remote development environment for the lab — available over Tailscale from anywhere and accessible locally from any browser.

Access paths:
- Local network: `http://192.168.20.11:8080`
- Tailscale (remote): `http://<tailscale-ip>:8080`
- Future optional: proxied via NPM as `code.jxstudios.dev`

code-server has built-in password authentication. The self-signed cert warning on first load is expected — accept in browser or configure via NPM later. Password auth is sufficient here.

code-server can open any path on the machine directly, including `/srv/forgejo` repos, which makes it a natural pairing with the local Forgejo instance.

### SSH Jump Host

OpenSSH is already present on any Debian install. Add the lab's admin public keys to `~/.ssh/authorized_keys` and disable password auth after confirming key-based login works.

Helios as a jump host means: if the Pi is ever unreachable, SSH access to the rest of the lab still exists via Helios. This is a backup path, not the primary.

---

## 5. Role in the Wider Lab

Helios occupies the middle tier of the three-host lab architecture, taking the position originally designed for mac-server.

| Tier | Device | Role | Always-on |
|------|--------|------|-----------|
| 1 — Lightweight anchor | Pi 5 | DNS, Tailscale, MGMT utilities | Yes — no planned downtime |
| 2 — Utility and media node | Helios | Git, NAS, Jellyfin, code-server, jump host | Yes — no planned downtime |
| 3 — Heavy compute | Genesis2 | Proxmox hypervisor, all LXCs and VMs | Planned maintenance windows |

Helios services are specifically chosen because they should be reachable when genesis2 is down. Forgejo availability during genesis2 maintenance means configs and docs can always be committed. NAS and Jellyfin availability means files and media are always accessible. code-server availability means remote editing is always possible. None of these services depend on genesis2 being healthy.

The MacBook (2008), which was the original candidate for this role, is retired to spare status. The hardware case for Helios over the MacBook is clear: better CPU (Sandy Bridge vs Penryn), double the RAM (16 GB vs 8 GB), three native HDDs in a RAIDZ1 pool rather than a single external drive, and a discrete GPU slot. The service stack and architectural reasoning are identical to the mac-server plan — only the hardware has changed.

### Portfolio Framing

Helios is documented as part of the larger JXStudios home lab project, not as a standalone project. The value is in the architectural reasoning — why these services live here, what problem the tier separation solves, and how it integrates with the network segmentation and the wider genesis2 stack. The hardware is older; the architecture and documentation are the talking points.

---

## 6. Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| OS | Debian 12 headless | Stable, minimal, well-documented. No desktop overhead. Consistent with mac-server-plan. |
| Service management | Native systemd | Five lightweight services with no complex inter-dependencies. No benefit to Docker. Fewer mental models during incident response. Consistent with Pi and mac-server-plan pattern. |
| Forgejo placement | Helios, not genesis2 | Genesis2 requires planned maintenance windows. Internal Git must be reachable during them. Go binary runs fine on i3-2120. genesis2 VMID 240 retired. |
| NAS placement | Helios | Always-on file access independent of genesis2 uptime. ZFS RAIDZ1 provides redundancy and checksumming — upgrade over mac-server external drive approach. |
| Jellyfin placement | Helios, not genesis2 LXC | Helios reads from local RAIDZ1 disk — no network hop. Media data stays on the same machine as the server. Genesis2 LXC would read over NFS unnecessarily. |
| *arr stack placement | Genesis2 LXCs (if/when deployed) | Separation of concerns: Genesis2 manages downloads; Helios stores and serves. Keeps Helios as a clean utility node. Writes to Helios via NFS. |
| code-server placement | Helios | Always-on remote dev access. Pairs naturally with local Forgejo instance. |
| Transcode strategy | Direct play — H.264 only | GT 220 has no hardware transcode (Tesla architecture). i3-2120 can manage occasional software transcode but it is not the primary strategy. Store media as H.264 MP4/MKV. |
| Storage | ZFS RAIDZ1 on 3× 500 GB HDD | Native drives available — no external dependency. 1 TB usable. Single-drive fault tolerance. ZFS checksumming prevents silent corruption. |
| SSH jump | Helios (backup) | Pi is primary jump host. Helios provides redundancy without additional config cost. |
| Network | LAB VLAN 20 — 192.168.20.11 | Infrastructure zone (.11–.19) — correct zone for physical hosts. Takes mac-server's intended address since that role is absorbed. |
| Samba/Jellyfin ACL | HOME→LAB permit rules required | These services require direct LAN access — cannot be proxied. Explicit ACL permits for ports 445 and 8096 from HOME VLAN to Helios IP. |
| Portfolio | Part of JXStudios lab project | Helios alone is insufficient context. As one node in a documented multi-host segmented lab, it supports the overall project narrative. |

---

## 7. Pending Items

### Active — Flat Network Build Phase

| Item | Priority | Notes |
|------|----------|-------|
| Boot drive identification | Before install | Run `lsblk` from live USB — confirm which drive to install Debian on. Do not partition a data HDD. |
| Set static IP 192.168.0.151 | During install | Outside DHCP range — confirm ER605 DHCP pool upper bound before choosing |
| Confirm MAC address | After Debian install | Update `network_settings_register_populated.md` — flat network entry for helios at 192.168.0.151 |
| NIC interface name | During install | Record in §1 — needed for static IP config |
| code-server password | During setup | Store in password manager — do not commit to repo |
| Forgejo admin credentials | During setup | Store in password manager — do not commit to repo |
| GitHub mirror token | During Forgejo setup | Personal access token — store in password manager |
| Migrate main lab repo to Helios Forgejo | After Forgejo confirmed healthy | Clone from GitHub, set as new origin, GitHub becomes push mirror |
| Update macbook-server-idea.md | After build begins | Note that home server role has moved to Helios — close out the MacBook plan |

### Future — VLAN Migration (Phase 2+)

| Item | Priority | Notes |
|------|----------|-------|
| Update static IP to 192.168.20.11 | At VLAN migration window | Change IP and gateway in `/etc/network/interfaces` — all service configs remain unchanged |
| Add ACL permits to network register | Before migration window | HOME → 192.168.20.11:445 (Samba) and HOME → 192.168.20.11:8096 (Jellyfin) — see §2.4 |
| Update DNS to 192.168.99.5 | At VLAN migration | Replace ER605 as DNS with Pi-hole on MGMT VLAN |
| Retire genesis2 VMID 240 (Forgejo LXC) | After Forgejo confirmed healthy on Helios | Remove from genesis2-project-genesis-plan.md VM register |
| NFS export config (if *arr stack deployed) | When genesis2 *arr LXCs are created | Export `/srv/samba/media` from Helios → genesis2 LXC subnet |

---

*Document version 1.0 — Created 23/03/2026 — Active build phase: flat network (192.168.0.151)*
*Supersedes: mac-server-plan.md (role absorbed — MacBook retired to spare)*
*Next update: After Debian install — record MAC address, NIC interface name, confirm static IP*
