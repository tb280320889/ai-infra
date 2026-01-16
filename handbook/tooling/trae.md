# Tooling: Trae

- 项目根 .rules 来自 ai-infra/rules/trae/.rules（install 同步）
- .rules 的作用是限制 agent 的改动范围与流程顺序，避免踩目录/跳工作流

强制记忆点：
- 禁止手改 android/ios 里复制的 web assets
- 必须走 web build -> cap sync