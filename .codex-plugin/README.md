# .codex-plugin — ECC 的 Codex 原生插件

此目录包含 ECC 的 **Codex 插件清单**。

## 结构

```
.codex-plugin/
└── plugin.json   — Codex 插件清单（名称、版本、技能引用、MCP 引用）
.mcp.json         — 插件根目录的 MCP 服务器配置（不在 .codex-plugin/ 内）
```

## 提供的内容

- **200 个技能** 来自 `./skills/` — 可重用的 Codex 工作流，用于 TDD、安全、
  代码审查、架构等
- **6 个 MCP 服务器** — GitHub、Context7、Exa、Memory、Playwright、Sequential Thinking

## 安装

Codex 插件支持当前基于市场。仓库在 `.agents/plugins/marketplace.json` 公开仓库范围的市场；Codex 可以从 CLI 添加和跟踪该市场来源：

```bash
# 添加公共仓库市场
codex plugin marketplace add affaan-m/ECC

# 或在开发时添加本地检出
codex plugin marketplace add /absolute/path/to/ECC
```

市场入口在仓库根目录，因此 `.codex-plugin/plugin.json`、
`skills/` 和 `.mcp.json` 从一个共享的真实来源解析。添加或更新市场后，
重启 Codex 并从插件目录安装或启用 `ecc`。

Codex 中的官方插件目录发布即将到来。在自助发布存在之前，
将公共仓库市场视为受支持的 Codex 分发路径，
并保持发布副本框架为仓库市场/手动安装。

已安装的插件在短 slug `ecc` 下注册，因此工具和命令名称
保持在提供程序长度限制之下。

## 包含的 MCP 服务器

| 服务器 | 用途 |
|---|---|
| `github` | GitHub API 访问 |
| `context7` | 实时文档查找 |
| `exa` | 神经网络搜索 |
| `memory` | 跨会话的持久内存 |
| `playwright` | 浏览器自动化和 E2E 测试 |
| `sequential-thinking` | 逐步推理 |

## 注意事项

- 仓库根目录的 `skills/` 目录在 Claude Code（`.claude-plugin/`）
  和 Codex（`.codex-plugin/`）之间共享 — 相同的真实来源，无重复
- ECC 正在转向技能优先的工作流表面。传统的 `commands/` 保留用于
  在仍然期望斜线入口垫片的 harness 上的兼容性。
- MCP 服务器凭据从启动环境（环境变量）继承
- 此清单**不**覆盖 `~/.codex/config.toml` 设置
