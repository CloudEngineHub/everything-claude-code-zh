# 仓库与分叉评估 + 配置建议

**日期：** 2026-03-21

---

## 可用资源

### 仓库：`Infiniteyieldai/everything-claude-code`

这是 **`affaan-m/everything-claude-code` 的分叉**（上游项目拥有 50K+ 星标、6K+ 分叉）。

| 属性 | 值 |
|-----------|-------|
| 版本 | 1.9.0（当前） |
| 状态 | 干净的分叉 — 领先上游 `main` 1 个提交（本次会话中添加的 EVALUATION.md 文档） |
| 远程分支 | `main`、`claude/evaluate-repo-comparison-ASZ9Y` |
| 上游同步 | 完全同步 — 最后合并的上游提交是 zh-CN 文档 PR (#728) |
| 许可证 | MIT |

**这是正确的工作仓库。** 它是最新上游版本，无分歧或合并冲突。

---

### 当前 `~/.claude/` 安装

| 组件 | 已安装 | 仓库中可用 |
|-----------|-----------|-------------------|
| 智能体 | 0 | 28 |
| 技能 | 0 | 116 |
| 命令 | 0 | 59 |
| 规则 | 0 | 60+ 文件（12 种语言） |
| 钩子 | 1 (git Stop 检查) | 完整的 PreToolUse/PostToolUse 矩阵 |
| MCP 配置 | 0 | 1 (Context7) |

现有的 Stop 钩子（`stop-hook-git-check.sh`）很可靠 — 在有未提交/未推送的工作时阻止会话结束。保留它。

---

## 安装配置建议

仓库提供 5 个安装配置。根据您的主要用例选择：

### 配置：`core`（最低可行配置）
> 安装最快。为您提供命令、核心智能体、钩子运行时和质量工作流。

**最适合：** 试用 ECC、最小占用空间或受限环境。

```bash
node scripts/install-plan.js --profile core
node scripts/install-apply.js
```

**安装：** rules-core、agents-core、commands-core、hooks-runtime、platform-configs、workflow-quality

---

### 配置：`developer`（推荐用于日常开发）
> 大多数 ECC 用户的默认工程配置。

**最适合：** 跨应用代码库的通用软件开发。

```bash
node scripts/install-plan.js --profile developer
node scripts/install-apply.js
```

**在 core 基础上增加：** 框架语言技能、数据库模式、编排命令

---

### 配置：`security`
> 基线运行时 + 安全专用智能体和规则。

**最适合：** 安全聚焦的工作流、代码审计、漏洞审查。

---

### 配置：`research`
> 调查、综合和发布工作流。

**最适合：** 内容创作、投资者材料、市场研究、交叉发布。

---

### 配置：`full`
> 全部 — 所有 18 个模块。

**最适合：** 想要完整工具包的高级用户。

```bash
node scripts/install-plan.js --profile full
node scripts/install-apply.js
```

---

## 优先添加项（高价值，低风险）

无论选择哪种配置，以下组件可立即提供价值：

### 1. 核心智能体（最高 ROI）

| 智能体 | 为什么重要 |
|-------|----------------|
| `planner.md` | 将复杂任务分解为实现计划 |
| `code-reviewer.md` | 质量和可维护性审查 |
| `tdd-guide.md` | TDD 工作流（RED→GREEN→IMPROVE） |
| `security-reviewer.md` | 漏洞检测 |
| `architect.md` | 系统设计和可扩展性决策 |

### 2. 关键命令

| 命令 | 为什么重要 |
|---------|----------------|
| `/plan` | 编码前的实现规划 |
| `/tdd` | 测试驱动工作流 |
| `/code-review` | 按需审查 |
| `/build-fix` | 自动化构建错误解决 |
| `/learn` | 从当前会话中提取模式 |

### 3. 钩子升级（来自 `hooks/hooks.json`）
仓库的钩子系统在当前单个 Stop 钩子基础上增加：

| 钩子 | 触发器 | 价值 |
|------|---------|-------|
| `block-no-verify` | PreToolUse: Bash | 阻止 `--no-verify` git 标志滥用 |
| `pre-bash-git-push-reminder` | PreToolUse: Bash | 推送前审查提醒 |
| `doc-file-warning` | PreToolUse: Write | 非标准文档文件警告 |
| `suggest-compact` | PreToolUse: Edit/Write | 在逻辑间隔建议压缩 |
| 持续学习观察器 | PreToolUse: * | 捕获工具使用模式以改进技能 |

### 4. 规则（始终开启的指南）
`rules/common/` 目录提供在每次会话中触发的基线指南：
- `security.md` — 安全护栏
- `testing.md` — 80%+ 覆盖率要求
- `git-workflow.md` — 约定式提交、分支策略
- `coding-style.md` — 跨语言风格标准

---

## 如何处理分叉

### 选项 A：用作上游跟踪器（当前状态）
保持分叉与 `affaan-m/everything-claude-code` 上游同步。定期合并上游变更：
```bash
git fetch upstream
git merge upstream/main
```
从本地克隆安装。这很干净且可维护。

### 选项 B：自定义分叉
向分叉添加个人技能、智能体或命令。适用于：
- 业务特定的领域技能（您的行业）
- 团队特定的编码约定
- 您技术栈的自定义钩子

分叉已有 EVALUATION.md 和 REPO-ASSESSMENT.md 文档 — 对于工作分叉来说这没问题。

### 选项 C：从 npm 安装（新机器最简单）
```bash
npx ecc-universal install --profile developer
```
无需克隆仓库。这是大多数用户的推荐安装方法。

---

## 推荐配置步骤

1. **保留现有 Stop 钩子** — 它在发挥作用
2. **从本地分叉运行 developer 配置安装**：
   ```bash
   cd /path/to/everything-claude-code
   node scripts/install-plan.js --profile developer
   node scripts/install-apply.js
   ```
3. **为您的主要技术栈添加语言规则**（TypeScript、Python、Go 等）：
   ```bash
   node scripts/install-plan.js --add rules/typescript
   node scripts/install-apply.js
   ```
4. **启用 MCP Context7** 用于实时文档查询：
   - 将 `mcp-configs/mcp-servers.json` 复制到您项目的 `.claude/` 目录
5. **审查钩子** — 选择性启用 `hooks/hooks.json` 中的新增内容，从 `block-no-verify` 和 `pre-bash-git-push-reminder` 开始

---

## 总结

| 问题 | 答案 |
|----------|--------|
| 分叉是否健康？ | 是 — 与上游 v1.9.0 完全同步 |
| 其他需要考虑的分叉？ | 此环境中无可见的其他分叉；上游 `affaan-m/everything-claude-code` 是事实来源 |
| 最佳安装配置？ | `developer` 用于日常开发工作 |
| 当前配置的最大差距？ | 0 个智能体已安装 — 至少添加：planner、code-reviewer、tdd-guide、security-reviewer |
| 最快的收益？ | 运行 `node scripts/install-plan.js --profile core && node scripts/install-apply.js` |
