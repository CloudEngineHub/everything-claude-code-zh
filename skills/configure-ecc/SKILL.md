---
name: configure-ecc
description: Everything Claude Code 的交互式安装器 — 引导用户选择并安装技能和规则到用户级或项目级目录，验证路径，并可选优化已安装的文件。
origin: ECC
---

# 配置 Everything Claude Code (ECC)

一个交互式的、逐步安装向导，用于 Everything Claude Code 项目。使用 `AskUserQuestion` 引导用户选择性安装技能和规则，然后验证正确性并提供优化。

## 何时激活

- 用户说"configure ecc"、"install ecc"、"setup everything claude code"或类似内容
- 用户想要从此项目中选择性安装技能或规则
- 用户想要验证或修复现有的 ECC 安装
- 用户想要为他们的项目优化已安装的技能或规则

## 前置条件

此技能必须在激活前可被 Claude Code 访问。两种引导方式：
1. **通过插件**：`/plugin install ecc@ecc` — 插件会自动加载此技能
2. **手动**：仅将此技能复制到 `~/.claude/skills/configure-ecc/SKILL.md`，然后通过说"configure ecc"激活

---

## 步骤 0：克隆 ECC 仓库

在安装之前，将最新的 ECC 源码克隆到 `/tmp`：

```bash
rm -rf /tmp/everything-claude-code
git clone https://github.com/affaan-m/everything-claude-code.git /tmp/everything-claude-code
```

设置 `ECC_ROOT=/tmp/everything-claude-code` 作为所有后续复制操作的源。

如果克隆失败（网络问题等），使用 `AskUserQuestion` 请求用户提供本地 ECC 克隆的路径。

---

## 步骤 1：选择安装级别

使用 `AskUserQuestion` 询问用户安装位置：

```
问题："ECC 组件应该安装到哪里？"
选项：
  - "用户级 (~/.claude/)" — "应用于你所有的 Claude Code 项目"
  - "项目级 (.claude/)" — "仅应用于当前项目"
  - "两者" — "通用/共享项用户级，项目特定项项目级"
```

将选择存储为 `INSTALL_LEVEL`。设置目标目录：
- 用户级：`TARGET=~/.claude`
- 项目级：`TARGET=.claude`（相对于当前项目根目录）
- 两者：`TARGET_USER=~/.claude`，`TARGET_PROJECT=.claude`

创建目标目录（如不存在）：
```bash
mkdir -p $TARGET/skills $TARGET/rules
```

---

## 步骤 2：选择并安装技能

### 2a：选择范围（核心 vs 细分）

默认为**核心（推荐新用户使用）** — 复制 `.agents/skills/*` 加上 `skills/search-first/` 用于研究优先工作流。此捆绑包涵盖工程、评估、验证、安全、战略压缩、前端设计和 Anthropic 跨职能技能（文章写作、内容引擎、市场研究、前端幻灯片）。

使用 `AskUserQuestion`（单选）：
```
问题："仅安装核心技能，还是包含细分/框架包？"
选项：
  - "仅核心（推荐）" — "tdd, e2e, 评估, 验证, 研究优先, 安全, 前端模式, 压缩, 跨职能 Anthropic 技能"
  - "核心 + 选择的细分" — "在核心之后添加框架/领域特定技能"
  - "仅细分" — "跳过核心，安装特定的框架/领域技能"
默认：仅核心
```

如果用户选择细分或核心 + 细分，继续到下面的类别选择，仅包含他们选择的那些细分技能。

### 2b：选择技能类别

下面有 7 个可选类别组。详细的确认列表涵盖 8 个类别的 45 个技能，加上 1 个独立模板。使用 `AskUserQuestion` 并设置 `multiSelect: true`：

```
问题："你想安装哪些技能类别？"
选项：
  - "框架与语言" — "Django, Laravel, Spring Boot, Quarkus, Go, Python, Java, 前端, 后端模式"
  - "数据库" — "PostgreSQL, ClickHouse, JPA/Hibernate 模式"
  - "工作流与质量" — "TDD, 验证, 学习, 安全审查, 压缩"
  - "研究与 API" — "深度研究, Exa 搜索, Claude API 模式"
  - "社交与内容分发" — "X/Twitter API, 跨平台发布配合内容引擎"
  - "媒体生成" — "fal.ai 图像/视频/音频配合 VideoDB"
  - "编排" — "dmux 多智能体工作流"
  - "所有技能" — "安装所有可用技能"
```

