# 变更日志

## 2.0.0-rc.1 - 2026-04-28

### 亮点

- 添加了公共 ECC 2.0 发布候选版本接口，用于 Hermes 运维场景。
- 将 ECC 记录为跨 Claude Code、Codex、Cursor、OpenCode 和 Gemini 的可复用跨 Harness 基础层。
- 添加了经过清理的 Hermes 导入技能接口，而非发布私有运维状态。

### 发布内容

- 更新了包、插件、市场、OpenCode、智能体和 README 元数据至 `2.0.0-rc.1`。
- 添加了 `docs/releases/2.0.0-rc.1/`，包含发布说明、社交媒体草稿、发布清单、交接说明和演示提示。
- 添加了 `docs/architecture/cross-harness.md` 和 ECC/Hermes 边界的回归覆盖。
- 目前保持 `ecc2/` 版本独立；除非发布工程另有决定，它仍然是 alpha 控制平面脚手架。

### 说明

- 这是一个发布候选版本，不是完整 ECC 2.0 控制平面路线图的 GA 声明。
- 预发布 npm 发布应使用 `next` dist-tag，除非发布工程明确选择其他方式。

## 1.10.0 - 2026-04-05

### 亮点

- 经过数周 OSS 增长和积压合并后，公共发布接口同步到实时仓库。
- 运维工作流通道扩展了语音、图谱排名、计费、工作空间和外发技能。
- 媒体生成通道扩展了 Manim 和 Remotion 优先的发布工具。
- ECC 2.0 alpha 控制平面二进制文件现在可从 `ecc2/` 本地构建，并暴露了首个可用的 CLI/TUI 接口。

### 发布内容

- 更新了插件、市场、Codex、OpenCode 和智能体元数据至 `1.10.0`。
- 同步了已发布计数到实时 OSS 接口：38 个智能体、156 个技能、72 个命令。
- 刷新了顶级面向安装的文档和市场描述以匹配当前仓库状态。

### 新工作流通道

- `brand-voice` — 规范来源衍生的写作风格系统。
- `social-graph-ranker` — 加权热引荐图谱排名原语。
- `connections-optimizer` — 基于图谱排名的网络修剪/添加工作流。
- `customer-billing-ops`、`google-workspace-ops`、`project-flow-ops`、`workspace-surface-audit`。
- `manim-video`、`remotion-video-creation`、`nestjs-patterns`。

### ECC 2.0 Alpha

- `cargo build --manifest-path ecc2/Cargo.toml` 在仓库基线上通过。
- `ecc-tui` 当前暴露了 `dashboard`、`start`、`sessions`、`status`、`stop`、`resume` 和 `daemon`。
- alpha 是真实可用的，可用于本地实验，但更广泛的控制平面路线图仍未完成，不应视为 GA。

### 说明

- Claude 插件仍受平台级规则分发限制；选择性安装 / OSS 路径仍然是最可靠的完整安装方式。
- 此版本是仓库接口修正和生态系统同步，而非声称完整 ECC 2.0 路线图已完成。

## 1.9.0 - 2026-03-20

### 亮点

- 选择性安装架构，带有清单驱动管道和 SQLite 状态存储。
- 语言覆盖扩展到 10+ 生态系统，新增 6 个智能体和语言特定规则。
- 观察器可靠性增强，包括内存节流、沙箱修复和 5 层循环防护。
- 自我改进技能基础，包括技能演化和会话适配器。

### 新智能体

