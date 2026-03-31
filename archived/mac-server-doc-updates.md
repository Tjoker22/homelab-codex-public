> **SUPERSEDED** — This document has been archived. helios (OR PC — Debian 12) replaced the MacBook Pro as the primary server. See `docs/helios_plan.md` and `docs/device_specs_list.md` for current platform details.

# JXStudios — Document Update Instructions
**Prepared:** 22/03/2026  
**Reason:** mac-server added to project, Forgejo moved from genesis2, roadmap updated

These are the exact changes needed across existing project files before the mac-server build begins. Apply all of these and commit together.

Suggested commit message:
```
[Docs] Add — mac-server plan, retire VMID 240, update registers and roadmap
```

---

## 1. CLAUDE.md

### Architecture Overview — add mac-server row

In the hardware stack table, add this row after the Raspberry Pi row:

```
| mac-server | 2008 MacBook — Debian 12 | Forgejo, NAS, code-server | 192.168.0.11 (temp) → 192.168.20.11 |
```

### IP and MAC Register — Network Devices — add row

```
| mac-server | 192.168.0.11 (temp) → 192.168.20.11 | 20 | [MAC — record after install] |
```

### VM/LXC Register — update Forgejo row

Change:
```
| 240 | .40 | forgejo | LXC | Forgejo internal Git | 3 |
```
To:
```
| 240 | — | forgejo | RETIRED | Moved to mac-server (native) | — |
```

### Phase Status — add mac-server phase

Add after the Phase 1b row:
```
| 1c | mac-server — Debian install + Forgejo + Samba + code-server | 🔄 Active — next session |
```

### Key Files — add mac-server plan

Add row:
```
| `docs/mac-server-plan.md` | mac-server planning document — hardware, services, decisions |
```

### Current State section — update the Active work line

Change:
```
**Active work:** Genesis2 Proxmox install and Phase 1b observability stack, running on flat network 192.168.0.0/24.
```
To:
```
**Active work:** mac-server Debian install and service setup (Phase 1c) — first build session. Genesis2 Proxmox install (Phase 1b) follows.
```

---

## 2. genesis2-project-genesis-plan.md

### VM and LXC Register — retire VMID 240

Change the Forgejo row from:
```
| 240 | .40 | forgejo | LXC | Forgejo internal Git | 3 |
```
To:
```
| ~~240~~ | ~~.40~~ | ~~forgejo~~ | RETIRED — LXC | Moved to mac-server as native Debian service | — |
```

### Service Stack — Phase 3 Developer Tooling — update Forgejo entry

Change:
```
| 240 | Forgejo | 192.168.20.40 | Internal Git — push mirror to GitHub. Deploy early so Genesis2 build is self-documented from here. |
```
To:
```
| — | Forgejo | mac-server 192.168.20.11:3000 | Moved to mac-server — native Debian service. See mac-server-plan.md. VMID 240 retired. |
```

### Decisions Log — add row

```
| Forgejo placement | mac-server (native), not genesis2 LXC | genesis2 has planned maintenance windows. Internal Git must be reachable during those windows. Core 2 Duo handles Go binary without issue. VMID 240 retired. |
```

---

## 3. network_settings_register_populated.md

### Section 1 — Hardware Inventory — add mac-server row

```
| 11 | mac-server | 2008 MacBook — Debian 12 | [Version] | Server Rack / Lab | Forgejo, NAS, code-server | 192.168.20.11 | Active — Phase 1c |
```

### Section 4 — IP Register — add mac-server rows

```
| mac-server (temp flat) | 192.168.0.11 | flat | [MAC — after install] | Static | 1c | Temporary — flat network during setup |
| mac-server (permanent) | 192.168.20.11 | 20 | [MAC — after install] | Static | 2 | Infrastructure zone — physical host |
```

Also retire the Forgejo LXC IP entry if it exists, or add a note on the genesis2 Forgejo entry:
```
| Forgejo LXC (genesis2) | RETIRED | 20 | N/A | — | — | Moved to mac-server 192.168.20.11:3000 — VMID 240 retired |
```

### Section 12 — Change Log — add entry

