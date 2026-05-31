---
name: eval-harness
description: Claude Code 会话的正式评估框架，实施 eval-driven development (EDD) 原则
tools: Read, Write, Edit, Bash, Grep, Glob
origin: ECC
---

# Eval Harness Skill

Claude Code 会话的正式评估框架，实施评估驱动开发 (eval-driven development, EDD) 原则。

## 哲学

评估驱动开发将 evals 视为 "AI 开发的单元测试":
- 在实施之前定义预期行为
- 在开发过程中持续运行 evals
- 随每次变更跟踪回归
- 使用 pass@k 指标进行可靠性测量

## Eval 类型

### 能力评估 (Capability Evals)
测试 Claude 是否能做以前不能做的事情：
```markdown
[CAPABILITY EVAL: feature-name]
Task: Description of what Claude should accomplish
Success Criteria:
  - [ ] Criterion 1
  - [ ] Criterion 2
  - [ ] Criterion 3
Expected Output: Description of expected result
```

### 回归评估 (Regression Evals)
确保变更不会破坏现有功能：
```markdown
[REGRESSION EVAL: feature-name]
Baseline: SHA or checkpoint name
Tests:
  - existing-test-1: PASS/FAIL
  - existing-test-2: PASS/FAIL
  - existing-test-3: PASS/FAIL
Result: X/Y passed (previously Y/Y)
```

## 评分器类型 (Grader Types)

### 1. 基于代码的评分器
使用代码进行确定性检查：
```bash
# Check if file contains expected pattern
grep -q "export function handleAuth" src/auth.ts && echo "PASS" || echo "FAIL"

# Check if tests pass
npm test -- --testPathPattern="auth" && echo "PASS" || echo "FAIL"

# Check if build succeeds
npm run build && echo "PASS" || echo "FAIL"
```

### 2. 基于模型的评分器
使用 Claude 评估开放式输出：
```markdown
[MODEL GRADER PROMPT]
Evaluate the following code change:
1. Does it solve the stated problem?
2. Is it well-structured?
3. Are edge cases handled?
4. Is error handling appropriate?

Score: 1-5 (1=poor, 5=excellent)
Reasoning: [explanation]
```

### 3. 人类评分器
标记以进行人工审查：
```markdown
[HUMAN REVIEW REQUIRED]
Change: Description of what changed
Reason: Why human review is needed
Risk Level: LOW/MEDIUM/HIGH
```

## 指标

### pass@k
"k 次尝试中至少有一次成功"
- pass@1: 第一次尝试成功率
- pass@3: 3 次尝试内成功
- 典型目标: pass@3 > 90%

### pass^k
"所有 k 次试验都成功"
- 对可靠性的更高要求
- pass^3: 3 次连续成功
- 用于关键路径

## Eval 工作流

### 1. 定义 (Before Coding)
```markdown
## EVAL DEFINITION: feature-xyz

### Capability Evals
1. Can create new user account
2. Can validate email format
3. Can hash password securely

### Regression Evals
1. Existing login still works
2. Session management unchanged
3. Logout flow intact

### Success Metrics
- pass@3 > 90% for capability evals
- pass^3 = 100% for regression evals
```

### 2. 实施 (Implement)
编写代码以通过定义的 evals。

### 3. 评估 (Evaluate)
```bash
# Run capability evals
[Run each capability eval, record PASS/FAIL]

# Run regression evals
npm test -- --testPathPattern="existing"

# Generate report
```

### 4. 报告 (Report)
```markdown
EVAL REPORT: feature-xyz
========================

Capability Evals:
  create-user:     PASS (pass@1)
  validate-email:  PASS (pass@2)
  hash-password:   PASS (pass@1)
  Overall:         3/3 passed

Regression Evals:
  login-flow:      PASS
  session-mgmt:    PASS
  logout-flow:     PASS
  Overall:         3/3 passed

Metrics:
  pass@1: 67% (2/3)
  pass@3: 100% (3/3)

Status: READY FOR REVIEW
```

## 集成模式

### 实施前 (Pre-Implementation)
```
/eval define feature-name
```
在 `.claude/evals/feature-name.md` 创建 eval 定义文件

### 实施期间 (During Implementation)
```
/eval check feature-name
```
运行当前 evals 并报告状态

### 实施后 (Post-Implementation)
```
/eval report feature-name
```
生成完整 eval 报告

## Eval 存储

在项目中存储 evals:
```
.claude/
  evals/
    feature-xyz.md      # Eval definition
    feature-xyz.log     # Eval run history
    baseline.json       # Regression baselines
```

## 最佳实践

1. **在编码之前定义 evals** - 强制清晰思考成功标准
2. **频繁运行 evals** - 尽早捕获回归
3. **随时间跟踪 pass@k** - 监控可靠性趋势
4. **尽可能使用代码评分器** - 确定性 > 概率性
5. **安全的人工审查** - 永远不要完全自动化安全检查
6. **保持 evals 快速** - 慢的 evals 不会被运行
7. **与代码一起版本化 evals** - Evals 是一等工件

## 示例: 添加认证

```markdown
## EVAL: add-authentication

### Phase 1: Define (10 min)
Capability Evals:
- [ ] User can register with email/password
- [ ] User can login with valid credentials
- [ ] Invalid credentials rejected with proper error
- [ ] Sessions persist across page reloads
- [ ] Logout clears session

Regression Evals:
- [ ] Public routes still accessible
- [ ] API responses unchanged
- [ ] Database schema compatible

### Phase 2: Implement (varies)
[Write code]

### Phase 3: Evaluate
Run: /eval check add-authentication

### Phase 4: Report
EVAL REPORT: add-authentication
==============================
Capability: 5/5 passed (pass@3: 100%)
Regression: 3/3 passed (pass^3: 100%)
Status: SHIP IT
```
