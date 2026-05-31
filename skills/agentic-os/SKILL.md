---
name: agentic-os
description: 在 Claude Code 上构建持久的多智能体操作系统。涵盖内核架构、专家智能体、斜杠命令、基于文件的内存、计划自动化和无外部数据库的状态管理。
origin: ECC
---

# 智能体 OS

将 Claude Code 视为持久运行时/操作系统而非聊天会话。此技能将生产智能体设置使用的架构编纂：将任务路由到专家智能体的内核配置、持久基于文件的内存、计划自动化和 JSON/markdown 数据层。

## 何时激活

- 在 Claude Code 中构建多智能体工作流
- 设置在会话重启后存活的持久 Claude Code 自动化
- 为重复任务创建"个人 OS"或"智能体 OS"
- 用户说"智能体 OS"、"个人 OS"、"多智能体"、"智能体协调器"、"持久智能体"
- 构建上下文必须在会话之间存活的长运行项目

## 架构概述

智能体 OS 有四层。每层都是项目根目录中的一个目录。

```
project-root/
├── CLAUDE.md          # 内核：身份、路由规则、智能体注册表
├── agents/            # 专家智能体定义（markdown 提示）
├── .claude/commands/  # 斜杠命令：面向用户的 CLI
├── scripts/           # 守护进程脚本：计划或事件驱动的任务
└── data/              # 状态：JSON/markdown 文件系统，无外部 DB
```

### 层职责

| 层 | 目的 | 持久化 |
|---|---|---|
| 内核 (`CLAUDE.md`) | 身份、路由、模型策略、智能体注册表 | Git 跟踪 |
| 智能体 (`agents/`) | 具有范围工具和内存的专家身份 | Git 跟踪 |
| 命令 (`.claude/commands/`) | 面向用户的斜杠命令（`/daily-sync`、`/outreach`） | Git 跟踪 |
| 脚本 (`scripts/`) | 由 cron 或 webhooks 触发的 Python/JS 守护进程 | Git 跟踪 |
| 状态 (`data/`) | 仅追加日志、项目状态、决策记录 | Git 忽略或跟踪 |

## 内核

`CLAUDE.md` 是内核。它充当 COO/协调器。Claude 在会话开始时读取它，并使用它来路由工作。

### 内核结构

```markdown
# CLAUDE.md - 智能体 OS 内核

## 身份
您是 [project-name] 的 COO。您将任务路由到专家智能体。
您从不直接编写代码。您委派给正确的智能体并综合结果。

## 智能体注册表

| 智能体 | 角色 | 触发器 |
|---|---|---|
| @dev | 代码、架构、调试 | 用户说"build"、"fix"、"refactor" |
| @writer | 文档、内容、电子邮件 | 用户说"write"、"draft"、"blog" |
| @researcher | 研究、分析、事实检查 | 用户说"research"、"analyze"、"compare" |
| @ops | DevOps、部署、基础设施 | 用户说"deploy"、"CI"、"server" |

## 路由规则
1. 解析用户请求的意图关键字
2. 匹配到智能体注册表触发器列
3. 从 `agents/<name>.md` 加载相应的智能体文件
4. 移交具有完整上下文的执行
5. 综合并向用户呈现结果

## 模型策略
- 默认模型：使用存储库或工具默认值。
- @dev 任务：对于复杂架构，优先考虑更高推理模型。
- @researcher 任务：使用配置的研究能力模型和批准的搜索工具。
- 成本上限：在超过项目配置的支出阈值之前警告。
```

### 关键原则

内核应**小且声明式**。路由逻辑存在于纯 markdown 表中，而非代码。这使系统可检查和可编辑而无需调试。

## 专家智能体

每个智能体都是 `agents/` 中的独立 markdown 文件。Claude 在路由任务时加载相关的智能体文件。

### 智能体定义格式

