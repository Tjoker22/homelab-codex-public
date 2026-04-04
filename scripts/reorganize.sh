#!/bin/bash
# ============================================================
# reorganize.sh  (v2 — updated)
# PROXMOX_HOMELAB — git-safe directory restructure
#
# Accounts for manual changes already made:
#   - containers/universal-prox-instance-template.md removed
#   - docs/universal-prox-instance-template.md present (git R)
#   - docs/network-setup-quick-guide-part-2.md present (untracked U)
#   - docs/network-design-document-template.md present (untracked U)
#
# Usage:
#   1. Place this file in your project root
#   2. Run: bash reorganize.sh
# ============================================================

set -e

# ── Colors ───────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[x]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}──── $1 ────${NC}"; }

# ── Helper: git mv only if source exists ─────────────────────
safe_git_mv() {
  local src="$1"
  local dst="$2"
  if [ -f "$src" ]; then
    git mv "$src" "$dst"
    log "Moved: $src → $dst"
  else
    warn "Skipped (not found): $src"
  fi
}

# ── Helper: git add untracked file if it exists ──────────────
safe_git_add() {
  local file="$1"
  if [ -f "$file" ]; then
    git add "$file"
    log "Staged untracked: $file"
  else
    warn "Skipped staging (not found): $file"
  fi
}

# ── Safety checks ────────────────────────────────────────────
[ ! -d ".git" ] && err "Not a git repo root. Run from your project root."

section "PRE-FLIGHT CHECK"

if ! git diff --quiet || ! git diff --cached --quiet; then
  warn "Staged or modified tracked files detected."
  warn "Stash or commit them first:"
  warn "  git stash && bash reorganize.sh && git stash pop"
fi

log "Starting reorganization (v2 — accounts for manual changes)..."

# ============================================================
# STEP 1 — Create new directory structure
# ============================================================
section "STEP 1 — Create directories"

mkdir -p docs/builds
mkdir -p docs/plans
mkdir -p docs/network
mkdir -p docs/templates
mkdir -p network/assets
mkdir -p scripts
mkdir -p configs/omada

log "Directories created."

# ============================================================
# STEP 2 — Stage the two manually-added untracked files (U)
#          These were added outside git so need staging first
# ============================================================
section "STEP 2 — Stage manually added untracked files"

safe_git_add "docs/network-setup-quick-guide-part-2.md"
safe_git_add "docs/network-design-document-template.md"

# ============================================================
# STEP 3 — docs/builds
# ============================================================
section "STEP 3 — docs/builds/"

safe_git_mv "docs/helios-build-guide.md"            "docs/builds/helios-build-guide.md"
safe_git_mv "docs/thoth-complete-build-guide.md"    "docs/builds/thoth-build-guide.md"
safe_git_mv "docs/genesis2-project-genesis-plan.md" "docs/builds/genesis-build-guide.md"

# ============================================================
# STEP 4 — docs/plans
# ============================================================
section "STEP 4 — docs/plans/"

safe_git_mv "docs/helios-plan.md"                          "docs/plans/helios-plan.md"
safe_git_mv "docs/project-summary-and-remaining-steps.md"  "docs/plans/project-summary.md"
safe_git_mv "docs/maintenance-window-updated.md"           "docs/plans/maintenance-window.md"
safe_git_mv "project_notes/raspi5-rebuild.md"              "docs/plans/raspi5-rebuild.md"

# Remove now-empty project_notes/ folder
if [ -d "project_notes" ] && [ -z "$(ls -A project_notes)" ]; then
  rmdir "project_notes"
  log "Removed empty folder: project_notes/"
else
  warn "project_notes/ not empty or missing — check manually"
fi

# ============================================================
# STEP 5 — docs/network
# ============================================================
section "STEP 5 — docs/network/"

safe_git_mv "docs/network-setup-quick-guide.md"        "docs/network/network-setup-guide.md"
safe_git_mv "docs/network-setup-quick-guide-part-2.md" "docs/network/network-setup-guide-part-2.md"
safe_git_mv "docs/pi-flat-network-rebuild.md"          "docs/network/pi-flat-network-rebuild.md"
safe_git_mv "docs/device-specs-list.md"                "docs/network/device-specs.md"

