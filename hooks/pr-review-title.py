#!/usr/bin/env python3
"""UserPromptSubmit hook: name the session pr-review-<number>-<repo> for /pr-review."""
import json
import re
import subprocess
import sys

DEFAULT_REPO = "platform-sw"


def repo_from_origin(cwd):
    try:
        url = subprocess.run(["git", "-C", cwd, "remote", "get-url", "origin"],
                             capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None
    slug = url.rstrip("/").rsplit("/", 1)[-1].rsplit(":", 1)[-1]
    return slug.removesuffix(".git") or None


def main():
    hook_input = json.load(sys.stdin)
    match = re.match(r"\s*/pr-review\s+#?(\d+)(?:\s+(\S+))?", hook_input.get("prompt", ""))
    if not match:
        return
    number, repo = match.groups()
    repo = repo or repo_from_origin(hook_input.get("cwd", ".")) or DEFAULT_REPO
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "sessionTitle": f"pr-review-{number}-{repo}",
    }}))


if __name__ == "__main__":
    main()