```markdown
# @dev - 软件工程师

## 身份
您是一名高级软件工程师。您编写干净、经过测试的生产级代码。
您偏好简单的解决方案。当需求模糊时，您会提出澄清性问题。

## 内存范围
- 读取 `data/projects/<current-project>.md` 以获取上下文
- 读取 `data/decisions/` 以获取架构决策
- 将执行日志追加到 `data/logs/<date>-@dev.md`

## 工具访问
- 项目根目录内的完整文件系统访问
- Git 操作（状态、差异、提交、分支）
- 测试运行器访问
- `.claude/mcp.json` 中配置的 MCP 服务器

## 约束
- 始终为新功能编写测试
- 永远不要直接提交到 `main`；使用功能分支
- 优先编辑现有文件而非创建新文件
- 尽可能保持函数在 50 行以下
```

### 多智能体协作模式

当任务跨越多个智能体时，内核按顺序或并行运行它们：

```
用户："Build a landing page and write the launch blog post"

内核路由：
1. @dev - "Build a landing page with [requirements]"
2. @writer - "Write a launch blog post for [product] using the landing page copy"
3. 内核将两个输出综合为统一响应
```

对于并行执行，使用 Claude Code 的后台任务功能或调用具有特定智能体上下文的 Claude Code 的 shell 脚本。

## 命令和日常工作流

斜杠命令是 `.claude/commands/` 中的 markdown 文件。它们定义可重用的工作流。

### 命令结构

```markdown
# /daily-sync

运行晨间简报：

1. 读取 `data/logs/last-sync.md` 以获取上下文
2. 检查项目状态：`git status`、挂起的 PR、CI 健康
3. 审查 `data/inbox/` 以获取新任务或所需决策
4. 生成阻止器、优先级和后续操作的摘要
5. 将简报追加到 `data/logs/daily/<date>.md`
```

### 标准命令集

| 命令 | 目的 |
|---|---|
| `/daily-sync` | 晨间简报：状态、阻止器、优先级 |
| `/outreach` | 运行外联工作流（电子邮件、LinkedIn 等） |
| `/research <topic>` | 具有引用跟踪的深度研究 |
| `/apply-jobs` | 为目标角色量身定制简历 + 求职信 |
| `/analytics` | 从 Stripe、GitHub 或自定义来源提取指标 |
| `/interview-prep` | 生成抽认卡或模拟面试问题 |
| `/decision <topic>` | 记录具有优缺点的决策和所选路径 |

### 激活命令

将命令文件放在 `.claude/commands/<command-name>.md` 中。Claude Code 自动发现它们。用户使用 `/<command-name>` 调用它们。

## 持久内存

内存基于文件。无向量 DB、无 Redis、无 PostgreSQL。`data/` 中的 JSON 和 markdown 文件是数据库。

### 内存目录结构

```
data/
├── daily-logs/         # 仅追加的日常活动日志
├── projects/           # 每项目上下文文件
├── decisions/          # 架构和业务决策（ADR 格式）
├── inbox/              # 等待分类的新任务或想法
├── contacts/           # 人员、公司、关系笔记
└── templates/          # 可重用提示和格式
```

### 日常日志格式

```markdown
# 2026-04-22 - 日常日志

## 会话
- 09:00 - 会话 1：重构了身份验证模块 (@dev)
- 11:30 - 会话 2：起草了投资者更新 (@writer)

## 决策
- 从 JWT 切换到会话 cookie（见 `data/decisions/2026-04-22-auth.md`）

## 阻塞器
- 等待供应商的 API 密钥（2026-04-24 跟进）

## 后续操作
- [ ] 合并身份验证重构 PR
- [ ] 发送投资者更新供审查
```

### 自动反思模式

在每个会话结束时，内核附加反思：

```markdown
## 反思 - 会话 3
- 有效：并行智能体执行节省了 20 分钟
- 无效：@researcher 遇到付费来源，需要更好的来源排名
- 变更：将 `source-tier` 字段添加到研究笔记（A/B/C 可信度）
```

这创建了一个反馈循环，随着时间推移改进系统而无需代码更改。

## 计划自动化

智能体 OS 任务使用外部 cron 按计划运行，而非 Claude Code 的内置 cron（会话结束时死亡）。

### macOS：LaunchAgent

```xml
<!-- ~/Library/LaunchAgents/com.agentic.daily-sync.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.agentic.daily-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/claude</string>
        <string>--cwd</string>
        <string>/path/to/project</string>
        <string>--command</string>
        <string>/daily-sync</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>8</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/agentic-daily-sync.log</string>
</dict>
</plist>
```

