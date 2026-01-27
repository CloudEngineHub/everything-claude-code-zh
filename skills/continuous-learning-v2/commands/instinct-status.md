---
name: instinct-status
description: 显示所有已学习的 instincts 及其置信度水平
command: /instinct-status
implementation: python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py status
---

# Instinct Status Command (Instinct 状态命令)

显示所有已学习的 instincts 及其置信度分数，按域分组。

## 实施

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py status
```

## 用法

```
/instinct-status
/instinct-status --domain code-style
/instinct-status --low-confidence
```

## 做什么

1. 读取 `~/.claude/homunculus/instincts/personal/` 中的所有 instinct 文件
2. 读取 `~/.claude/homunculus/instincts/inherited/` 中的继承 instincts
3. 将它们按域分组并显示置信度条

## 输出格式

```
📊 Instinct Status
==================

## Code Style (4 instincts)

### prefer-functional-style
Trigger: when writing new functions
Action: Use functional patterns over classes
Confidence: ████████░░ 80%
Source: session-observation | Last updated: 2025-01-22

### use-path-aliases
Trigger: when importing modules
Action: Use @/ path aliases instead of relative imports
Confidence: ██████░░░░ 60%
Source: repo-analysis (github.com/acme/webapp)

## Testing (2 instincts)

### test-first-workflow
Trigger: when adding new functionality
Action: Write test first, then implementation
Confidence: █████████░ 90%
Source: session-observation

## Workflow (3 instincts)

### grep-before-edit
Trigger: when modifying code
Action: Search with Grep, confirm with Read, then Edit
Confidence: ███████░░░ 70%
Source: session-observation

---
Total: 9 instincts (4 personal, 5 inherited)
Observer: Running (last analysis: 5 min ago)
```

## 标志 (Flags)

- `--domain <name>`: 用于过滤 (code-style, testing, git, etc.)
- `--low-confidence`: 仅显示置信度 < 0.5 的 instincts
- `--high-confidence`: 仅显示置信度 >= 0.7 的 instincts
- `--source <type>`: 按来源过滤 (session-observation, repo-analysis, inherited)
- `--json`: 输出为 JSON 以供程序使用