# ============================================================
# STEP 6 — docs/templates
# ============================================================
section "STEP 6 — docs/templates/"

# Double extension already fixed by user (.docx.md → .md)
safe_git_mv "docs/network-design-document-template.md"   "docs/templates/network-design-template.md"
safe_git_mv "docs/network-settings-register-template.md" "docs/templates/network-settings-template.md"
safe_git_mv "network/live-network-inventory-template.md" "docs/templates/live-network-inventory-template.md"

# universal-prox-instance-template.md was renamed into docs/ (git R)
# Move it to docs/templates/ where it logically belongs
if [ -f "docs/universal-prox-instance-template.md" ]; then
  git mv "docs/universal-prox-instance-template.md" "docs/templates/universal-prox-instance-template.md"
  log "Moved: docs/universal-prox-instance-template.md → docs/templates/"
fi

# ============================================================
# STEP 7 — network/ cleanup
# ============================================================
section "STEP 7 — network/"

safe_git_mv "network/network-design-document-populated.md"   "network/network-design-populated.md"
safe_git_mv "network/network-settings-register-populated.md" "network/network-settings-populated.md"
safe_git_mv "network/network-map-3-1-26.drawio"              "network/network-map.drawio"
safe_git_mv "network/network-map-3-1-26.png"                 "network/assets/network-map.png"

# ============================================================
# STEP 8 — configs/omada/ (group dated backup configs)
# ============================================================
section "STEP 8 — configs/omada/"

for f in configs/omada-backup-*.cfg; do
  [ -f "$f" ] && safe_git_mv "$f" "configs/omada/$(basename "$f")"
done

# ============================================================
# STEP 9 — scripts/ (host-setup from root)
# ============================================================
section "STEP 9 — scripts/"

safe_git_mv "host-setup.md" "scripts/host-setup.md"

# ============================================================
# STEP 10 — .gitkeep for any new empty dirs
# ============================================================
section "STEP 10 — .gitkeep housekeeping"

for dir in docs/builds docs/plans docs/network docs/templates network/assets scripts configs/omada; do
  if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    touch "$dir/.gitkeep"
    git add "$dir/.gitkeep"
    log "Added .gitkeep to empty dir: $dir"
  fi
done

# ============================================================
# STEP 11 — Create CHANGELOG.md if missing
# ============================================================
section "STEP 11 — CHANGELOG.md"

if [ ! -f "CHANGELOG.md" ]; then
  cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to this project will be documented here.

## [Unreleased]

### Changed
- Reorganized directory structure to domain-based layout
- Standardized filenames to kebab-case
- Split docs/ into builds/, plans/, network/, templates/
- Grouped omada backup configs into configs/omada/
- Moved host-setup.md to scripts/
- Removed dates from network map filename (history preserved in git)
- Merged project_notes/ into docs/plans/
EOF
  git add CHANGELOG.md
  log "Created CHANGELOG.md"
else
  warn "CHANGELOG.md already exists — skipping"
fi

# ============================================================
# STEP 12 — Single structured commit
# ============================================================
section "STEP 12 — Committing"

git commit -m "refactor: reorganize directory structure to domain-based layout

docs/ split into subdirectories:
  - docs/builds/     → helios, thoth, genesis build guides
  - docs/plans/      → helios-plan, project-summary, maintenance, raspi5
  - docs/network/    → setup guides (parts 1+2), pi-rebuild, device-specs
  - docs/templates/  → design, settings, inventory, prox-instance templates

network/:
  - Removed dates from network-map filenames (git tracks history)
  - Moved exported PNG → network/assets/
  - Simplified populated filenames

configs/:
  - Grouped omada backup .cfg files → configs/omada/

project_notes/:
  - Merged raspi5-rebuild.md → docs/plans/
  - Removed now-empty project_notes/ folder

root:
  - Moved host-setup.md → scripts/
  - Added CHANGELOG.md
  - Staged two previously untracked (U) files from manual changes"

# ============================================================
# DONE
# ============================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
log "Reorganization complete!"
echo ""
echo "  Verify structure:    git show --stat HEAD"
echo "  Full log:            git log --oneline"
echo "  Trace file history:  git log --follow docs/builds/helios-build-guide.md"
echo -e "${GREEN}============================================================${NC}"
