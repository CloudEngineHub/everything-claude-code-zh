---
name: plan-orchestrate
description: 读取计划文档，将其分解为步骤，从 ECC 目录中为每个步骤设计智能体链，并生成可直接粘贴的 /orchestrate 自定义提示。仅生成 —— 从不调用 /orchestrate 本身。当用户有多个步骤的计划并希望通过 orchestrate 驱动而无需手动组合链时使用。
origin: ECC
---

# 计划编排

通过为每个步骤生成一个可直接粘贴的调用，将计划文档桥接到 `/orchestrate custom`。该技能仅生成 —— 它从不执行 `/orchestrate`。用户在准备好时粘贴每一行。

## 何时激活

- 用户有一个多步骤计划文档（PRD、RFC、实现计划）并希望通过 `/orchestrate` 驱动。
- 用户说"编排这个计划"、"给我每个步骤的 orchestrate 提示"、"为这个计划组合链"。
- 存在逐步计划但用户不想手动为每个步骤选择智能体。

跳过条件：
- 工作是一个临时步骤 -> 直接调用 `/orchestrate custom`。
- 计划不可读或为空。仅缺少显式编号本身不是跳过条件 —— 参见下面的"无明确步骤"边界情况。

## 输入

```
<plan-doc-path> [--lang=python|typescript|go|rust|cpp|java|kotlin|flutter|auto] [--scope=all|step:<n>|range:<a>-<b>] [--dry-run]
```

- `<plan-doc-path>` —— 必需；相对或绝对路径（接受 `@docs/...`）。
- `--lang` —— 审查者语言变体；默认为 `auto`（从项目检测）。
- `--scope` —— 限制输出的步骤；默认为 `all`。
- `--dry-run` —— 仅打印分解 + 链理由；不输出最终提示。

## 权威的 `/orchestrate` 格式（不要偏离）

```
{ORCH_CMD} custom "<agent1>,<agent2>,...,<agentN>" "<任务描述>"
```

其中 `{ORCH_CMD}` 在阶段 0 中确定（见下文）。输出中的命令字符串**始终使用一种具体形式** —— 从不同时使用两种，不使用占位符。

- `custom` 是顺序链；每个智能体的 HANDOFF 传递给下一个。
- 逗号分隔的智能体列表。首选无空格；允许一个空格。
- 不存在 `--mode` / `--gate` / `--agents=...` 标志 —— 永远不要发明它们。
- 智能体名称来自此技能中的目录。任务描述中的嵌入双引号转义为 `\"`。

## ECC 安装形式和命名空间

两种安装形式决定了斜杠命令和每个智能体名称的前缀。两者必须保持同步 —— 每个输出使用一种形式，从不混用：

设 `<claude-home>` 表示 Claude Code 主目录：macOS/Linux 上为 `~/.claude`，Windows 上为 `%USERPROFILE%\.claude`。按宿主平台解析用户主目录的方式解析它（不要硬编码 `~`）。

| 形式 | 检测方式 | `{ORCH_CMD}` | 智能体名称格式 |
|---|---|---|---|
| 插件安装（1.9.0+） | `<claude-home>/plugins/marketplaces/everything-claude-code/` 存在 | `/everything-claude-code:orchestrate` | `everything-claude-code:<name>` |
| 遗留裸安装 | 上述不存在；智能体文件在 `<claude-home>/agents/` 下 | `/orchestrate` | `<name>` |

为什么这很重要：在插件安装下，智能体注册为 `everything-claude-code:tdd-guide`。裸名称强制模糊匹配，这在并行调用下会间歇性失败。在遗留模式下，带前缀的形式未注册并直接失败。

## 可用智能体目录（必须从中选择）

