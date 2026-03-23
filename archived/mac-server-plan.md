# mac-server Planning Document
**Site:** JXStudios  
**Hostname:** `mac-server`  
**Document Version:** 1.0  
**Created:** 22/03/2026  
**Last Updated:** 22/03/2026  
**Status:** Planning complete — pending Debian install session  
**Companion Files:** `CLAUDE.md` | `project-summary-and-remaining-steps.md` | `network_settings_register_populated.md`

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
| Machine | 2008 MacBook | Intel platform — run headless via ethernet |
| CPU | Intel Core 2 Duo | 45nm Penryn — 35W TDP |
| RAM | 8 GB | Sufficient for all planned services |
| Drive | 256 GB SSD | Replaces original HDD — lower power, faster |
| Network | Ethernet (wired) | Broadcom Wi-Fi avoided entirely — unreliable under Linux |
| Power draw (idle) | ~12–18W | ~$16–18/yr at $0.12/kWh — always-on viable |
| Power draw (load) | ~20–30W | Light server load expected |
| OS | Debian 12 headless | No desktop environment |

---

## 2. Network Placement

| Phase | Network | mac-server IP | Notes |
|-------|---------|---------------|-------|
| Setup (current) | Flat 192.168.0.0/24 | 192.168.0.11 (temp) | During initial OS and service setup |
| Phase 2+ | VLAN 20 LAB | 192.168.20.11 (permanent) | After 3750G is configured |

### Final Network Configuration (Target)

| Parameter | Value |
|-----------|-------|
| Hostname | mac-server.jxstudios.dev |
| IP Address | 192.168.20.11 |
| Subnet | 255.255.255.0 |
| Gateway | 192.168.20.1 (3750G SVI) |
| DNS | 192.168.99.5 (Pi-hole primary) |
| VLAN | 20 — LAB |
| Zone | Infrastructure (.11–.19) — physical host |

> mac-server is a physical host in the LAB VLAN infrastructure zone. It has no VMID — that convention applies to genesis2 LXCs and VMs only. It is managed directly via SSH and native systemd services.

---

## 3. Service Stack

All services run as native Debian systemd units. No Docker, no containers. Each service runs as its own dedicated system user.

| Service | Port | User | Purpose | Phase |
|---------|------|------|---------|-------|
| Forgejo | 3000 | `forgejo` | Internal Git — push mirror to GitHub | 1 |
| Samba | 445 | `root` / share mapping | Always-on home NAS — external drive | 1 |
| code-server | 8080 | `codeserver` | VS Code in browser — remote dev access | 1 |
| OpenSSH | 22 | system | SSH jump host — backup to Pi | always |

> All four services are deployed in Phase 1 of the mac-server build. There are no future phases planned for this machine — it is a utility node, not a growth platform.

### Storage

| Path | Purpose | Notes |
|------|---------|-------|
| `/srv/forgejo` | Forgejo data directory | Repos, attachments, config |
| `/srv/samba/files` | General file share | Documents, backups |
| `/srv/samba/media` | Media share | Jellyfin source on genesis2 can also read from here |
| `/home/codeserver` | code-server workspace | Default workspace for remote editing |

> The external drive mounts at `/mnt/external`. Samba share paths bind into `/srv/samba/` from there. If the external drive is not connected, Samba shares are unavailable but all other services continue normally.

---

## 4. Service Architecture Notes

### Forgejo

Forgejo is a single Go binary. It requires no runtime beyond the binary itself. All lab repositories — network documentation, Ansible playbooks, config backups, scripts — are hosted here and push-mirrored to GitHub. The internal instance is the primary; GitHub is the backup.

mac-server Forgejo replaces the genesis2 VMID 240 entry, which is retired. The decision to host Forgejo here rather than genesis2 is documented in §6 Decisions Log.

Forgejo should be the **first service configured and the first repo committed** before any other lab work continues. Every subsequent build step — genesis2 LXC deployments, Cisco configs, network changes — should be committed here.

```
Suggested initial repos:
  jxstudios-homelab    ← main lab repo (already on GitHub)
  configs              ← Cisco running configs, Omada backups
```

### Samba / NFS

Samba provides SMB shares accessible from Windows, macOS, and Linux home devices on VLAN 10 (after network window). NFS is an option if all admin machines run Linux — Samba is the default for cross-platform compatibility.

The external drive should be formatted ext4 or XFS. Mount it by UUID in `/etc/fstab` — not by device path (`/dev/sdX`), which is not stable across reboots.

```bash
# Get UUID after formatting
sudo blkid /dev/sdb1

# /etc/fstab entry
UUID=<your-uuid>  /mnt/external  ext4  defaults,nofail  0  2
```

