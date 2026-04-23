#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
CLAUDE_DIR="$HOME/.claude"

FILES=(
    "settings.json"
    "statusline-command.sh"
)

# ── Uninstall ────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
    echo "Uninstalling claude-config..."
    for f in "${FILES[@]}"; do
        target="$CLAUDE_DIR/$f"
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$REPO_DIR/$f" ]]; then
            rm -v "$target"
        else
            echo "Skipping $target (not a symlink to this repo)"
        fi
    done
    echo "Done. Backups (if any) remain at $CLAUDE_DIR/*.bak.*"
    exit 0
fi

# ── Install ──────────────────────────────────────────────────────────────────
echo "Installing claude-config from $REPO_DIR into $CLAUDE_DIR ..."

mkdir -p "$CLAUDE_DIR"

for f in "${FILES[@]}"; do
    src="$REPO_DIR/$f"
    target="$CLAUDE_DIR/$f"

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$src" ]]; then
            echo "  $f already linked — skipping"
            continue
        fi
        backup="${target}.bak.${TIMESTAMP}"
        mv -v "$target" "$backup"
    fi

    ln -sv "$src" "$target"
done

echo ""
echo "Done! Restart Claude Code to pick up changes."
