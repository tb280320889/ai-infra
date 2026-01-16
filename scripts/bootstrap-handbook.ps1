param(
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p)
{
    if (!(Test-Path $p))
    { New-Item -ItemType Directory -Path $p | Out-Null 
    }
}

function Write-Utf8NoBom([string]$path, [string]$content)
{
    $dir = Split-Path $path -Parent
    Ensure-Dir $dir
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
}

$handbookRoot = Join-Path $RepoRoot "handbook"
Ensure-Dir $handbookRoot
Ensure-Dir (Join-Path $handbookRoot "tooling")
Ensure-Dir (Join-Path $handbookRoot "rules")
Ensure-Dir (Join-Path $handbookRoot "templates")

Write-Utf8NoBom (Join-Path $handbookRoot "README.md") @"
# AI Infra Handbook

这份手册属于 ai-infra（跨项目复用）。每次执行 install-to-project.ps1，会把本目录同步到项目的 `.ai/handbook/`。

建议：
- 不要在项目的 `.ai/handbook/` 里做长期修改（会被覆盖）。
- 项目特有内容放在项目仓库的 `docs/`（例如 PRD / ADR / contracts / acceptance）。
- 若你需要个人笔记，放在项目的 `.ai/handbook.local/`（不被同步覆盖）。
"@

Write-Utf8NoBom (Join-Path $handbookRoot "00-sop-overview.md") @"
# 00 SOP Overview（独立开发 + AI 协同）

目标：你（总指挥）掌控需求与验收；IDE 内 agent/模型负责局部实现、测试、生成证据。

三条硬原则：
1) 任何改动必须可验收：卡片里要有 DoD（Definition of Done）和 Evidence（证据）。
2) 生命链路优先：后台存活、断联检测、幂等上报、通知可达性 > UI 完整性。
3) 小步快跑：一张卡最好 0.5–2 天完成；超出就拆卡。

项目内“产品事实”应该放哪里：
- PRD / user journey / failure-modes / ADR / contracts / acceptance：放项目仓库 docs/ 下并走 git 版本。
- ai-infra 只沉淀：SOP、工具手册、通用 rules/skills 模板与执行规范。
"@

Write-Utf8NoBom (Join-Path $handbookRoot "01-workflow-loop.md") @"
# 01 Workflow Loop（每次迭代固定循环）

每次迭代只推进一张卡（WIP=1，最多 2）。

Step 0：选卡
- 从看板 Ready 选 1 张 P0/P1 卡进 In Progress
- 写完整：Why（对应旅程/章节）、Touches（改哪些目录）、DoD、Risks

Step 1：约束 AI 输出格式（强制）
- 变更文件清单（路径）
- 每个文件改动要点
- 风险点
- 自测/验收步骤（命令 + 手动）
- 回滚方式（revert / checkout）

Step 2：实现（小步提交）
- 避免跨层大改；跨 UI/Native/DB 就拆卡
- 任何涉及 Capacitor：必须遵守 build -> cap sync -> run/open

Step 3：验收（对照 DoD）
- DoD 没过不能进 Review
- Evidence 必填：日志/截图/录屏/命令输出

Step 4：复盘写回
- 新的坑：写进 failure-modes 或 setup 文档
- AI 反复犯错：把约束补进 rules / skill / handbook

Step 5：收尾
- 卡片状态：In Progress -> Review -> Done
- Done 之前必须有 Evidence
"@

Write-Utf8NoBom (Join-Path $handbookRoot "02-ai-usage-rules.md") @"
# 02 AI Usage Rules（给 IDE 内 agent/模型的硬约束）

必须遵守：
- 任何改动先说明会改哪些文件（路径列表）
- 改动后必须给出自测方式与验收步骤
- 必须给出回滚方案（如何撤销）
- Capacitor 工作流固定：web build -> cap sync -> run/open
- 禁止手改：android/ 内复制的 web assets（assets/public 等），只能通过 build+sync 生成

推荐输出模板（你可以直接粘给 agent）：
1) Files to change:
- path1
- path2
2) What changes:
- ...
3) Risks:
- ...
4) How to test:
- commands
- manual steps
5) Rollback:
- git revert ...
- git checkout ...

禁止行为：
- 一次性大重构跨多个层（UI + Native + DB）且无拆分计划
- 未经说明修改 build 产物或复制目录
- 修改安全敏感字段（token/secret）且未说明脱敏与存储策略
"@

Write-Utf8NoBom (Join-Path $handbookRoot "03-quality-gates.md") @"
# 03 Quality Gates（进入 Review / Done 的门禁）

进入 Review 前：
- DoD 已写清且可执行
- 本地至少跑过一次关键流程（或给出为什么无法跑）
- 变更范围与目录边界清楚（Touches）

进入 Done 前：
- Evidence 已提供（截图/日志/录屏/命令输出）
- 失败分支至少覆盖 1–2 个（权限/弱网/离线队列/幂等）
- 若涉及协议/schema：同时更新项目 docs/contracts 或 ADR（在项目仓库里）
"@

Write-Utf8NoBom (Join-Path $handbookRoot "tooling\opencode.md") @"
# Tooling: OpenCode

- opencode.json 由 ai-infra 的 install-to-project.ps1 生成（项目根）
- MCP servers 配置来源：ai-infra/mcp/servers.json
- 推荐：在项目根使用终端调用（而不是全局安装）以保证版本一致

建议实践：
- 遇到 UI/路由/组件：优先使用 svelte MCP（如果启用）
- 遇到 Native/Gradle/权限：优先走 handbook + skills 的约束，不要让 agent自由发挥跨目录
"@

Write-Utf8NoBom (Join-Path $handbookRoot "tooling\trae.md") @"
# Tooling: Trae

- 项目根 .rules 来自 ai-infra/rules/trae/.rules（install 同步）
- .rules 的作用是限制 agent 的改动范围与流程顺序，避免踩目录/跳工作流

强制记忆点：
- 禁止手改 android/ios 里复制的 web assets
- 必须走 web build -> cap sync
"@

Write-Utf8NoBom (Join-Path $handbookRoot "tooling\zed.md") @"
# Tooling: Zed + Terminal

建议：
- 终端只跑“可复现”的命令（写进卡片 DoD）
- 出现环境问题（SDK/Gradle/adb）时，把解决步骤记录到项目 docs/setup（产品仓库里）
"@

Write-Utf8NoBom (Join-Path $handbookRoot "templates\KANBAN.card-template.md") @"
# Kanban Card Template（复制到飞书卡片里）

Title:
Area / Layer / Priority:
JourneyRef:
Touches:
Deliverable:

DoD (Definition of Done):
- [ ] ...
- [ ] ...

Risks:
- ...

Evidence:
- logs / screenshots / video / command output

Rollback:
- ...
"@

Write-Host "OK: handbook created at $handbookRoot"
