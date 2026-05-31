---
name: projects
description: 列出已知项目及其本能统计信息
command: true
---

# Projects 命令

列出项目注册表条目和每个项目的本能/观察计数，用于 continuous-learning-v2。

## 实现

使用插件根路径运行本能 CLI：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" projects
```

如果未设置 `CLAUDE_PLUGIN_ROOT`（手动安装）：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py projects
```

## 用法

```bash
/projects
```

## 操作步骤

1. 读取 `~/.claude/homunculus/projects.json`
2. 对于每个项目，显示：
   - 项目名称、id、root、remote
   - 个人和继承的本能数量
   - 观察事件数量
   - 最后活跃时间戳
3. 同时显示全局本能总数