### 2c：确认各个技能

对每个选择的类别，打印以下完整技能列表并让用户确认或取消选择特定的。如果列表超过 4 项，将列表作为文本打印，并使用 `AskUserQuestion` 提供"安装所有列出"选项加上"其他"让用户粘贴特定名称。

**类别：框架与语言（25 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `backend-patterns` | 后端架构、API 设计、Node.js/Express/Next.js 的服务端最佳实践 |
| `coding-standards` | TypeScript、JavaScript、React、Node.js 的通用编码标准 |
| `django-patterns` | Django 架构、使用 DRF 的 REST API、ORM、缓存、信号、中间件 |
| `django-security` | Django 安全：认证、CSRF、SQL 注入、XSS 防护 |
| `django-tdd` | 使用 pytest-django 的 Django 测试、factory_boy、mock、覆盖率 |
| `django-verification` | Django 验证循环：迁移、代码检查、测试、安全扫描 |
| `laravel-patterns` | Laravel 架构模式：路由、控制器、Eloquent、队列、缓存 |
| `laravel-security` | Laravel 安全：认证、策略、CSRF、批量赋值、速率限制 |
| `laravel-tdd` | 使用 PHPUnit 和 Pest 的 Laravel 测试、工厂、fake、覆盖率 |
| `laravel-verification` | Laravel 验证：代码检查、静态分析、测试、安全扫描 |
| `frontend-patterns` | React、Next.js、状态管理、性能、UI 模式 |
| `frontend-slides` | 零依赖 HTML 演示、样式预览和 PPTX 转 Web |
| `golang-patterns` | 地道的 Go 模式、健壮 Go 应用的约定 |
| `golang-testing` | Go 测试：表驱动测试、子测试、基准测试、模糊测试 |
| `java-coding-standards` | Spring Boot 和 Quarkus 的 Java 编码标准：命名、不可变性、Optional、流、CDI |
| `python-patterns` | Python 地道写法、PEP 8、类型提示、最佳实践 |
| `python-testing` | 使用 pytest 的 Python 测试、TDD、夹具、mock、参数化 |
| `quarkus-patterns` | Quarkus 架构、Camel 消息、CDI 服务、Panache 数据访问 |
| `quarkus-security` | Quarkus 安全：JWT/OIDC、RBAC、输入验证、密钥管理 |
| `quarkus-tdd` | 使用 JUnit 5、Mockito、REST Assured、Camel 测试的 Quarkus TDD |
| `quarkus-verification` | Quarkus 验证：构建、静态分析、测试、原生编译 |
| `springboot-patterns` | Spring Boot 架构、REST API、分层服务、缓存、异步 |
| `springboot-security` | Spring Security：认证/授权、验证、CSRF、密钥、速率限制 |
| `springboot-tdd` | 使用 JUnit 5、Mockito、MockMvc、Testcontainers 的 Spring Boot TDD |
| `springboot-verification` | Spring Boot 验证：构建、静态分析、测试、安全扫描 |

**类别：数据库（3 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `clickhouse-io` | ClickHouse 模式、查询优化、分析、数据工程 |
| `jpa-patterns` | JPA/Hibernate 实体设计、关系、查询优化、事务 |
| `postgres-patterns` | PostgreSQL 查询优化、模式设计、索引、安全 |

**类别：工作流与质量（8 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `continuous-learning` | 遗留 v1 Stop-hook 会话模式提取；新安装建议使用 `continuous-learning-v2` |
| `continuous-learning-v2` | 基于本能的学习，带置信度评分，演化为技能、智能体和可选的遗留命令 shim |
| `eval-harness` | 评估驱动开发（EDD）的正式评估框架 |
| `iterative-retrieval` | 渐进式上下文细化，用于子智能体上下文问题 |
| `security-review` | 安全检查清单：认证、输入、密钥、API、支付功能 |
| `strategic-compact` | 在逻辑间隔建议手动上下文压缩 |
| `tdd-workflow` | 强制 TDD 并达到 80%+ 覆盖率：单元、集成、E2E |
| `verification-loop` | 验证和质量循环模式 |

