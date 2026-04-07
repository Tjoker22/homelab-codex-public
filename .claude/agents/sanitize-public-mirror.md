# Agent: sanitize-public-mirror
# Purpose: Replay private repo history as sanitized public mirror
# Invoke: manually when ready to initialize or sync public repo
# Architect approved: yes

---

## Task Overview

Create and maintain a sanitized public mirror of homelab-codex at:
  git@github.com:[USERNAME]/homelab-codex-public.git

Replay all commits with sanitization applied, preserving commit messages
and timestamps. After initial replay, this agent handles incremental
syncs on demand.

---

## Repo Details

| | Private | Public |
|---|---|---|
| GitHub | git@github.com:[USERNAME]/homelab-codex.git | git@github.com:[USERNAME]/homelab-codex-public.git |
| Local (WSL/Linux) | /mnt/h/repos/homelab-codex | /mnt/h/repos/homelab-codex-public |
| Local (Windows) | H:/repos/homelab-codex | H:/repos/homelab-codex-public |

---

## Sanitization Rules

Apply these substitutions to every file before committing to public repo.

### String replacements:

| Find | Replace |
|------|---------|
| `[OWNER]` | `[OWNER]` |
| `[USERNAME]` | `[USERNAME]` |

### MAC addresses — regex pattern:
```
([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}
```
Replace all matches with `[MAC_REDACTED]`

### Do NOT redact:
- `JXStudios` — public-facing site name, safe to keep
- `jxstudios.dev` — public domain, safe to keep
- All `192.168.x.x` addresses — RFC 1918 private ranges, safe to keep
  and important to show — they demonstrate real network design work
- Credential placeholder rows containing `[your chosen username]` or
  `[your chosen password]` — already placeholders, leave as-is

---

## Exclusions

Never commit these to the public repo. Add to .gitignore on first run:

```
configs/omada/
*.cfg
```

All other files and directories are safe to include after sanitization.

---

## Phase 1 — Setup (run once before replay)

1. Confirm private repo exists at /mnt/h/repos/homelab-codex
   If not, clone it first:
   ```bash
   mkdir -p /mnt/h/repos
   cd /mnt/h/repos
   git clone git@github.com:[USERNAME]/homelab-codex.git
   ```

2. Initialize public repo locally and connect to remote:
   ```bash
   mkdir -p /mnt/h/repos/homelab-codex-public
   cd /mnt/h/repos/homelab-codex-public
   git init
   git remote add origin git@github.com:[USERNAME]/homelab-codex-public.git
   ```

3. Create .gitignore in public repo:
   ```
   configs/omada/
   *.cfg
   ```

4. Create README.md in public repo (see README template below)

---

## Phase 2 — Initial History Replay

Run this process to build the full sanitized commit history.

```bash
# From private repo — get full commit list oldest to newest
cd /mnt/h/repos/homelab-codex
git log --reverse --format="%H|%s|%aI" > /tmp/commit-list.txt
```

For each line in commit-list.txt:

```
HASH|commit message|timestamp
```

Perform these steps in order:

```bash
# 1. Checkout that commit in private repo
cd /mnt/h/repos/homelab-codex
git checkout [HASH]

# 2. Sync files to public repo (excluding omada configs)
rsync -av --delete \
  --exclude='.git' \
  --exclude='configs/omada/' \
  --exclude='*.cfg' \
  /mnt/h/repos/homelab-codex/ \
  /mnt/h/repos/homelab-codex-public/

# 3. Apply sanitization to all text files in public repo
cd /mnt/h/repos/homelab-codex-public

# Replace owner name
find . -not -path './.git/*' -type f \
  -exec sed -i 's/W\. Johann Huebschmann/[OWNER]/g' {} +

# Replace GitHub handle
find . -not -path './.git/*' -type f \
  -exec sed -i 's/[USERNAME]/[USERNAME]/g' {} +

# Replace MAC addresses
find . -not -path './.git/*' -type f \
  -exec sed -i -E \
  's/([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}/[MAC_REDACTED]/g' {} +

# 4. Stage all changes
git add -A

# 5. Commit with original message and timestamp
GIT_AUTHOR_DATE="[timestamp]" \
GIT_COMMITTER_DATE="[timestamp]" \
git commit -m "[original commit message]" || echo "Nothing to commit — skipping"
```

Repeat for every commit in the list.

After all commits replayed:

```bash
# Return private repo to HEAD
cd /mnt/h/repos/homelab-codex
git checkout main

# Push public repo
cd /mnt/h/repos/homelab-codex-public
git push -u origin main
```

---

## Phase 3 — Incremental Sync (all future runs)

When invoked after new private commits exist:

```bash
# Get last synced commit hash from public repo log
cd /mnt/h/repos/homelab-codex-public
LAST=$(git log --format="%s" | head -1)

# In private repo, find commits after that point
cd /mnt/h/repos/homelab-codex
git log --reverse --format="%H|%s|%aI" > /tmp/commit-list.txt
# Filter to only commits after LAST — replay those using Phase 2 process
```

Then push:
```bash
cd /mnt/h/repos/homelab-codex-public
git push origin main
```

---

## README.md Template

Use this as the README.md in the public repo root.
Do not mirror the private repo README — use this instead.

```markdown
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
```

---

## Verification Checklist

Before pushing to public remote, confirm:

```
☐  No real MAC addresses present — search for pattern XX:XX:XX
☐  No owner full name present — search for "Johann"
☐  No [USERNAME] references present
☐  configs/omada/ directory not present
☐  No *.cfg files present
☐  Commit count matches private repo
☐  Commit messages and timestamps preserved
☐  README.md is the public template, not the private one
☐  git log looks clean and readable
```

---

## Do Not

- Redact IP addresses
- Alter commit messages beyond sanitization substitutions
- Commit omada .cfg backup files
- Create GitHub repos or configure GitHub settings — owner does this manually
- Push until all commits replayed and verification checklist is complete
- Modify this agent file without architect instruction
