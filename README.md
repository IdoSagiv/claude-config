# claude-config

Personal [Claude Code](https://claude.com/claude-code) configuration: permissions, statusline, plugins, MCP servers.

## Contents

- **`settings.json`** — permission allow/deny/ask rules, statusline hook, plugin and MCP server registrations
- **`statusline-command.sh`** — Python script rendering model, context bar, session cost, rate-limit countdowns, project, and git branch
- **`CLAUDE.md`** — global instructions loaded in every session
- **`commands/pr-review.md`** — `/pr-review <number> [repo]`: local review of a BitBucket PR, nothing posted
- **`hooks/pr-review-title.py`** — names a `/pr-review` session `pr-review-<number>[-<repo>]`
- **`install.sh`** — symlinks files into `~/.claude/` (backs up any existing files first), then optionally installs skills and the Bitbucket MCP server

## Statusline

```text
Opus 4.7 (1M) │ ████████████ 42% 420k/1.0M ⏱️ 12m 5s │ $3.47 │ 5h: 23% (3h14m) 7d: 67% (4d1h) │ claude-config │ main
```

Segments, left to right:

- **Model** — e.g. `Opus 4.7 (1M)`
- **Context bar** — fill proportional to window used; green < 65%, yellow 65–85%, red ≥ 85%
- **Percent used** and **tokens used / window size** (e.g. `420k/1.0M`)
- **⏱️ Session duration** — wall-clock since session start
- **Session cost** — total cost of the current session in USD (e.g. `$3.47`)
- **Rate limits** — 5-hour and 7-day usage percent, with countdown until reset (same color thresholds)
- **Project** — basename of the working directory
- **Git branch** — current branch, or short commit SHA in detached HEAD

Rate-limit, cost, and context segments are hidden when the underlying data isn't provided by Claude Code.

## Install

```bash
git clone https://github.com/IdoSagiv/claude-config.git
cd claude-config
./install.sh
```

Then restart Claude Code.

`install.sh` asks two optional questions:

- **Skills** — installs `find-skills`, `herdr` and `crit` with the [skills CLI](https://github.com/vercel-labs/skills). Needs `npx`.
- **Bitbucket MCP server** — clones and builds [mcp-server-bitbucket](https://github.com/IdoSagiv/mcp-server-bitbucket) next to this repo (override with `BITBUCKET_MCP_DIR`), prompts for an API token, email and workspace, and registers it at user scope. Needs `node`, `npm` and `claude`.

## Other MCP servers

Add these per project, from inside the project directory:

```bash
claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp
claude mcp add --transport sse hailo-docs <internal hailo-docs SSE URL>
```

Run `/mcp` in Claude Code to authenticate Atlassian.

## Uninstall

```bash
./install.sh --uninstall
```

Removes the symlinks only. Any `*.bak.*` backups created during install, skills and MCP servers are left in place.
