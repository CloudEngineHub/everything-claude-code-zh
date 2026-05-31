---
name: eval-harness
description: 实现评估驱动开发 (EDD) 原则的 Claude Code 会话的正式评估框架
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Eval Harness 技能

Claude Code 会话的正式评估框架，实现评估驱动开发 (EDD) 原则。

## 何时激活

- 为 AI 辅助工作流设置评估驱动开发 (EDD)
- 定义 Claude Code 任务完成的通过/失败标准
- 使用 pass@k 指标测量代理可靠性
- 为提示或代理更改创建回归测试套件
- 跨模型版本对代理性能进行基准测试

## 理念

评估驱动开发将评估视为"AI 开发的单元测试"：
- 在实现之前定义预期行为
- 在开发期间持续运行评估
- 跟踪每次更改的回归
- 使用 pass@k 指标进行可靠性测量

## 评估类型

### 能力评估
测试 Claude 能否做以前做不到的事情：
```markdown
[能力评估：功能名称]
任务：Claude 应该完成的内容的描述
成功标准：
  - [ ] 标准 1
  - [ ] 标准 2
  - [ ] 标准 3
预期输出：预期结果的描述
```

### 回归评估
确保更改不会破坏现有功能：
```markdown
[回归评估：功能名称]
基线：SHA 或检查点名称
测试：
  - existing-test-1: PASS/FAIL
  - existing-test-2: PASS/FAIL
  - existing-test-3: PASS/FAIL
结果：X/Y 通过（之前 Y/Y）
```

## 评分者类型

### 1. 基于代码的评分者
使用代码的确定性检查：
```bash
# 检查文件是否包含预期模式
grep -q "export function handleAuth" src/auth.ts && echo "PASS" || echo "FAIL"

# 检查测试是否通过
npm test -- --testPathPattern="auth" && echo "PASS" || echo "FAIL"

# 检查构建是否成功
npm run build && echo "PASS" || echo "FAIL"
```

### 2. 基于模型的评分者
使用 Claude 评估开放式输出：
```markdown
[模型评分者提示]
评估以下代码更改：
1. 它是否解决了所述问题？
2. 它是否结构良好？
3. 是否处理了边缘情况？
4. 错误处理是否合适？

分数：1-5（1=差，5=优秀）
推理：[解释]
```

### 3. 人工评分者
标记供手动审查：
```markdown
[需要人工审查]
更改：更改内容的描述
原因：为什么需要人工审查
风险级别：低/中/高
```

## 指标

### pass@k
"k 次尝试中至少一次成功"
- pass@1：首次尝试成功率
- pass@3：3 次尝试内成功
- 典型目标：pass@3 > 90%

### pass^k
"所有 k 次试验都成功"
- 更高的可靠性标准
- pass^3：3 次连续成功
- 用于关键路径

## 评估工作流

### 1. 定义（编码之前）
```markdown
## 评估定义：feature-xyz

### 能力评估
1. 可以创建新用户账户
2. 可以验证电子邮件格式
3. 可以安全地哈希密码

### 回归评估
1. 现有登录仍然有效
2. 会话管理不变
3. 注销流程完好

### 成功指标
- 能力评估的 pass@3 > 90%
- 回归评估的 pass^3 = 100%
```

### 2. 实现
编写代码以通过定义的评估。

### 3. 评估
```bash
# 运行能力评估
[运行每个能力评估，记录 PASS/FAIL]

# 运行回归评估
npm test -- --testPathPattern="existing"

# 生成报告
```

### 4. 报告
```markdown
评估报告：feature-xyz
========================

能力评估：
  create-user:     PASS (pass@1)
  validate-email:  PASS (pass@2)
  hash-password:   PASS (pass@1)
  总计：         3/3 通过

回归评估：
  login-flow:      PASS
  session-mgmt:    PASS
  logout-flow:     PASS
  总计：         3/3 通过

指标：
  pass@1: 67% (2/3)
  pass@3: 100% (3/3)

状态：准备审查
```

## 集成模式

### 实现前
```
/eval define feature-name
```
在 `.claude/evals/feature-name.md` 创建评估定义文件

### 实现期间
```
/eval check feature-name
```
运行当前评估并报告状态

### 实现后
```
/eval report feature-name
```
生成完整的评估报告

## 评估存储

在项目中存储评估：
```
.claude/
  evals/
    feature-xyz.md      # 评估定义
    feature-xyz.log     # 评估运行历史
    baseline.json       # 回归基线
```

## 最佳实践

1. **在编码之前定义评估** - 强制对成功标准进行清晰思考
2. **频繁运行评估** - 尽早发现回归
3. **跟踪 pass@k 趋势** - 监控可靠性趋势
4. **尽可能使用代码评分者** - 确定性 > 概率性
5. **安全的人工审查** - 永远不要完全自动化安全检查
6. **保持评估快速** - 慢评估不会运行
7. **评估与代码一起版本化** - 评估是一等工件

## 示例：添加身份验证

```markdown
## 评估：add-authentication

### 阶段 1：定义 (10 分钟)
能力评估：
- [ ] 用户可以使用电子邮件/密码注册
- [ ] 用户可以使用有效凭据登录
- [ ] 无效凭据被拒绝并显示适当错误
- [ ] 会话跨页面重新加载持久化
- [ ] 注销清除会话

回归评估：
- [ ] 公共路由仍然可访问
- [ ] API 响应不变
- [ ] 数据库架构兼容

### 阶段 2：实现（变化）
[编写代码]

### 阶段 3：评估
运行：/eval check add-authentication

### 阶段 4：报告
评估报告：add-authentication
==============================
能力：5/5 通过 (pass@3: 100%)
回归：3/3 通过 (pass^3: 100%)
状态：发布
```
