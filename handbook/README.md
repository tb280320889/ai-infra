# AI Infra Handbook

这份手册属于 ai-infra（跨项目复用）。每次执行 install-to-project.ps1，会把本目录同步到项目的 .ai/handbook/。

建议：
- 不要在项目的 .ai/handbook/ 里做长期修改（会被覆盖）。
- 项目特有内容放在项目仓库的 docs/（例如 PRD / ADR / contracts / acceptance）。
- 若你需要个人笔记，放在项目的 .ai/handbook.local/（不被同步覆盖）。