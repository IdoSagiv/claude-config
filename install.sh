#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
CLAUDE_DIR="$HOME/.claude"

FILES=(
    "settings.json"
    "statusline-command.sh"
    "CLAUDE.md"
    "hooks/pr-review-title.py"
    "commands/pr-review.md"
)

# "<github source> <skill name>", installed with the skills CLI (https://github.com/vercel-labs/skills)
SKILLS=(
    "vercel-labs/skills find-skills"
    "herdrdev/herdr herdr"
    "tomasz-tomczyk/crit crit"
)

BITBUCKET_MCP_REPO="https://github.com/IdoSagiv/mcp-server-bitbucket.git"
BITBUCKET_MCP_DIR="${BITBUCKET_MCP_DIR:-$(dirname "$REPO_DIR")/mcp-server-bitbucket}"

ask() {
    [[ -t 0 ]] || { echo "$1 Not interactive, skipping."; return 1; }
    local answer
    read -rp "$1 [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

require() {
    command -v "$1" >/dev/null || { echo "  '$1' not found, skipping."; return 1; }
}

install_skills() {
    require npx || return 0
    for entry in "${SKILLS[@]}"; do
        read -r source skill <<< "$entry"
        npx -y skills add "$source" --skill "$skill" --global --agent claude-code --yes
    done
}

install_bitbucket_mcp() {
    require node || return 0
    require npm || return 0
    require claude || return 0

    if [[ ! -d "$BITBUCKET_MCP_DIR" ]]; then
        git clone "$BITBUCKET_MCP_REPO" "$BITBUCKET_MCP_DIR"
    fi
    (cd "$BITBUCKET_MCP_DIR" && npm install && npm run build)

    local token email workspace
    read -rsp "  Bitbucket API token: " token
    echo
    [[ -n "$token" ]] || { echo "  No token given, skipping."; return 0; }
    read -rp "  Bitbucket user email [$(git config user.email || true)]: " email
    email="${email:-$(git config user.email || true)}"
    read -rp "  Default workspace [hailotech]: " workspace
    workspace="${workspace:-hailotech}"

    claude mcp remove bitbucket --scope user >/dev/null 2>&1 || true
    claude mcp add bitbucket --scope user \
        -e "BITBUCKET_TOKEN=$token" \
        -e "BITBUCKET_USER_EMAIL=$email" \
        -e "BITBUCKET_DEFAULT_WORKSPACE=$workspace" \
        -- "$(command -v node)" "$BITBUCKET_MCP_DIR/dist/index.js"
}

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
    echo "Skills and MCP servers are left in place."
    exit 0
fi

# ── Install ──────────────────────────────────────────────────────────────────
echo "Installing claude-config from $REPO_DIR into $CLAUDE_DIR ..."

mkdir -p "$CLAUDE_DIR"

for f in "${FILES[@]}"; do
    src="$REPO_DIR/$f"
    target="$CLAUDE_DIR/$f"
    mkdir -p "$(dirname "$target")"

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
if ask "Install skills (find-skills, herdr, crit)?"; then
    install_skills
fi

echo ""
if ask "Set up the Bitbucket MCP server?"; then
    install_bitbucket_mcp
fi

echo ""
echo "Done! Restart Claude Code to pick up changes."
