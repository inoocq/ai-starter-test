---
name: get-started
description: >-
  Placeholder for the setup skill of a starter pack: checks the tools, the GitHub sign-in, the plugin and the private folder, one step at a time. Use when the user says "get me started" or "check my setup".
---

# get-started (placeholder)

1. Run `scripts/check_requirements.sh --check` (Mac, Linux) or `scripts\check_requirements.ps1 -Check` (Windows) and report each line in plain words.
2. If `gh auth status` fails, run `gh auth login --web --hostname github.com --git-protocol https` in the background and give the user the one-time code and the link.
3. Check that `git check-ignore -q private/test.pdf` succeeds.
