---
name: everything-claude-code-conventions
description: everything-claude-code 的开发约定和模式。使用 Conventional Commits 的 JavaScript 项目。
---

# Everything Claude Code 约定

> 从 [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) 于 2026-03-20 生成

## 概述

此技能教 Claude everything-claude-code 中使用的开发模式和约定。

## 技术栈

- **主要语言**：JavaScript
- **架构**：混合模块组织
- **测试位置**：separate

## 何时使用此技能

在以下情况下激活此技能：
- 更改此仓库
- 按照既定模式添加新功能
- 编写符合项目约定的测试
- 创建具有正确消息格式的提交

## 提交约定

遵循基于 500 个已分析提交的这些提交消息约定。

### 提交样式：Conventional Commits

### 使用的前缀

- `fix`
- `test`
- `feat`
- `docs`

### 消息指南

- 平均消息长度：约 65 个字符
- 保持第一行简洁和描述性
- 使用祈使语气（"添加功能"而非"已添加功能"）


*提交消息示例*

```text
feat(rules): 添加 C# 语言支持
```

*提交消息示例*

```text
chore(deps-dev): 更新 flatted (#675)
```

*提交消息示例*

```text
fix: 当 CLAUDE_PLUGIN_ROOT 未设置时从插件缓存自动检测 ECC 根目录 (#547) (#691)
```

*提交消息示例*

```text
docs: 添加 Antigravity 设置和使用指南 (#552)
```

*提交消息示例*

```text
merge: PR #529 — feat(skills): 添加 documentation-lookup、bun-runtime、nextjs-turbopack；feat(agents): 添加 rust-reviewer
```

*提交消息示例*

```text
Revert "添加 Kiro IDE 支持 (.kiro/) (#548)"
```

*提交消息示例*

```text
添加 Kiro IDE 支持 (.kiro/) (#548)
```

*提交消息示例*

```text
feat: 为 Claude Code 和 Cursor 添加 block-no-verify 钩子 (#649)
```

## 架构

### 项目结构：单一包

此项目使用**混合**模块组织。

### 配置文件

- `.github/workflows/ci.yml`
- `.github/workflows/maintenance.yml`
- `.github/workflows/monthly-metrics.yml`
- `.github/workflows/release.yml`
- `.github/workflows/reusable-release.yml`
- `.github/workflows/reusable-test.yml`
- `.github/workflows/reusable-validate.yml`
- `.opencode/package.json`
- `.opencode/tsconfig.json`
- `.prettierrc`
- `eslint.config.js`
- `package.json`

### 指南

- 此项目使用混合组织
- 添加新代码时遵循现有模式

## 代码风格

### 语言：JavaScript

### 命名约定

| 元素 | 约定 |
|---------|------------|
| 文件 | camelCase |
| 函数 | camelCase |
| 类 | PascalCase |
| 常量 | SCREAMING_SNAKE_CASE |

### 导入样式：相对导入

### 导出样式：混合样式


*首选导入样式*

```typescript
// 使用相对导入
import { Button } from '../components/Button'
import { useAuth } from './hooks/useAuth'
```

## 测试

### 测试框架

未检测到特定测试框架 — 使用仓库的现有测试模式。

### 文件模式：`*.test.js`

### 测试类型

- **单元测试**：单独测试单个函数和组件
- **集成测试**：测试多个组件/服务之间的交互

### 覆盖率

此项目已配置覆盖率报告。目标为 80%+ 覆盖率。


## 错误处理

### 错误处理样式：Try-Catch 块


