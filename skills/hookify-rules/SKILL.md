---
name: hookify-rules
description: 当用户要求创建 hookify 规则、编写 hook 规则、配置 hookify、添加 hookify 规则或需要有关 hookify 规则语法和模式的指导时使用此技能。
---

# 编写 Hookify 规则

## 概述

Hookify 规则是带有 YAML frontmatter 的 markdown 文件，定义要监视的模式以及这些模式匹配时显示的消息。规则存储在 `.claude/hookify.{rule-name}.local.md` 文件中。

## 规则文件格式

### 基本结构

```markdown
---
name: rule-identifier
enabled: true
event: bash|file|stop|prompt|all
pattern: regex-pattern-here
---

当此规则触发时向 Claude 显示的消息。
可以包括 markdown 格式、警告、建议等。
```

### Frontmatter 字段

| 字段 | 必需 | 值 | 描述 |
|-------|----------|--------|-------------|
| name | 是 | kebab-case 字符串 | 唯一标识符（动词优先：warn-*、block-*、require-*） |
| enabled | 是 | true/false | 在不删除的情况下切换 |
| event | 是 | bash/file/stop/prompt/all | 哪个挂钩事件触发此 |
| action | 否 | warn/block | warn（默认）显示消息；block 阻止操作 |
| pattern | 是* | regex 字符串 | 要匹配的模式 (*或对复杂规则使用 conditions） |

### 高级格式（多个条件）

```markdown
---
name: warn-env-api-keys
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
  - field: new_text
    operator: contains
    pattern: API_KEY
---

您正在将 API 密钥添加到 .env 文件。确保此文件在 .gitignore 中！
```

**按事件的字段：**
- bash: `command`
- file: `file_path`、`new_text`、`old_text`、`content`
- prompt: `user_prompt`

**运算符：** `regex_match`、`contains`、`equals`、`not_contains`、`starts_with`、`ends_with`

所有条件必须匹配才能触发规则。

## 事件类型指南

### bash 事件
匹配 Bash 命令模式：
- 危险命令：`rm\s+-rf`、`dd\s+if=`、`mkfs`
- 权限升级：`sudo\s+`、`su\s+`
- 权限问题：`chmod\s+777`

### file 事件
匹配编辑/写入/多重编辑操作：
- 调试代码：`console\.log\(`、`debugger`
- 安全风险：`eval\(`、`innerHTML\s*=`
- 敏感文件：`\.env$`、`credentials`、`\.pem$`

### stop 事件
完成检查和提醒。模式 `.*` 始终匹配。

### prompt 事件
匹配用户提示内容以强制执行工作流。

## 模式编写技巧

### Regex 基础
- 转义特殊字符：`.` 到 `\.`、`(` 到 `\(`
- `\s` 空白、`\d` 数字、`\w` 单词字符
- `+` 一个或多个、`*` 零个或多个、`?` 可选
- `|` 或运算符

### 常见陷阱
- **太宽泛**：`log` 匹配 "login"、"dialog" — 使用 `console\.log\(`
- **太具体**：`rm -rf /tmp` — 使用 `rm\s+-rf`
- **YAML 转义**：使用未引用的模式；引用的字符串需要 `\\s`

### 测试
```bash
python3 -c "import re; print(re.search(r'your_pattern', 'test text'))"
```

## 文件组织

- **位置**：项目根目录中的 `.claude/` 目录
- **命名**：`.claude/hookify.{descriptive-name}.local.md`
- **Gitignore**：将 `.claude/*.local.md` 添加到 `.gitignore`

## 命令

- `/hookify [description]` - 创建新规则（如果没有参数，自动分析对话）
- `/hookify-list` - 以表格格式查看所有规则
- `/hookify-configure` - 以交互方式切换规则开/关
- `/hookify-help` - 完整文档

## 快速参考

最小可行规则：
```markdown
---
name: my-rule
enabled: true
event: bash
pattern: dangerous_command
---

警告消息在这里
```
