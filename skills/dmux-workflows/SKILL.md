---
name: dmux-workflows
description: 使用 dmux（AI 智能体的 tmux 面板管理器）进行多智能体编排。跨 Claude Code、Codex、OpenCode 和其他工具的并行智能体工作流模式。适用于并行运行多个智能体会话或协调多智能体开发工作流。
origin: ECC
---

# dmux 工作流

使用 dmux 编排并行 AI 智能体会话，一个面向智能体工具的 tmux 面板管理器。

## 何时激活

- 并行运行多个智能体会话
- 跨 Claude Code、Codex 和其他工具协调工作
- 受益于分而治之并行化的复杂任务
- 用户说"并行运行"、"拆分这个工作"、"使用 dmux"或"多智能体"

## 什么是 dmux

dmux 是一个基于 tmux 的编排工具，管理 AI 智能体面板：
- 按 `n` 创建一个带提示的新面板
- 按 `m` 将面板输出合并回主会话
- 支持：Claude Code、Codex、OpenCode、Cline、Gemini、Qwen

**安装：** 审查包后从其仓库安装 dmux。参见 [github.com/standardagents/dmux](https://github.com/standardagents/dmux)

## 快速入门

```bash
# 启动 dmux 会话
dmux

# 创建智能体面板（在 dmux 中按 'n'，然后输入提示）
# 面板 1："实现 src/auth/ 中的认证中间件"
# 面板 2："为用户服务编写测试"
# 面板 3："更新 API 文档"

# 每个面板运行自己的智能体会话
# 按 'm' 将结果合并回来
```

## 工作流模式

### 模式 1：研究 + 实现

将研究和实现分为并行轨道：

```
面板 1（研究）："研究 Node.js 中速率限制的最佳实践。
  检查当前的库、比较方法，将发现写入
  /tmp/rate-limit-research.md"

面板 2（实现）："为我们的 Express API 实现速率限制中间件。
  从基本的令牌桶开始，研究完成后我们将优化。"

# 面板 1 完成后，将发现合并到面板 2 的上下文中
```

### 模式 2：多文件功能

在独立文件之间并行化工作：

```
面板 1："创建计费功能的数据库模式和迁移"
面板 2："在 src/api/billing/ 中构建计费 API 端点"
面板 3："创建计费仪表板 UI 组件"

# 全部合并，然后在主面板中进行集成
```

### 模式 3：测试 + 修复循环

在一个面板中运行测试，在另一个面板中修复：

```
面板 1（监视器）："以监视模式运行测试套件。当测试失败时，
  总结失败信息。"

面板 2（修复器）："根据面板 1 的错误输出修复失败的测试"
```

### 模式 4：跨工具

为不同任务使用不同的 AI 工具：

```
面板 1（Claude Code）："审查认证模块的安全性"
面板 2（Codex）："重构工具函数以提高性能"
面板 3（Claude Code）："为结账流程编写 E2E 测试"
```

### 模式 5：代码审查管道

并行的审查视角：

```
面板 1："审查 src/api/ 的安全漏洞"
面板 2："审查 src/api/ 的性能问题"
面板 3："审查 src/api/ 的测试覆盖缺口"

# 将所有审查合并为单一报告
```

## 最佳实践

1. **仅独立任务。** 不要并行化依赖彼此输出的任务。
2. **清晰的边界。** 每个面板应处理不同的文件或关注点。
3. **策略性合并。** 在合并前审查面板输出以避免冲突。
4. **使用 git 工作树。** 对于文件冲突风险高的工作，每个面板使用单独的工作树。
5. **资源意识。** 每个面板使用 API token — 总面板数保持在 5-6 个以下。

## Git 工作树集成

对于涉及重叠文件的任务：

```bash
# 为隔离创建工作树
git worktree add -b feat/auth ../feature-auth HEAD
git worktree add -b feat/billing ../feature-billing HEAD

# 在单独的工作树中运行智能体
# 面板 1: cd ../feature-auth && claude
# 面板 2: cd ../feature-billing && claude

# 完成后合并分支
git merge feat/auth
git merge feat/billing
```

## 互补工具

| 工具 | 作用 | 何时使用 |
|------|-------------|-------------|
| **dmux** | 智能体的 tmux 面板管理 | 并行智能体会话 |
| **Superset** | 10+ 并行智能体的终端 IDE | 大规模编排 |
| **Claude Code Task 工具** | 进程内子智能体生成 | 会话内的编程式并行化 |
| **Codex 多智能体** | 内置智能体角色 | Codex 特定的并行工作 |

## ECC 辅助工具

ECC 现在包含一个用于外部 tmux 面板编排与独立 git 工作树的辅助工具：

```bash
node scripts/orchestrate-worktrees.js plan.json --execute
```

示例 `plan.json`：

```json
{
  "sessionName": "skill-audit",
  "baseRef": "HEAD",
  "launcherCommand": "codex exec --cwd {worktree_path} --task-file {task_file}",
  "workers": [
    { "name": "docs-a", "task": "修复技能 1-4 并写交接笔记。" },
    { "name": "docs-b", "task": "修复技能 5-8 并写交接笔记。" }
  ]
}
```

辅助工具：
- 为每个工作器创建一个基于分支的 git 工作树
- 可选地将主检出中选择的 `seedPaths` 叠加到每个工作器工作树中
- 在 `.orchestration/<session>/` 下为每个工作器写入 `task.md`、`handoff.md` 和 `status.md` 文件
- 启动一个 tmux 会话，每个工作器一个面板
- 在自己的面板中启动每个工作器命令
- 将主面板留给编排器

当工作器需要访问尚未成为 `HEAD` 一部分的脏文件或未跟踪本地文件时使用 `seedPaths`，如本地编排脚本、草稿计划或文档：

```json
{
  "sessionName": "workflow-e2e",
  "seedPaths": [
    "scripts/orchestrate-worktrees.js",
    "scripts/lib/tmux-worktree-orchestrator.js",
    ".claude/plan/workflow-e2e-test.json"
  ],
  "launcherCommand": "bash {repo_root}/scripts/orchestrate-codex-worker.sh {task_file} {handoff_file} {status_file}",
  "workers": [
    { "name": "seed-check", "task": "在开始工作之前验证已植入的文件是否存在。" }
  ]
}
```

## 故障排除

- **面板无响应：** 直接切换到面板或使用 `tmux capture-pane -pt <session>:0.<pane-index>` 检查。
- **合并冲突：** 使用 git 工作树隔离每个面板的文件变更。
- **高 token 使用量：** 减少并行面板数量。每个面板是一个完整的智能体会话。
- **tmux 未找到：** 使用 `brew install tmux`（macOS）或 `apt install tmux`（Linux）安装。