通用：
- `planner` —— 需求重述、风险分解、步骤规划
- `architect` —— 架构、系统设计、重构提案
- `tdd-guide` —— 编写测试 -> 实现 -> 80%+ 覆盖率
- `code-reviewer` —— 通用代码审查
- `security-reviewer` —— 安全审计、OWASP、秘密泄露
- `refactor-cleaner` —— 死代码、重复、knip 类清理
- `doc-updater` —— 文档、代码地图、README
- `docs-lookup` —— 第三方库 API 查找（Context7）
- `e2e-runner` —— 端到端测试编排
- `database-reviewer` —— PostgreSQL 模式、迁移、性能
- `harness-optimizer` —— 本地智能体 harness 配置
- `loop-operator` —— 长时间运行的自主循环
- `chief-of-staff` —— 多渠道分流（很少适合计划步骤）

构建错误解析器：
- `build-error-resolver`（通用）/ `cpp-build-resolver` / `go-build-resolver` / `java-build-resolver` / `kotlin-build-resolver` / `rust-build-resolver` / `pytorch-build-resolver`

代码审查者：
- `python-reviewer` / `typescript-reviewer` / `go-reviewer` / `rust-reviewer` / `cpp-reviewer` / `java-reviewer` / `kotlin-reviewer` / `flutter-reviewer`

拼写错误的智能体名称会导致 `/orchestrate` 失败。在输出前对照此列表进行交叉检查。

## 工作原理

### 阶段 0 —— 检测 ECC 模式 + 语言

1. 读取 `<plan-doc-path>`。如果缺失或为空，报告并停止。
2. 检测一次 ECC 安装形式并将其冻结为 `ECC_MODE`。算法（按顺序运行，在第一个匹配时停止）：
   1. 如果 `<claude-home>/plugins/marketplaces/everything-claude-code/` 存在 -> `ECC_MODE=plugin`。
   2. 否则如果 `<claude-home>/agents/` 存在且包含至少一个 ECC 智能体文件（如 `tdd-guide.md`、`code-reviewer.md`） -> `ECC_MODE=legacy`。
   3. 否则 -> 默认为 `ECC_MODE=legacy` 并在输出顶部发出一行警告：`> 警告：无法检测 ECC 安装；默认使用遗留形式。如果你使用插件安装，请手动编辑前缀。`
   4. 如果两个标记都存在（混合安装），`plugin` 胜出 —— 插件命名空间是唯一能在不使用模糊匹配的情况下解析智能体名称的。

   从此时起，每行输出在斜杠命令和每个智能体名称上都使用匹配的前缀。**从不在同一输出中发出两种形式。**
3. 解析 `--lang`。当为 `auto` 时，运行多语言感知检测：
   - 探测标记：`pyproject.toml` / `uv.lock` / `requirements.txt` -> python；`package.json` -> typescript；`go.mod` -> go；`Cargo.toml` -> rust；`CMakeLists.txt` 或顶层 `*.cpp` -> cpp；`pom.xml` / `build.gradle`（Java） -> java；`build.gradle.kts` 或顶层 Kotlin -> kotlin；`pubspec.yaml` -> flutter。
   - **多语言决胜**：如果多个标记匹配，选择源文件数量最多的语言（通过 `git ls-files` 计数，排除 `vendor/`、`node_modules/`、`dist/`、`build/`、`.venv/`、生成文件和明显的测试固件）。平局或没有语言超过源文件的 60% 时，设置 `lang=unknown`。
   - 没有标记匹配 -> 设置 `lang=unknown`。
   - `lang=unknown` 是哨兵值 —— 它**不是**智能体名称。阶段 2 的规则 4 和 5 在链组合时将其转换为 `code-reviewer` / `build-error-resolver`。
4. 检测 **PyTorch 子配置**：当 `lang=python` 且 `pyproject.toml` / `requirements.txt` / `uv.lock` 中的任一声明了对 `torch` 的依赖时，设置 `pytorch=true`。这仅影响 `build` 链选择（下面的阶段 2 规则）；审查者保持为 `python-reviewer`。
5. **规范化计划中声明的任何智能体名称**：如果计划文本以插件前缀形式引用智能体（如 `everything-claude-code:tdd-guide`），去除前缀以获取裸目录名称，然后再验证或组合链。重新加前缀仅在输出时根据 `ECC_MODE` 进行（阶段 4）。永远不要让预加前缀的名称流入链组合 —— 这在插件模式下会导致双重前缀。

