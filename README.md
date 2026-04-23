# claude-config

Personal [Claude Code](https://claude.com/claude-code) configuration: permissions, statusline, plugins, MCP servers.

## Contents

- **`settings.json`** — permission allow/deny/ask rules, statusline hook, plugin and MCP server registrations
- **`statusline-command.sh`** — Python script rendering model, context bar, rate-limit countdowns, project, and git branch
- **`install.sh`** — symlinks files into `~/.claude/` (backs up any existing files first)

## Statusline

```text
Opus 4.7 (1M) │ ████████████ 42% 420k/1.0M ⏱️ 12m 5s │ 5h: 23% (3h14m) 7d: 67% (4d1h) │ claude-config │ main
```

Segments, left to right:

- **Model** — e.g. `Opus 4.7 (1M)`
- **Context bar** — fill proportional to window used; green < 65%, yellow 65–85%, red ≥ 85%
- **Percent used** and **tokens used / window size** (e.g. `420k/1.0M`)
- **⏱️ Session duration** — wall-clock since session start
- **Rate limits** — 5-hour and 7-day usage percent, with countdown until reset (same color thresholds)
- **Project** — basename of the working directory
- **Git branch** — current branch, or short commit SHA in detached HEAD

Rate-limit and context segments are hidden when the underlying data isn't provided by Claude Code.

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
