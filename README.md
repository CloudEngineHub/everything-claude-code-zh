# Everything Claude Code

[![Stars](https://img.shields.io/github/stars/affaan-m/everything-claude-code?style=flat)](https://github.com/affaan-m/everything-claude-code/stargazers)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/-Shell-4EAA25?logo=gnu-bash&logoColor=white)
![TypeScript](https://img.shields.io/badge/-TypeScript-3178C6?logo=typescript&logoColor=white)
![Go](https://img.shields.io/badge/-Go-00ADD8?logo=go&logoColor=white)
![Markdown](https://img.shields.io/badge/-Markdown-000000?logo=markdown&logoColor=white)

**Anthropic Hackathon 获胜者提供的 Claude Code 配置全集。**

包含生产级 agent、skills（技能）、hooks（钩子）、commands（命令）、rules（规则）和 MCP 配置，这些都是在构建真实产品的 10 多个月高强度日常使用中演变而来的。

---

## 指南 (The Guides)

本仓库仅包含原始代码。详细说明请参阅指南。

<table>
<tr>
<td width="50%">
<a href="https://x.com/affaanmustafa/status/2012378465664745795">
<img src="https://github.com/user-attachments/assets/1a471488-59cc-425b-8345-5245c7efbcef" alt="Everything Claude Code 简明指南" />
</a>
</td>
<td width="50%">
<a href="https://x.com/affaanmustafa/status/2014040193557471352">
<img src="https://github.com/user-attachments/assets/c9ca43bc-b149-427f-b551-af6840c368f0" alt="Everything Claude Code 详尽指南" />
</a>
</td>
</tr>
<tr>
<td align="center"><b>简明指南 (Shorthand Guide)</b><br/>设置、基础、哲学。<b>请先阅读此篇。</b></td>
<td align="center"><b>详尽指南 (Longform Guide)</b><br/>Token 优化、记忆持久化、评估 (evals)、并行化。</td>
</tr>
</table>

| 主题 | 你将学到什么 |
|-------|-------------------|
| Token 优化 | 模型选择、SysPrompt 精简、后台进程 |
| 记忆持久化 (Memory Persistence) | 跨会话自动保存/加载上下文的 Hooks |
| 持续学习 (Continuous Learning) | 自动从会话中提取模式并转化为可重用的 Skills |
| 验证循环 (Verification Loops) | 检查点 vs 持续评估 (evals)、评分器类型、pass@k 指标 |
| 并行化 (Parallelization) | Git worktrees、级联方法、何时扩展实例 |
| 子 agent 编排 | 上下文问题、迭代检索模式 |

---

## 跨平台支持

此插件现在完全支持 **Windows, macOS, 和 Linux**。所有的 hooks 和脚本都已用 Node.js 重写，以实现最大的兼容性。

### 包管理器检测

插件会自动按照以下优先级检测你偏好的包管理器（npm, pnpm, yarn, 或 bun）：

1. **环境变量**: `CLAUDE_PACKAGE_MANAGER`
2. **项目配置**: `.claude/package-manager.json`
3. **package.json**: `packageManager` 字段
4. **锁文件 (Lock file)**: 检测 `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, 或 `bun.lockb`
5. **全局配置**: `~/.claude/package-manager.json`
6. **回退 (Fallback)**: 第一个可用的包管理器

要设置你偏好的包管理器：

```bash
# 通过环境变量
export CLAUDE_PACKAGE_MANAGER=pnpm

# 通过全局配置
node scripts/setup-package-manager.js --global pnpm

# 通过项目配置
node scripts/setup-package-manager.js --project bun

# 检测当前设置
node scripts/setup-package-manager.js --detect
```

或者使用 Claude Code 中的 `/setup-pm` 命令。

---

## 内容概览 (What's Inside)

本仓库是一个 **Claude Code 插件** - 可以直接安装它，也可以手动复制组件。

```
everything-claude-code/
|-- .claude-plugin/   # 插件和市场清单
|   |-- plugin.json         # 插件元数据和组件路径
|   |-- marketplace.json    # 用于 /plugin marketplace add 的市场目录
|
|-- agents/           # 用于委派的专用子 agent
|   |-- planner.md           # 功能实现规划
|   |-- architect.md         # 系统设计决策
|   |-- tdd-guide.md         # 测试驱动开发
|   |-- code-reviewer.md     # 质量和安全审查
|   |-- security-reviewer.md # 漏洞分析
|   |-- build-error-resolver.md
|   |-- e2e-runner.md        # Playwright E2E 测试
|   |-- refactor-cleaner.md  # 死代码清理
|   |-- doc-updater.md       # 文档同步
|   |-- go-reviewer.md       # Go 代码审查 (NEW)
|   |-- go-build-resolver.md # Go 构建错误修复 (NEW)
|
|-- skills/           # 工作流定义和领域知识
|   |-- coding-standards/           # 语言最佳实践
|   |-- backend-patterns/           # API、数据库、缓存模式
|   |-- frontend-patterns/          # React, Next.js 模式
|   |-- continuous-learning/        # 从会话中自动提取模式 (详尽指南)
|   |-- continuous-learning-v2/     # 基于本能的学习与置信度评分
|   |-- iterative-retrieval/        # 子 agent 的渐进式上下文精炼
|   |-- strategic-compact/          # 手动压缩建议 (详尽指南)
|   |-- tdd-workflow/               # TDD 方法论
|   |-- security-review/            # 安全检查清单
|   |-- eval-harness/               # 验证循环评估 (详尽指南)
|   |-- verification-loop/          # 持续验证 (详尽指南)
|   |-- golang-patterns/            # Go 惯用语和最佳实践 (NEW)
|   |-- golang-testing/             # Go 测试模式、TDD、基准测试 (NEW)
|
|-- commands/         # 快速执行的 Slash 命令
|   |-- tdd.md              # /tdd - 测试驱动开发
|   |-- plan.md             # /plan - 实现规划
|   |-- e2e.md              # /e2e - 生成 E2E 测试
|   |-- code-review.md      # /code-review - 质量审查
|   |-- build-fix.md        # /build-fix - 修复构建错误
|   |-- refactor-clean.md   # /refactor-clean - 移除死代码
|   |-- learn.md            # /learn - 会话中提取模式 (详尽指南)
|   |-- checkpoint.md       # /checkpoint - 保存验证状态 (详尽指南)
|   |-- verify.md           # /verify - 运行验证循环 (详尽指南)
|   |-- setup-pm.md         # /setup-pm - 配置包管理器
|   |-- go-review.md        # /go-review - Go 代码审查 (NEW)
|   |-- go-test.md          # /go-test - Go TDD 工作流 (NEW)
|   |-- go-build.md         # /go-build - 修复 Go 构建错误 (NEW)
|
|-- rules/            # 必须遵守的准则 (复制到 ~/.claude/rules/)
|   |-- security.md         # 强制安全检查
|   |-- coding-style.md     # 不可变性、文件组织
|   |-- testing.md          # TDD、80% 覆盖率要求
|   |-- git-workflow.md     # 提交格式、PR 流程
|   |-- agents.md           # 何时委派给子 agent
|   |-- performance.md      # 模型选择、上下文管理
|
|-- hooks/            # 基于触发器的自动化
|   |-- hooks.json                # 所有 hooks 配置 (PreToolUse, PostToolUse, Stop 等)
|   |-- memory-persistence/       # 会话生命周期 hooks (详尽指南)
|   |-- strategic-compact/        # 压缩建议 (详尽指南)
|
|-- scripts/          # 跨平台 Node.js 脚本 (NEW)
|   |-- lib/                     # 共享工具
|   |   |-- utils.js             # 跨平台文件/路径/系统工具
|   |   |-- package-manager.js   # 包管理器检测和选择
|   |-- hooks/                   # Hook 实现
|   |   |-- session-start.js     # 会话开始时加载上下文
|   |   |-- session-end.js       # 会话结束时保存状态
|   |   |-- pre-compact.js       # 预压缩状态保存
|   |   |-- suggest-compact.js   # 战略性压缩建议
|   |   |-- evaluate-session.js  # 从会话中提取模式
|   |-- setup-package-manager.js # 交互式 PM 设置
|
|-- tests/            # 测试套件 (NEW)
|   |-- lib/                     # 库测试
|   |-- hooks/                   # Hook 测试
|   |-- run-all.js               # 运行所有测试
|
|-- contexts/         # 动态系统提示词注入上下文 (详尽指南)
|   |-- dev.md              # 开发模式上下文
|   |-- review.md           # 代码审查模式上下文
|   |-- research.md         # 研究/探索模式上下文
|
|-- examples/         # 示例配置和会话
|   |-- CLAUDE.md           # 项目级配置示例
|   |-- user-CLAUDE.md      # 用户级配置示例
|
|-- mcp-configs/      # MCP 服务器配置
|   |-- mcp-servers.json    # GitHub, Supabase, Vercel, Railway 等
|
|-- marketplace.json  # 自托管市场配置 (用于 /plugin marketplace add)
```

---

## 生态系统工具

### ecc.tools - Skill 生成器

从你的仓库自动生成 Claude Code skills。

[安装 GitHub App](https://github.com/apps/skill-creator) | [ecc.tools](https://ecc.tools)

分析你的仓库并创建：
- **SKILL.md 文件** - 即可用于 Claude Code 的 skills
- **本能 (Instinct) 集合** - 用于 continuous-learning-v2
- **模式提取** - 从你的提交历史中学习

```bash
# 安装 GitHub App 后，skills 将出现在：
~/.claude/skills/generated/
```

与 `continuous-learning-v2` skill 无缝协作，以实现继承的本能。

---

## 安装 (Installation)

### 选项 1: 作为插件安装 (推荐)

使用此仓库最简单的方法 - 作为 Claude Code 插件安装：

```bash
# 添加此仓库为 marketplace
/plugin marketplace add affaan-m/everything-claude-code

# 安装插件
/plugin install everything-claude-code@everything-claude-code
```

或者直接添加到你的 `~/.claude/settings.json`：

```json
{
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": {
        "source": "github",
        "repo": "affaan-m/everything-claude-code"
      }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
```

这将让你立即获得所有 commands、agents、skills 和 hooks 的访问权限。

---

### 选项 2: 手动安装

如果你更喜欢手动控制安装内容：

```bash
# 克隆仓库
git clone https://github.com/affaan-m/everything-claude-code.git

# 复制 agents 到你的 Claude 配置
cp everything-claude-code/agents/*.md ~/.claude/agents/

# 复制 rules
cp everything-claude-code/rules/*.md ~/.claude/rules/

# 复制 commands
cp everything-claude-code/commands/*.md ~/.claude/commands/

# 复制 skills
cp -r everything-claude-code/skills/* ~/.claude/skills/
```

#### 添加 hooks 到 settings.json

将 `hooks/hooks.json` 中的 hooks 复制到你的 `~/.claude/settings.json`。

#### 配置 MCPs

将所需的 MCP servers 从 `mcp-configs/mcp-servers.json` 复制到你的 `~/.claude.json`。

**重要:** 将 `YOUR_*_HERE` 占位符替换为你的实际 API keys。

---

## 核心概念 (Key Concepts)

### Agents

子 agent 处理具有有限范围的委派任务。示例：

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability
tools: ["Read", "Grep", "Glob", "Bash"]
model: opus
---

You are a senior code reviewer...
```

### Skills

Skills 是由 command 或 agent 调用的工作流定义：

```markdown
# TDD Workflow

1. Define interfaces first
2. Write failing tests (RED)
3. Implement minimal code (GREEN)
4. Refactor (IMPROVE)
5. Verify 80%+ coverage
```

### Hooks

Hooks 在工具事件上触发。示例 - 警告关于 console.log：

```json
{
  "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
  "hooks": [{
    "type": "command",
    "command": "#!/bin/bash\ngrep -n 'console\\.log' \"$file_path\" && echo '[Hook] Remove console.log' >&2"
  }]
}
```

### Rules

Rules 是必须始终遵循的准则。保持模块化：

```
~/.claude/rules/
  security.md      # No hardcoded secrets
  coding-style.md  # Immutability, file limits
  testing.md       # TDD, coverage requirements
```

---

## 运行测试

插件包含全面的测试套件：

```bash
# 运行所有测试
node tests/run-all.js

# 运行单个测试文件
node tests/lib/utils.test.js
node tests/lib/package-manager.test.js
node tests/hooks/hooks.test.js
```

---

## 贡献 (Contributing)

**欢迎并鼓励贡献。**

本仓库旨在成为社区资源。如果你有：
- 有用的 agents 或 skills
- 巧妙的 hooks
- 更好的 MCP 配置
- 改进的 rules

请贡献！查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解指南。

### 贡献思路

- 特定语言的 skills (Python, Rust 模式) - Go 现已包含！
- 特定框架的配置 (Django, Rails, Laravel)
- DevOps agents (Kubernetes, Terraform, AWS)
- 测试策略 (不同的框架)
- 特定领域的知识 (ML, 数据工程, 移动端)

---

## 背景 (Background)

我从 Claude Code 实验性推出以来就一直在使用它。在 2025 年 9 月的 Anthropic x Forum Ventures hackathon 中，我和 [@DRodriguezFX](https://x.com/DRodriguezFX) 凭借构建 [zenith.chat](https://zenith.chat) 获胜 - 完全使用 Claude Code 构建。

这些配置已在多个生产级应用程序中经过实战检验。

---

## 重要说明

### 上下文窗口管理 (Context Window Management)

**关键:** 不要一次性启用所有 MCPs。如果有太多工具启用，你的 200k 上下文窗口可能会缩减到 70k。

经验法则：
- 配置 20-30 个 MCPs
- 每个项目启用少于 10 个
- 活跃工具少于 80 个

在项目配置中使用 `disabledMcpServers` 来禁用未使用的服务。

### 自定义 (Customization)

这些配置适用于我的工作流。你应该：
1. 从产生共鸣的内容开始
2. 根据你的技术栈进行修改
3. 移除你不使用的内容
4. 添加你自己的模式

---

## Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=affaan-m/everything-claude-code&type=Date)](https://star-history.com/#affaan-m/everything-claude-code&Date)

---

## 链接

- **简明指南 (由此开始):** [The Shorthand Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2012378465664745795)
- **详尽指南 (进阶):** [The Longform Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2014040193557471352)
- **关注:** [@affaanmustafa](https://x.com/affaanmustafa)
- **zenith.chat:** [zenith.chat](https://zenith.chat)

---

## 许可证 (License)

MIT - 自由使用，按需修改，如果可以请回馈。

---

**如果此仓库对你有帮助，请给它加星 (Star)。阅读两份指南。构建伟大的产品。**
