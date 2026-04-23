# claude-config

Personal [Claude Code](https://claude.com/claude-code) configuration: permissions, statusline, plugins, MCP servers.

## Contents

- **`settings.json`** — permission allow/deny/ask rules, statusline hook, plugin and MCP server registrations
- **`statusline-command.sh`** — Python script rendering model, context bar, rate-limit countdowns, project, and git branch
- **`install.sh`** — symlinks files into `~/.claude/` (backs up any existing files first)

## Install

```bash
git clone https://github.com/IdoSagiv/claude-config.git
cd claude-config
./install.sh
```

Then restart Claude Code.

## Uninstall

```bash
./install.sh --uninstall
```

Removes the symlinks only. Any `*.bak.*` backups created during install are left in place.
