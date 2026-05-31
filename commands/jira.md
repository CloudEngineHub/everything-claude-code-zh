---
description: 获取 Jira 工单、分析需求、更新状态或添加评论。使用 jira-integration 技能和 MCP 或 REST API。
---

# Jira 命令

直接从工作流中与 Jira 工单交互 — 获取工单、分析需求、添加评论和转换状态。

## 用法

```
/jira get <TICKET-KEY>          # 获取并分析工单
/jira comment <TICKET-KEY>      # 添加进度评论
/jira transition <TICKET-KEY>   # 更改工单状态
/jira search <JQL>              # 使用 JQL 搜索问题
```

## 此命令的功能

1. **获取与分析** — 获取 Jira 工单并提取需求、验收标准、测试场景和依赖项
2. **评论** — 向工单添加结构化的进度更新
3. **转换** — 将工单在工作流状态间移动（待办 → 进行中 → 完成）
4. **搜索** — 使用 JQL 查询查找问题

## 工作原理

### `/jira get <TICKET-KEY>`

1. 从 Jira 获取工单（通过 MCP `jira_get_issue` 或 REST API）
2. 提取所有字段：摘要、描述、验收标准、优先级、标签、关联问题
3. 可选地获取评论以获取额外上下文
4. 生成结构化分析：

```
工单：PROJ-1234
摘要：[标题]
状态：[状态]
优先级：[优先级]
类型：[Story/Bug/Task]

需求：
1. [提取的需求]
2. [提取的需求]

验收标准：
- [ ] [工单中的标准]

测试场景：
- 正常路径：[描述]
- 错误情况：[描述]
- 边界情况：[描述]

依赖项：
- [关联问题、API、服务]

推荐下一步：
- /plan 创建实现计划
- `tdd-workflow` 技能先测试后实现
```

### `/jira comment <TICKET-KEY>`

1. 总结当前会话进度（构建了什么、测试了什么、提交了什么）
2. 格式化为结构化评论
3. 发布到 Jira 工单

### `/jira transition <TICKET-KEY>`

1. 获取工单可用的转换
2. 向用户展示选项
3. 执行选定的转换

### `/jira search <JQL>`

1. 对 Jira 执行 JQL 查询
2. 返回匹配问题的汇总表

## 前提条件

此命令需要 Jira 凭据。选择其一：

**选项 A — MCP 服务器（推荐）：**
将 `jira` 添加到你的 `mcpServers` 配置（参见 `mcp-configs/mcp-servers.json` 中的模板）。

**选项 B — 环境变量：**
```bash
export JIRA_URL="https://yourorg.atlassian.net"
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_TOKEN="your-api-token"
```

如果凭据缺失，停止并引导用户进行设置。

## 与其他命令集成

分析工单后：
- 使用 `/plan` 从需求创建实现计划
- 使用 `tdd-workflow` 技能进行测试驱动开发实现
- 实现后使用 `/code-review`
- 使用 `/jira comment` 将进度发布回工单
- 工作完成时使用 `/jira transition` 移动工单

## 相关

- **技能：** `skills/jira-integration/`
- **MCP 配置：** `mcp-configs/mcp-servers.json` → `jira`
