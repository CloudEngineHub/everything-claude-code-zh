---
description: 检查活动循环的状态、进度、失败信号和建议的干预措施。
---

# Loop 状态命令

检查活动循环的状态、进度和失败信号。

此斜杠命令只能在当前会话出队后运行。如果你需要检查卡住或同级会话的状态，从另一个终端运行打包的 CLI：

```bash
npx --package ecc-universal ecc loop-status --json
```

CLI 扫描 `~/.claude/projects/**` 下的本地 Claude 转录 JSONL 文件，报告过时的 `ScheduleWakeup` 调用或没有匹配 `tool_result` 的 `Bash` 工具调用。

## 用法

`/loop-status [--watch]`

## 报告内容

- 活动循环模式
- 当前阶段和最后一个成功的检查点
- 失败的检查（如果有）
- 预估的时间/成本偏差
- 建议的干预措施（继续/暂停/停止）

## 跨会话 CLI

- `ecc loop-status --json` 为最近的本地 Claude 转录输出机器可读状态。
- `ecc loop-status --home <dir>` 在检查另一个本地配置文件或挂载的工作区时扫描不同的主目录。
- `ecc loop-status --transcript <session.jsonl>` 直接检查一个转录文件。
- `ecc loop-status --bash-timeout-seconds 1800` 调整过时 Bash 阈值。
- `ecc loop-status --exit-code` 当发现过时循环或工具信号时以 `2` 退出，或当无法扫描转录时以 `1` 退出。
- `--exit-code` 搭配 `--watch` 需要 `--watch-count`，这样看门狗脚本不会永远等待进程退出。
- `ecc loop-status --watch` 持续刷新状态直到被中断。
- `ecc loop-status --watch --watch-count 3 --exit-code` 刷新有限次数，然后以见过的最高状态退出。
- `ecc loop-status --watch --watch-count 3` 为脚本和交接输出有限的监视流。
- `ecc loop-status --watch --write-dir ~/.claude/loops` 维护 `index.json` 和每个会话的 JSON 快照，供同级终端或看门狗脚本使用。

## 监视模式

当存在 `--watch` 时，定期刷新状态。搭配 `--json` 时，每次刷新作为一行 JSON 对象输出，以便另一个终端或脚本消费流。

## 快照文件

当单独的进程需要检查循环状态而不等待当前 Claude 会话出队 `/loop-status` 时，使用 `--write-dir <dir>`。CLI 写入：

- `index.json`，每个检查的会话一行。
- `<session-id>.json`，该会话的完整状态载荷。

这些文件是本地转录分析的快照。它们不控制或超时 Claude Code 运行时工具调用。

## 参数

$ARGUMENTS:
- `--watch` 可选
