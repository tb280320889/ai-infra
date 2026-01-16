param(
    [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

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
{ throw "skills link not created: $ClaudeSkills" 
}Write-Host "OK: Linked .claude/skills -> .ai/ai-infra/skills"

# 2) Sync Trae rules to project root .rules
$InfraRules = Join-Path $InfraPath "rules\trae\.rules"
$ProjectRules = Join-Path $ProjectRoot ".rules"
if (Test-Path $InfraRules)
{
    Copy-Item $InfraRules $ProjectRules -Force
    Write-Host "OK: Synced .rules -> $ProjectRules"
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
} else
{
    Write-Host "WARN: No servers.json found at $ServersJson"
}

# 4) Create AGENTS.md if missing
$AgentsTmpl = Join-Path $InfraPath "project-templates\AGENTS.md.tmpl"
$AgentsOut = Join-Path $ProjectRoot "AGENTS.md"
if (!(Test-Path $AgentsOut) -and (Test-Path $AgentsTmpl))
{
    Copy-Item $AgentsTmpl $AgentsOut
    Write-Host "OK: Created AGENTS.md"
}
