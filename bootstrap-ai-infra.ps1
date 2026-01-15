param(
  [string]$Root = "D:\dev\ai-infra"
)

$ErrorActionPreference = "Stop"

function Ensure-Dir($p) {
  if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function Write-FileUtf8($path, $content) {
  $dir = Split-Path $path -Parent
  Ensure-Dir $dir
  # Windows PowerShell 5 uses UTF16 by default; force UTF8
  [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
}

# --- 0) Root ---
Ensure-Dir $Root

# --- 1) Directory skeleton ---
$dirs = @(
  "skills",
  "mcp\templates",
  "rules\trae",
  "project-templates",
  "scripts"
)

foreach ($d in $dirs) { Ensure-Dir (Join-Path $Root $d) }

# --- 2) Create P0+P1 skill folders ---
$skillNames = @(
  "product-prd-execution",
  "sveltekit-capacitor-static-build",
  "capacitor-workflow-guardrails",
  "guardian-core-contract",
  "guardian-runtime-android-foreground",
  "capacitor-plugin-bridge-pattern",
  "tower-runtime-http-sqlite",
  "notification-provider-email",
  "observability-diagnostics",
  "permissions-selfcheck-ux",
  "api-security-transport"
)

foreach ($name in $skillNames) {
  $skillDir = Join-Path $Root ("skills\" + $name)
  Ensure-Dir $skillDir
  $skillFile = Join-Path $skillDir "SKILL.md"
  if (!(Test-Path $skillFile)) {
    Write-FileUtf8 $skillFile @"
# Skill: $name

## Scope
- (Fill in) What this skill does for SafeHaven MVP.

## Out of scope
- (Fill in) What this skill must NOT do.

## Contracts
- (Fill in) Data structures, event names, error codes, file/dir boundaries.

## Workflow
- (Fill in) Required commands and forbidden actions.

## Acceptance checks
- (Fill in) How to verify correctness.

## Examples
- (Fill in) Minimal examples / pseudo-code.
"@
  }
}

# --- 3) MCP single source of truth (servers.json) ---
$serversJsonPath = Join-Path $Root "mcp\servers.json"
if (!(Test-Path $serversJsonPath)) {
  Write-FileUtf8 $serversJsonPath @"
{
  "servers": [
    {
      "name": "svelte",
      "type": "remote",
      "url": "https://mcp.svelte.dev/mcp",
      "enabled": true
    }
  ]
}
"@
}

# --- 4) Trae rules placeholder ---
$rulesPath = Join-Path $Root "rules\trae\.rules"
if (!(Test-Path $rulesPath)) {
  Write-FileUtf8 $rulesPath @"
# Trae .rules (project-level)
# Goal: keep agents from stepping on each other's areas and enforce Capacitor workflow.

- Never edit generated web assets under android/ or ios/ directly. Always run web build then cap sync.
- UI changes live under src/. Native runtime changes live under android/ (and optionally packages/guardian-* if you create them).
- Any change that affects Guardian Core must preserve stability when UI crashes.
- Prefer event-driven plugin APIs (notifyListeners) over polling.
"@
}

# --- 5) AGENTS.md template (project-level guidance) ---
$agentsTmplPath = Join-Path $Root "project-templates\AGENTS.md.tmpl"
if (!(Test-Path $agentsTmplPath)) {
  Write-FileUtf8 $agentsTmplPath @"
# SafeHaven - Agent Guidance

## Non-negotiables
- Guardian Core reliability > UI. UI may crash; Guardian Core must keep running.
- Capacitor workflow: web build -> cap sync -> run/open. Never hand-edit copied web assets in native projects.

## Key directories (suggested)
- src/ : SvelteKit UI
- android/ : Android native + Guardian runtime
- ios/ : iOS native (later)
- .claude/skills : linked from ai-infra

## Commands (update to your actual scripts)
- pnpm dev
- pnpm build:web
- pnpm cap:sync
- pnpm cap:android

## Acceptance (MVP)
- BLE disconnect triggers countdown; if not cancelled -> AlertEvent queued and sent to Tower.
- Weak/No network: queue persists and flushes on recovery.
- Tower stores to SQLite and sends Email successfully.
- Diagnostics exports recent logs + config summary.
"@
}

# --- 6) Install-to-project.ps1 (links skills + generates opencode.json + sync rules) ---
$installScriptPath = Join-Path $Root "scripts\install-to-project.ps1"
if (!(Test-Path $installScriptPath)) {
  Write-FileUtf8 $installScriptPath @"
param(
  [string]`$ProjectRoot = (Get-Location).Path
)

`$ErrorActionPreference = "Stop"

`$InfraPath = Join-Path `$ProjectRoot ".ai\ai-infra"
if (!(Test-Path `$InfraPath)) {
  throw "ai-infra submodule not found at `$InfraPath. Run: git submodule update --init --recursive"
}

function Ensure-Dir(`$p) { if (!(Test-Path `$p)) { New-Item -ItemType Directory -Path `$p | Out-Null } }

# 1) Link skills to .claude/skills (Claude-standard for maximum compatibility)
`$ClaudeDir = Join-Path `$ProjectRoot ".claude"
`$ClaudeSkills = Join-Path `$ClaudeDir "skills"
`$InfraSkills = Join-Path `$InfraPath "skills"
Ensure-Dir `$ClaudeDir

if (Test-Path `$ClaudeSkills) {
  try { Remove-Item `$ClaudeSkills -Recurse -Force } catch {}
}

cmd /c "mklink /J `"`$ClaudeSkills`" `"`$InfraSkills`"" | Out-Null
Write-Host "OK: Linked .claude/skills -> .ai/ai-infra/skills"

# 2) Sync Trae rules to project root .rules
`$InfraRules = Join-Path `$InfraPath "rules\trae\.rules"
`$ProjectRules = Join-Path `$ProjectRoot ".rules"
if (Test-Path `$InfraRules) {
  Copy-Item `$InfraRules `$ProjectRules -Force
  Write-Host "OK: Synced .rules -> `$ProjectRules"
} else {
  Write-Host "WARN: No Trae rules found at `$InfraRules"
}

# 3) Generate opencode.json from mcp/servers.json
`$ServersJson = Join-Path `$InfraPath "mcp\servers.json"
`$OpenCodeJson = Join-Path `$ProjectRoot "opencode.json"

if (Test-Path `$ServersJson) {
  `$servers = Get-Content `$ServersJson -Raw | ConvertFrom-Json
  `$mcpObj = @{}

  foreach (`$s in `$servers.servers) {
    if (`$s.enabled -ne `$false) {
      if (`$s.type -eq "remote") {
        `$mcpObj[`$s.name] = @{ type = "remote"; url = `$s.url; enabled = `$true }
      } elseif (`$s.type -eq "local") {
        `$mcpObj[`$s.name] = @{ type = "local"; command = `$s.command; enabled = `$true }
      }
    }
  }

  `$out = @{ '`$schema' = "https://opencode.ai/config.json"; mcp = `$mcpObj } | ConvertTo-Json -Depth 10
  [System.IO.File]::WriteAllText(`$OpenCodeJson, `$out, (New-Object System.Text.UTF8Encoding(`$false)))
  Write-Host "OK: Generated opencode.json"
} else {
  Write-Host "WARN: No servers.json found at `$ServersJson"
}

# 4) Create AGENTS.md if missing
`$AgentsTmpl = Join-Path `$InfraPath "project-templates\AGENTS.md.tmpl"
`$AgentsOut = Join-Path `$ProjectRoot "AGENTS.md"
if (!(Test-Path `$AgentsOut) -and (Test-Path `$AgentsTmpl)) {
  Copy-Item `$AgentsTmpl `$AgentsOut
  Write-Host "OK: Created AGENTS.md"
}
"@
}

# --- 7) Initialize git repo (if not already) ---
Push-Location $Root
try {
  if (!(Test-Path (Join-Path $Root ".git"))) {
    git init | Out-Null
    Write-Host "OK: git init"
  } else {
    Write-Host "OK: git repo already exists"
  }

  # Create a basic .gitignore
  $gitignore = Join-Path $Root ".gitignore"
  if (!(Test-Path $gitignore)) {
    Write-FileUtf8 $gitignore @"
# OS / Editors
.DS_Store
Thumbs.db
.vscode/
.zed/
.idea/

# Node
node_modules/

# Logs
*.log

# Local env
.env
.env.*
"@
    Write-Host "OK: .gitignore created"
  }

  # Optional initial commit if repo is new and clean
  git add -A | Out-Null
  $status = git status --porcelain
  if ($status) {
    git commit -m "chore: bootstrap ai-infra skeleton" | Out-Null
    Write-Host "OK: initial commit created"
  } else {
    Write-Host "OK: nothing to commit"
  }
}
finally {
  Pop-Location
}

Write-Host ""
Write-Host "DONE."
Write-Host "ai-infra created at: $Root"
Write-Host "Next: add remote (optional) and push, then add as submodule in SafeHaven."
