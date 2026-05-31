---
description: 启动具有安全默认值和显式停止条件的托管自治循环模式。
---

# Loop 启动命令

启动具有安全默认值的托管自治循环模式。

## 用法

`/loop-start [pattern] [--mode safe|fast]`

- `pattern`：`sequential`、`continuous-pr`、`rfc-dag`、`infinite`
- `--mode`：
  - `safe`（默认）：严格的质量门控和检查点
  - `fast`：减少门控以提升速度

## 流程

1. 确认仓库状态和分支策略。
2. 选择循环模式和模型层级策略。
3. 启用所选模式所需的钩子/配置。
4. 创建循环计划并在 `.claude/plans/` 下编写运行手册。
5. 打印启动和监控循环的命令。

## 必需的安全检查

- 验证测试在首次循环迭代前通过。
- 确保 `ECC_HOOK_PROFILE` 未被全局禁用。
- 确保循环有显式停止条件。

## 参数

$ARGUMENTS:
- `<pattern>` 可选（`sequential|continuous-pr|rfc-dag|infinite`）
- `--mode safe|fast` 可选
