# AI Infra Handbook

## TL;DR (read this first)
- Project handbook (synced): `.ai/handbook/`  — generated/synced from `ai-infra`, do not keep long-lived edits here.
- Project-local notes: `.ai/handbook.local/` — for project/personal additions, recommended to gitignore.
- Shared changes: edit `ai-infra/handbook/`, then bump the submodule in the project.

## Project-local notes (do not lose your changes)

- `.ai/handbook/` in a project is **synced output** from `ai-infra`. Do not maintain long-lived edits there.
- Put project-specific or personal additions in `.ai/handbook.local/` instead (recommended to be gitignored).
- If you need to change the shared handbook content, edit it in `ai-infra/handbook/` and bump the submodule in the project.

## 说明（中文）

这份手册属于 ai-infra（跨项目复用）。每次执行 `install-to-project.ps1`，会把本目录同步到项目的 `.ai/handbook/`。

建议：
- 不要在项目的 `.ai/handbook/` 里做长期修改（会被覆盖）。
- 项目特有内容建议放在项目仓库 `docs/`（例如 PRD / ADR / contracts / acceptance）。
- 个人笔记放在项目的 `.ai/handbook.local/`（不被同步覆盖，建议不入库）。
