# Codex CLI 的 ECC

这用 Codex 特定指导补充根目录的 `AGENTS.md`。

## 模型推荐

| 任务类型 | 推荐模型 |
|-----------|------------------|
| 常规编码、测试、格式化 | GPT 5.4 |
| 复杂功能、架构 | GPT 5.4 |
| 调试、重构 | GPT 5.4 |
| 安全审查 | GPT 5.4 |

## 技能发现

技能从 `.agents/skills/` 自动加载。每个技能包含：
- `SKILL.md` — 详细说明和工作流
- `agents/openai.yaml` — Codex 接口元数据

可用技能：
- tdd-workflow — 具有 80%+ 覆盖率的测试驱动开发
- security-review — 全面的安全检查清单
- coding-standards — 通用编码标准
- frontend-patterns — React/Next.js 模式
- frontend-slides — 视口安全的 HTML 演示文稿和 PPTX 到网页转换
- article-writing — 从笔记和语音引用进行长形式写作
- content-engine — 平台原生社交内容和重新利用
- market-research — 来源归属的市场和竞争对手研究
- investor-materials — 文稿、备忘录、模型和一页纸
- investor-outreach — 个性化投资者外联和后续跟进
- backend-patterns — API 设计、数据库、缓存
- e2e-testing — Playwright E2E 测试
- eval-harness — 评估驱动开发
- strategic-compact — 上下文管理
- api-design — REST API 设计模式
- verification-loop — 构建、测试、lint、类型检查、安全
- deep-research — 使用 firecrawl 和 exa MCP 的多来源研究
- exa-search — 通过 Exa MCP 进行网络、代码和公司的神经搜索
- claude-api — Anthropic Claude API 模式和 SDK
- x-api — X/Twitter API 集成，用于发布、线程和分析
- crosspost — 多平台内容分发
- fal-ai-media — 通过 fal.ai 进行 AI 图像/视频/音频生成
- dmux-workflows — 使用 dmux 的多代理编排

## MCP 服务器

将项目本地的 `.codex/config.toml` 视为 ECC 的默认 Codex 基线。当前的 ECC 基线启用 GitHub、Context7、Exa、Memory、Playwright 和 Sequential Thinking；仅当任务实际需要时，才在 `~/.codex/config.toml` 中添加更重的额外功能。

ECC 的规范 Codex 部分名称是 `[mcp_servers.context7]`。启动器包保持为 `@upstash/context7-mcp`；只有 TOML 部分名称被规范化，以与 `codex mcp list` 和参考配置保持一致。

### 自动 config.toml 合并

同步脚本（`scripts/sync-ecc-to-codex.sh`）使用基于 Node 的 TOML 解析器将 ECC MCP 服务器安全合并到 `~/.codex/config.toml`：

- **默认仅添加** — 缺失的 ECC 服务器被追加；现有服务器永不被修改或删除。
- **7 个托管服务器** — Supabase、Playwright、Context7、Exa、GitHub、Memory、Sequential Thinking。
- **规范命名** — ECC 将 Context7 管理为 `[mcp_servers.context7]`；传统的 `[mcp_servers.context7-mcp]` 条目在更新期间被视为别名。
- **包管理器感知** — 使用项目配置的包管理器（npm/pnpm/yarn/bun）而不是硬编码 `pnpm`。
- **漂移警告** — 如果现有服务器的配置与 ECC 建议不同，脚本会记录警告。
- **`--update-mcp`** — 显式用最新推荐的配置替换所有 ECC 托管的服务器（安全删除像 `[mcp_servers.supabase.env]` 这样的子表）。
- **用户配置始终保留** — 自定义服务器、args、环境变量和 ECC 托管部分之外的凭据永不被触及。

## 外部操作边界

默认将网络工具视为只读。在用户请求的范围内自由搜索、检查和起草，但在发布、推送、合并、打开付费作业、调度远程代理、更改第三方资源或修改凭据之前需要明确的用户批准。

当批准不明确时，生成本地计划或草稿工件，而不是采取外部操作。保留用户配置和私有状态，除非用户明确要求进行范围更改。

## 多代理支持

Codex 现在在实验性 `features.multi_agent` 标志后面支持多代理工作流。

- 在 `.codex/config.toml` 中启用 `[features] multi_agent = true`
- 在 `[agents.<name>]` 下定义项目本地角色
- 将每个角色指向 `.codex/agents/` 下的 TOML 层
- 在 Codex CLI 内使用 `/agent` 检查和引导子代理

此仓库中的示例角色配置：
- `.codex/agents/explorer.toml` — 只读证据收集
- `.codex/agents/reviewer.toml` — 正确性/安全审查
- `.codex/agents/docs-researcher.toml` — API 和发行说明验证

## 与 Claude Code 的主要区别

| 功能 | Claude Code | Codex CLI |
|---------|------------|-----------|
| 钩子 | 8+ 种事件类型 | 尚不支持 |
| 上下文文件 | CLAUDE.md + AGENTS.md | 仅 AGENTS.md |
| 技能 | 通过插件加载技能 | `.agents/skills/` 目录 |
| 命令 | `/slash` 命令 | 基于指令 |
| 代理 | 子代理任务工具 | 通过 `/agent` 和 `[agents.<name>]` 角色进行多代理 |
| 安全 | 基于钩子的执行 | 指令 + 沙盒 |
| MCP | 完全支持 | 通过 `config.toml` 和 `codex mcp add` 支持 |

## 无钩子的安全性

由于 Codex 缺少钩子，安全执行是基于指令的：
1. 始终在系统边界验证输入
2. 永远不要硬编码机密 — 使用环境变量
3. 提交前运行 `npm audit` / `pip audit`
4. 每次推送前审查 `git diff`
5. 在配置中使用 `sandbox_mode = "workspace-write"`