- `typescript-reviewer` — TypeScript/JavaScript 代码审查专家 (#647)
- `pytorch-build-resolver` — PyTorch 运行时、CUDA 和训练错误解决 (#549)
- `java-build-resolver` — Maven/Gradle 构建错误解决 (#538)
- `java-reviewer` — Java 和 Spring Boot 代码审查 (#528)
- `kotlin-reviewer` — Kotlin/Android/KMP 代码审查 (#309)
- `kotlin-build-resolver` — Kotlin/Gradle 构建错误 (#309)
- `rust-reviewer` — Rust 代码审查 (#523)
- `rust-build-resolver` — Rust 构建错误解决 (#523)
- `docs-lookup` — 文档和 API 参考研究 (#529)

### 新技能

- `pytorch-patterns` — PyTorch 深度学习工作流 (#550)
- `documentation-lookup` — API 参考和库文档研究 (#529)
- `bun-runtime` — Bun 运行时模式 (#529)
- `nextjs-turbopack` — Next.js Turbopack 工作流 (#529)
- `mcp-server-patterns` — MCP 服务器设计模式 (#531)
- `data-scraper-agent` — AI 驱动的公共数据收集 (#503)
- `team-builder` — 团队组成技能 (#501)
- `ai-regression-testing` — AI 回归测试工作流 (#433)
- `claude-devfleet` — 多智能体编排 (#505)
- `blueprint` — 多会话构建规划
- `everything-claude-code` — 自引用 ECC 技能 (#335)
- `prompt-optimizer` — 提示优化技能 (#418)
- 8 个 Evos 运维领域技能 (#290)
- 3 个 Laravel 技能 (#420)
- VideoDB 技能 (#301)

### 新命令

- `/docs` — 文档查找 (#530)
- `/aside` — 侧面对话 (#407)
- `/prompt-optimize` — 提示优化 (#418)
- `/resume-session`、`/save-session` — 会话管理
- `learn-eval` 改进，带基于检查表的整体评判

### 新规则

- Java 语言规则 (#645)
- PHP 规则包 (#389)
- Perl 语言规则和技能（模式、安全、测试）
- Kotlin/Android/KMP 规则 (#309)
- C++ 语言支持 (#539)
- Rust 语言支持 (#523)

### 基础设施

- 选择性安装架构，带有清单解析（`install-plan.js`、`install-apply.js`）(#509, #512)
- SQLite 状态存储，带有查询 CLI 用于跟踪已安装组件 (#510)
- 用于结构化会话记录的会话适配器 (#511)
- 用于自我改进技能的技能演化基础 (#514)
- 带有确定性评分的编排线束 (#524)
- CI 中的目录计数强制执行 (#525)
- 所有 109 个技能的安装清单验证 (#537)
- PowerShell 安装包装器 (#532)
- 通过 `--target antigravity` 标志支持 Antigravity IDE (#332)
- Codex CLI 自定义脚本 (#336)

### 错误修复

- 解决了 6 个文件中的 19 个 CI 测试失败 (#519)
- 修复了安装管道、编排器和修复中的 8 个测试失败 (#564)
- 通过节流、重入防护和尾部采样修复观察器内存膨胀 (#536)
- 修复了 Haiku 调用的观察器沙箱访问问题 (#661)
- 修复了工作树项目 ID 不匹配问题 (#665)
- 修复了观察器延迟启动逻辑 (#508)
- 修复了观察器 5 层循环防护 (#399)
- 钩子可移植性和 Windows .cmd 支持
- Biome 钩子优化 — 消除了 npx 开销 (#359)
- InsAIts 安全钩子改为可选启用 (#370)
- Windows spawnSync 导出修复 (#431)
- instinct CLI 的 UTF-8 编码修复 (#353)
- 钩子中的密钥清理 (#348)

### 翻译

- 韩语 (ko-KR) 翻译 — README、智能体、命令、技能、规则 (#392)
- 中文 (zh-CN) 文档同步 (#428)

### 致谢

- @ymdvsymd — 观察器沙箱和工作树修复
- @pythonstrup — biome 钩子优化
- @Nomadu27 — InsAIts 安全钩子
- @hahmee — 韩语翻译
- @zdocapp — 中文翻译同步
- @cookiee339 — Kotlin 生态系统
- @pangerlkr — CI 工作流修复
- @0xrohitgarg — VideoDB 技能
- @nocodemf — Evos 运维技能
- @swarnika-cmd — 社区贡献

## 1.8.0 - 2026-03-04

### 亮点

- Harness 优先版本，专注于可靠性、评估规范和自主循环操作。
- 钩子运行时现在支持基于配置的控制和定向钩子禁用。
- NanoClaw v2 添加了模型路由、技能热加载、分支、搜索、压缩、导出和指标。

### 核心

- 新增命令：`/harness-audit`、`/loop-start`、`/loop-status`、`/quality-gate`、`/model-route`。
- 新增技能：
  - `agent-harness-construction`
  - `agentic-engineering`
  - `ralphinho-rfc-pipeline`
  - `ai-first-engineering`
  - `enterprise-agent-ops`
  - `nanoclaw-repl`
  - `continuous-agent-loop`
- 新增智能体：
  - `harness-optimizer`
  - `loop-operator`

### 钩子可靠性

- 修复了 SessionStart 根解析，带有健壮的回退搜索。
- 将会话摘要持久化移至 `Stop`，此时记录负载可用。
- 添加了 quality-gate 和 cost-tracker 钩子。
- 将脆弱的内联钩子单行命令替换为专用脚本文件。
- 添加了 `ECC_HOOK_PROFILE` 和 `ECC_DISABLED_HOOKS` 控制。

### 跨平台

- 改进了文档警告逻辑中的 Windows 安全路径处理。
- 加固了观察器循环行为，避免非交互式挂起。

### 说明

- `autonomous-loops` 作为一个版本保留为兼容别名；`continuous-agent-loop` 是规范名称。

### 致谢

- 灵感来自 [zarazhangrui](https://github.com/zarazhangrui)
- homunculus 灵感来自 [humanplane](https://github.com/humanplane)
