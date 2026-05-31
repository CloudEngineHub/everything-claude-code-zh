---
name: autonomous-agent-harness
description: 将 Claude Code 转变为完全自主的代理系统，具有持久记忆、计划操作、计算机使用和任务队列。通过利用 Claude Code 的原生 cron、调度、MCP 工具和记忆，替换独立的代理框架（Hermes、AutoGPT）。当用户想要连续自主操作、计划任务或自导向代理循环时使用。
origin: ECC
---

# 自主代理系统

仅使用原生功能和 MCP 服务器将 Claude Code 转变为持久、自导向的代理系统。

## 同意和安全边界

自主操作必须由用户明确请求和界定。在用户批准该能力和当前设置的目标工作空间之前，不要创建计划、调度远程代理、写入持久记忆、使用计算机控制、对外发布、修改第三方资源或对私人通信采取行动。

在启用循环或事件驱动操作之前，首选试运行计划和本地队列文件。将凭据、私有工作空间导出、个人数据集和特定于帐户的自动化排除在可重用的 ECC 工件之外。

## 何时激活

- 用户想要代理连续或按计划运行
- 设置定期触发的自动化工作流
- 构建跨会话记住上下文的个人 AI 助手
- 用户说"每天运行这个"、"定期检查这个"、"继续监控"
- 想要复制来自 Hermes、AutoGPT 或类似自主代理框架的功能
- 需要结合计划执行的计算机使用

## 架构

```
┌──────────────────────────────────────────────────────────────┐
│                    Claude Code 运行时                        │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │  Crons   │  │ Dispatch │  │ Memory   │  │ Computer    │ │
│  │ Schedule │  │ Remote   │  │ Store    │  │ Use         │ │
│  │ Tasks    │  │ Agents   │  │          │  │             │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬──────┘ │
│       │              │             │                │        │
│       ▼              ▼             ▼                ▼        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              ECC 技能 + 代理层                         │    │
│  │                                                      │    │
│  │  skills/     agents/     commands/     hooks/        │    │
│  └──────────────────────────────────────────────────────┘    │
│       │              │             │                │        │
│       ▼              ▼             ▼                ▼        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              MCP 服务器层                             │    │
│  │                                                      │    │
│  │  memory    github    exa    supabase    browser-use  │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. 持久记忆

使用 Claude Code 的内置记忆系统和用于结构化数据的 MCP 记忆服务器进行增强。

**内置记忆**（`~/.claude/projects/*/memory/`）：
- 用户偏好、反馈、项目上下文
- 作为带有 frontmatter 的 markdown 文件存储
- 在会话开始时自动加载

**MCP 记忆服务器**（结构化知识图谱）：
- 实体、关系、观察
- 可查询的图结构
- 跨会话持久性

**记忆模式：**

```
# 短期：当前会话上下文
使用 TodoWrite 进行会话内任务跟踪

# 中期：项目记忆文件
写入 ~/.claude/projects/*/memory/ 以进行跨会话回忆

# 长期：MCP 知识图谱
使用 mcp__memory__create_entities 获取永久结构化数据
使用 mcp__memory__create_relations 进行关系映射
使用 mcp__memory__add_observations 添加关于已知实体的事实
```

### 2. 计划操作（Crons）

使用 Claude Code 的计划任务创建循环代理操作。

**设置 cron：**

```
# 通过 MCP 工具
mcp__scheduled-tasks__create_scheduled_task({
  name: "daily-pr-review",
  schedule: "0 9 * * 1-5",  # 工作日上午 9 点
  prompt: "审查 affaan-m/everything-claude-code 中的所有开放 PR。对于每个：检查 CI 状态、审查更改、标记问题。将摘要发布到记忆。",
  project_dir: "/path/to/repo"
})

# 通过 claude -p（编程模式）
echo "审查开放 PR 并汇总" | claude -p --project /path/to/repo
```

**有用的 cron 模式：**

| 模式 | 计划 | 用例 |
|---------|----------|----------|
| 每日站会 | `0 9 * * 1-5` | 审查 PR、问题、部署状态 |
| 每周审查 | `0 10 * * 1` | 代码质量指标、测试覆盖率 |
| 每小时监控 | `0 * * * *` | 生产运行状况、错误率检查 |
| 每晚构建 | `0 2 * * *` | 运行完整测试套件、安全扫描 |
| 会前准备 | `*/30 * * * *` | 为即将到来的会议准备上下文 |

### 3. 调度 / 远程代理

通过远程触发 Claude Code 代理进行事件驱动工作流。

**调度模式：**

```bash
# 从 CI/CD 触发
curl -X POST "https://api.anthropic.com/dispatch" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{"prompt": "主分支构建失败。诊断并修复。", "project": "/repo"}'

