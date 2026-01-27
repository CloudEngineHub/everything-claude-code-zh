# Agent 编排 (Agent Orchestration)

## 可用 Agents

位于 `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | 实施规划 | 复杂特性，重构 |
| architect | 系统设计 | 架构决策 |
| tdd-guide | 测试驱动开发 | 新特性，bug 修复 |
| code-reviewer | 代码审查 | 编写代码后 |
| security-reviewer | 安全分析 | 提交之前 |
| build-error-resolver | 修复构建错误 | 当构建失败时 |
| e2e-runner | E2E 测试 | 关键用户流程 |
| refactor-cleaner | 死代码清理 | 代码维护 |
| doc-updater | 文档 | 更新文档 |

## 立即 Agent 使用 (Immediate Agent Usage)

无需用户提示：
1. 复杂特性请求 - 使用 **planner** agent
2. 刚刚写入/修改的代码 - 使用 **code-reviewer** agent
3. Bug 修复或新特性 - 使用 **tdd-guide** agent
4. 架构决策 - 使用 **architect** agent

## 并行任务执行 (Parallel Task Execution)

对于独立操作，始终使用并行任务执行：

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth.ts
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utils.ts

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## 多视角分析 (Multi-Perspective Analysis)

对于复杂问题，使用拆分角色的子 agent：
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
