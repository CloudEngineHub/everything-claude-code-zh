---
description: 获取 hookify 系统的帮助
---

显示全面的 hookify 文档。

## 钩子系统概述

Hookify 创建规则文件，与 Claude Code 的钩子系统集成，以防止不需要的行为。

### 事件类型

- `bash`: 在 Bash 工具使用时触发并匹配命令模式
- `file`: 在 Write/Edit 工具使用时触发并匹配文件路径
- `stop`: 在会话结束时触发
- `prompt`: 在用户消息提交时触发并匹配输入模式
- `all`: 在所有事件上触发

### 规则文件格式

文件存储为 `.claude/hookify.{name}.local.md`：

```yaml
---
name: descriptive-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "要匹配的正则表达式模式"
---
规则触发时显示的消息。
支持多行。
```

### 命令

- `/hookify [描述]` 创建新规则，未提供描述时自动分析对话
- `/hookify-list` 列出已配置的规则
- `/hookify-configure` 切换规则的启用或禁用

### 模式技巧

- 使用正则表达式语法
- 对于 `bash`，匹配完整命令字符串
- 对于 `file`，匹配文件路径
- 部署前测试模式
