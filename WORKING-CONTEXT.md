# 工作上下文

最后更新：2026-04-08

## 目的

用于智能体、技能、命令、钩子、规则、安装界面和 ECC 2.0 平台构建的公共 ECC 插件仓库。

## 当前事实

- 默认分支：`main`
- 公共发布界面对齐于 `v1.10.0`
- 公共目录事实为 `47` 个智能体、`79` 个命令和 `181` 个技能
- 公共插件标识符现在是 `ecc`；遗留的 `everything-claude-code` 安装路径仍然支持以保持兼容性
- 发布讨论：`#1272`
- ECC 2.0 存在于树中并可以构建，但它仍然是 alpha 而不是 GA
- 主要活跃操作工作：
  - 保持默认分支绿色
  - 继续从 `main` 进行问题驱动的修复，因为公共 PR 待办积压现在为零
  - 继续 ECC 2.0 控制面和操作员界面构建

## 当前约束

- 不要仅按标题或提交摘要合并。
- 不要在已发布的 ECC 界面中任意安装外部运行时。
- 当重叠是实质性的且不需要运行时分离时，应合并重叠的技能、钩子或智能体。

## 活跃队列

- PR 待办积压：已减少但仍然活跃；仅保持直接移植安全的 ECC 原生更改，并关闭重叠、陈旧的生成器和未经审计的外部运行时通道
- 上游分支待办积压仍需要选择性挖掘和清理：
  - `origin/feat/hermes-generated-ops-skills` 仍有三个独特的提交，但只能从中抢救可复用的 ECC 原生技能
  - 多个 `origin/ecc-tools/*` 自动化分支已陈旧，应在确认它们没有独特价值后修剪
- 产品：
  - 选择性安装清理
  - 控制面原语
  - 操作员界面
  - 自我改进技能
  - 保持 `agent.yaml` 导出与已发布的 `commands/` 和 `skills/` 目录同步，以便现代安装界面不会静默丢失命令注册
- 技能质量：
  - 重写面向内容的技能以使用源支持的声音建模
  - 删除通用 LLM 修辞、罐头 CTA 模式和强制平台刻板印象
  - 继续逐个审计重叠或低信号技能内容
  - 将仓库指导和贡献流程转移到技能优先，仅将命令保留为显式兼容性 shims
  - 添加包装连接界面而不是仅暴露原始 API 或断开连接的原语的操作员技能
  - 落地规范声音系统、网络优化通道和可复用的 Manim 解说通道
- 安全：
  - 保持依赖姿态干净
  - 保持自包含的钩子和 MCP 行为

## 开放 PR 分类

- 于 2026-04-01 在待办积压卫生/合并策略下关闭：
  - `#1069` `feat: add everything-claude-code ECC bundle`
  - `#1068` `feat: add everything-claude-code-conventions ECC bundle`
  - `#1080` `feat: add everything-claude-code ECC bundle`
  - `#1079` `feat: add everything-claude-code-conventions ECC bundle`
  - `#1064` `chore(deps-dev): bump @eslint/js from 9.39.2 to 10.0.1`
  - `#1063` `chore(deps-dev): bump eslint from 9.39.2 to 10.1.0`
- 于 2026-04-01 关闭，因为内容来自外部生态系统，应仅通过手动 ECC 原生重新移植落地：
  - `#852` openclaw-user-profiler
  - `#851` openclaw-soul-forge
  - `#640` harper skills
- 下次需要完全差异审计的本机支持候选：
  - `#1055` Dart / Flutter 支持
  - `#1043` C# reviewer 和 .NET 技能
- 审计后直接移植的候选：
  - `#1078` 用于托管 Claude 钩子重新安装的 hook-id 去重
  - `#844` ui-demo 技能
  - `#1110` 安装时 Claude 钩子根解决方案
  - `#1106` 便携式 Codex Context7 密钥提取
  - `#1107` Codex 基线合并和示例智能体角色同步
  - `#1119` 仍然包含安全低风险修复的陈旧 CI/lint 清理
