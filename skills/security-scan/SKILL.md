---
name: security-scan
description: 使用 AgentShield 扫描你的 Claude Code 配置（.claude/ 目录）以发现安全漏洞、配置错误和注入风险。检查 CLAUDE.md、settings.json、MCP 服务器、钩子和智能体定义。
origin: ECC
---

# 安全扫描技能

使用 [AgentShield](https://github.com/affaan-m/agentshield) 审计你的 Claude Code 配置中的安全问题。

## 何时激活

- 设置新的 Claude Code 项目时
- 修改 `.claude/settings.json`、`CLAUDE.md` 或 MCP 配置之后
- 提交配置更改之前
- 接入已有 Claude Code 配置的新仓库时
- 定期安全卫生检查

## 扫描内容

| 文件 | 检查项 |
|------|--------|
| `CLAUDE.md` | 硬编码密钥、自动运行指令、提示注入模式 |
| `settings.json` | 过于宽松的允许列表、缺少拒绝列表、危险的绕过标志 |
| `mcp.json` | 有风险的 MCP 服务器、硬编码环境密钥、npx 供应链风险 |
| `hooks/` | 通过插值的命令注入、数据泄露、静默错误抑制 |
| `agents/*.md` | 不受限制的工具访问、提示注入面、缺少模型规格 |

## 前提条件

必须安装 AgentShield。检查并在需要时安装：

```bash
# 检查是否已安装
npx ecc-agentshield --version

# 全局安装（推荐）
npm install -g ecc-agentshield

# 或直接通过 npx 运行（无需安装）
npx ecc-agentshield scan .
```

## 使用方法

### 基本扫描

对当前项目的 `.claude/` 目录运行：

```bash
# 扫描当前项目
npx ecc-agentshield scan

# 扫描特定路径
npx ecc-agentshield scan --path /path/to/.claude

# 使用最低严重性过滤器扫描
npx ecc-agentshield scan --min-severity medium
```

### 输出格式

```bash
# 终端输出（默认）— 带颜色的报告和评分
npx ecc-agentshield scan

# JSON — 用于 CI/CD 集成
npx ecc-agentshield scan --format json

# Markdown — 用于文档
npx ecc-agentshield scan --format markdown

# HTML — 自包含的深色主题报告
npx ecc-agentshield scan --format html > security-report.html
```

### 自动修复

自动应用安全修复（仅修复标记为可自动修复的项）：

```bash
npx ecc-agentshield scan --fix
```

这将会：
- 将硬编码密钥替换为环境变量引用
- 将通配符权限收紧为限定范围的替代方案
- 永不修改仅手动建议的项

### Opus 4.6 深度分析

运行对抗性三智能体流水线进行更深入的分析：

```bash
# 需要 ANTHROPIC_API_KEY
export ANTHROPIC_API_KEY=your-key
npx ecc-agentshield scan --opus --stream
```

运行：
1. **攻击者（红队）** — 发现攻击向量
2. **防御者（蓝队）** — 推荐加固措施
3. **审计员（最终判决）** — 综合两个视角

### 初始化安全配置

从零开始搭建新的安全 `.claude/` 配置：

```bash
npx ecc-agentshield init
```

创建：
- 带有限定范围权限和拒绝列表的 `settings.json`
- 带有安全最佳实践的 `CLAUDE.md`
- `mcp.json` 占位符

### GitHub Action

添加到你的 CI 流水线：

```yaml
- uses: affaan-m/agentshield@v1
  with:
    path: '.'
    min-severity: 'medium'
    fail-on-findings: true
```

## 严重性级别

| 等级 | 分数 | 含义 |
|-------|-------|---------|
| A | 90-100 | 安全配置 |
| B | 75-89 | 次要问题 |
| C | 60-74 | 需要关注 |
| D | 40-59 | 重大风险 |
| F | 0-39 | 严重漏洞 |

## 结果解读

### 严重发现（立即修复）
- 配置文件中的硬编码 API 密钥或令牌
- 允许列表中的 `Bash(*)`（不受限制的 Shell 访问）
- 钩子中通过 `${file}` 插值的命令注入
- 运行 Shell 的 MCP 服务器

### 高危发现（生产前修复）
- CLAUDE.md 中的自动运行指令（提示注入向量）
- 权限中缺少拒绝列表
- 智能体拥有不必要的 Bash 访问权限

### 中危发现（建议修复）
- 钩子中的静默错误抑制（`2>/dev/null`、`|| true`）
- 缺少 PreToolUse 安全钩子
- MCP 服务器配置中的 `npx -y` 自动安装

### 信息级发现（了解即可）
- MCP 服务器缺少描述
- 限制性指令被正确标记为良好实践

## 链接

- **GitHub**: [github.com/affaan-m/agentshield](https://github.com/affaan-m/agentshield)
- **npm**: [npmjs.com/package/ecc-agentshield](https://www.npmjs.com/package/ecc-agentshield)
