param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$ForceAgents
)

$ErrorActionPreference = "Stop"

$summary = @{
  skills_linked       = 0
  handbook_synced     = 0
  rules_synced        = 0
  opencode_generated  = 0
  agents_written      = 0
  ai_readme_written   = 0
}

$InfraPath = Join-Path $ProjectRoot ".ai\ai-infra"
if (!(Test-Path $InfraPath))
{
    throw "ai-infra submodule not found at $InfraPath. Run: git submodule update --init --recursive"
}

function Ensure-Dir($p)
{
    if (!(Test-Path $p))
    { New-Item -ItemType Directory -Path $p | Out-Null }
}

# Ensure project .ai folder and common subfolders
$ProjectAiDir = Join-Path $ProjectRoot ".ai"
Ensure-Dir $ProjectAiDir
Ensure-Dir (Join-Path $ProjectAiDir "handbook.local")
Ensure-Dir (Join-Path $ProjectAiDir "vendor")
Ensure-Dir (Join-Path $ProjectAiDir "cache")

# 0) Create .ai/README.md if missing (from template)
$AiReadmeOut  = Join-Path $ProjectAiDir "README.md"
$AiReadmeTmpl = Join-Path $InfraPath "project-templates\AI_README.md.tmpl"

if (!(Test-Path $AiReadmeOut) -and (Test-Path $AiReadmeTmpl))
{
    $projName = Split-Path $ProjectRoot -Leaf
    $content = Get-Content $AiReadmeTmpl -Raw
    $content = $content -replace "__PROJECT__", [Regex]::Escape($projName)
    # Undo regex escaping for plain replacement
    $content = $content -replace "\\", ""

    [System.IO.File]::WriteAllText($AiReadmeOut, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "OK: Created .ai/README.md"
    $summary.ai_readme_written = 1
}
elseif (Test-Path $AiReadmeOut)
{
    Write-Host "OK: .ai/README.md exists (not overwritten)."
}
else
{
    Write-Host "WARN: No AI_README template found at $AiReadmeTmpl"
}

# 1) Link skills to .claude/skills (Claude-standard for maximum compatibility)
$ClaudeDir = Join-Path $ProjectRoot ".claude"
$ClaudeSkills = Join-Path $ClaudeDir "skills"
$InfraSkills = Join-Path $InfraPath "skills"
Ensure-Dir $ClaudeDir

if (Test-Path $ClaudeSkills)
{
    try { Remove-Item $ClaudeSkills -Recurse -Force } catch {}
}

cmd /c mklink /J "$ClaudeSkills" "$InfraSkills" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "mklink failed with exit code $LASTEXITCODE" }
if (!(Test-Path $ClaudeSkills)) { throw "skills link not created: $ClaudeSkills" }

Write-Host "OK: Linked .claude/skills -> .ai/ai-infra/skills"
$summary.skills_linked = 1

# 1.5) Sync handbook to project .ai/handbook (copy, not link)
$InfraHandbook = Join-Path $InfraPath "handbook"
$ProjectHandbook = Join-Path $ProjectAiDir "handbook"

if (Test-Path $InfraHandbook)
{
    if (Test-Path $ProjectHandbook)
    {
        try { Remove-Item $ProjectHandbook -Recurse -Force } catch {}
    }
    Ensure-Dir $ProjectHandbook

    Copy-Item (Join-Path $InfraHandbook "*") $ProjectHandbook -Recurse -Force
    if (!(Test-Path $ProjectHandbook)) { throw "handbook sync failed: $ProjectHandbook" }

    Write-Host "OK: Synced .ai/handbook -> $ProjectHandbook"
    $summary.handbook_synced = 1
}
else
{
    Write-Host "WARN: No handbook found at $InfraHandbook"
}

# 2) Sync Trae rules to project root .rules
$InfraRules = Join-Path $InfraPath "rules\trae\.rules"
$ProjectRules = Join-Path $ProjectRoot ".rules"
if (Test-Path $InfraRules)
{
    Copy-Item $InfraRules $ProjectRules -Force
    Write-Host "OK: Synced .rules -> $ProjectRules"
    $summary.rules_synced = 1
}
else
{
    Write-Host "WARN: No Trae rules found at $InfraRules"
}

# 3) Generate opencode.json from mcp/servers.json
$ServersJson = Join-Path $InfraPath "mcp\servers.json"
$OpenCodeJson = Join-Path $ProjectRoot "opencode.json"

if (Test-Path $ServersJson)
{
    $servers = Get-Content $ServersJson -Raw | ConvertFrom-Json
    $mcpObj = @{}

    foreach ($s in $servers.servers)
    {
        if ($s.enabled -ne $false)
        {
            if ($s.type -eq "remote")
            {
                $mcpObj[$s.name] = @{ type = "remote"; url = $s.url; enabled = $true }
            }
            elseif ($s.type -eq "local")
            {
                $mcpObj[$s.name] = @{ type = "local"; command = $s.command; enabled = $true }
            }
        }
    }

    $out = @{ '$schema' = "https://opencode.ai/config.json"; mcp = $mcpObj } | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($OpenCodeJson, $out, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "OK: Generated opencode.json"
    $summary.opencode_generated = 1
}
else
{
    Write-Host "WARN: No servers.json found at $ServersJson"
}

# 4) Create/Update AGENTS.md (default: only create if missing)
$AgentsTmpl = Join-Path $InfraPath "project-templates\AGENTS.md.tmpl"
$AgentsOut = Join-Path $ProjectRoot "AGENTS.md"

if (!(Test-Path $AgentsTmpl))
{
    Write-Host "WARN: No AGENTS template found at $AgentsTmpl"
}
else
{
    if (!(Test-Path $AgentsOut))
    {
        Copy-Item $AgentsTmpl $AgentsOut -Force
        Write-Host "OK: Created AGENTS.md"
        $summary.agents_written = 1
    }
    elseif ($ForceAgents)
    {
        Copy-Item $AgentsTmpl $AgentsOut -Force
        Write-Host "OK: Updated AGENTS.md (ForceAgents)"
        $summary.agents_written = 1
    }
    else
    {
        Write-Host "OK: AGENTS.md exists (not overwritten). Use -ForceAgents to refresh from template."
    }
}

Write-Host ("SUMMARY " + ($summary.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" } -join " "))