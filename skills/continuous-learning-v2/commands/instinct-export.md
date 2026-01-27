---
name: instinct-export
description: 导出 instincts 以与队友或其他项目共享
command: /instinct-export
---

# Instinct Export Command (Instinct 导出命令)

将 instincts 导出为可共享格式。适用于：
- 与队友共享
- 传输到新机器
- 为项目约定做贡献

## 用法

```
/instinct-export                           # 导出所有个人 instincts
/instinct-export --domain testing          # 仅导出 testing instincts
/instinct-export --min-confidence 0.7      # 仅导出高置信度 instincts
/instinct-export --output team-instincts.yaml
```

## 做什么

1. 读取 `~/.claude/homunculus/instincts/personal/` 中的 instincts
2. 基于标志过滤
3. 剥离敏感信息：
   - 移除会话 ID
   - 移除文件路径 (仅保留模式)
   - 移除早于 "last week" 的时间戳
4. 生成导出文件

## 输出格式

创建一个 YAML 文件：

```yaml
# Instincts Export
# Generated: 2025-01-22
# Source: personal
# Count: 12 instincts

version: "2.0"
exported_by: "continuous-learning-v2"
export_date: "2025-01-22T10:30:00Z"

instincts:
  - id: prefer-functional-style
    trigger: "when writing new functions"
    action: "Use functional patterns over classes"
    confidence: 0.8
    domain: code-style
    observations: 8

  - id: test-first-workflow
    trigger: "when adding new functionality"
    action: "Write test first, then implementation"
    confidence: 0.9
    domain: testing
    observations: 12

  - id: grep-before-edit
    trigger: "when modifying code"
    action: "Search with Grep, confirm with Read, then Edit"
    confidence: 0.7
    domain: workflow
    observations: 6
```

## 隐私注意事项

导出包含：
- ✅ 触发模式
- ✅ 动作
- ✅ 置信度分数
- ✅ 域
- ✅ 观察计数

导出 **不** 包含：
- ❌ 实际代码片段
- ❌ 文件路径
- ❌ 会话记录
- ❌ 个人标识符

## 标志 (Flags)

- `--domain <name>`: 仅导出指定域
- `--min-confidence <n>`: 最小置信度阈值 (默认: 0.3)
- `--output <file>`: 输出文件路径 (默认: instincts-export-YYYYMMDD.yaml)
- `--format <yaml|json|md>`: 输出格式 (默认: yaml)
- `--include-evidence`: 包含证据文本 (默认: 排除)
