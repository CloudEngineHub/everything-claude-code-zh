# 验证循环技能 (Verification Loop Skill)

Claude Code 会话的综合验证系统。

## 何时使用

在以下情况调用此技能：
- 完成特性或重大代码更改后
- 创建 PR 之前
- 当你想确保通过质量门控时
- 重构之后

## 验证阶段

### 阶段 1: 构建验证 (Build Verification)
```bash
# Check if project builds
npm run build 2>&1 | tail -20
# OR
pnpm build 2>&1 | tail -20
```

如果构建失败，停止并在继续之前修复。

### 阶段 2: 类型检查 (Type Check)
```bash
# TypeScript projects
npx tsc --noEmit 2>&1 | head -30

# Python projects
pyright . 2>&1 | head -30
```

报告所有类型错误。在继续之前修复关键错误。

### 阶段 3: Lint 检查 (Lint Check)
```bash
# JavaScript/TypeScript
npm run lint 2>&1 | head -30

# Python
ruff check . 2>&1 | head -30
```

### 阶段 4: 测试套件 (Test Suite)
```bash
# Run tests with coverage
npm run test -- --coverage 2>&1 | tail -50

# Check coverage threshold
# Target: 80% minimum
```

报告:
- 总测试数: X
- 通过: X
- 失败: X
- 覆盖率: X%

### 阶段 5: 安全扫描 (Security Scan)
```bash
# Check for secrets
grep -rn "sk-" --include="*.ts" --include="*.js" . 2>/dev/null | head -10
grep -rn "api_key" --include="*.ts" --include="*.js" . 2>/dev/null | head -10

# Check for console.log
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10
```

### 阶段 6: 差异审查 (Diff Review)
```bash
# Show what changed
git diff --stat
git diff HEAD~1 --name-only
```

审查每个更改的文件：
- 意外更改
- 缺失的错误处理
- 潜在边缘情况

## 输出格式

运行所有阶段后，生成验证报告：

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## 连续模式

对于长会话，每 15 分钟或重大更改后运行验证：

```markdown
设置心理检查点:
- After completing each function
- After finishing a component
- Before moving to next task

Run: /verify
```

## 与 Hooks 集成

此技能补充 PostToolUse hooks，但提供更深入的验证。
Hooks 立即捕获问题；此技能提供全面审查。
