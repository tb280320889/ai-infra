param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$ForceAgents
)

$ErrorActionPreference = "Stop"

# install summary flags (machine-readable)
$skills_linked = 0
$handbook_synced = 0
$rules_synced = 0
$opencode_generated = 0
$agents_written = 0


$InfraPath = Join-Path $ProjectRoot ".ai\ai-infra"
if (!(Test-Path $InfraPath))
{
    throw "ai-infra submodule not found at $InfraPath. Run: git submodule update --init --recursive"
}

function Ensure-Dir($p)
{ if (!(Test-Path $p))
    { New-Item -ItemType Directory -Path $p | Out-Null
    }
}

# 1) Link skills to .claude/skills (Claude-standard for maximum compatibility)
$ClaudeDir = Join-Path $ProjectRoot ".claude"
$ClaudeSkills = Join-Path $ClaudeDir "skills"
$InfraSkills = Join-Path $InfraPath "skills"
Ensure-Dir $ClaudeDir

if (Test-Path $ClaudeSkills)
{
    try
    { Remove-Item $ClaudeSkills -Recurse -Force
    } catch
    {
    }
}

cmd /c mklink /J "$ClaudeSkills" "$InfraSkills" | Out-Null
if ($LASTEXITCODE -ne 0)
{ throw "mklink failed with exit code $LASTEXITCODE"
}
if (!(Test-Path $ClaudeSkills))
{
    throw "skills link not created: $ClaudeSkills"
}

$skills_linked = 1
Write-Host "OK: Linked .claude/skills -> .ai/ai-infra/skills"
$handbook_synced = 1

# 1.5) Sync handbook to project .ai/handbook (copy, not link)
$ProjectAiDir = Join-Path $ProjectRoot ".ai"
$InfraHandbook = Join-Path $InfraPath "handbook"
$ProjectHandbook = Join-Path $ProjectAiDir "handbook"

Ensure-Dir $ProjectAiDir

if (Test-Path $InfraHandbook)
{
    # remove old synced handbook (keep user's local notes elsewhere, e.g. .ai/handbook.local)
    if (Test-Path $ProjectHandbook)
    {
        try
        { Remove-Item $ProjectHandbook -Recurse -Force
        } catch
        {
        }
    }
    Ensure-Dir $ProjectHandbook

    Copy-Item (Join-Path $InfraHandbook "*") $ProjectHandbook -Recurse -Force
    if (!(Test-Path $ProjectHandbook))
    { throw "handbook sync failed: $ProjectHandbook"
    }

    Write-Host "OK: Synced .ai/handbook -> $ProjectHandbook"
} else
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
    $rules_synced = 1
} else
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
            } elseif ($s.type -eq "local")
            {
                $mcpObj[$s.name] = @{ type = "local"; command = $s.command; enabled = $true }
            }
        }
    }

    $out = @{ '$schema' = "https://opencode.ai/config.json"; mcp = $mcpObj } | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($OpenCodeJson, $out, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "OK: Generated opencode.json"
    $opencode_generated = 1
} else
{
    Write-Host "WARN: No servers.json found at $ServersJson"
}

# 4) Create/Update AGENTS.md (default: only create if missing)
$AgentsTmpl = Join-Path $InfraPath "project-templates\AGENTS.md.tmpl"
$AgentsOut = Join-Path $ProjectRoot "AGENTS.md"

if (!(Test-Path $AgentsTmpl))
{
    Write-Host "WARN: No AGENTS template found at $AgentsTmpl"
} else
{
    if (!(Test-Path $AgentsOut))
    {
        Copy-Item $AgentsTmpl $AgentsOut -Force
        Write-Host "OK: Created AGENTS.md"
        $agents_written = 1
    } elseif ($ForceAgents)
    {
        Copy-Item $AgentsTmpl $AgentsOut -Force
        Write-Host "OK: Updated AGENTS.md (ForceAgents)"
        $agents_written = 1
    } else
    {
        Write-Host "OK: AGENTS.md exists (not overwritten). Use -ForceAgents to refresh from template."
    }
}

Write-Host ("SUMMARY skills_linked={0} handbook_synced={1} rules_synced={2} opencode_generated={3} agents_written={4}" -f `
        $skills_linked, $handbook_synced, $rules_synced, $opencode_generated, $agents_written)
