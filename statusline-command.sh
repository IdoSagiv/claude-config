#!/usr/bin/env python3
import json, sys, subprocess, os, time

data = json.load(sys.stdin)

model = data.get('model', {}).get('display_name', 'unknown')
session_name = data.get('session_name', '') or ''
project_dir = data.get('workspace', {}).get('project_dir', '')
ctx = data.get('context_window', {})
pct = int(ctx.get('used_percentage', 0) or 0)
ctx_size = int(ctx.get('context_window_size', 200000) or 200000)
usage = ctx.get('current_usage') or {}
ctx_used = int(usage.get('input_tokens', 0) or 0) + int(usage.get('cache_creation_input_tokens', 0) or 0) + int(usage.get('cache_read_input_tokens', 0) or 0)

# ANSI colors
RESET       = '\033[0m'
BOLD        = '\033[1m'
DIM         = '\033[2m'
CYAN        = '\033[36m'
BRIGHT_CYAN = '\033[96m'
GREEN       = '\033[32m'
YELLOW      = '\033[33m'
RED         = '\033[31m'
BRIGHT_RED  = '\033[91m'
BLUE        = '\033[34m'
MAGENTA     = '\033[35m'
WHITE       = '\033[37m'

# Progress bar — uses █ for both filled and empty (different colors) for uniform height
BAR_WIDTH = 12
BLOCK = '\u2588'  # █
DIM_FG = '\033[90m'  # dark gray for empty portion

filled_cells = round(pct * BAR_WIDTH / 100.0)
if filled_cells > BAR_WIDTH:
    filled_cells = BAR_WIDTH
empty_cells = BAR_WIDTH - filled_cells

if pct >= 85:
    bar_color = BRIGHT_RED
    pct_color = BRIGHT_RED + BOLD
elif pct >= 65:
    bar_color = YELLOW
    pct_color = YELLOW
else:
    bar_color = GREEN
    pct_color = GREEN

bar_str = f"{bar_color}{BLOCK * filled_cells}{RESET}{DIM_FG}{BLOCK * empty_cells}{RESET}"

# Format tokens
def fmt(t):
    if t >= 1_000_000:
        return f"{t / 1_000_000:.1f}M"
    elif t >= 1_000:
        return f"{t / 1_000:.0f}k"
    return str(t)

# Git branch
branch = ''
try:
    branch = subprocess.check_output(
        ['git', '-C', project_dir, '--no-optional-locks', 'symbolic-ref', '--short', 'HEAD'],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
except Exception:
    try:
        branch = subprocess.check_output(
            ['git', '-C', project_dir, '--no-optional-locks', 'rev-parse', '--short', 'HEAD'],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
    except Exception:
        pass

# Project name
project = os.path.basename(project_dir) if project_dir else ''

# Separators
SEP  = f"{DIM} \u2502 {RESET}"   # │  dim vertical bar

# Build output
parts = []
parts.append(f"{BRIGHT_CYAN}{BOLD}{model}{RESET}")

# Session duration from cost.total_duration_ms
duration_ms = int((data.get('cost', {}) or {}).get('total_duration_ms', 0) or 0)
duration_s = duration_ms // 1000
d_hours, d_rem = divmod(duration_s, 3600)
d_mins, d_secs = divmod(d_rem, 60)
if d_hours > 0:
    duration_str = f"{d_hours}h {d_mins}m {d_secs}s"
elif d_mins > 0:
    duration_str = f"{d_mins}m {d_secs}s"
else:
    duration_str = f"{d_secs}s"

ctx_label = f"{pct_color}{pct}%{RESET}"
ctx_tokens = f"{DIM}{fmt(ctx_used)}/{fmt(ctx_size)}{RESET}"
parts.append(f"{bar_str} {ctx_label} {ctx_tokens} ⏱️ {DIM}{duration_str}{RESET}")

# Rate limits (5-hour and 7-day usage)
def usage_color(p):
    if p >= 85:
        return BRIGHT_RED + BOLD
    elif p >= 65:
        return YELLOW
    return GREEN

def fmt_countdown(resets_at):
    remaining = max(0, int(resets_at - time.time()))
    days, rem = divmod(remaining, 86400)
    hours, rem = divmod(rem, 3600)
    mins = rem // 60
    if days > 0:
        return f"{days}d{hours}h"
    elif hours > 0:
        return f"{hours}h{mins}m"
    else:
        return f"{mins}m"

rate_limits = data.get('rate_limits') or {}
five_hour = rate_limits.get('five_hour') or {}
seven_day = rate_limits.get('seven_day') or {}
five_pct = five_hour.get('used_percentage')
seven_pct = seven_day.get('used_percentage')

if five_pct is not None or seven_pct is not None:
    rl_parts = []
    if five_pct is not None:
        p = round(five_pct)
        s = f"{usage_color(p)}5h: {p}%{RESET}"
        resets = five_hour.get('resets_at')
        if resets:
            s += f" {DIM}({fmt_countdown(resets)}){RESET}"
        rl_parts.append(s)
    if seven_pct is not None:
        p = round(seven_pct)
        s = f"{usage_color(p)}7d: {p}%{RESET}"
        resets = seven_day.get('resets_at')
        if resets:
            s += f" {DIM}({fmt_countdown(resets)}){RESET}"
        rl_parts.append(s)
    parts.append(' '.join(rl_parts))

if project:
    parts.append(f"{WHITE}{BOLD}{project}{RESET}")

if branch:
    parts.append(f"{MAGENTA}{branch}{RESET}")


print(SEP.join(parts))
