# Git 工作流 (Git Workflow)

## 提交消息格式

```
<type>: <description>

<optional body>
```

类型: feat, fix, refactor, docs, test, chore, perf, ci

注意: 通过 ~/.claude/settings.json 全局禁用归因 (Attribution)。

## Pull Request 工作流

创建 PR 时：
1. 分析完整提交历史 (不仅仅是最新提交)
2. 使用 `git diff [base-branch]...HEAD` 查看所有更改
3. 起草全面的 PR 摘要
4. 包含带有 TODOs 的测试计划
5. 如果是新分支，使用 `-u` 标志推送

## 特性实施工作流

1. **先计划 (Plan First)**
   - 使用 **planner** agent 创建实施计划
   - 识别依赖关系和风险
   - 分解为阶段

2. **TDD 方法 (TDD Approach)**
   - 使用 **tdd-guide** agent
   - 先写测试 (红)
   - 实施以通过测试 (绿)
   - 重构 (改进)
   - 验证 80%+ 覆盖率

3. **代码审查 (Code Review)**
   - 编写代码后立即使用 **code-reviewer** agent
   - 解决 CRITICAL 和 HIGH 问题
   - 尽可能修复 MEDIUM 问题

4. **提交 & 推送 (Commit & Push)**
   - 详细的提交消息
   - 遵循 conventional commits 格式
