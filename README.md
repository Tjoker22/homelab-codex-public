# homelab-codex

Personal home lab documentation and infrastructure project — sanitized
public mirror of my private working repository.

## What This Covers

- Multi-VLAN segmented network design (TP-Link Omada + Cisco Catalyst)
- Proxmox hypervisor setup and VM/LXC planning
- Bare-metal Linux builds (Debian, i3 window manager)
- Raspberry Pi network services (Pi-hole, Tailscale)
- Service deployments: Forgejo, Jellyfin, Nginx Proxy Manager, code-server
- Full infrastructure documentation and change management practices

## Repo Structure

| Directory | Contents |
|-----------|----------|
| `docs/builds/` | Step-by-step build guides per machine |
| `docs/plans/` | Project planning and phase tracking |
| `docs/network/` | Network setup guides |
| `docs/notes/` | Working notes per project |
| `docs/templates/` | Reusable doc templates |
| `network/` | VLAN design, IP register, firewall rules, network map |
| `scripts/` | Setup and automation scripts |
| `configs/` | Cisco IOS configs (omada configs excluded) |
| `.claude/agents/` | Claude Code agent definitions |

## Status

Active — updated as work progresses. Commit history mirrors the
private repo timeline.