### 阶段 1 —— 分解步骤

按优先级顺序识别"步骤单元"：

1. 显式编号：`## Step N` / `### Phase N` / `## N. ...` / 顶层有序列表。
2. 表格中的"Step"列。
3. 以 `---` 分隔的带动词引导标题的块。
4. 否则将每个 H2 视为一个步骤。

每个步骤提取 `id`（从 1 开始）、`title`（<= 80 字符）、`intent`（1-3 句话）、`tags`。

### 阶段 2 —— 标记并选择链

按意图标记（允许多标记；链由主标记 + 堆叠的辅助标记构建）：

下面的触发词以不区分大小写的方式匹配。支持多语言计划，只要含义与列出的英文触发词一致，就匹配任何语言的词干。

| 标记 | 触发词 | 默认链 |
|---|---|---|
| `design` | architecture、design、choose、evaluate、RFC | `planner,architect` |
| `plan` | plan、breakdown、milestone | `planner` |
| `impl` | implement、build、add、create、port | `tdd-guide,<lang>-reviewer` |
| `test` | test、coverage、e2e、integration | `tdd-guide,e2e-runner` |
| `refactor` | refactor、cleanup、dedupe、split | `architect,refactor-cleaner,<lang>-reviewer` |
| `migration` | migrate、upgrade、rewrite、port | `architect,tdd-guide,<lang>-reviewer` |
| `db` | schema、migration、index、SQL、Postgres、alembic、sqlmodel | `database-reviewer,<lang>-reviewer` |
| `security` | encrypt、auth、secret、OWASP、PII | `security-reviewer,<lang>-reviewer` |
| `build` | build、compile、lint failure、CI | `<lang>-build-resolver`（回退到 `build-error-resolver`） |
| `docs` | docs、readme、codemap、changelog | `doc-updater` |
| `lookup` | lookup、reference、API usage | `docs-lookup` |
| `review` | review、audit、verify | `<lang>-reviewer,code-reviewer` |
| `loop` | loop、autonomous、watchdog | `loop-operator` |

链组合规则：
1. **主标记选择**：当步骤匹配多个标记时，表格顺序中的**第一个**（表格顶部 = 最高优先级）是主标记；其余为辅助标记。下面的组合规则 2 和 3 明确处理特定的多标记组合；否则，按标记表顺序追加辅助链。
2. `impl` + `security` -> `tdd-guide,<lang>-reviewer,security-reviewer`。
3. `impl` + `db` -> `tdd-guide,database-reviewer,<lang>-reviewer`。
4. **去重**结果链（保留首次出现）。例如 `review` + `lang=unknown` 在规则 5 后会产生 `code-reviewer,code-reviewer`；去重将其折叠为 `code-reviewer`。
5. 当 `lang=unknown` 时，`<lang>-reviewer` 解析为 `code-reviewer`。
6. 当 `lang=unknown` 时，`<lang>-build-resolver` 解析为 `build-error-resolver`。**特殊情况**：如果阶段 0 设置了 `pytorch=true`，则 `build` 链使用 `pytorch-build-resolver`，无论 `<lang>` 如何。不存在 `python-build-resolver`；不带 `pytorch=true` 的 `--lang=python` 解析为 `build-error-resolver`。
7. **零标记步骤**：如果没有触发词匹配，设置链为 `code-reviewer` 并在"链理由"下写 `no tag matched; default review-only chain`。
8. 去重后链长度 <= 4。如果超过，丢弃最弱的标记（先丢弃 `lookup` 和 `docs`）。
9. 不要在 `impl` 链中配对 `planner` 和 `architect`（token 浪费）。仅在 `design` 步骤上配对它们。
10. 标记为 `impl`、`refactor` 或 `migration` 的步骤以**审查者类**智能体结束 —— `<lang>-reviewer`、`code-reviewer`、`security-reviewer` 或 `database-reviewer` 中的任何一个。最领域特定的审查者赢得尾部位置（例如规则 2 的 `impl+security` 以 `security-reviewer` 结束；规则 3 的 `impl+db` 以 `<lang>-reviewer` 结束，因为 `database-reviewer` 已在链中较早地门控了迁移）。`test` 和 `build` 步骤由它们自己的验证器门控（`e2e-runner` 和构建解析器），不需要额外的审查者。