```
| 22/03/26 | [Time] | Project | Planning | mac-server added to project | Not planned | mac-server confirmed as always-on utility node — Forgejo, Samba, code-server, SSH jump | N/A | Architecture decision |
| 22/03/26 | [Time] | genesis2 | VM Register | VMID 240 Forgejo LXC retired | VMID 240 planned | Forgejo moved to mac-server native Debian service | N/A | mac-server architecture decision |
```

---

## 4. project-summary-and-remaining-steps.md

### Hardware table — add mac-server row

In the hardware summary table, add:
```
| mac-server | 2008 MacBook — Debian 12 | Forgejo, NAS, code-server | 192.168.20.11 | Active — Phase 1c |
```

### Key Decisions — add mac-server section

Add a new subsection under Key Decisions:

```
### Key Decisions Made — mac-server

**mac-server as always-on utility tier**
2008 MacBook running Debian 12 headless. Sits between the Pi (lightweight anchor) and genesis2 (heavy compute) as a permanent always-on utility node at 192.168.20.11. No Docker — all services native systemd.

**Services: Forgejo, Samba, code-server, SSH jump**
Four native systemd services. Forgejo replaces genesis2 VMID 240 (retired). NAS via Samba with external drive. code-server for always-on browser-based VS Code access. SSH jump as Pi backup.

**Portfolio: part of wider JXStudios lab project**
mac-server is documented as one node in the multi-host segmented lab, not a standalone project. The tier separation reasoning, architecture decisions, and documentation discipline are the portfolio narrative.
```

### Build Checklist — add mac-server Phase 1c

Add a new checklist section before the Genesis2 section:

```
### Phase 1c — mac-server Build Checklist

**Debian install:**
- [ ] Debian 12 minimal install — no desktop
- [ ] Static IP set to 192.168.0.11 (flat network temp)
- [ ] SSH key auth configured — password auth disabled
- [ ] All packages updated — apt update && apt full-upgrade
- [ ] Record MAC address — update network register

**Forgejo:**
- [ ] forgejo user created
- [ ] Forgejo binary downloaded and installed
- [ ] systemd unit file written and enabled
- [ ] Forgejo confirmed accessible at http://192.168.0.11:3000
- [ ] Admin account created — credentials in password manager
- [ ] Main lab repo migrated from GitHub to internal Forgejo
- [ ] GitHub push mirror configured from Forgejo
- [ ] Git commit — "Phase 1c — mac-server Forgejo baseline"

**Samba:**
- [ ] External drive formatted ext4, mounted by UUID in /etc/fstab (nofail)
- [ ] Samba installed — share paths created at /srv/samba/
- [ ] Shares confirmed accessible from admin PC and admin laptop
- [ ] Git commit — "Phase 1c — mac-server Samba shares"

**code-server:**
- [ ] code-server installed — systemd unit written and enabled
- [ ] Password set — stored in password manager, not committed to repo
- [ ] Accessible at http://192.168.0.11:8080
- [ ] Git commit — "Phase 1c — mac-server code-server"

**Final:**
- [ ] All four services confirmed healthy after reboot
- [ ] mac-server checklist marked complete in register
- [ ] Screenshot — all four services running (systemctl status)
- [ ] Git commit — "Phase 1c — mac-server baseline complete"
```

### Phase Status table — add Phase 1c and update sequencing

Add row:
```
| 1c | mac-server — Debian install + services | 🔄 Active — next session |
```

Update Phase 1b:
```
| 1b | Genesis2 — Proxmox install + ZFS + observability stack | 🔲 Not started — follows Phase 1c |
```

### Roadmap section — update sequencing note

Add a note at the top of the Future Phases section:
```
> **Build sequence confirmed 22/03/2026:** Phase 1c (mac-server) runs first. Genesis2 Proxmox baseline (Phase 1b) follows. Service deployment on genesis2 begins only after Forgejo is confirmed live on mac-server. Network window and Pi migration remain an independent track.
```

---

## 5. New file to add to repo

`docs/mac-server-plan.md` — the full planning document provided separately.

Place alongside `genesis2-project-genesis-plan.md` in the `docs/` folder.

---

*Instructions prepared 22/03/2026 — apply all changes before beginning mac-server build guide*
