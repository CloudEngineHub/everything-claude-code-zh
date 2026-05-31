---
description: 从 cost-tracker SQLite 数据库生成本地 Claude Code 成本报告。
argument-hint: [csv]
---

# 成本报告

查询本地成本跟踪数据库并按天、项目、工具和会话呈现支出报告。此命令假定成本跟踪钩子或插件已将使用记录写入 `~/.claude-cost-tracker/usage.db`。

## 此命令的作用

1. 检查 `sqlite3` 是否可用。
2. 检查 `~/.claude-cost-tracker/usage.db` 是否存在。
3. 对 `usage` 表运行聚合查询。
4. 呈现紧凑报告，或在参数为 `csv` 时导出最近记录为 CSV。

## 前提条件

数据库必须由本地成本跟踪器填充。如果文件缺失，告知用户跟踪器未设置，并建议先安装或启用可信的 Claude Code 成本跟踪钩子/插件。

```bash
test -f ~/.claude-cost-tracker/usage.db && echo "数据库已找到" || echo "数据库未找到"
```

## 汇总查询

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT
    ROUND(COALESCE(SUM(CASE WHEN date(timestamp) = date('now') THEN cost_usd END), 0), 4) AS today_cost,
    ROUND(COALESCE(SUM(CASE WHEN date(timestamp) = date('now', '-1 day') THEN cost_usd END), 0), 4) AS yesterday_cost,
    ROUND(COALESCE(SUM(cost_usd), 0), 4) AS total_cost,
    COUNT(*) AS total_calls,
    COUNT(DISTINCT session_id) AS sessions
  FROM usage;
"
```

## 项目明细

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT project, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY project
  ORDER BY cost DESC;
"
```

## 工具明细

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT tool_name, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY tool_name
  ORDER BY cost DESC;
"
```

## 最近七天

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT date(timestamp) AS date, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY date(timestamp)
  ORDER BY date DESC
  LIMIT 7;
"
```

## CSV 导出

如果用户请求 `/cost-report csv`，使用显式列列表导出最近的使用记录：

```bash
sqlite3 -csv -header ~/.claude-cost-tracker/usage.db "
  SELECT timestamp, project, tool_name, input_tokens, output_tokens, cost_usd, session_id, model
  FROM usage
  ORDER BY timestamp DESC
  LIMIT 100;
"
```

## 报告格式

将响应格式化为：

1. 汇总：今天、昨天、总计、调用次数、会话数。
2. 按项目：按总成本排名的项目。
3. 按工具：按总成本排名的工具。
4. 最近七天：日期、成本、调用次数。

使用四位小数显示不足一美元的金额。在此命令中不要从原始 token 估算定价；依赖跟踪器写入的预计算 `cost_usd` 值。

## 来源

从 `MayurBhavsar` 的过期社区 PR #1304 中恢复。