*标准错误处理模式*

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('操作失败:', error)
  throw new Error('用户友好的消息')
}
```

## 常见工作流

这些工作流是从分析提交模式中检测到的。

### 数据库迁移

带有迁移文件的数据库 schema 更改

**频率**：每月约 2 次

**步骤**：
1. 创建迁移文件
2. 更新 schema 定义
3. 生成/更新类型

**典型涉及的文件**：
- `**/schema.*`
- `migrations/*`

**示例提交序列**：
```
feat: 实现 --with/--without 选择性安装标志 (#679)
fix: 同步目录计数与文件系统（27 个代理、113 个技能、58 个命令）(#693)
feat(rules): 添加 Rust 语言规则（基于 #660 的 rebase）(#686)
```

### 功能开发

标准功能实现工作流

**频率**：每月约 22 次

**步骤**：
1. 添加功能实现
2. 为功能添加测试
3. 更新文档

**典型涉及的文件**：
- `manifests/*`
- `schemas/*`
- `**/*.test.*`
- `**/api/**`

**示例提交序列**：
```
feat(skills): 添加 documentation-lookup、bun-runtime、nextjs-turbopack；feat(agents): 添加 rust-reviewer
docs(skills): 使 documentation-lookup 与 CONTRIBUTING 模板对齐；添加跨 harness（Codex/Cursor）技能副本
fix: 解决 PR 审查 — 技能模板（何时使用、如何工作、示例）、bun.lock、next build 注释、rust-reviewer CI 注释、doc-lookup 隐私/不确定性
```

### 添加语言规则

向规则系统添加新的编程语言，包括编码风格、钩子、模式、安全和测试指南。

**频率**：每月约 2 次

**步骤**：
1. 在 rules/{language}/ 下创建新目录
2. 添加具有特定语言内容的 coding-style.md、hooks.md、patterns.md、security.md 和 testing.md 文件
3. 可选地引用或链接到相关技能

**典型涉及的文件**：
- `rules/*/coding-style.md`
- `rules/*/hooks.md`
- `rules/*/patterns.md`
- `rules/*/security.md`
- `rules/*/testing.md`

**示例提交序列**：
```
在 rules/{language}/ 下创建新目录
添加具有特定语言内容的 coding-style.md、hooks.md、patterns.md、security.md 和 testing.md 文件
可选地引用或链接到相关技能
```

### 添加新技能

向系统添加新技能，记录其工作流、触发器和用法，通常带有支持脚本。

**频率**：每月约 4 次

**步骤**：
1. 在 skills/{skill-name}/ 下创建新目录
2. 添加带有文档的 SKILL.md（何时使用、如何工作、示例等）
3. 可选地在 skills/{skill-name}/scripts/ 下添加脚本或支持文件
4. 解决审查反馈并迭代文档

**典型涉及的文件**：
- `skills/*/SKILL.md`
- `skills/*/scripts/*.sh`
- `skills/*/scripts/*.js`

**示例提交序列**：
```
在 skills/{skill-name}/ 下创建新目录
添加带有文档的 SKILL.md（何时使用、如何工作、示例等）
可选地在 skills/{skill-name}/scripts/ 下添加脚本或支持文件
解决审查反馈并迭代文档
```

### 添加新代理

向系统添加新代理，用于代码审查、构建解决或其他自动化任务。

**频率**：每月约 2 次

**步骤**：
1. 在 agents/{agent-name}.md 下创建新代理 markdown 文件
2. 在 AGENTS.md 中注册代理
3. 可选地更新 README.md 和 docs/COMMAND-AGENT-MAP.md

**典型涉及的文件**：
- `agents/*.md`
- `AGENTS.md`
- `README.md`
- `docs/COMMAND-AGENT-MAP.md`

**示例提交序列**：
```
在 agents/{agent-name}.md 下创建新代理 markdown 文件
在 AGENTS.md 中注册代理
可选地更新 README.md 和 docs/COMMAND-AGENT-MAP.md
```

### 添加新命令

向系统添加新命令，通常与后备技能配对。

**频率**：每月约 1 次

**步骤**：
1. 在 commands/{command-name}.md 下创建新 markdown 文件
2. 可选地在 skills/{skill-name}/SKILL.md 下添加或更新后备技能

**典型涉及的文件**：
- `commands/*.md`
- `skills/*/SKILL.md`

**示例提交序列**：
```
在 commands/{command-name}.md 下创建新 markdown 文件
可选地在 skills/{skill-name}/SKILL.md 下添加或更新后备技能
```

### 同步目录计数

将 AGENTS.md 和 README.md 中记录的代理、技能和命令计数与实际仓库状态同步。

**频率**：每月约 3 次

**步骤**：
1. 更新 AGENTS.md 中的代理、技能和命令计数
2. 更新 README.md 中的相同计数（快速入门、比较表等）
3. 可选地更新其他文档文件

**典型涉及的文件**：
- `AGENTS.md`
- `README.md`

**示例提交序列**：
```
更新 AGENTS.md 中的代理、技能和命令计数
更新 README.md 中的相同计数（快速入门、比较表等）
可选地更新其他文档文件
```

### 添加跨 Harness 技能副本

为不同的 agent harness（例如 Codex、Cursor、Antigravity）添加技能副本，以确保跨平台兼容性。

**频率**：每月约 2 次

**步骤**：
1. 将 SKILL.md 复制或调整到 .agents/skills/{skill}/SKILL.md 和/或 .cursor/skills/{skill}/SKILL.md
2. 可选地添加特定于 harness 的 openai.yaml 或配置文件
3. 解决审查反馈以与 CONTRIBUTING 模板对齐

**典型涉及的文件**：
- `.agents/skills/*/SKILL.md`
- `.cursor/skills/*/SKILL.md`
- `.agents/skills/*/agents/openai.yaml`

**示例提交序列**：
```
将 SKILL.md 复制或调整到 .agents/skills/{skill}/SKILL.md 和/或 .cursor/skills/{skill}/SKILL.md
可选地添加特定于 harness 的 openai.yaml 或配置文件
解决审查反馈以与 CONTRIBUTING 模板对齐
```

### 添加或更新钩子

添加或更新 git 或 bash 钩子以强制执行工作流、质量或安全策略。

**频率**：每月约 1 次

**步骤**：
1. 在 hooks/ 或 scripts/hooks/ 中添加或更新钩子脚本
2. 在 hooks/hooks.json 或类似配置中注册钩子
3. 可选地在 tests/hooks/ 中添加或更新测试

**典型涉及的文件**：
- `hooks/*.hook`
- `hooks/hooks.json`
- `scripts/hooks/*.js`
- `tests/hooks/*.test.js`
- `.cursor/hooks.json`

**示例提交序列**：
```
在 hooks/ 或 scripts/hooks/ 中添加或更新钩子脚本
在 hooks/hooks.json 或类似配置中注册钩子
可选地在 tests/hooks/ 中添加或更新测试
```

### 解决审查反馈

通过更新文档、脚本或配置来解决代码审查反馈，以提高清晰度、正确性或约定对齐。

**频率**：每月约 4 次

**步骤**：
1. 编辑 SKILL.md、代理或命令文件以解决审查者评论
2. 根据请求更新示例、标题或配置
3. 迭代直到所有审查反馈解决

**典型涉及的文件**：
- `skills/*/SKILL.md`
- `agents/*.md`
- `commands/*.md`
- `.agents/skills/*/SKILL.md`
- `.cursor/skills/*/SKILL.md`

**示例提交序列**：
```
编辑 SKILL.md、代理或命令文件以解决审查者评论
根据请求更新示例、标题或配置
迭代直到所有审查反馈解决
```


## 最佳实践

基于代码库分析，遵循这些实践：

### 应该

- 使用传统提交格式（feat:、fix: 等）
- 遵循 *.test.js 命名模式
- 文件名使用 camelCase
- 优先使用混合导出

### 不应该

- 不要编写模糊的提交消息
- 不要跳过新功能的测试
- 不要在未经讨论的情况下偏离既定模式

---

*此技能由 [ECC Tools](https://ecc.tools) 自动生成。根据需要为您的团队审查和自定义。*
