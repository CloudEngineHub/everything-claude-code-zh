# 为 Everything Claude Code 做贡献

感谢你想做贡献！此仓库是 Claude Code 用户的社区资源。

## 目录

- [我们在寻找什么](#我们在寻找什么)
- [快速开始](#快速开始)
- [贡献 Skills](#贡献-skills)
- [Skill 适配策略](#skill-适配策略)
- [贡献 Agents](#贡献-agents)
- [贡献 Hooks](#贡献-hooks)
- [贡献 Commands](#贡献-commands)
- [MCP 和文档（如 Context7）](#mcp-和文档如-context7)
- [跨工具链和翻译](#跨工具链和翻译)
- [Pull Request 流程](#pull-request-流程)

---

## 我们在寻找什么

### Agents
处理特定任务的新 agent：
- 语言特定的审查器 (Python, Go, Rust)
- 框架专家 (Django, Rails, Laravel, Spring)
- DevOps 专家 (Kubernetes, Terraform, CI/CD)
- 领域专家 (ML 管道, 数据工程, 移动端)

### Skills
工作流定义和领域知识：
- 语言最佳实践
- 框架模式
- 测试策略
- 架构指南

### Hooks
有用的自动化：
- Linting/格式化 hooks
- 安全检查
- 验证 hooks
- 通知 hooks

### Commands
调用有用工作流的斜杠命令：
- 部署命令
- 测试命令
- 代码生成命令

---

## 快速开始

```bash
# 1. Fork 并克隆
gh repo fork affaan-m/everything-claude-code --clone
cd everything-claude-code

# 2. 创建分支
git checkout -b feat/my-contribution

# 3. 添加你的贡献（参见下面的章节）

# 4. 本地测试
cp -r skills/my-skill ~/.claude/skills/  # 对于 skills
# 然后使用 Claude Code 进行测试

# 5. 提交 PR
git add . && git commit -m "feat: add my-skill" && git push -u origin feat/my-contribution
```

---

## 贡献 Skills

Skills 是 Claude Code 根据上下文加载的知识模块。

> **综合指南：** 有关创建有效 skill 的详细指导，请参阅 [Skill 开发指南](docs/SKILL-DEVELOPMENT-GUIDE.md)。它涵盖了：
> - Skill 架构和类别
> - 编写有效内容和示例
> - 最佳实践和常见模式
> - 测试和验证
> - 完整示例库

### 目录结构

```
skills/
└── your-skill-name/
    └── SKILL.md
```

### SKILL.md 模板

```markdown
---
name: your-skill-name
description: Brief description shown in skill list and used for auto-activation
origin: ECC
---

# Your Skill Title

Brief overview of what this skill covers.

## When to Activate

Describe scenarios where Claude should use this skill. This is critical for auto-activation.

## Core Concepts

Explain key patterns and guidelines.

## Code Examples

\`\`\`typescript
// Include practical, tested examples
function example() {
  // Well-commented code
}
\`\`\`

## Anti-Patterns

Show what NOT to do with examples.

## Best Practices

- Actionable guidelines
- Do's and don'ts
- Common pitfalls to avoid

## Related Skills

Link to complementary skills (e.g., `related-skill-1`, `related-skill-2`).
```

### Skill 类别

| 类别 | 目的 | 示例 |
|------|------|------|
| **语言标准** | 惯用法、约定、最佳实践 | `python-patterns`、`golang-patterns` |
| **框架模式** | 框架特定指导 | `django-patterns`、`nextjs-patterns` |
| **工作流** | 分步流程 | `tdd-workflow`、`refactoring-workflow` |
| **领域知识** | 专业领域 | `security-review`、`api-design` |
| **工具集成** | 工具/库使用 | `docker-patterns`、`supabase-patterns` |
| **模板** | 项目特定的 skill 模板 | `docs/examples/project-guidelines-template.md` |

### Skill 适配策略

如果你是从其他仓库、插件、工具链或个人提示包移植想法，请在提交 PR 之前阅读 [Skill 适配策略](docs/skill-adaptation-policy.md)。

简短版本：

- 复制底层想法，而不是外部产品标识
- 当 ECC 对功能面进行实质性更改或扩展时，重命名 skill
- 优先使用 ECC 原生的 rules、skills、scripts 和 MCP，而不是新的默认第三方依赖
- 不要发布主要价值是告诉用户安装未经审查的包的 skill

### Skill 检查清单

- [ ] 聚焦于一个领域/技术（不要过于宽泛）
- [ ] 包含"When to Activate"部分用于自动激活
- [ ] 包含实用的、可复制粘贴的代码示例
- [ ] 展示反模式（什么不该做）
- [ ] 不超过 500 行（最多 800 行）
- [ ] 使用清晰的章节标题
- [ ] 已使用 Claude Code 测试
- [ ] 链接到相关 skills
- [ ] 无敏感数据（API 密钥、令牌、路径）
- [ ] Frontmatter 声明的 `name:` 与目录名称匹配
- [ ] Frontmatter 的 `description:` 是内联字符串或折叠（`>`）标量 — 而不是字面块（`|`、`|-` 或 `|+`），后者会保留内部换行符并破坏扁平表格渲染器

### 示例 Skills

| Skill | 类别 | 目的 |
|-------|------|------|
| `coding-standards/` | 语言标准 | TypeScript/JavaScript 模式 |
| `frontend-patterns/` | 框架模式 | React 和 Next.js 最佳实践 |
| `backend-patterns/` | 框架模式 | API 和数据库模式 |
| `security-review/` | 领域知识 | 安全检查清单 |
| `tdd-workflow/` | 工作流 | 测试驱动开发流程 |
| `docs/examples/project-guidelines-template.md` | 模板 | 项目特定的 skill 模板 |

---

## 贡献 Agents

Agents 是通过 Task 工具调用的专门助手。

### 文件位置

```
agents/your-agent-name.md
```

### Agent 模板

```markdown
---
name: your-agent-name
description: What this agent does and when Claude should invoke it. Be specific!
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
model: sonnet
---

You are a [role] specialist.

## Your Role

- Primary responsibility
- Secondary responsibility
- What you DO NOT do (boundaries)

## Workflow

### Step 1: Understand
How you approach the task.

### Step 2: Execute
How you perform the work.

### Step 3: Verify
How you validate results.

## Output Format

What you return to the user.

## Examples

### Example: [Scenario]
Input: [what user provides]
Action: [what you do]
Output: [what you return]
```

### Agent 字段

| 字段 | 描述 | 选项 |
|------|------|------|
| `name` | 小写，用连字符连接 | `code-reviewer` |
| `description` | 用于决定何时调用 | 要具体！ |
| `tools` | 只包含需要的工具 | `Read, Write, Edit, Bash, Grep, Glob, WebFetch, Task`，或 MCP 工具名称（如 `mcp__context7__resolve-library-id`、`mcp__context7__query-docs`）当 agent 使用 MCP 时 |
| `model` | 复杂度级别 | `haiku`（简单）、`sonnet`（编码）、`opus`（复杂） |

### 示例 Agents

| Agent | 目的 |
|-------|------|
| `tdd-guide.md` | 测试驱动开发 |
| `code-reviewer.md` | 代码审查 |
| `security-reviewer.md` | 安全扫描 |
| `build-error-resolver.md` | 修复构建错误 |

---

## 贡献 Hooks

Hooks 是由 Claude Code 事件触发的自动行为。

### 文件位置

```
hooks/hooks.json
```

### Hook 类型

| 类型 | 触发时机 | 用例 |
|------|----------|------|
| `PreToolUse` | 工具运行前 | 验证、警告、阻止 |
| `PostToolUse` | 工具运行后 | 格式化、检查、通知 |
| `SessionStart` | 会话开始 | 加载上下文 |
| `Stop` | 会话结束 | 清理、审计 |

### Hook 格式

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "tool == \"Bash\" && tool_input.command matches \"rm -rf /\"",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[Hook] BLOCKED: Dangerous command' && exit 1"
          }
        ],
        "description": "Block dangerous rm commands"
      }
    ]
  }
}
```

### Matcher 语法

```javascript
// 匹配特定工具
tool == "Bash"
tool == "Edit"
tool == "Write"

// 匹配输入模式
tool_input.command matches "npm install"
tool_input.file_path matches "\\.tsx?$"

// 组合条件
tool == "Bash" && tool_input.command matches "git push"
```

### Hook 示例

```json
// 在 tmux 之外阻止开发服务器
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"npm run dev\"",
  "hooks": [{"type": "command", "command": "echo 'Use tmux for dev servers' && exit 1"}],
  "description": "Ensure dev servers run in tmux"
}

// 编辑 TypeScript 后自动格式化
{
  "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\.tsx?$\"",
  "hooks": [{"type": "command", "command": "npx prettier --write \"$file_path\""}],
  "description": "Format TypeScript files after edit"
}

// git push 前提醒
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"git push\"",
  "hooks": [{"type": "command", "command": "echo '[Hook] Review changes before pushing'"}],
  "description": "Reminder to review before push"
}
```

### Hook 检查清单

- [ ] Matcher 足够具体（不过于宽泛）
- [ ] 包含清晰的错误/信息消息
- [ ] 使用正确的退出代码（`exit 1` 阻止，`exit 0` 允许）
- [ ] 已彻底测试
- [ ] 有描述

---

## 贡献 Commands

Commands 是用户通过 `/command-name` 调用的操作。

### 文件位置

```
commands/your-command.md
```

### Command 模板

```markdown
---
description: Brief description shown in /help
---

# Command Name

## Purpose

What this command does.

## Usage

\`\`\`
/your-command [args]
\`\`\`

## Workflow

1. First step
2. Second step
3. Final step

## Output

What the user receives.
```

### 示例 Commands

| Command | 目的 |
|---------|------|
| `commit.md` | 创建 git 提交 |
| `code-review.md` | 审查代码更改 |
| `tdd.md` | TDD 工作流 |
| `e2e.md` | E2E 测试 |

---

## MCP 和文档（如 Context7）

Skills 和 agents 可以使用 **MCP（Model Context Protocol）** 工具来获取最新数据，而不是仅依赖训练数据。这对于文档特别有用。

- **Context7** 是一个 MCP 服务器，提供 `resolve-library-id` 和 `query-docs` 工具。当用户询问关于库、框架或 API 的问题时使用它，以便答案反映当前的文档和代码示例。
- 在贡献依赖实时文档的 **skills**（如设置、API 使用）时，描述如何使用相关的 MCP 工具（如解析库 ID，然后查询文档）并指向 `documentation-lookup` skill 或 Context7 作为模式。
- 在贡献回答文档/API 问题的 **agents** 时，在 agent 的工具中包含 Context7 MCP 工具名称（如 `mcp__context7__resolve-library-id`、`mcp__context7__query-docs`）并记录 resolve -> query 工作流。
- **mcp-configs/mcp-servers.json** 包含一个 Context7 条目；用户在其工具链（如 Claude Code、Cursor）中启用它以使用 documentation-lookup skill（在 `skills/documentation-lookup/` 中）和 `/docs` 命令。

---

## 跨工具链和翻译

### Skill 子集（Codex 和 Cursor）

ECC 为其他工具链提供 skill 子集：

- **Codex:** `.agents/skills/` — 列在 `agents/openai.yaml` 中的 skills 由 Codex 加载。
- **Cursor:** `.cursor/skills/` — 为 Cursor 打包了一组 skill 子集。

当你 **添加新 skill** 时，如果它应该在 Codex 或 Cursor 上可用：

1. 像往常一样在 `skills/your-skill-name/` 下添加 skill。
2. 如果它应该在 **Codex** 上可用，将其添加到 `.agents/skills/`（复制 skill 目录或添加引用），并确保在 `agents/openai.yaml` 中引用它（如果需要）。
3. 如果它应该在 **Cursor** 上可用，按照 Cursor 的布局将其添加到 `.cursor/skills/` 下。

查看这些目录中现有 skill 的预期结构。保持这些子集同步是手动的；如果你更新了它们，请在 PR 中提及。

### 翻译

翻译位于 `docs/` 下（如 `docs/zh-CN`、`docs/zh-TW`、`docs/ja-JP`）。如果你更改了已翻译的 agents、commands 或 skills，请考虑更新相应的翻译文件或提交 issue，以便维护者或翻译人员可以更新它们。

---

## Pull Request 流程

### 1. PR 标题格式

```
feat(skills): add rust-patterns skill
feat(agents): add api-designer agent
feat(hooks): add auto-format hook
fix(skills): update React patterns
docs: improve contributing guide
```

### 2. PR 描述

```markdown
## Summary
What you're adding and why.

## Type
- [ ] Skill
- [ ] Agent
- [ ] Hook
- [ ] Command

## Testing
How you tested this.

## Checklist
- [ ] Follows format guidelines
- [ ] Tested with Claude Code
- [ ] No sensitive info (API keys, paths)
- [ ] Clear descriptions
```

### 3. 审查流程

1. 维护者在 48 小时内审查
2. 根据反馈进行修改（如有要求）
3. 批准后，合并到 main 分支

---

## 指南

### Do
- 保持贡献专注和模块化
- 包含清晰的描述
- 提交前进行测试
- 遵循现有模式
- 记录依赖关系

### Don't
- 包含敏感数据（API 密钥、令牌、路径）
- 添加过于复杂或小众的配置
- 提交未经测试的贡献
- 创建重复功能的配置

---

## 文件命名

- 使用小写加连字符：`python-reviewer.md`
- 具有描述性：`tdd-workflow.md` 而不是 `workflow.md`
- 名称与文件名匹配

---

## 有问题？

- **Issues:** [github.com/affaan-m/everything-claude-code/issues](https://github.com/affaan-m/everything-claude-code/issues)
- **X/Twitter:** [@affaanmustafa](https://x.com/affaanmustafa)

---

感谢贡献！让我们一起构建一个伟大的资源。
