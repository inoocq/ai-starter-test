# check_requirements.ps1: checks that everything this starter pack needs is installed (Windows).
#
# For each tool it prints OK, or what is missing with a link and the command that installs it.
# It installs something only if you answer "y" when asked. Run with -Check (or from Claude), it never installs.
#
# Usage (in PowerShell, from the starter-pack folder):
#   powershell -ExecutionPolicy Bypass -File scripts\check_requirements.ps1          # check, offer to install
#   powershell -ExecutionPolicy Bypass -File scripts\check_requirements.ps1 -Check   # check only
#
# Mac and Linux: use scripts/check_requirements.sh instead.

param([switch]$Check)

$ErrorActionPreference = 'Continue'
$checkOnly = $Check.IsPresent -or -not [Environment]::UserInteractive -or [Console]::IsInputRedirected
$missingRequired = $false
$script:installedSomething = $false

function Ok($msg)   { Write-Host "  [OK]      $msg" }
function Warn($msg) { Write-Host "  [WARNING] $msg" -ForegroundColor Yellow }
function Miss($msg) { Write-Host "  [MISSING] $msg" -ForegroundColor Red }
function Have($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# Asks before running the command; returns $true only if it ran.
function Offer-Install($what, $cmd) {
  Write-Host "            To install: $cmd"
  if ($script:checkOnly) { return $false }
  $answer = Read-Host "            Install $what now? [y/N]"
  if ($answer -match '^(y|yes)$') {
    Write-Host "            Running: $cmd"
    $script:installedSomething = $true
    $global:LASTEXITCODE = 0
    try { Invoke-Expression $cmd | Out-Host } catch { Write-Host "            The install failed: $_"; return $false }
    if ($LASTEXITCODE -ne 0) { Write-Host "            The install did not finish (code $LASTEXITCODE). Read the message above, or ask Claude about it."; return $false }
    return $true
  }
  Write-Host "            Skipped."
  return $false
}

$hasWinget = Have 'winget'
Write-Host "Checking what the starter pack needs..."
Write-Host ""

# 1. Claude (the app or the command-line tool)
Write-Host "1. Claude"
$desktop = (Test-Path (Join-Path $env:LOCALAPPDATA 'AnthropicClaude')) -or (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\Claude'))
if (-not $desktop) { try { $desktop = [bool](Get-AppxPackage -Name '*Claude*' -ErrorAction Stop) } catch { } }
if (Have 'claude') {
  Ok ("Claude Code command-line tool: " + (claude --version | Select-Object -First 1))
} elseif ($desktop) {
  Ok "Claude Desktop app is installed (use its Code tab to open this folder)"
} else {
  Miss "Claude: install the Claude Desktop app (it includes Claude Code in its Code tab)"
  Write-Host "            Download: https://claude.ai/download"
  $cmd = if ($hasWinget) { 'winget install --id Anthropic.ClaudeCode -e' } else { 'irm https://claude.ai/install.ps1 | iex' }
  if (-not (Offer-Install 'the Claude Code command-line tool' $cmd)) { $missingRequired = $true }
}

# 2. Git (keeps the history of your setup and backs it up)
Write-Host "2. Git"
if (Have 'git') {
  Ok (git --version)
} else {
  Miss "Git. Download: https://git-scm.com/download/win"
  if ($hasWinget) {
    if (-not (Offer-Install 'Git' 'winget install --id Git.Git -e')) { $missingRequired = $true }
  } else { $missingRequired = $true }
}

# 3. GitHub CLI (gets the repo, installs skills, drafts issues for the team)
Write-Host "3. GitHub CLI (gh)"
if (Have 'gh') {
  Ok (gh --version | Select-Object -First 1)
  gh auth status *> $null
  if ($LASTEXITCODE -eq 0) { Ok "signed in to GitHub" }
  else {
    Miss "not signed in to GitHub. Run: gh auth login   (choose GitHub.com, HTTPS, and sign in with a browser)"
    $missingRequired = $true
  }
  gh skill --help *> $null
  if ($LASTEXITCODE -eq 0) { Ok "gh skill is available (installs single skills in other AI tools)" }
  else { Warn "gh skill is not available in this gh version (optional). Update gh: https://cli.github.com" }
} else {
  Miss "GitHub CLI. Download: https://cli.github.com"
  if ($hasWinget) {
    if (-not (Offer-Install 'the GitHub CLI' 'winget install --id GitHub.cli -e')) { $missingRequired = $true }
  } else { $missingRequired = $true }
}

# 4. Billing trap: an API key in the environment makes Claude Code bill the API, not your plan
Write-Host "4. Billing"
if ($env:ANTHROPIC_API_KEY) {
  Warn "ANTHROPIC_API_KEY is set: Claude Code will bill that API key instead of your Claude plan."
  Write-Host "            Unless you want that, remove it: Settings > System > About > Advanced system settings > Environment Variables."
} else {
  Ok "no API key in the environment: Claude Code uses your Claude plan"
}

# 5. This folder
Write-Host "5. This folder"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ((Test-Path (Join-Path $repoRoot '.claude-plugin\marketplace.json')) -and (Test-Path (Join-Path $repoRoot 'plugins\starter\skills'))) {
  Ok "the starter pack is here: $repoRoot"
} else {
  Miss "the starter pack files are not next to this script. Get it with: gh repo clone inoocq/ai-starter-test"
  $missingRequired = $true
}
if ((Have 'git') -and (Test-Path (Join-Path $repoRoot '.git'))) {
  git -C $repoRoot check-ignore -q private/example.pdf
  if ($LASTEXITCODE -eq 0) { Ok "the private\ folder is excluded from git (confidential files stay on your computer)" }
  else { Warn "the private\ folder is NOT excluded from git: do not put confidential files there until this is fixed" }
}

Write-Host ""
if ($script:installedSomething) {
  Write-Host "Something was just installed. Close PowerShell, open a new one, and run this check again."
  exit 1
} elseif (-not $missingRequired) {
  Write-Host "All set. Open this folder in Claude and say: get me started"
  exit 0
} else {
  Write-Host "Something is missing (see [MISSING] above). Install it, then run this check again."
  exit 1
}
