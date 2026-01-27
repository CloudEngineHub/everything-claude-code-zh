---
name: instinct-import
description: 从teammates、Skill Creator 或其他来源导入 instincts
command: /instinct-import
implementation: python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py import <file>
---

# Instinct Import Command (Instinct 导入命令)

## 实施

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py import <file-or-url> [--dry-run] [--force] [--min-confidence 0.7]
```

从以下来源导入 instincts：
- 队友的导出
- Skill Creator (repo分析)
- 社区集合
- 之前的机器备份

## 用法

```
/instinct-import team-instincts.yaml
/instinct-import https://github.com/org/repo/instincts.yaml
/instinct-import --from-skill-creator acme/webapp
```

## 做什么

1. 获取 instinct 文件 (本地路径或 URL)
2. 解析并验证格式
3. 检查与现有 instincts 的重复项
4. 合并或添加新 instincts
5. 保存到 `~/.claude/homunculus/instincts/inherited/`

## 导入过程

```
📥 Importing instincts from: team-instincts.yaml
================================================

Found 12 instincts to import.

Analyzing conflicts...

## New Instincts (8)
These will be added:
  ✓ use-zod-validation (confidence: 0.7)
  ✓ prefer-named-exports (confidence: 0.65)
  ✓ test-async-functions (confidence: 0.8)
  ...

## Duplicate Instincts (3)
Already have similar instincts:
  ⚠️ prefer-functional-style
     Local: 0.8 confidence, 12 observations
     Import: 0.7 confidence
     → Keep local (higher confidence)

  ⚠️ test-first-workflow
     Local: 0.75 confidence
     Import: 0.9 confidence
     → Update to import (higher confidence)

## Conflicting Instincts (1)
These contradict local instincts:
  ❌ use-classes-for-services
     Conflicts with: avoid-classes
     → Skip (requires manual resolution)

---
Import 8 new, update 1, skip 3?
```

## 合并策略

### 针对重复项
当导入与现有 instinct 匹配的 instinct 时：
- **Higher confidence wins**: 保留置信度较高的那个
- **Merge evidence**: 合并观察计数
- **Update timestamp**: 标记为最近验证

### 针对冲突
当导入与现有 instinct 矛盾的 instinct 时：
- **Skip by default**: 不导入冲突的 instincts
- **Flag for review**: 标记两者都需要注意
- **Manual resolution**: 用户决定保留哪个

## 源跟踪

导入的 instincts 标记为：
```yaml
source: "inherited"
imported_from: "team-instincts.yaml"
imported_at: "2025-01-22T10:30:00Z"
original_source: "session-observation"  # or "repo-analysis"
```

## Skill Creator 集成

当从 Skill Creator 导入时：

```
/instinct-import --from-skill-creator acme/webapp
```

这会获取从 repo 分析生成的 instincts：
- Source: `repo-analysis`
- 更高的初始置信度 (0.7+)
- 链接到源仓库

## 标志 (Flags)

- `--dry-run`: 预览而不导入
- `--force`: 即使存在冲突也导入
- `--merge-strategy <higher|local|import>`: 如何处理重复项
- `--from-skill-creator <owner/repo>`: 从 Skill Creator 分析导入
- `--min-confidence <n>`: 仅导入高于阈值的 instincts

## 输出

导入后：
```
✅ Import complete!

Added: 8 instincts
Updated: 1 instinct
Skipped: 3 instincts (2 duplicates, 1 conflict)

New instincts saved to: ~/.claude/homunculus/instincts/inherited/

Run /instinct-status to see all instincts.
```
