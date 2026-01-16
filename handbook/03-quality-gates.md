# 03 Quality Gates（进入 Review / Done 的门禁）

进入 Review 前：
- DoD 已写清且可执行
- 本地至少跑过一次关键流程（或给出为什么无法跑）
- 变更范围与目录边界清楚（Touches）

进入 Done 前：
- Evidence 已提供（截图/日志/录屏/命令输出）
- 失败分支至少覆盖 1–2 个（权限/弱网/离线队列/幂等）
- 若涉及协议/schema：同时更新项目 docs/contracts 或 ADR（在项目仓库里）