### Linux：systemd Timer

```ini
# ~/.config/systemd/user/agentic-daily-sync.service
[Unit]
Description=Agentic OS Daily Sync

[Service]
Type=oneshot
ExecStart=/usr/local/bin/claude --cwd /path/to/project --command /daily-sync
```

```ini
# ~/.config/systemd/user/agentic-daily-sync.timer
[Unit]
Description=Run daily sync every morning

[Timer]
OnCalendar=*-*-* 8:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### 跨平台：pm2

```bash
# ecosystem.config.js
module.exports = {
  apps: [{
    name: 'agentic-daily-sync',
    script: 'claude',
    args: '--cwd /path/to/project --command /daily-sync',
    cron_restart: '0 8 * * *',
    autorestart: false
  }]
};
```

## 数据层

数据层是您的文件系统。对结构化数据使用 JSON，对叙述内容使用 markdown。

### 用于结构化状态的 JSON

```json
// data/projects/website-v2.json
{
  "name": "Website v2",
  "status": "in-progress",
  "milestone": "beta-launch",
  "agents_involved": ["@dev", "@writer"],
  "files": {
    "spec": "docs/website-v2-spec.md",
    "design": "designs/website-v2.fig"
  },
  "metrics": {
    "commits": 47,
    "last_session": "2026-04-22T11:30:00Z"
  }
}
```

### 用于叙述的 Markdown

对人类阅读的任何内容使用 markdown：决策、日志、研究笔记、联系人记录。

### 架构演变

永远不重命名现有字段。添加新字段并将旧字段标记为已弃用：

```json
{
  "name": "Website v2",
  "status": "in-progress",
  "milestone": "beta-launch",
  "_deprecated_priority": "high",
  "priority_v2": { "level": "high", "rationale": "阻止投资者演示" }
}
```

这使历史数据可读而无需迁移脚本。

## 反模式

### 单体单一智能体

```markdown
# BAD - 一个智能体执行所有操作
您是一名全栈开发人员、作家、研究员和 DevOps 工程师。
```

拆分为专家智能体。内核处理路由。

### 无状态会话

```markdown
# BAD - 会话之间没有内存
每次 Claude Code 打开时都重新开始。
```

始终在会话开始时读取 `data/` 并在会话结束时写回。

### 硬编码凭据

```markdown
# BAD - 智能体文件或 CLAUDE.md 中的 API 密钥
您的 OpenAI API 密钥是 sk-xxxxxxxx
```

使用环境变量或由脚本加载的 `.env` 文件。智能体引用 `process.env.API_KEY`。

### 简单状态的外部数据库

```markdown
# BAD - 单个用户的智能体 OS 使用 PostgreSQL
```

在您有多个并发用户或 GB 数据之前，使用 JSON/markdown 文件。

### 过度工程的路由

```markdown
# BAD - 代码中的路由逻辑而非 markdown 表
if (intent.includes('deploy')) { agent = opsAgent; }
```

在 `CLAUDE.md` markdown 表中保持路由声明式。它是可检查、可编辑和可调试的。

## 最佳实践

- [ ] `CLAUDE.md` 在 200 行以下，适合上下文窗口
- [ ] 每个智能体文件在 100 行以下，专注于一个领域
- [ ] `data/` 对于敏感日志被 git 忽略，对于决策和规格被 git 跟踪
- [ ] 命令使用命令性名称：`/daily-sync`，而非 `/run-daily-sync`
- [ ] 日志仅追加；永远不编辑过去的日常日志
- [ ] 每个智能体都有一个 `内存范围` 部分，定义它读取的文件
- [ ] 在每个会话结束时写入反思
- [ ] 计划任务使用外部 cron（LaunchAgent、systemd、pm2），而非 Claude Code 的会话 cron
- [ ] 成本跟踪：在 `data/logs/<date>-costs.json` 中记录每会话的 API 支出
- [ ] 一个项目 = 一个智能体 OS。不要在无关项目之间共享单个 `CLAUDE.md`。
