# Checkpoint 命令

在你的工作流中创建或验证 checkpoint（检查点）。

## 用法

`/checkpoint [create|verify|list] [name]`

## 创建 Checkpoint

创建 checkpoint 时：

1. 运行 `/verify quick` 以确保当前状态是干净的
2. 使用 checkpoint 名称创建 git stash 或 commit
3. 将 checkpoint 记录到 `.claude/checkpoints.log`：

```bash
echo "$(date +%Y-%m-%d-%H:%M) | $CHECKPOINT_NAME | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
```

4. 报告 checkpoint 已创建

## 验证 Checkpoint

针对 checkpoint 进行验证时：

1. 从日志中读取 checkpoint
2. 将当前状态与 checkpoint 进行比较：
   - 自 checkpoint 以来添加的文件
   - 自 checkpoint 以来修改的文件
   - 现在 vs 当时的测试通过率
   - 现在 vs 当时的覆盖率

3. 报告：
```
CHECKPOINT COMPARISON: $NAME
============================
Files changed: X
Tests: +Y passed / -Z failed
Coverage: +X% / -Y%
Build: [PASS/FAIL]
```

## 列出 Checkpoints

显示所有 checkpoints 及其：
- 名称
- 时间戳
- Git SHA
- 状态 (current, behind, ahead)

## 工作流

典型的 checkpoint 流程：

```
[开始] --> /checkpoint create "feature-start"
   |
[实现] --> /checkpoint create "core-done"
   |
[测试] --> /checkpoint verify "core-done"
   |
[重构] --> /checkpoint create "refactor-done"
   |
[PR] --> /checkpoint verify "feature-start"
```

## 参数

$ARGUMENTS:
- `create <name>` - 创建指定名称的 checkpoint
- `verify <name>` - 针对指定名称的 checkpoint 进行验证
- `list` - 显示所有 checkpoints
- `clear` - 移除旧的 checkpoints（保留最后 5 个）