The `nofail` flag is important — if the external drive is not connected at boot, the system continues to start normally rather than hanging at the mount step.

### code-server

code-server provides a VS Code-compatible interface in the browser. It is the remote development environment for the lab — available over Tailscale from anywhere, accessible on the local network from any browser.

Access paths:
- Local network: `http://192.168.20.11:8080`
- Tailscale (remote): `http://<tailscale-ip>:8080`
- Future (optional): proxied via NPM as `code.jxstudios.dev`

code-server has built-in password authentication. The self-signed cert warning on first load is expected — either accept it in the browser or configure a proper cert via NPM later. Password auth is sufficient for this use case; no additional auth layer is needed.

code-server is configured with `/home/codeserver` as the default workspace but can open any path on the machine, including `/srv/forgejo` repos directly.

### SSH jump host

OpenSSH is already present on any Debian install. The only setup required is adding the lab's admin public keys to `/home/<user>/.ssh/authorized_keys` and confirming key-based auth works. Password auth can then be disabled.

mac-server as a jump host means: if the Pi is ever unreachable, SSH access to the rest of the lab still exists via mac-server. This is a backup, not the primary path.

---

## 5. Role in the Wider Lab

mac-server occupies the middle tier of the three-host lab architecture.

| Tier | Device | Role | Always-on |
|------|--------|------|-----------|
| 1 — Lightweight anchor | Pi 5 | DNS, Tailscale, MGMT utilities | Yes — no planned downtime |
| 2 — Utility node | mac-server | Git, NAS, code-server, jump host | Yes — no planned downtime |
| 3 — Heavy compute | genesis2 | Proxmox hypervisor, all LXCs and VMs | Planned maintenance windows |

mac-server services are specifically chosen because they should be reachable when genesis2 is down. Forgejo availability during genesis2 maintenance means configs and docs can always be committed. NAS availability means files are always accessible. code-server availability means remote editing is always possible. None of these should depend on genesis2 being healthy.

### Portfolio framing

mac-server is documented as part of the larger JXStudios home lab project, not as a standalone project. The value is in the architectural reasoning — why these services live here, what problem the tier separation solves, and how it integrates with the network segmentation and the wider genesis2 stack. This is the talking point, not the hardware.

---

## 6. Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| OS | Debian 12 headless | Stable, minimal, well-documented. No desktop overhead. |
| Service management | Native systemd | Three lightweight services with no inter-dependencies. No benefit to Docker. Fewer mental models during incident response. Consistent with Pi service management pattern. |
| Forgejo placement | mac-server, not genesis2 | genesis2 requires planned maintenance. Internal Git should be reachable during maintenance windows. Go binary runs fine on Core 2 Duo. VMID 240 on genesis2 retired. |
| NAS placement | mac-server | Always-on file access independent of genesis2 uptime. External drive sufficient for media and document storage at home lab scale. |
| code-server placement | mac-server | Always-on remote dev access. genesis2 code-server LXC (VMID 241, 192.168.20.41) reserved as a future option for editing genesis2-resident files directly — different use case. |
| SSH jump | mac-server (backup) | Pi is primary jump host. mac-server provides redundancy without additional config cost. |
| Network | Ethernet only | 2008 MacBook Broadcom Wi-Fi unreliable under Linux. Ethernet eliminates the problem entirely. |
| External drive format | ext4 | Simple, stable, well-supported under Debian. No ZFS overhead needed at this scale. |
| Hostname | mac-server.jxstudios.dev | Consistent with genesis2.jxstudios.dev naming convention. |
| IP | 192.168.20.11 | Infrastructure zone (.11–.19) — correct zone for physical hosts. .10 is genesis2. |
| Portfolio | Part of JXStudios lab project | mac-server alone is insufficient. As one node in a documented multi-host segmented lab, it supports the overall project narrative. |

---

## 7. Pending Items

| Item | Priority | Notes |
|------|----------|-------|
| Confirm MAC address | After Debian install | Update network_settings_register_populated.md |
| External drive selection | Before Samba setup | Format ext4, mount by UUID |
| code-server password | During setup | Store in password manager — do not commit to repo |
| Forgejo admin credentials | During setup | Store in password manager — do not commit to repo |
| GitHub mirror token | During Forgejo setup | Personal access token — store in password manager, add to .gitignore / env |
| Migrate main lab repo to internal Forgejo | After Forgejo confirmed healthy | Clone from GitHub, set as new origin, GitHub becomes push mirror |

---

*Document version 1.0 — Created 22/03/2026*  
*Next update: After Debian install session*
