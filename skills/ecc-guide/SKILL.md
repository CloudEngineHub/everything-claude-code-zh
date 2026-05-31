---
name: ecc-guide
description: 通过读取实时仓库内容，引导用户了解 ECC 当前的智能体、技能、命令、钩子、规则、安装配置文件和项目入门。
origin: community
---

# ECC 指南

当用户需要帮助理解、导航、安装或选择 Everything Claude Code 的各个部分时，使用此技能。

## 何时使用

当用户出现以下情况时使用此技能：

- 询问 ECC 包含什么
- 想要帮助查找技能、命令、智能体、钩子、规则或安装配置文件
- 是仓库新手，需要引导路径
- 询问"我如何用 ECC 做某事？"
- 询问哪些 ECC 组件适合某个项目
- 需要关于命令、技能、智能体、钩子和规则之间关系的简要说明
- 对安装路径、重复安装、重置/卸载或选择性安装选项感到困惑

## 核心原则

从当前文件回答，而非记忆。ECC 变化很快，因此硬编码的目录计数、功能列表和安装说明会过时。

当 ECC 仓库可用时，在给出具体答案之前检查相关文件：

```bash
node scripts/ci/catalog.js --json
find skills -maxdepth 2 -name SKILL.md | sort
find commands -maxdepth 1 -name '*.md' | sort
find agents -maxdepth 1 -name '*.md' | sort
node scripts/install-plan.js --list-profiles
node scripts/install-plan.js --list-components --json
```

使用回答用户问题所需的最少读取量。

## 仓库结构

- `README.md`：安装路径、卸载/重置指南、公开定位、常见问题
- `AGENTS.md`：贡献者指南和项目结构
- `agent.yaml`：导出的 gitagent 接口和命令列表
- `commands/`：维护的斜杠命令兼容层
- `skills/*/SKILL.md`：可复用工作流和领域手册
- `agents/*.md`：委派的子智能体角色提示
- `rules/`：语言和工具规则
- `hooks/README.md`、`hooks/hooks.json`、`scripts/hooks/`：钩子行为和安全门控
- `manifests/install-*.json`：选择性安装模块、组件、配置文件和目标支持
- `docs/`：工具指南、架构说明、翻译文档、发布文档

## 响应风格

先给出答案，然后给出下一步操作。大多数用户不需要完整的目录转储。

良好的首次响应结构：

1. 使用什么
2. 为什么合适
3. 要检查的确切文件或命令
4. 一个下一步命令或问题

避免：

- 默认列出每个技能或命令
- 重复大量 README 章节
- 当存在技能优先路径时推荐已退役的命令兼容层
- 在未检查文件系统的情况下声称某个组件存在
- 当托管安装器支持目标时，用手动复制命令替代安装指南

## 常见任务

### 新用户入门

给出简短菜单：

- 安装或重置 ECC
- 为项目选择技能
- 了解命令与技能的区别
- 检查钩子和安全行为
- 运行工具审计
- 查找特定工作流

指向 `README.md` 进行安装/重置，指向 `/project-init` 进行项目特定入门。

### 功能发现

对于"我应该用什么来做 X？"：

1. 搜索 `skills/`、`commands/` 和 `agents/`。
2. 优先使用技能作为主要工作流接口。
3. 仅当命令是维护的兼容层或用户明确需要斜杠命令行为时才使用命令。
4. 当委派有用时提及智能体。

有用的搜索：

```bash
rg -n "<query>" skills commands agents docs
find skills -maxdepth 2 -name SKILL.md | sort
```

### 安装指南

使用托管安装路径：

```bash
node scripts/install-plan.js --list-profiles
node scripts/install-plan.js --profile minimal --target claude --json
node scripts/install-apply.js --profile minimal --target claude --dry-run
```

对于特定技能安装：

```bash
node scripts/install-plan.js --skills <skill-id> --target claude --json
node scripts/install-apply.js --skills <skill-id> --target claude --dry-run
```

警告用户不要叠加插件安装和完整手动/配置文件安装，除非他们有意需要重复接口。

### 项目入门

当用户想要为目标仓库配置 ECC 时，使用 `/project-init`。预期序列是：

1. 从项目文件检测技术栈
2. 解析试运行安装计划
3. 检查现有的 `CLAUDE.md` 和设置文件
4. 在应用更改之前询问
5. 保持生成的指导最小化和仓库特定化

### 故障排除

首先询问目标工具和安装路径，然后检查：

- 插件安装元数据
- `.claude/`、`.cursor/`、`.codex/`、`.gemini/`、`.opencode/`、`.codebuddy/`、`.joycode/` 或 `.qwen/`
- `hooks/hooks.json`
- 安装状态文件
- 相关的命令/技能文件

对于仓库健康检查，建议：

```bash
npm run harness:audit -- --format text
npm run observability:ready
npm test
```

## 输出模板

### 简短推荐

```text
使用 <skill-or-command>。它适合因为 <reason>。

规范文件：<path>
验证命令：<command>
下一步：<one concrete action>
```

### 搜索结果

```text
最佳匹配：
- <path>: <why it matters>
- <path>: <why it matters>

推荐：<which one to use first and why>
```

### 安装计划摘要

```text
检测到：<stack evidence>
目标：<harness>
计划：<profile/modules/skills>
试运行：<command>
将更改：<paths>
应用前需要批准：<yes/no>
```

## 相关接口

- `/project-init`：针对目标仓库的技术栈感知入门计划
- `/harness-audit`：确定性就绪评分卡
- `/skill-health`：技能质量审查
- `/skill-create`：从本地 git 历史生成新技能
- `/security-scan`：检查 Claude/OpenCode 配置安全性
