#!/usr/bin/env bash
# check_requirements.sh: checks that everything this starter pack needs is installed (Mac and Linux).
#
# For each tool it prints OK, or what is missing with a link and the command that installs it.
# It installs something only if you answer "y" when asked. Run without a terminal (for example
# from Claude), it never installs: it only reports.
#
# Usage:  bash scripts/check_requirements.sh            # check, and offer to install what is missing
#         bash scripts/check_requirements.sh --check    # check only, never offer to install
#
# Windows: use scripts/check_requirements.ps1 instead.

set -u

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1
[ -t 0 ] || CHECK_ONLY=1   # no keyboard attached: never install

MISSING_REQUIRED=0
INSTALLED_SOMETHING=0
OS="$(uname -s)"

say()  { printf '%s\n' "$*"; }
ok()   { printf '  [OK]      %s\n' "$*"; }
warn() { printf '  [WARNING] %s\n' "$*"; }
miss() { printf '  [MISSING] %s\n' "$*"; }

# offer_install <description> <command>: asks before running the command.
offer_install() {
  local what="$1" cmd="$2"
  say "            To install: $cmd"
  if [ "$CHECK_ONLY" -eq 1 ]; then return 1; fi
  printf '            Install %s now? [y/N] ' "$what"
  local answer; read -r answer
  case "$answer" in
    y|Y|yes|YES)
      say "            Running: $cmd"
      INSTALLED_SOMETHING=1
      if bash -c "$cmd"; then return 0; fi
      say "            The install did not finish. Read the message above, or ask Claude about it."
      return 1 ;;
    *) say "            Skipped."; return 1 ;;
  esac
}

have() { command -v "$1" >/dev/null 2>&1; }

pkg_cmd() {  # the package-manager command for a tool, or empty
  local brew_name="$1" apt_name="$2"
  if [ "$OS" = "Darwin" ] && have brew; then echo "brew install $brew_name"
  elif have apt-get; then echo "sudo apt-get install -y $apt_name"
  else echo ""; fi
}

say "Checking what the starter pack needs..."
say ""

# 1. Claude (the app or the command-line tool)
say "1. Claude"
if have claude; then
  ok "Claude Code command-line tool: $(claude --version 2>/dev/null | head -1)"
elif [ "$OS" = "Darwin" ] && { [ -d "/Applications/Claude.app" ] || [ -d "$HOME/Applications/Claude.app" ]; }; then
  ok "Claude Desktop app is installed (use its Code tab to open this folder)"
else
  miss "Claude: install the Claude Desktop app (it includes Claude Code in its Code tab)"
  say "            Download: https://claude.ai/download"
  offer_install "the Claude Code command-line tool" "curl -fsSL https://claude.ai/install.sh | bash" \
    || MISSING_REQUIRED=1
fi

# 2. Git (keeps the history of your setup and backs it up)
say "2. Git"
if have git && { [ "$OS" != "Darwin" ] || xcode-select -p >/dev/null 2>&1 || [ "$(command -v git)" != "/usr/bin/git" ]; }; then
  ok "$(git --version)"
else
  miss "Git. About: https://git-scm.com/downloads"
  cmd="$(pkg_cmd git git)"
  if [ "$OS" = "Darwin" ] && [ -z "$cmd" ]; then cmd="xcode-select --install"; fi
  if [ -n "$cmd" ]; then offer_install "Git" "$cmd" || MISSING_REQUIRED=1; else MISSING_REQUIRED=1; fi
fi

# 3. GitHub CLI (gets the repo, installs skills, drafts issues for the team)
say "3. GitHub CLI (gh)"
if have gh; then
  ok "$(gh --version | head -1)"
  if gh auth status >/dev/null 2>&1; then
    ok "signed in to GitHub"
  else
    miss "not signed in to GitHub. Run: gh auth login   (choose GitHub.com, HTTPS, and sign in with a browser)"
    MISSING_REQUIRED=1
  fi
  if gh skill --help >/dev/null 2>&1; then
    ok "gh skill is available (installs single skills in other AI tools)"
  else
    warn "gh skill is not available in this gh version (optional). Update gh: https://cli.github.com"
  fi
else
  miss "GitHub CLI. About: https://cli.github.com"
  cmd="$(pkg_cmd gh gh)"
  if [ -n "$cmd" ]; then offer_install "the GitHub CLI" "$cmd" || MISSING_REQUIRED=1; else MISSING_REQUIRED=1; fi
fi

# 4. Billing trap: an API key in the environment makes Claude Code bill the API, not your plan
say "4. Billing"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  warn "ANTHROPIC_API_KEY is set: Claude Code will bill that API key instead of your Claude plan."
  say "            Unless you want that, remove it from your shell profile (~/.zshrc or ~/.bashrc)."
else
  ok "no API key in the environment: Claude Code uses your Claude plan"
fi

# 5. This folder
say "5. This folder"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ] && [ -d "$REPO_ROOT/plugins/starter/skills" ]; then
  ok "the starter pack is here: $REPO_ROOT"
else
  miss "the starter pack files are not next to this script. Get it with: gh repo clone inoocq/ai-starter-test"
  MISSING_REQUIRED=1
fi
if have git && [ -d "$REPO_ROOT/.git" ]; then
  if git -C "$REPO_ROOT" check-ignore -q private/example.pdf; then
    ok "the private/ folder is excluded from git (confidential files stay on your computer)"
  else
    warn "the private/ folder is NOT excluded from git: do not put confidential files there until this is fixed"
  fi
fi

say ""
if [ "$INSTALLED_SOMETHING" -eq 1 ]; then
  say "Something was just installed. Close this terminal, open a new one, and run this check again."
  exit 1
elif [ "$MISSING_REQUIRED" -eq 0 ]; then
  say "All set. Open this folder in Claude and say: get me started"
  exit 0
else
  say "Something is missing (see [MISSING] above). Install it, then run this check again."
  exit 1
fi
