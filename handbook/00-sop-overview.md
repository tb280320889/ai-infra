# 00 SOP Overview（独立开发 + AI 协同）

目标：你（总指挥）掌控需求与验收；IDE 内 agent/模型负责局部实现、测试、生成证据。

三条硬原则：
1) 任何改动必须可验收：卡片里要有 DoD（Definition of Done）和 Evidence（证据）。
2) 生命链路优先：后台存活、断联检测、幂等上报、通知可达性 > UI 完整性。
3) 小步快跑：一张卡最好 0.5–2 天完成；超出就拆卡。

项目内“产品事实”应该放哪里：
- PRD / user journey / failure-modes / ADR / contracts / acceptance：放项目仓库 docs/ 下并走 git 版本。
- ai-infra 只沉淀：SOP、工具手册、通用 rules/skills 模板与执行规范。