- 完全审计后在 ECC 内部移植或重建：
  - `#894` Jira 集成
  - `#814` + `#808` 重建为 Opencode 和跨 harness 界面的单个统一通知通道

## 接口

- 公共事实：GitHub issues 和 PRs
- 内部执行事实：ECC 程序下的关联 Linear 工作项
- 当前关联的 Linear 项：
  - `ECC-206` 生态系统 CI 基线
  - `ECC-207` PR 待办审计和合并策略执行
  - `ECC-208` 上下文卫生
  - `ECC-210` 技能优先工作流迁移和命令兼容性退役

## 更新规则

仅将此文件详细记录当前冲刺、阻塞因素和后续操作。一旦完成的工作不再积极影响执行，就将其总结到存档或仓库文档中。

## 最新执行说明

- 2026-04-05：通过将 `coding-standards` 缩小到基线跨项目约定层而不是删除它来继续 `#1213` 重叠清理。该技能现在明确将详细的 React/UI 指导指向 `frontend-patterns`，将后端/API 结构指向 `backend-patterns`/`api-design`，并仅保留可复用的命名、可读性、不可变性和代码质量期望。
- 2026-04-05：在 `#1287` 显示已发布的 `v1.10.0` 构件仍然陈旧后，为 OpenCode 发布路径添加了打包回归防护。`tests/scripts/build-opencode.test.js` 现在断言 `npm pack --dry-run` tarball 包含 `.opencode/dist/index.js` 加上编译的插件/工具入口点，因此未来的发布不能静默省略已构建的 OpenCode 负载。
- 2026-04-05：为 `#829` 落地了 `skills/agent-introspection-debugging`，作为 ECC 原生自调试框架。它有意是指导优先而不是伪造的运行时自动化：捕获失败状态、对模式进行分类、应用最小的包含恢复操作，然后发出结构化内省报告，并在适当时移交给 `verification-loop`/`continuous-learning-v2`。
- 2026-04-05：在最新的直接移植后修复了 `main` npm CI 中断。`package-lock.json` 已在 `globals` 开发依赖（`^17.1.0` vs `^17.4.0`）上落后于 `package.json`，这导致所有基于 npm 的 GitHub Actions 作业在 `npm ci` 时失败。仅刷新了 lockfile，验证了 `npm ci --ignore-scripts`，并保持混合锁定工作空间其他方面不变。
- 2026-04-05：在不复制第二个医疗保健合规系统的情况下直接移植了 `#1221` 的有用可发现性部分。添加了 `skills/hipaa-compliance/SKILL.md` 作为指向规范 `healthcare-phi-compliance`/`healthcare-reviewer` 通道的精简 HIPAA 特定入口点，并将两个医疗保健隐私技能连接到 `security` 安装模块以进行选择性安装。
- 2026-04-05：将 `#1222` 中审计的区块链/web3 安全通道直接移植到 `main`，作为四个自包含技能：`defi-amm-security`、`evm-token-decimals`、`llm-trading-agent-security` 和 `nodejs-keccak256`。这些现在是 `security` 安装模块的一部分，而不是作为未合并的分叉 PR 存在。
- 2026-04-05：直接在 `main` 上完成了 `#1203` 的有用抢救通道。`skills/security-bounty-hunter`、`skills/api-connector-builder` 和 `skills/dashboard-builder` 现在作为 ECC 原生重写存在于树中，而不是更薄的原始社区草稿。原始 PR 应被视为被取代而不是合并。
- 2026-04-02：`ECC-Tools/main` 发布了 `9566637` (`fix: prefer commit lookup over git ref resolution`)。PR 分析火现在在应用仓库中通过在 `git.getRef` 之前优先显式提交解决来修复，具有 pull refs 和普通分支 refs 的回归覆盖。在此仓库中镜像的公共跟踪问题 `#1184` 作为在上游解决而关闭。
- 2026-04-02：将 `#1043` 的干净本机支持核心直接移植到 `main`：`agents/csharp-reviewer.md`、`skills/dotnet-patterns/SKILL.md` 和 `skills/csharp-testing/SKILL.md`。这填补了现有 C# 规则/文档提及与实际已发布的 C# 审查/测试指导之间的空白。
- 2026-04-02：将 `#1055` 的干净本机支持核心直接移植到 `main`：`agents/dart-build-resolver.md`、`commands/flutter-build.md`、`commands/flutter-review.md`、`commands/flutter-test.md`、`rules/dart/*` 和 `skills/dart-flutter-patterns/SKILL.md`。技能路径连接到当前的 `framework-language` 模块，而不是重播旧 PR 的单独 `flutter-dart` 模块布局。
- 2026-04-02：在差异审计后关闭 `#1081`。PR 仅向规范 `x-api` 技能添加了外部 X/Twitter 后端（`Xquik`/`x-twitter-scraper`）的供应商营销文档，而不是贡献 ECC 原生功能。
- 2026-04-02：直接移植了 `#894` 的有用 Jira 通道，但对其进行了清理以匹配当前供应链策略。`commands/jira.md`、`skills/jira-integration/SKILL.md` 和 `mcp-configs/mcp-servers.json` 中的固定 `jira` MCP 模板存在于树中，而技能不再告诉用户通过 `curl | bash` 安装 `uv`。`jira-integration` 被归类在 `operator-workflows` 下以进行选择性安装。
- 2026-04-02：在完全差异审计后关闭 `#1125`。bundle/skill-router 通道硬编码了许多不存在或非规范的界面，并创建了第二个路由抽象，而不是小型 ECC 原生索引层。
- 2026-04-02：在完全差异审计后关闭 `#1124`。添加的智能体名册经过深思熟虑编写，但它用第二个竞争目录（`dispatch`、`explore`、`verifier`、`executor` 等）重复了现有 ECC 智能体界面，而不是加强已在树中的规范智能体。
- 2026-04-02：在完全差异审计后关闭了完整的 Argus 集群 `#1098`、`#1099`、`#1100`、`#1101` 和 `#1102`。所有五个 PR 的常见失败模式相同：外部多 CLI 分派被视为已发布 ECC 界面的一等运行时依赖。任何有用的协议想法应该稍后重新移植到 ECC 原生编排、审查或反射通道，而不假设外部 CLI 扩展。
- 2026-04-02：以前开放的本机支持/集成队列（`#1081`、`#1055`、`#1043`、`#894`）现已通过直接移植或关闭策略完全解决。活跃的公共 PR 队列目前为零；下一个重点仍然是问题驱动的干线修复和 CI 健康，而不是待办 PR 接收。
- 2026-04-01：在 lockfile 和钩子验证修复后，本地恢复了 `main` CI，通过了 `1723/1723` 测试。
- 2026-04-01：自动生成的 ECC bundle PR `#1068` 和 `#1069` 已关闭而不是合并；有用的想法必须在明确差异审计后手动移植。
- 2026-04-01：主要版本 ESLint 提升 PR `#1063` 和 `#1064` 已关闭；仅在计划内的 ESLint 10 迁移通道中重新访问。
- 2026-04-01：通知 PR `#808` 和 `#814` 被确定为重叠，应重建为一个统一功能，而不是作为并行分支落地。
- 2026-04-01：外部来源技能 PR `#640`、`#851` 和 `#852` 在新摄取策略下关闭；稍后从审计来源复制想法，而不是直接合并品牌/来源导入 PR。
- 2026-04-01：通过将 `ratatui` 移动到具有 `crossterm_0_28` 的 `0.30` 来解决 `ecc2/Cargo.lock` 上的剩余低 GitHub 建议，这将传递的 `lru` 从 `0.12.5` 更新到 `0.16.3`。`cargo build --manifest-path ecc2/Cargo.toml` 仍然通过。
- 2026-04-01：`#834` 的安全核心直接移植到 `main`，而不是批量合并 PR。这包括更严格的安装计划验证、跳过不受支持的模块树的 antigravity 目标过滤、用于英语加 zh-CN 文档的跟踪目录同步，以及专用的 `catalog:sync` 写入模式。
- 2026-04-01：仓库目录事实现在在跟踪的英语和 zh-CN 文档中同步为 `36` 个智能体、`68` 个命令和 `142` 个技能。
- 2026-04-01：文档、脚本和测试中的遗留表情符号和非必要符号使用已规范化，以保持 unicode 安全通道绿色，而不削弱检查本身。
- 2026-04-01：`#834` 的剩余自包含部分 `docs/zh-CN/skills/browser-qa/SKILL.md` 直接移植到仓库。提交后，`#834` 应作为被直接移植取代而关闭。
- 2026-04-01：内容技能清理从 `content-engine`、`crosspost`、`article-writing` 和 `investor-outreach` 开始。新方向是源优先的声音捕获、显式反套路禁令，以及没有强制平台人设转变。
- 2026-04-01：`node scripts/ci/check-unicode-safety.js --write` 清理了剩余带有表情符号的 Markdown 文件，包括几个 `remotion-video-creation` 规则文档和一个旧的本地计划注释。
- 2026-04-01：核心英语仓库界面转变为技能优先姿态。README、AGENTS、插件元数据和贡献者指令现在将 `skills/` 视为规范，将 `commands/` 视为迁移期间的遗留斜杠条目兼容性。
- 2026-04-01：后续 bundle 清理关闭了 `#1080` 和 `#1079`，它们是重复命令优先脚手架而不是发布规范 ECC 源更改的生成的 `.claude/` bundle PR。
- 2026-04-01：将 `#1078` 的有用核心直接移植到 `main`，但收紧了实现，以便遗留无 id 钩子安装在第一次重新安装时干净地去重，而不是第二次。向 `hooks/hooks.json` 添加了稳定的钩子 id，在 `mergeHookEntries()` 中添加了语义后备别名，以及覆盖从无 id 设置升级的回归测试。
- 2026-04-01：将明显的命令/技能重复折叠为精简的遗留 shims，因此 `skills/` 现在保存 NanoClaw、context-budget、DevFleet、docs 查找、E2E、evals、编排、提示优化、规则提炼、TDD 和验证的维护主体。
- 2026-04-01：将 `#844` 的自包含核心直接移植到 `main` 作为 `skills/ui-demo/SKILL.md`，并将其注册在 `media-generation` 安装模块下，而不是批量合并 PR。
- 2026-04-01：添加了第一个连接工作流操作员通道作为 ECC 原生技能，而不是将界面保留为原始插件或 API：`workspace-surface-audit`、`customer-billing-ops`、`project-flow-ops` 和 `google-workspace-ops`。这些在新 `operator-workflows` 安装模块下跟踪。
- 2026-04-01：将未解决的钩子路径 PR 通道的真实修复直接移植到活动安装程序。Claude 安装现在在 `settings.json` 和复制的 `hooks/hooks.json` 中用具体安装根替换 `${CLAUDE_PLUGIN_ROOT}`，这使 PreToolUse/PostToolUse 钩子在插件管理的环境注入之外工作。
- 2026-04-01：用便携式 Node 解析器替换了 `scripts/sync-ecc-to-codex.sh` 中的仅 GNU `grep -P` 解析器用于 Context7 密钥提取。添加了源级回归覆盖，因此 BSD/macOS 同步不会漂移回不可移植的解析。
- 2026-04-01：直接移植后的针对性回归套件通过：`tests/scripts/install-apply.test.js`、`tests/scripts/sync-ecc-to-codex.test.js` 和 `tests/scripts/codex-hooks.test.js`。
- 2026-04-01：将 `#1107` 的有用核心直接移植到 `main` 作为仅添加的 Codex 基线合并。`scripts/sync-ecc-to-codex.sh` 现在从 `.codex/config.toml` 填充缺失的非 MCP 默认值，将示例智能体角色文件同步到 `~/.codex/agents`，并保留用户配置而不是替换它。为稀疏配置和隐式父表添加了回归覆盖。
- 2026-04-01：将 `#1119` 的安全低风险清理直接移植到 `main`，而不是保持过时的 CI PR 开放。这包括 `.mjs` eslint 处理、更严格的空检查、bash-log 测试中的 Windows 主目录覆盖，以及更长的 Trae shell 测试超时。
- 2026-04-01：添加了 `brand-voice` 作为规范源派生写作风格系统，并将内容通道连接到将其视为共享声音事实来源，而不是在技能中复制部分样式启发式。
- 2026-04-01：添加了 `connections-optimizer` 作为 X 和 LinkedIn 的审查优先社交图重组工作流，具有显式修剪模式、浏览器后备预期以及 Apple Mail 起草指导。
- 2026-04-01：添加了 `manim-video` 作为可复用的技术解说通道，并使用入门网络图场景播种，因此启动和系统动画不依赖一次性临时脚本。
- 2026-04-02：作为独立的原语重新提取了 `social-graph-ranker`，因为加权桥衰减模型在完整线索工作流之外是可复用的。`lead-intelligence` 现在指向它以进行规范图排名，而不是携带完整的算法解释内联，而 `connections-optimizer` 保持用于修剪、添加和外展审查包的更广泛操作员层。
- 2026-04-02：将相同的合并规则应用于写作通道。`brand-voice` 保持规范声音系统，而 `content-engine`、`crosspost`、`article-writing` 和 `investor-outreach` 现在仅保留工作流特定指导，而不是复制第二个 Affaan/ECC 声音模型或在多个位置重复完整禁令列表。
- 2026-04-02：在现有策略下关闭了新鲜自动生成的 bundle PR `#1182` 和 `#1183`。生成器输出的有用想法必须手动移植到规范仓库界面，而不是批量合并 `.claude`/bundle PR。
- 2026-04-02：将 `#1164` 的安全单文件 macOS 观察者修复直接移植到 `main`，作为 POSIX `mkdir` 后备，用于 `continuous-learning-v2` 延迟启动锁定，然后将 PR 关闭为被直接移植取代。
- 2026-04-02：将 `#1153` 的安全核心直接移植到 `main`：编排/文档界面的 markdownlint 清理，以及 `install-apply`/`repair` 测试中的 Windows `USERPROFILE` 和路径规范化修复。安装仓库依赖项后的本地验证：`node tests/scripts/install-apply.test.js`、`node tests/scripts/repair.test.js` 和针对性的 `yarn markdownlint` 全部通过。
- 2026-04-02：将 `#1122` 的安全 web/前端规则通道直接移植到 `rules/web/`，但调整了 `rules/web/hooks.md` 以优先考虑项目本地工具并避免远程一次性包执行示例。
- 2026-04-02：将 `#1127` 的设计质量提醒改编为当前 ECC 钩子架构，具有本地 `scripts/hooks/design-quality-check.js`、Claude `hooks/hooks.json` 连接、Cursor `after-file-edit.js` 连接，以及 `tests/hooks/design-quality-check.test.js` 中的专用钩子覆盖。
- 2026-04-02：在 `16e9b17` 中修复了 `main` 上的 `#1141`。观察者生命周期现在是会话感知的而不是纯粹的分离：`SessionStart` 编写项目范围的租约，`SessionEnd` 删除该租约并在最终租约消失时停止观察者，`observe.sh` 记录项目活动，`observer-loop.sh` 现在在没有剩余租约时在空闲时退出。针对性验证通过了 `bash -n`、`node tests/hooks/observer-memory.test.js`、`node tests/integration/hooks.test.js`、`node scripts/ci/validate-hooks.js hooks/hooks.json` 和 `node scripts/ci/check-unicode-safety.js`。
- 2026-04-02：通过使 `scripts/lib/utils.js#getHomeDir()` 在回退到 `os.homedir()` 之前优先考虑显式 `HOME`/`USERPROFILE` 覆盖来修复 `#1070` 后的剩余仅 Windows 钩子回归。这恢复了 Windows 上钩子集成运行的测试隔离观察者状态路径。在 `tests/lib/utils.test.js` 中添加了回归覆盖。针对性验证通过了 `node tests/lib/utils.test.js`、`node tests/integration/hooks.test.js`、`node tests/hooks/observer-memory.test.js` 和 `node scripts/ci/check-unicode-safety.js`。
- 2026-04-02：将 `#1022` 的 NestJS 支持直接移植到 `main` 作为 `skills/nestjs-patterns/SKILL.md`，并将其连接到 `framework-language` 安装模块。之后同步仓库目录（`38` 个智能体、`72` 个命令、`156` 个技能）并更新文档，因此 NestJS 不再列为未填充的框架空白。
- 2026-04-05：发布了 `846ffb7` (`chore: ship v1.10.0 release surface refresh`)。这更新了 README/插件元数据/包版本，同步了显式插件智能体清单，提升了陈旧的 star/fork/贡献者计数，创建了 `docs/releases/1.10.0/*`，标记和发布 `v1.10.0`，并在 `#1272` 发布了公告讨论。
- 2026-04-05：在 `6eba30f` 中抢救了可复用的 Hermes 分支操作员技能，而没有重播整个分支。添加了 `skills/github-ops`、`skills/knowledge-ops` 和 `skills/hookify-rules`，将它们连接到安装模块，并重新同步仓库到 `159` 个技能。`knowledge-ops` 显式适应当前工作区模型：克隆仓库中的实时代码，GitHub/Linear 中的活跃事实，KB/存档层中的更广泛非代码上下文。
- 2026-04-05：在 `db6d52e` 中修复了剩余的 OpenCode npm 发布差距。根包现在在 `prepack` 期间构建 `.opencode/dist`，在已发布的 tarball 中包含编译的 OpenCode 插件资产，并携带专用回归测试（`tests/scripts/build-opencode.test.js`），因此该包不再仅为该界面发布原始 TypeScript 源。
- 2026-04-05：添加了 `skills/council`，直接移植了 `#1193` 的安全 `code-tour` 通道，并重新同步仓库到 `162` 个技能。`code-tour` 保持自包含，仅生成具有真实文件/行锚点的 `.tours/*.tour` 构件；技能内不假设外部运行时或扩展安装。
- 2026-04-05：在部署 `ECC-Tools/main` 修复 `f615905` 后关闭了最新的自动生成 ECC bundle PR 波（`#1275`-`#1281`），该修复现在阻止仓库级 issue 注释 `/analyze` 请求打开重复的 bundle PR，同时仍允许 PR 线程重试分析针对不可变的头部 SHA 运行。
- 2026-04-05：通过直接移植 `agents/seo-specialist.md` 和 `skills/seo/SKILL.md` 到 `main`，然后将 `skills/seo` 连接到 `business-content` 来填补 SEO 空白。这解决了对 SEO 专家的陈旧 `team-builder` 引用，并将公共目录带到 `39` 个智能体和 `163` 个技能，而无需批量合并陈旧 PR。
- 2026-04-05：直接从 `#1214` 抢救了有用的通用规则增量到 `rules/common/coding-style.md` 和 `rules/common/testing.md`（KISS/DRY/YAGNI 提醒、命名约定、代码异味指导和 AAA 风格测试指导），然后关闭原始的混合删除 PR。该 PR 中的广泛技能删除有意未重播。
- 2026-04-05：在 `bf5961e` 中修复了 `.github/workflows/monthly-metrics.yml` 中的陈旧行 bug。工作流现在刷新 issue `#1087` 中的当前月份行，而不是在月份已存在时提前返回，调度的运行将 4 月快照更新到当前 star/fork/发布计数。
- 2026-04-05：从分歧的 Hermes 分支恢复了有用的成本控制工作流，作为小型 ECC 原生操作员技能，而不是重播分支。`skills/ecc-tools-cost-audit/SKILL.md` 现在连接到 `operator-workflows`，专注于 webhook -> queue -> worker 追踪、燃烧遏制、配绕过、高级模型泄漏和兄弟 `ECC-Tools` 仓库中的重试扩展。
- 2026-04-05：在 `753da37` 中添加了 `skills/council/SKILL.md` 作为 ECC 原生四种声音决策工作流。PR `#1254` 的有用协议被保留，但影子 `~/.claude/notes` 写入路径被显式删除，以支持 `knowledge-ops`、`/save-session` 或直接 GitHub/Linear 更新（当决策增量重要时）。
- 2026-04-05：将 PR `#1243` 的安全 `globals` 提升直接移植到 `main` 作为委员会通道的一部分，并将 PR 关闭为被取代。
- 2026-04-05：在完全审计后关闭 PR `#1232`。提议的 `skill-scout` 工作流与当前的 `search-first`、`/skill-create` 和 `skill-stocktake` 重叠；如果稍后返回专用市场发现层，应在当前安装/目录模型之上重建，而不是作为并行发现路径落地。
- 2026-04-05：直接将 PR `#1209` 的安全本地化 README 切换器修复移植到 `main`，而不是批量合并文档 PR。导航现在在本地化 README 切换器中始终包括 `Português (Brasil)` 和 `Türkçe`，而较新的本地化正文副本保持不变。
- 2026-04-05：从 `main` 中删除了陈旧的 InsAIts 已发布界面。ECC 不再发布外部 Python MCP 条目、可选钩子连接、包装器/监控脚本或 `insa-its` 的当前文档提及；变更日志历史保留，但实时产品界面现在再次完全 ECC 原生。
- 2026-04-05：在没有重播整个分支的情况下抢救了可复用的 Hermes 生成操作员工作流通道。添加了六个 ECC 原生顶级技能，而不是旧的嵌套 `skills/hermes-generated/*` 树：`automation-audit-ops`、`email-ops`、`finance-billing-ops`、`messages-ops`、`research-ops` 和 `terminal-ops`。`research-ops` 现在包装现有研究堆，而其他五个扩展 `operator-workflows` 而不引入任何外部运行时假设。
- 2026-04-05：添加了 `skills/product-capability` 加上 `docs/examples/product-capability-template.md` 作为 issue `#1185` 的规范 PRD-to-SRS 通道。这是 ECC 原生功能契约步骤，位于模糊的产品意图和实现之间，它位于 `business-content` 而不是生成并行规划子系统。
- 2026-04-05：收紧了 `product-lens`，使其不再与新的功能契约通道重叠。`product-lens` 现在显式拥有产品诊断/简要验证，而 `product-capability` 拥有实现就绪的功能计划和 SRS 风格约束。
- 2026-04-05：通过从导出的库存/文档中删除对已删除的 `project-guidelines-example` 技能的陈旧引用并将 `continuous-learning` v1 标记为具有显式移交到 `continuous-learning-v2` 的支持遗留路径来继续 `#1213` 清理。
- 2026-04-05：从 `docs/ko-KR` 和 `docs/zh-CN` 中删除了最后一个孤立的本地化 `project-guidelines-example` 文档。模板现在仅位于 `docs/examples/project-guidelines-template.md`，这与当前仓库界面匹配，并避免为已删除的技能发布翻译文档。
- 2026-04-05：添加了 `docs/HERMES-OPENCLAW-MIGRATION.md` 作为 issue `#1051` 的当前公共迁移指南。它将 Hermes/OpenClaw 重新构建为要提取的源系统，而不是最终运行时，并将调度程序、分派、内存、技能和服务层映射到已存在的 ECC 原生界面和 ECC 2.0 待办积压。
- 2026-04-05：从 issue `#916` 落地了 `skills/agent-sort` 和遗留 `/agent-sort` shim 作为 ECC 原生选择性安装工作流。它使用具体仓库证据将智能体、技能、命令、规则、钩子和额外组件分类为 DAILY 与 LIBRARY 存储桶，然后将安装更改移交给 `configure-ecc`，而不是发明并行安装程序。目录事实现在是 `39` 个智能体、`73` 个命令和 `179` 个技能。
- 2026-04-05：直接将安全仅 README 的 `#1285` 切片移植到 `main`，而不是合并分支：添加了一个小型 `Community Projects` 部分，以便下游团队可以链接基于 ECC 构建的公共工作，而无需更改安装、安全或运行时界面。在审查时拒绝 `#1286`，因为它添加了不满足当前供应链策略的外部第三方 GitHub Action（`hashgraph-online/codex-plugin-scanner`）。
- 2026-04-05：通过完全差异重新审计了 `origin/feat/hermes-generated-ops-skills`。分支仍然不可合并：它删除当前 ECC 原生界面，回归打包/安装元数据，并删除较新的 `main` 内容。继续选择性抢救策略而不是分支合并。
- 2026-04-05：从 Hermes 分支选择性抢救了 `skills/frontend-design` 作为自包含 ECC 原生技能，将其镜像到 `.agents`，将其连接到 `framework-language`，并在验证后重新同步目录到 `180` 个技能。分支本身保持只读，直到每个剩余的独特文件都被有意移植或拒绝。
- 2026-04-05：从 Hermes 分支选择性抢救了 `hookify` 命令 bundle 加上支持的 `conversation-analyzer` 智能体。`hookify-rules` 已经作为规范技能存在；此通道恢复了用户面向的命令界面（`/hookify`、`/hookify-help`、`/hookify-list`、`/hookify-configure`），而不引入任何外部运行时或分支范围的回归。目录事实现在是 `40` 个智能体、`77` 个命令和 `180` 个技能。
- 2026-04-05：从 Hermes 分支选择性抢救了自包含审查/开发 bundle：`review-pr`、`feature-dev` 和支持的分析师/架构智能体（`code-architect`、`code-explorer`、`code-simplifier`、`comment-analyzer`、`pr-test-analyzer`、`silent-failure-hunter`、`type-design-analyzer`）。这围绕 PR 审查和功能规划添加了 ECC 原生命令界面，而没有合并分支的更广泛回归。目录事实现在是 `47` 个智能体、`79` 个命令和 `180` 个技能。
- 2026-04-05：从 Hermes 分支移植了 `docs/HERMES-SETUP.md` 作为迁移通道的清理操作员拓扑文档。这是对 `#1051` 的仅文档支持，而不是运行时更改，也不是 Hermes 分支本身可合并的迹象。
- 2026-04-05：完成了对 `origin/feat/hermes-generated-ops-skills` 的有用抢救通道。剩余的独特文件被显式拒绝：
  - 重复的 git 辅助命令（`commit`、`commit-push-pr`、`clean-gone`）与当前检查点/发布流程重叠
  - `scripts/hooks/security-reminder*` 添加了新的 Python 支持的钩子路径，未由当前运行时策略证明
  - `skills/oura-health` 和 `skills/pmx-guidelines` 是用户或项目特定的，而不是规范 ECC 界面
  - `docs/releases/2.0.0-preview/*` 是过早的附带材料，应稍后根据当前产品事实重建
  - 嵌套 `skills/hermes-generated/*` 被已移植到 `main` 的顶级 ECC 原生操作员技能取代
- 2026-04-08：通过在 `agent.yaml` 中恢复规范的 `commands:` 部分并添加 `tests/ci/agent-yaml-surface.test.js` 来强制执行 YAML 导出界面与真实 `commands/` 目录之间的精确对等，修复了 `#1327` 中报告的命令导出回归。通过完整的仓库测试扫描验证：`1764/1764` 通过。
