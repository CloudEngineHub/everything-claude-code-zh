# 仓库评估与当前设置对比

**日期：** 2026-03-21
**分支：** `claude/evaluate-repo-comparison-ASZ9Y`

---

## 当前设置 (`~/.claude/`)

当前活跃的 Claude Code 安装接近最小化：

| 组件 | 当前 |
|-----------|---------|
| Agents | 0 |
| Skills | 0 已安装 |
| Commands | 0 |
| Hooks | 1 (Stop: git check) |
| Rules | 0 |
| MCP configs | 0 |

**已安装的 hooks：**
- `Stop` → `stop-hook-git-check.sh` — 如果有未提交的更改或未推送的提交，阻止会话结束

**已安装的权限：**
- `Skill` — 允许技能调用

**插件：** 仅 `blocklist.json`（未安装活动插件）

---

## 本仓库 (`everything-claude-code` v1.9.0)

| 组件 | 仓库 |
|-----------|------|
| Agents | 28 |
| Skills | 116 |
| Commands | 59 |
| Rules sets | 12 种语言 + 通用（60+ 规则文件） |
| Hooks | 综合系统（PreToolUse、PostToolUse、SessionStart、Stop） |
| MCP configs | 1 (Context7 + 其他) |
| Schemas | 9 个 JSON 验证器 |
| Scripts/CLI | 46+ Node.js 模块 + 多个 CLI |
| Tests | 58 个测试文件 |
| Install profiles | core、developer、security、research、full |
| Supported harnesses | Claude Code、Codex、Cursor、OpenCode |

---

## 差距分析

### Hooks
- **当前：** 1 个 Stop hook（git 卫生检查）
- **仓库：** 完整 hook 矩阵，覆盖：
  - 危险命令阻止（`rm -rf`、强制推送）
  - 文件编辑时自动格式化
  - 开发服务器 tmux 强制
  - 成本跟踪
  - 会话评估和治理捕获
  - MCP 健康监控

### Agents（缺失 28 个）
仓库为每个主要工作流提供专用 agents：
- 语言审查者：TypeScript、Python、Go、Java、Kotlin、Rust、C++、Flutter
- 构建解析器：Go、Java、Kotlin、Rust、C++、PyTorch
- 工作流 agents：planner、tdd-guide、code-reviewer、security-reviewer、architect
- 自动化：loop-operator、doc-updater、refactor-cleaner、harness-optimizer

### Skills（缺失 116 个）
覆盖以下领域的领域知识模块：
- 语言模式（Python、Go、Kotlin、Rust、C++、Java、Swift、Perl、Laravel、Django）
- 测试策略（TDD、E2E、覆盖率）
- 架构模式（后端、前端、API 设计、数据库迁移）
- AI/ML 工作流（Claude API、评估工具、agent 循环、成本感知管道）
- 业务工作流（投资者材料、市场研究、内容引擎）

### Commands（缺失 59 个）
- `/tdd`、`/plan`、`/e2e`、`/code-review` — 核心开发工作流
- `/sessions`、`/save-session`、`/resume-session` — 会话持久化
- `/orchestrate`、`/multi-plan`、`/multi-execute` — 多 agent 协调
- `/learn`、`/skill-create`、`/evolve` — 持续改进
- `/build-fix`、`/verify`、`/quality-gate` — 构建/质量自动化

### Rules（缺失 60+ 个文件）
针对 TypeScript、Python、Go、Java、Kotlin、Rust、C++、C#、Swift、Perl、PHP 的特定语言编码风格、模式、测试和安全指南，以及通用/跨语言规则。

---

## 建议

### 立即获得价值（核心安装）
运行 `ecc install --profile core` 获取：
- 核心 agents（code-reviewer、planner、tdd-guide、security-reviewer）
- 必要技能（tdd-workflow、coding-standards、security-review）
- 关键命令（/tdd、/plan、/code-review、/build-fix）

### 完整安装
运行 `ecc install --profile full` 获取所有 28 个 agents、116 个 skills 和 59 个 commands。

### Hooks 升级
当前的 Stop hook 很稳健。仓库的 `hooks.json` 添加了：
- 危险命令阻止（安全）
- 自动格式化（质量）
- 成本跟踪（可观察性）
- 会话评估（学习）

### Rules
添加语言规则（如 TypeScript、Python）提供始终启用的编码指南，无需依赖每会话提示。

---

## 当前设置做得好的地方

- `stop-hook-git-check.sh` Stop hook 是生产级质量，已经执行良好的 git 卫生
- `Skill` 权限配置正确
- 设置干净，无冲突或冗余

---

## 总结

当前设置本质上是一个空白板，只有一个实现良好的 git 卫生 hook。本仓库提供了一个完整的、经过生产测试的增强层，涵盖 agents、skills、commands、hooks 和 rules — 具有选择性安装系统，因此您可以精确添加所需内容，而不会使配置膨胀。
