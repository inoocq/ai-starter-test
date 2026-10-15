# ai-starter-test

Public test fixture for a Claude Code "starter pack" workspace: one repository that is a Claude Code workspace, a plugin marketplace, and a source of skills. It exists so the install path can be tested on Windows and Mac with free GitHub runners.

Everything here is a placeholder except the install mechanism (`scripts/check_requirements.*`, `.gitignore`, the marketplace and plugin layout), which is synced from the private pack it tests. No personal or client content is in this repository.

## What the workflow checks (`.github/workflows/setup.yml`)

On `windows-latest` (and `macos-latest`):

1. A fresh HTTPS clone into an empty folder works and lands the workspace at the folder's top level.
2. The requirements check runs in Windows PowerShell 5.1 (the one every Windows PC has) and finds git and the GitHub CLI, and reports Claude as missing before it is installed.
3. Claude Code installs with the documented one-liner, and the requirements check then says "All set".
4. The plugin validates, the marketplace in this folder can be added, and the plugin installs and lists as enabled.
5. A trusted folder's `.claude/settings.json` registers its marketplace when a session starts.
6. `gh auth login --web` with no keyboard prints a one-time code and a link (so Claude can relay them) instead of waiting for input.
7. Git Bash and winget are present (reported).
