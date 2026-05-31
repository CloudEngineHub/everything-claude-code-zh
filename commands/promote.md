---
name: promote
description: 将项目作用域的本能提升为全局作用域
command: true
---

# Promote 命令

在 continuous-learning-v2 中将本能从项目作用域提升为全局作用域。

## 实现

使用插件根路径运行本能 CLI：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" promote [instinct-id] [--force] [--dry-run]
```

如果未设置 `CLAUDE_PLUGIN_ROOT`（手动安装）：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py promote [instinct-id] [--force] [--dry-run]
```

## 用法

```bash
/promote                      # 自动检测可提升的候选
/promote --dry-run            # 预览自动提升候选
/promote --force              # 无提示提升所有合格的候选
/promote grep-before-edit     # 从当前项目提升一个特定的本能
```

## 操作步骤

1. 检测当前项目
2. 如果提供了 `instinct-id`，仅提升该本能（如果存在于当前项目中）
3. 否则，查找跨项目候选：
   - 出现在至少 2 个项目中
   - 满足置信度阈值
4. 将提升的本能写入 `~/.claude/homunculus/instincts/personal/`，标记 `scope: global`