### 阶段 3 —— 压缩任务描述

每个输出的 `<任务描述>` 必须：
- 自包含（第一个智能体不需要打开计划文档）。
- 以 `[Plan: <path>#step-<id>]` 开始。
- 包含 1-3 个可验证的验收标准。
- 包含范围守护（`Out of scope: ...`）**仅当计划为此步骤声明了范围守护时**。原样继承。如果计划没有范围外声明，完全省略该子句 —— 不要发明一个。
- 长度为 200-600 字符；单行；嵌入的 `"` 转义为 `\"`；无字面换行符。

### 阶段 4 —— 输出

使用**由 `ECC_MODE` 确定的形式**输出 Markdown。输出始终使用一种形式 —— 每行 `{ORCH_CMD}` 和每个智能体名称都使用阶段 0 中匹配的前缀渲染。**不要输出两种形式；不要在渲染的输出中包含"这是插件形式"/"去除前缀"指令。**

具体渲染规则：

- `{ORCH_CMD}` = 在 `plugin` 下为 `/everything-claude-code:orchestrate`，在 `legacy` 下为 `/orchestrate`。
- `{AGENT(name)}` = 在 `plugin` 下为 `everything-claude-code:<name>`，在 `legacy` 下为 `<name>`。
- 概览表的"Chain"列使用相同的 `{AGENT(name)}` 渲染。
- 每步骤的 bash 块仅包含可运行的命令。**没有 `# 插件形式` 或 `# 遗留形式` 注释** —— 形式是隐式的且在整个输出中统一。

输出结构：

````markdown
# Plan-Orchestrate 结果

**计划**：`<path>`
**语言**：`<detected-or-given>`
**ECC 模式**：`<plugin | legacy>`
**步骤数**：<N>
**范围**：<all | step:n | range:a-b>

## 步骤概览

| # | 标题 | 标记 | 链 |
|---|---|---|---|
| 1 | ... | impl, db | `{AGENT(tdd-guide)},{AGENT(database-reviewer)},{AGENT(python-reviewer)}` |
| ... | | | |

---

## 步骤 1 — <标题>

**意图**：<1-3 句话>
**标记**：<a, b>
**链理由**：<为什么选择此链；哪个智能体关闭循环>

```bash
{ORCH_CMD} custom "{AGENT(tdd-guide)},{AGENT(database-reviewer)},{AGENT(python-reviewer)}" "[Plan: docs/foo.md#step-1] <压缩的任务描述>; 验收标准：<1-3 项>; 超出范围：<…>"
```
````

> 上面的 `{ORCH_CMD}` 和 `{AGENT(...)}` 表示法描述了此技能在运行时执行的替换。实际输出的 Markdown 包含解析后的字符串，而非占位符。

在末尾追加一个"批量执行"块，按顺序聚合每个步骤的命令，以便用户可以一次性全部粘贴。**在仅概览模式下跳过批量块**（参见"大型计划"边界情况）：当只输出概览表时，没有每步骤命令可聚合。

### 阶段 5 —— 自检（在输出前运行）