**类别：商业与内容（5 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `article-writing` | 使用笔记、示例或源文档以提供的声音进行长文写作 |
| `content-engine` | 多平台社交内容、脚本和复用工作流 |
| `market-research` | 带来源引用的市场、竞争对手、基金和技术研究 |
| `investor-materials` | 路演文档、单页介绍、投资者备忘录和财务模型 |
| `investor-outreach` | 个性化投资者冷邮件、热介绍和跟进 |

**类别：研究与 API（2 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `deep-research` | 使用 firecrawl 和 exa MCP 进行多源深度研究并附引用报告 |
| `exa-search` | 通过 Exa MCP 进行神经搜索，用于网页、代码、公司和人物研究 |

`claude-api` 是 Anthropic 的官方技能。当你想要官方 Claude API 工作流而非 ECC 捆绑副本时，从 [`anthropics/skills`](https://github.com/anthropics/skills) 安装。

**类别：社交与内容分发（2 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `x-api` | X/Twitter API 集成，用于发帖、推文串、搜索和分析 |
| `crosspost` | 带平台原生适配的多平台内容分发 |

**类别：媒体生成（2 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `fal-ai-media` | 通过 fal.ai MCP 的统一 AI 媒体生成（图像、视频、音频） |
| `video-editing` | AI 辅助视频编辑，用于剪辑、结构化和增强真实素材 |

**类别：编排（1 个技能）**

| 技能 | 描述 |
|-------|-------------|
| `dmux-workflows` | 使用 dmux 进行多智能体编排的并行智能体会话 |

**独立**

| 技能 | 描述 |
|-------|-------------|
| `docs/examples/project-guidelines-template.md` | 创建项目特定技能的模板 |

### 2d：执行安装

对每个选择的技能，从正确的源根复制整个技能目录：

```bash
# 核心技能位于 .agents/skills/
cp -R "$ECC_ROOT/.agents/skills/<skill-name>" "$TARGET/skills/"

# 细分技能位于 skills/
cp -R "$ECC_ROOT/skills/<skill-name>" "$TARGET/skills/"
```

遍历 glob 源目录时，永远不要直接将带尾部斜杠的源传给 `cp`。显式使用目录路径作为目标名称：

```bash
cp -R "${src%/}" "$TARGET/skills/$(basename "${src%/}")"
```

注意：`continuous-learning` 和 `continuous-learning-v2` 有额外文件（config.json、hooks、scripts）— 确保复制整个目录，而不仅是 SKILL.md。

---

## 步骤 3：选择并安装规则

使用 `AskUserQuestion` 并设置 `multiSelect: true`：

```
问题："你想安装哪些规则集？"
选项：
  - "通用规则（推荐）" — "语言无关的原则：编码风格、Git 工作流、测试、安全等（8 个文件）"
  - "TypeScript/JavaScript" — "TS/JS 模式、钩子、使用 Playwright 的测试（5 个文件）"
  - "Python" — "Python 模式、pytest、black/ruff 格式化（5 个文件）"
  - "Go" — "Go 模式、表驱动测试、gofmt/staticcheck（5 个文件）"
```

执行安装：
```bash
# 通用规则
cp -r $ECC_ROOT/rules/common $TARGET/rules/common

# 语言特定规则（保留每种语言的目录）
cp -r $ECC_ROOT/rules/typescript $TARGET/rules/typescript   # 如已选择
cp -r $ECC_ROOT/rules/python $TARGET/rules/python            # 如已选择
cp -r $ECC_ROOT/rules/golang $TARGET/rules/golang            # 如已选择
```

**重要**：如果用户选择了任何语言特定规则但未选择通用规则，警告他们：
> "语言特定规则扩展了通用规则。不安装通用规则可能导致覆盖不完整。也安装通用规则吗？"

---

## 步骤 4：安装后验证

安装后，执行以下自动化检查：

### 4a：验证文件存在

列出所有已安装文件并确认它们存在于目标位置：
```bash
ls -la $TARGET/skills/
ls -la $TARGET/rules/
```

### 4b：检查路径引用

扫描所有已安装的 `.md` 文件中的路径引用：
```bash
grep -rn "~/.claude/" $TARGET/skills/ $TARGET/rules/
grep -rn "../common/" $TARGET/rules/
grep -rn "skills/" $TARGET/skills/
```

**对于项目级安装**，标记任何引用 `~/.claude/` 路径的内容：
- 如果技能引用 `~/.claude/settings.json` — 这通常没问题（设置始终是用户级的）
- 如果技能引用 `~/.claude/skills/` 或 `~/.claude/rules/` — 如果仅安装在项目级，这可能有问题
- 如果技能按名称引用另一个技能 — 检查被引用的技能是否也已安装

### 4c：检查技能之间的交叉引用

一些技能引用其他技能。验证这些依赖：
- `django-tdd` 可能引用 `django-patterns`
- `laravel-tdd` 可能引用 `laravel-patterns`
- `quarkus-tdd` 可能引用 `quarkus-patterns`
- `springboot-tdd` 可能引用 `springboot-patterns`
- `continuous-learning-v2` 引用 `~/.claude/homunculus/` 目录
- `python-testing` 可能引用 `python-patterns`
- `golang-testing` 可能引用 `golang-patterns`
- `crosspost` 引用 `content-engine` 和 `x-api`
- `deep-research` 引用 `exa-search`（互补的 MCP 工具）
- `fal-ai-media` 引用 `videodb`（互补的媒体技能）
- `x-api` 引用 `content-engine` 和 `crosspost`
- 语言特定规则引用 `common/` 对应内容

### 4d：报告问题

对发现的每个问题，报告：
1. **文件**：包含有问题引用的文件
2. **行号**：行号
3. **问题**：出了什么问题（如"引用了 ~/.claude/skills/python-patterns 但 python-patterns 未安装"）
4. **建议修复**：怎么做（如"安装 python-patterns 技能"或"更新路径为 .claude/skills/"）

---

## 步骤 5：优化已安装文件（可选）

使用 `AskUserQuestion`：

```
问题："你想为你的项目优化已安装的文件吗？"
选项：
  - "优化技能" — "移除不相关的部分、调整路径、为你的技术栈定制"
  - "优化规则" — "调整覆盖率目标、添加项目特定模式、自定义工具配置"
  - "优化两者" — "对所有已安装文件进行全面优化"
  - "跳过" — "保持原样"
```

### 如果优化技能：
1. 读取每个已安装的 SKILL.md
2. 询问用户他们项目的技术栈（如果尚未知道）
3. 对每个技能，建议移除不相关的部分
4. 在安装目标位置原地编辑 SKILL.md 文件（而非源仓库）
5. 修复步骤 4 中发现的任何路径问题

### 如果优化规则：
1. 读取每个已安装的规则 .md 文件
2. 询问用户的偏好：
   - 测试覆盖率目标（默认 80%）
   - 首选格式化工具
   - Git 工作流约定
   - 安全要求
3. 在安装目标位置原地编辑规则文件

**关键**：仅修改安装目标（`$TARGET/`）中的文件，绝不修改源 ECC 仓库（`$ECC_ROOT/`）中的文件。

---

## 步骤 6：安装摘要

从 `/tmp` 清理克隆的仓库：

```bash
rm -rf /tmp/everything-claude-code
```

然后打印摘要报告：

```
## ECC 安装完成

### 安装目标
- 级别：[用户级 / 项目级 / 两者]
- 路径：[目标路径]

### 已安装的技能（[数量]）
- skill-1, skill-2, skill-3, ...

### 已安装的规则（[数量]）
- common（8 个文件）
- typescript（5 个文件）
- ...

### 验证结果
- 发现 [数量] 个问题，修复了 [数量] 个
- [列出任何剩余问题]

### 已应用的优化
- [列出所做的更改，或"无"]
```

---

## 故障排除

### "技能未被 Claude Code 识别"
- 验证技能目录包含 `SKILL.md` 文件（而非仅松散的 .md 文件）
- 用户级：检查 `~/.claude/skills/<skill-name>/SKILL.md` 是否存在
- 项目级：检查 `.claude/skills/<skill-name>/SKILL.md` 是否存在

### "规则不工作"
- 规则是扁平文件，不在子目录中：`$TARGET/rules/coding-style.md`（正确）vs `$TARGET/rules/common/coding-style.md`（扁平安装时不正确）
- 安装规则后重启 Claude Code

### "项目级安装后出现路径引用错误"
- 一些技能假设 `~/.claude/` 路径。运行步骤 4 验证来发现并修复这些问题。
- 对于 `continuous-learning-v2`，`~/.claude/homunculus/` 目录始终是用户级的 — 这是预期的，不是错误。
