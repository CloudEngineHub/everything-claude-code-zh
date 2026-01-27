# Eval 命令

管理 eval 驱动的开发工作流。

## 用法

`/eval [define|check|report|list] [feature-name]`

## 定义 Evals

`/eval define feature-name`

创建一个新的 eval 定义：

1. 创建 `.claude/evals/feature-name.md`，使用模板：

```markdown
## EVAL: feature-name
Created: $(date)

### Capability Evals (能力评估)
- [ ] [能力 1 的描述]
- [ ] [能力 2 的描述]

### Regression Evals (回归评估)
- [ ] [现有行为 1 仍然工作]
- [ ] [现有行为 2 仍然工作]

### Success Criteria (成功标准)
- pass@3 > 90% for capability evals
- pass^3 = 100% for regression evals
```

2. 提示用户填写具体标准

## 检查 Evals

`/eval check feature-name`

为某一功能运行 evals：

1. 从 `.claude/evals/feature-name.md` 读取 eval 定义
2. 对于每个 capability eval：
   - 尝试验证标准
   - 记录 PASS/FAIL
   - 将尝试记录在 `.claude/evals/feature-name.log` 中
3. 对于每个 regression eval：
   - 运行相关测试
   - 与基准进行比较
   - 记录 PASS/FAIL
4. 报告当前状态：

```
EVAL CHECK: feature-name
========================
Capability: X/Y passing
Regression: X/Y passing
Status: IN PROGRESS / READY
```

## 报告 Evals

`/eval report feature-name`

生成全面的 eval 报告：

```
EVAL REPORT: feature-name
=========================
Generated: $(date)

CAPABILITY EVALS
----------------
[eval-1]: PASS (pass@1)
[eval-2]: PASS (pass@2) - required retry
[eval-3]: FAIL - see notes

REGRESSION EVALS
----------------
[test-1]: PASS
[test-2]: PASS
[test-3]: PASS

METRICS
-------
Capability pass@1: 67%
Capability pass@3: 100%
Regression pass^3: 100%

NOTES
-----
[Any issues, edge cases, or observations]

RECOMMENDATION
--------------
[SHIP / NEEDS WORK / BLOCKED]
```

## 列出 Evals

`/eval list`

显示所有 eval 定义：

```
EVAL DEFINITIONS
================
feature-auth      [3/5 passing] IN PROGRESS
feature-search    [5/5 passing] READY
feature-export    [0/4 passing] NOT STARTED
```

## 参数

$ARGUMENTS:
- `define <name>` - 创建新的 eval 定义
- `check <name>` - 运行并检查 evals
- `report <name>` - 生成完整报告
- `list` - 显示所有 evals
- `clean` - 移除旧的 eval 日志（保留最后 10 次运行）
