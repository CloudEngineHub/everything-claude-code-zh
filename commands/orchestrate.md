# Orchestrate 命令 (编排命令)

用于复杂任务的顺序 agent 工作流。

## 用法

`/orchestrate [workflow-type] [task-description]`

## 工作流类型

### feature (功能)
完整的功能实现工作流：
```
planner -> tdd-guide -> code-reviewer -> security-reviewer
```

### bugfix (修复)
Bug 调查和修复工作流：
```
explorer -> tdd-guide -> code-reviewer
```

### refactor (重构)
安全的重构工作流：
```
architect -> code-reviewer -> tdd-guide
```

### security (安全)
专注于安全的审查：
```
security-reviewer -> code-reviewer -> architect
```

## 执行模式

对于工作流中的每个 agent：

1. 使用来自上一个 agent 的上下文 **调用 agent**
2. **收集输出** 为结构化的交接 (handoff) 文档
3. **传递给下一个 agent**
4. **汇总结果** 到最终报告中

## 交接 (Handoff) 文档格式

在 agents 之间，创建交接文档：

```markdown
## HANDOFF: [previous-agent] -> [next-agent]

### Context
[已完成工作的摘要]

### Findings
[关键发现或决定]

### Files Modified
[触及的文件列表]

### Open Questions
[留给下一个 agent 的未解决事项]

### Recommendations
[建议的后续步骤]
```

## 示例：Feature 工作流

```
/orchestrate feature "Add user authentication"
```

执行：

1. **Planner Agent**
   - 分析需求
   - 创建实现计划
   - 识别依赖
   - 输出: `HANDOFF: planner -> tdd-guide`

2. **TDD Guide Agent**
   - 读取 planner 交接
   - 先编写测试
   - 实现以通过测试
   - 输出: `HANDOFF: tdd-guide -> code-reviewer`

3. **Code Reviewer Agent**
   - 审查实现
   - 检查问题
   - 建议改进
   - 输出: `HANDOFF: code-reviewer -> security-reviewer`

4. **Security Reviewer Agent**
   - 安全审计
   - 漏洞检查
   - 最终批准
   - 输出: Final Report

## 最终报告格式

```
ORCHESTRATION REPORT
====================
Workflow: feature
Task: Add user authentication
Agents: planner -> tdd-guide -> code-reviewer -> security-reviewer

SUMMARY
-------
[一段摘要]

AGENT OUTPUTS
-------------
Planner: [summary]
TDD Guide: [summary]
Code Reviewer: [summary]
Security Reviewer: [summary]

FILES CHANGED
-------------
[所有修改的文件列表]

TEST RESULTS
------------
[测试通过/失败摘要]

SECURITY STATUS
---------------
[安全发现]

RECOMMENDATION
--------------
[SHIP / NEEDS WORK / BLOCKED]
```

## 并行执行

对于独立的检查，并行运行 agents：

```markdown
### Parallel Phase
Run simultaneously:
- code-reviewer (质量)
- security-reviewer (安全)
- architect (设计)

### Merge Results
Combine outputs into single report
```

## 参数

$ARGUMENTS:
- `feature <description>` - 完整的功能工作流
- `bugfix <description>` - Bug 修复工作流
- `refactor <description>` - 重构工作流
- `security <description>` - 安全审查工作流
- `custom <agents> <description>` - 自定义 agent 序列

## 自定义工作流示例

```
/orchestrate custom "architect,tdd-guide,code-reviewer" "Redesign caching layer"
```

## 提示

1. 对于复杂功能 **从 planner 开始**
2. 合并前 **始终包含 code-reviewer**
3. 对于 auth/支付/个人信息识别 (PII) **使用 security-reviewer**
4. **保持交接简明** - 专注于下一个 agent 需要什么
5. 如果需要，在 agents 之间 **运行验证**