- [ ] 每条链中的每个智能体来自目录（去除计划中出现的任何 `everything-claude-code:` 前缀后；见阶段 0 步骤 5）。
- [ ] 解析的 `{ORCH_CMD}` 和每个解析的 `{AGENT(...)}` 使用**相同的**形式（`plugin` 或 `legacy`） —— 从不在一个输出中混用。
- [ ] 没有剩余的 `# 插件形式` / `# 遗留形式` 注释和"去除前缀"指令。
- [ ] 没有发明的 `--mode` / `--gate` / `--agents=...` 字段。
- [ ] 每个任务描述是单行的、双引号的，嵌入的 `"` 已转义。
- [ ] 每个任务描述以 `[Plan: <path>#step-<id>]` 开始并包含验收标准（1-3 项）。`Out of scope:` 子句仅在从计划继承时存在。
- [ ] 阶段 2 去重后任何链中没有重复智能体。
- [ ] 链长度 <= 4。
- [ ] 标记为 `impl`/`refactor`/`migration` 的步骤以审查者类智能体结束（`<lang>-reviewer`、`code-reviewer`、`security-reviewer` 或 `database-reviewer`）。`test` 和 `build` 豁免 —— 见阶段 2 规则 10。
- [ ] 零标记步骤输出 `code-reviewer`，理由为 `no tag matched; default review-only chain`。
- [ ] 概览表列出计划中的每个步骤，不受 `--scope` 影响。
- [ ] 每步骤详情块数量与解析的 `--scope` 匹配（`--scope=all` 时为完整计划；`step:n` 时为一个块；`range:a-b` 时为范围大小）。在仅概览模式下，不输出每步骤详情块和批量块。

## 边界情况

- **无明确步骤**：优先使用 H2/H3 分割；如果仍然模糊，报告"未检测到结构化步骤"并附上文档大纲，要求用户确认是否按大纲运行。
- **大型计划（>1500 行）**：进入**仅概览模式** —— 仅输出概览表，要求用户在重新运行详情前用 `--scope` 缩小范围。在此模式下，跳过每步骤详情块和批量执行块。
- **步骤过于宽泛**（如"完成所有后端工作"）：不要强制使用单条链。建议拆分为 N.a 和 N.b 并提出拆分方案。
- **计划声明了智能体**（罕见）：首先**去除任何 `everything-claude-code:` 前缀**以获取裸目录名称（阶段 0 步骤 5），然后对照目录验证。替换无效智能体并在"链理由"下解释。裸名称在输出时根据 `ECC_MODE` 重新加前缀。
- **`--lang=auto` 无法选出赢家的多语言项目**：设置 `lang=unknown`；审查者解析为 `code-reviewer`，构建解析器解析为 `build-error-resolver`。在"链理由"下提及回退。

## 示例

### 示例 1 —— 插件模式，Python 计划

输入：
```
plan-orchestrate @docs/plan/example-feature.md --lang=python
```

预期输出摘录：
````markdown
## 步骤 2 — 加密敏感 UserProfile 字段

**意图**：引入 `EncryptedString` SQLAlchemy 类型，在持久化之前使用 AES-GCM 加密 `birth_datetime` / `location`；从环境变量加载密钥。
**标记**：impl, security, db
**链理由**：安全敏感的写入路径，因此 `security-reviewer` 关闭链；`database-reviewer` 验证 alembic 迁移；`python-reviewer` 覆盖类型和 PEP 8。

```bash
/everything-claude-code:orchestrate custom "everything-claude-code:tdd-guide,everything-claude-code:database-reviewer,everything-claude-code:python-reviewer,everything-claude-code:security-reviewer" "[Plan: docs/plan/example-feature.md#step-2] 实现 EncryptedString SQLAlchemy 类型并迁移 UserProfile.birth_datetime/location 列；密钥来自 ENV APP_DB_KEY；验收标准：加密/解密往返测试通过；alembic upgrade/downgrade 在空 DB 上干净；迁移后 DB 中无明文；超出范围：跨租户配置文件共享逻辑"
```
````

### 示例 2 —— 遗留模式，相同步骤

如果检测到 `ECC_MODE=legacy`，相同的步骤将作为单个统一命令输出（输出中任何地方都没有插件前缀形式）：

```bash
/orchestrate custom "tdd-guide,database-reviewer,python-reviewer,security-reviewer" "[Plan: docs/plan/example-feature.md#step-2] ..."
```

上面两个示例展示了两种不同环境的**两种可能输出**。单个技能调用从头到尾只产生其中一种。

## 注意事项

- 仅生成。从不在该技能内部调用 `/orchestrate`。
- 任务描述使用计划文档的语言匹配（智能体名称始终保持英文）。
- 除非用户明确要求，否则不要在输出中插入"Co-Authored-By"行或 emoji。
