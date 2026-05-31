---
description: 创建钩子以防止不需要的行为，支持从对话分析或显式指令
---

创建钩子规则，通过分析对话模式或用户显式指令来防止不需要的 Claude Code 行为。

## 用法

`/hookify [要防止的行为描述]`

如果未提供参数，分析当前对话以查找值得防止的行为。

## 工作流

### 步骤 1：收集行为信息

- 有参数时：解析用户对不需要行为的描述
- 无参数时：使用 `conversation-analyzer` 智能体查找：
  - 显式纠正
  - 对重复错误的沮丧反应
  - 被还原的更改
  - 反复出现的类似问题

### 步骤 2：展示发现

向用户展示：

- 行为描述
- 建议的事件类型
- 建议的模式或匹配器
- 建议的操作

### 步骤 3：生成规则文件

对于每条批准的规则，在 `.claude/hookify.{name}.local.md` 创建文件：

```yaml
---
name: rule-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "正则表达式模式"
---
规则触发时显示的消息。
```

### 步骤 4：确认

报告创建的规则以及如何使用 `/hookify-list` 和 `/hookify-configure` 管理它们。
