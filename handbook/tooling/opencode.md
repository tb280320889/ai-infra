# Tooling: OpenCode

- opencode.json 由 ai-infra 的 install-to-project.ps1 生成（项目根）
- MCP servers 配置来源：ai-infra/mcp/servers.json
- 推荐：在项目根使用终端调用（而不是全局安装）以保证版本一致

建议实践：
- 遇到 UI/路由/组件：优先使用 svelte MCP（如果启用）
- 遇到 Native/Gradle/权限：优先走 handbook + skills 的约束，不要让 agent自由发挥跨目录