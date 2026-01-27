# 为 Everything Claude Code 做贡献

感谢你想做贡献。此 repo 旨在成为 Claude Code 用户的社区资源。

## 我们在寻找什么

### Agents

处理特定任务良好的新 agents：
- 语言特定审查员 (Python, Go, Rust)
- 框架专家 (Django, Rails, Laravel, Spring)
- DevOps 专家 (Kubernetes, Terraform, CI/CD)
- 领域专家 (ML pipelines, data engineering, mobile)

### Skills

工作流定义和领域知识：
- 语言最佳实践
- 框架模式
- 测试策略
- 架构指南
- 领域特定知识

### Commands

调用有用工作流的 Slash commands：
- 部署命令
- 测试命令
- 文档命令
- 代码生成命令

### Hooks

有用的自动化：
- Linting/formatting hooks
- 安全检查
- 验证 hooks
- 通知 hooks

### Rules

始终遵循的准则：
- 安全规则
- 代码风格规则
- 测试要求
- 命名约定

### MCP 配置

新的或改进的 MCP 服务器配置：
- 数据库集成
- 云提供商 MCPs
- 监控工具
- 通讯工具

---

## 如何贡献

### 1. Fork 仓库

```bash
git clone https://github.com/YOUR_USERNAME/everything-claude-code.git
cd everything-claude-code
```

### 2. 创建分支

```bash
git checkout -b add-python-reviewer
```

### 3. 添加你的贡献

将文件放在适当的目录中：
- `agents/` 用于新 agents
- `skills/` 用于 skills (可以是单个 .md 或目录)
- `commands/` 用于 slash commands
- `rules/` 用于 rule 文件
- `hooks/` 用于 hook 配置
- `mcp-configs/` 用于 MCP 服务器配置

### 4. 遵循格式

**Agents** 应该由 frontmatter:

```markdown
---
name: agent-name
description: What it does
tools: Read, Grep, Glob, Bash
model: sonnet
---

Instructions here...
```

**Skills** 应该清晰且可操作：

```markdown
# Skill Name

## When to Use

...

## How It Works

...

## Examples

...
```

**Commands** 应该解释它们做什么：

```markdown
---
description: Brief description of command
---

# Command Name

Detailed instructions...
```

**Hooks** 应该包含描述：

```json
{
  "matcher": "...",
  "hooks": [...],
  "description": "What this hook does"
}
```

### 5. 测试你的贡献

在提交之前确保你的配置与 Claude Code 一起工作。

### 6. 提交 PR

```bash
git add .
git commit -m "Add Python code reviewer agent"
git push origin add-python-reviewer
```

然后打开 PR，包含：
- 你添加了什么
- 为什么它有用
- 你是如何测试它的

---

## 指南

### Do

- 保持配置专注和模块化
- 包含清晰的描述
- 在提交前测试
- 遵循现有模式
- 记录任何依赖关系

### Don't

- 包含敏感数据 (API keys, 令牌, 路径)
- 添加过于复杂或小众的配置
- 提交未经测试的配置
- 创建重复功能
- 添加需要特定付费服务且无替代方案的配置

---

## 文件命名

- 使用连字符的小写: `python-reviewer.md`
- 具有描述性: `tdd-workflow.md` 而不是 `workflow.md`
- 使 agent/skill 名称与文件名匹配

---

## 有问题?

Open an issue or reach out on X: [@affaanmustafa](https://x.com/affaanmustafa)

---

感谢贡献。让我们一起建立通过建立一个伟大的资源。
