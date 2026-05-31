---
name: cost-tracking
description: 从本地成本跟踪数据库跟踪和报告 Claude Code token 使用量、支出和预算。适用于用户询问成本、支出、使用量、token、预算，或按项目、工具、会话或日期划分的成本明细。
origin: community
---

# 成本跟踪

使用此技能从本地 SQLite 数据库分析 Claude Code 的成本和使用历史。它适用于已经安装了成本跟踪钩子或插件并将使用记录写入 `~/.claude-cost-tracker/usage.db` 的用户。

来源：从 `MayurBhavsar` 的过期社区 PR #1304 中抢救。

## 何时使用

- 用户问"我花了多少钱？"、"这次会话花了什么？"或"我的 token 使用量是多少？"
- 用户提到预算、支出限制、超支或成本控制
- 用户想要按项目、工具、会话、模型或日期的成本明细
- 用户想要将今天与昨天进行对比或检查最近的趋势
- 用户要求导出最近使用记录的 CSV

## 工作原理

首先验证前置条件：

```bash
command -v sqlite3 >/dev/null && echo "sqlite3 可用" || echo "sqlite3 缺失"
test -f ~/.claude-cost-tracker/usage.db && echo "数据库已找到" || echo "数据库未找到"
```

如果数据库不存在，不要编造使用数据。告知用户成本跟踪未配置，并建议安装或启用可信的本地成本跟踪钩子/插件。

预期的 `usage` 表通常每个工具调用或模型交互有一行。列名因跟踪器而异，但以下示例假设：

| 列 | 含义 |
| --- | --- |
| `timestamp` | 使用事件的 ISO 时间戳 |
| `project` | 项目或仓库名称 |
| `tool_name` | 工具或事件名称 |
| `input_tokens` | 输入 token 数，当有记录时 |
| `output_tokens` | 输出 token 数，当有记录时 |
| `cost_usd` | 预计算的美元成本 |
| `session_id` | Claude Code 会话标识符 |
| `model` | 事件使用的模型 |

优先使用 `cost_usd` 而非手动计算定价。模型价格和缓存定价会随时间变化，跟踪器应该是每行如何定价的事实来源。

## 示例

### 快速摘要

```bash
sqlite3 ~/.claude-cost-tracker/usage.db "
  SELECT
    '今天: $' || ROUND(COALESCE(SUM(CASE WHEN date(timestamp) = date('now') THEN cost_usd END), 0), 4) ||
    ' | 总计: $' || ROUND(COALESCE(SUM(cost_usd), 0), 4) ||
    ' | 调用: ' || COUNT(*) ||
    ' | 会话: ' || COUNT(DISTINCT session_id)
  FROM usage;
"
```

### 按项目的成本

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT project, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY project
  ORDER BY cost DESC;
"
```

### 按工具的成本

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT tool_name, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY tool_name
  ORDER BY cost DESC;
"
```

### 最近七天

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT date(timestamp) AS date, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY date(timestamp)
  ORDER BY date DESC
  LIMIT 7;
"
```

### 会话明细

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT session_id,
    MIN(timestamp) AS started,
    MAX(timestamp) AS ended,
    ROUND(SUM(cost_usd), 4) AS cost,
    COUNT(*) AS calls
  FROM usage
  GROUP BY session_id
  ORDER BY started DESC
  LIMIT 10;
"
```

## 报告指南

展示成本数据时，包含：

1. 今日支出和昨日对比。
2. 跟踪数据库中的总支出。
3. 按成本排名的顶级项目。
4. 按成本排名的顶级工具。
5. 在有足够数据时，提供会话数和每个会话的平均成本。

对于小金额，使用四位小数格式化货币。对于较大金额，两位小数即可。

## 反模式

- 当 `cost_usd` 存在时，不要从原始 token 数估算成本。
- 不要在未检查的情况下假设数据库存在。
- 不要在大型数据库上运行无限制的 `SELECT *` 导出。
- 不要在面向用户的回答中硬编码当前模型定价。
- 不要推荐安装未经审查的执行任意代码的钩子或插件。

## 相关

- `/cost-report` - 使用同一数据库的命令形式报告。
- `cost-aware-llm-pipeline` - 模型路由和预算设计模式。
- `token-budget-advisor` - 上下文和 token 预算规划。
- `strategic-compact` - 上下文压缩以减少重复的 token 支出。
