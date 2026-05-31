# 安全策略

## 支持的版本

| 版本 | 是否支持          |
| ------- | ------------------ |
| 1.9.x   | :white_check_mark: |
| 1.8.x   | :white_check_mark: |
| < 1.8   | :x:                |

## 报告漏洞

如果您在 ECC 中发现安全漏洞，请负责任地报告。

**不要为安全漏洞创建公开的 GitHub Issue。**

请发送邮件至 **<security@ecc.tools>**，包含：

- 漏洞描述
- 复现步骤
- 受影响的版本
- 任何潜在影响评估

您可以期望：

- **确认** 在 48 小时内
- **状态更新** 在 7 天内
- **修复或缓解** 关键问题在 30 天内

如果漏洞被接受，我们将：

- 在发布说明中致谢您（除非您希望匿名）
- 及时修复问题
- 与您协调披露时间

如果漏洞被拒绝，我们将解释原因并提供是否应向其他渠道报告的指导。

## 范围

此策略涵盖：

- ECC 插件和本仓库中的所有脚本
- 在您的机器上执行的钩子脚本
- 安装/卸载/修复生命周期脚本
- ECC 附带的 MCP 配置
- AgentShield 安全扫描器 ([github.com/affaan-m/agentshield](https://github.com/affaan-m/agentshield))

## 操作指南

### 密钥处理

`mcp-configs/mcp-servers.json` 是一个**模板**。所有 `YOUR_*_HERE` 值必须在安装时从环境变量或密钥管理器中替换。切勿提交真实凭据。如果密钥被意外提交，请立即轮换并重写历史；不要依赖简单的回滚。

同样的规则适用于您的用户范围 Claude Code 配置（`~/.claude/settings.json` 或 `%USERPROFILE%\.claude\settings.json`）。该文件不在此仓库中，但通常通过 `claude doctor` 输出、截图或错误报告共享。不要将 PAT、API 密钥或 OAuth 令牌硬编码到其 `mcpServers[*].env` 块中；在生成时从 OS 密钥链或 MCP 服务器已支持的环境变量中解析。快速审计：

```bash
# macOS / Linux
grep -EnH '(TOKEN|SECRET|KEY|PASSWORD)\s*"\s*:\s*"[A-Za-z0-9_-]{16,}"' ~/.claude/settings.json
# Windows PowerShell
Select-String -Path "$env:USERPROFILE\.claude\settings.json" -Pattern '(TOKEN|SECRET|KEY|PASSWORD)"\s*:\s*"[A-Za-z0-9_-]{16,}"'
```

如果审计发现匹配项，请在颁发提供商处轮换密钥，然后将其从文件中移出（使用按提供商的环境变量或支持的服务器的 `credentialHelper`）。

### 本地 MCP 端口

某些捆绑的 MCP 服务器通过纯 HTTP 连接到本地端口（例如 `devfleet` 连接到 `http://localhost:18801/mcp`）。首次使用前，请验证监听进程：

```bash
# Windows
netstat -ano | findstr :18801
# macOS / Linux
lsof -iTCP:18801 -sTCP:LISTEN
```

将 PID 与预期的 devfleet 二进制文件进行比较。该端口上的任何其他进程都可能拦截 MCP 流量。

## 分流：可疑的 `<system-reminder>` 块

ECC 在 Claude Code 内运行，后者会在每轮注入**临时的客户端系统提醒**到模型输入中（TodoWrite 提示、日期变更通知、文件修改通知等）。这些块：

- 通常以 *"ignore if not applicable"* 或 *"NEVER mention this reminder to the user"* / *"Don't tell the user this, since they are already aware"* 等措辞结尾；该措辞是 Anthropic 自己的提示，而非恶意的尾部；
- 由 CLI 按轮添加，**不会持久化** 在 `~/.claude/projects/<slug>/<sessionId>.jsonl` 的会话记录中。

这种组合使它们容易被误认为是附加到工具结果的提示注入。在将其视为攻击之前，请验证：

1. 该块是否实际存在于本仓库的文件中？`grep -rEn "system-reminder|NEVER mention|DO NOT mention" .`；如果没有结果，则不是由仓库携带的。
2. 该块是否存储在记录中？检查当前会话的 `.jsonl`；如果确切文本未出现在 `tool_result` 主体中，则它是客户端注入的临时提醒，而非来自任何工具的负载。
3. 内容是否与 Anthropic 已知的提醒在上下文上一致（TodoWrite 提示、日期变更、文件修改通知）？如果是，则是临时提醒机制，无需采取行动。

仅当某个块**同时** (a) 存在于记录中的 `tool_result` 内 **且** (b) 不能归因于实际读取的文件或 URL 时，才升级至 Anthropic。最小化报告：一个新会话、一个干净本地文件的读取、观察到的确切文本和记录摘录。发送至 <https://github.com/anthropics/claude-code/issues>（非敏感）或 <mailto:security@anthropic.com>（保密级别）。

不要因临时提醒而清理仓库文件；它们不是载体。

## 安全资源

- **AgentShield**: 扫描您的智能体配置以查找漏洞 — `npx ecc-agentshield scan`
- **安全指南**: [智能体安全简写指南](./the-security-guide.md)
- **供应链事件响应**: [npm/GitHub Actions 包注册手册](./docs/security/supply-chain-incident-response.md)
- **OWASP MCP Top 10**: [owasp.org/www-project-mcp-top-10](https://owasp.org/www-project-mcp-top-10/)
- **OWASP 智能体应用 Top 10**: [genai.owasp.org](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
