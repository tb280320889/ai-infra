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