# 从 webhook 触发
# GitHub webhook → dispatch → Claude agent → fix → PR

# 从另一个代理触发
claude -p "分析安全扫描的输出并为发现创建问题"
```

### 4. 计算机使用

利用 Claude 的计算机使用 MCP 进行物理世界交互。

**功能：**
- 浏览器自动化（导航、点击、填写表单、屏幕截图）
- 桌面控制（打开应用程序、输入、鼠标控制）
- 超越 CLI 的文件系统操作

**在系统中的用例：**
- Web UI 的自动化测试
- 表单填写和数据输入
- 基于屏幕截图的监控
- 多应用程序工作流

### 5. 任务队列

管理一个跨会话边界的持久任务队列。

**实现：**

```
# 通过记忆的任务持久性
将任务队列写入 ~/.claude/projects/*/memory/task-queue.md

# 任务格式
---
name: task-queue
type: project
description: 自主操作的持久任务队列
---

## 活动任务
- [ ] PR #123：审查并在 CI 绿色时批准
- [ ] 监控部署：在 2 小时内每 30 分钟检查 /health
- [ ] 研究：在 AI 工具领域寻找 5 个线索

## 已完成
- [x] 每日站会：审查了 3 个 PR、2 个问题
```

## 替换 Hermes

| Hermes 组件 | ECC 等效项 | 如何 |
|------------------|---------------|-----|
| Gateway/Router | Claude Code dispatch + crons | 计划任务触发代理会话 |
| Memory System | Claude memory + MCP memory server | 内置持久性 + 知识图谱 |
| Tool Registry | MCP 服务器 | 动态加载的工具提供商 |
| Orchestration | ECC 技能 + 代理 | 技能定义指导代理行为 |
| Computer Use | computer-use MCP | 原生浏览器和桌面控制 |
| Context Manager | 会话管理 + 记忆 | ECC 2.0 会话生命周期 |
| Task Queue | 记忆持久任务列表 | TodoWrite + 记忆文件 |

## 设置指南

### 步骤 1：配置 MCP 服务器

确保这些在 `~/.claude.json` 中：

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic/memory-mcp-server"]
    },
    "scheduled-tasks": {
      "command": "npx",
      "args": ["-y", "@anthropic/scheduled-tasks-mcp-server"]
    },
    "computer-use": {
      "command": "npx",
      "args": ["-y", "@anthropic/computer-use-mcp-server"]
    }
  }
}
```

### 步骤 2：创建基础 Crons

```bash
# 每日晨间简报
claude -p "创建一个计划任务：每个工作日上午 9 点，审查我的 GitHub 通知、开放 PR 和日历。将晨间简报写入记忆。"

# 持续学习
claude -p "创建一个计划任务：每周日晚 8 点，从本周会话中提取模式并更新学到的技能。"
```

### 步骤 3：初始化记忆图谱

```bash
# 引导您的身份和上下文
claude -p "为以下内容创建记忆实体：我（用户配置文件）、我的项目、我的关键联系人。添加关于当前优先级的观察。"
```

### 步骤 4：启用计算机使用（可选）

授予 computer-use MCP 浏览器和桌面控制所需的必要权限。

## 示例工作流

### 自主 PR 审查者
```
Cron：工作时间内每 30 分钟
1. 检查被监视仓库上的新 PR
2. 对于每个新 PR：
   - 在本地拉取分支
   - 运行测试
   - 使用 code-reviewer 代理审查更改
   - 通过 GitHub MCP 发布审查评论
3. 用审查状态更新记忆
```

### 个人研究代理
```
Cron：每天早上 6 点
1. 检查记忆中保存的搜索查询
2. 为每个查询运行 Exa 搜索
3. 汇总新发现
4. 与昨天的结果进行比较
5. 将摘要写入记忆
6. 为晨间审查标记高优先级项目
```

### 会议准备代理
```
触发：每个日历事件前 30 分钟
1. 阅读日历事件详细信息
2. 搜索与会者的记忆上下文
3. 拉取与会者的最近电子邮件/Slack 线程
4. 准备谈话要点和议程建议
5. 将准备文档写入记忆
```

## 约束

- Cron 任务在隔离会话中运行 — 它们不与交互式会话共享上下文，除非通过记忆。
- 计算机使用需要明确的权限授予。不要假设访问权限。
- 远程调度可能有速率限制。设计适当间隔的 crons。
- 记忆文件应保持简洁。归档旧数据而不是让文件无限增长。
- 始终验证计划任务是否成功完成。将错误处理添加到 cron 提示中。
