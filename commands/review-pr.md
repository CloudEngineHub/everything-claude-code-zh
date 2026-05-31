---
description: 使用专业智能体进行全面的 PR 审查
---

# 审查 PR

运行全面的多视角拉取请求审查。

## 用法

`/review-pr [PR-编号或-URL] [--focus=comments|tests|errors|types|code|simplify]`

如果未指定 PR，审查当前分支的 PR。如果未指定焦点，运行完整审查栈。

## 步骤

1. 识别 PR：
   - 使用 `gh pr view` 获取 PR 详情、变更文件和 diff
2. 查找项目指导：
   - 查找 `CLAUDE.md`、lint 配置、TypeScript 配置、仓库约定
3. 运行专业审查智能体：
   - `code-reviewer`
   - `comment-analyzer`
   - `pr-test-analyzer`
   - `silent-failure-hunter`
   - `type-design-analyzer`
   - `code-simplifier`
4. 汇总结果：
   - 去重重叠的发现
   - 按严重程度排名
5. 按严重程度分组报告发现

## 置信度规则

仅报告置信度 >= 80 的问题：

- Critical：Bug、安全、数据丢失
- Important：缺失测试、质量问题、风格违规
- Advisory：仅在明确要求时的建议
