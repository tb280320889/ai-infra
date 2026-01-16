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