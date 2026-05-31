---
name: prompt-optimizer
description: >-
  分析原始提示词，识别意图和缺口，匹配 ECC 组件（技能/命令/智能体/钩子），并输出可直接粘贴的优化提示词。仅提供顾问角色 —— 从不执行任务本身。
  触发条件：用户说"优化prompt"、"改进prompt"、"怎么写prompt"、"帮我prompt"、"重写这个prompt"，
  或明确要求提升提示词质量。也触发于中文等价表达："优化prompt"、"改进prompt"、"怎么写prompt"、"帮我优化这个指令"。
  不触发条件：用户想要直接执行任务，或说"直接做"。不触发于"优化代码"、"优化性能"、"optimize performance"——这些是重构/性能任务，不是提示词优化。
origin: community
metadata:
  author: YannJY02
  version: "1.0.0"
---

# 提示词优化器

分析草稿提示词，批评它，将其匹配到 ECC 生态系统组件，并输出用户可以粘贴运行的完整优化提示词。

## 何时使用

- 用户说"优化这个提示词"、"改进我的提示词"、"重写这个提示词"
- 用户说"帮我写一个更好的提示词来..."
- 用户说"向 Claude Code 提问的最佳方式是什么..."
- 用户说"优化prompt"、"改进prompt"、"怎么写prompt"、"帮我优化这个指令"
- 用户粘贴草稿提示词并要求反馈或改进
- 用户说"我不知道怎么为这个写提示词"
- 用户说"我该怎么为...使用 ECC"
- 用户明确调用 `/prompt-optimize`

### 何时不使用

- 用户想要直接完成任务（直接执行）
- 用户说"优化代码"、"优化性能"——这些是重构任务，不是提示词优化
- 用户在询问 ECC 配置（改用 `configure-ecc`）
- 用户想要技能盘点（改用 `skill-stocktake`）
- 用户说"直接做"

## 工作原理

**仅提供顾问 —— 不执行用户的任务。**

不要编写代码、创建文件、运行命令或采取任何实现行动。你唯一的输出是分析加一个优化提示词。

如果用户说"直接做"或"不要优化，直接执行"，不要在此技能内切换到实现模式。告诉用户此技能仅产出优化提示词，并指示他们如果想要执行则提出正常的任务请求。

按顺序运行此 6 阶段管道。使用下面的输出格式呈现结果。

### 分析管道

### 阶段 0：项目检测

在分析提示词之前，检测当前项目上下文：

1. 检查工作目录中是否存在 `CLAUDE.md` —— 读取其中的项目约定
2. 从项目文件检测技术栈：
   - `package.json` -> Node.js / TypeScript / React / Next.js
   - `go.mod` -> Go
   - `pyproject.toml` / `requirements.txt` -> Python
   - `Cargo.toml` -> Rust
   - `build.gradle` / `pom.xml` -> Java / Kotlin（然后检查构建文件中的 `quarkus` -> Quarkus，或 `spring-boot` -> Spring Boot）
   - `Package.swift` -> Swift
   - `Gemfile` -> Ruby
   - `composer.json` -> PHP
   - `*.csproj` / `*.sln` -> .NET
   - `Makefile` / `CMakeLists.txt` -> C / C++
   - `cpanfile` / `Makefile.PL` -> Perl
3. 注意检测到的技术栈以用于阶段 3 和阶段 4

如果没有找到项目文件（例如提示词是抽象的或用于新项目），跳过检测并在阶段 4 中标记"技术栈未知"。

### 阶段 1：意图检测

将用户的任务分类为一个或多个类别：

| 类别 | 信号词 | 示例 |
|----------|-------------|---------|
| 新功能 | build、create、add、implement、创建、实现、添加 | "构建登录页面" |
| 错误修复 | fix、broken、not working、error、修复、报错 | "修复认证流程" |
| 重构 | refactor、clean up、restructure、重构、整理 | "重构 API 层" |
| 研究 | how to、what is、explore、investigate、怎么、如何 | "如何添加 SSO" |
| 测试 | test、coverage、verify、测试、覆盖率 | "为购物车添加测试" |
| 审查 | review、audit、check、审查、检查 | "审查我的 PR" |
| 文档 | document、update docs、文档 | "更新 API 文档" |
| 基础设施 | deploy、CI、docker、database、部署、数据库 | "设置 CI/CD 管道" |
| 设计 | design、architecture、plan、设计、架构 | "设计数据模型" |

### 阶段 2：范围评估

如果阶段 0 检测到项目，使用代码库大小作为信号。否则，仅从提示词描述估算并标记估算为不确定。

| 范围 | 启发式 | 编排 |
|-------|-----------|---------------|
| TRIVIAL（微小） | 单文件，< 50 行 | 直接执行 |
| LOW（低） | 单个组件或模块 | 单个命令或技能 |
| MEDIUM（中） | 多组件，同领域 | 命令链 + /verify |
| HIGH（高） | 跨领域，5+ 文件 | 先 /plan，然后分阶段执行 |
| EPIC（史诗） | 多会话、多 PR、架构转变 | 使用 blueprint 技能做多会话计划 |

### 阶段 3：ECC 组件匹配

将意图 + 范围 + 技术栈（来自阶段 0）映射到特定的 ECC 组件。

#### 按意图类型

| 意图 | 命令 | 技能 | 智能体 |
|--------|----------|--------|--------|
| 新功能 | /plan, /tdd, /code-review, /verify | tdd-workflow, verification-loop | planner, tdd-guide, code-reviewer |
| 错误修复 | /tdd, /build-fix, /verify | tdd-workflow | tdd-guide, build-error-resolver |
| 重构 | /refactor-clean, /code-review, /verify | verification-loop | refactor-cleaner, code-reviewer |
| 研究 | /plan | search-first, iterative-retrieval | — |
| 测试 | /tdd, /e2e, /test-coverage | tdd-workflow, e2e-testing | tdd-guide, e2e-runner |
| 审查 | /code-review | security-review | code-reviewer, security-reviewer |
| 文档 | /update-docs, /update-codemaps | — | doc-updater |
| 基础设施 | /plan, /verify | docker-patterns, deployment-patterns, database-migrations | architect |
| 设计（中-高） | /plan | — | planner, architect |
| 设计（史诗） | — | blueprint（作为技能调用） | planner, architect |

#### 按技术栈

| 技术栈 | 要添加的技能 | 智能体 |
|------------|--------------|-------|
| Python / Django | django-patterns, django-tdd, django-security, django-verification, python-patterns, python-testing | python-reviewer |
| Go | golang-patterns, golang-testing | go-reviewer, go-build-resolver |
| Spring Boot / Java | springboot-patterns, springboot-tdd, springboot-security, springboot-verification, java-coding-standards, jpa-patterns | java-reviewer |
| Quarkus / Java | quarkus-patterns, quarkus-tdd, quarkus-security, quarkus-verification, java-coding-standards, jpa-patterns | java-reviewer |
| Kotlin / Android | kotlin-coroutines-flows, compose-multiplatform-patterns, android-clean-architecture | kotlin-reviewer |
| TypeScript / React | frontend-patterns, backend-patterns, coding-standards | code-reviewer |
| Swift / iOS | swiftui-patterns, swift-concurrency-6-2, swift-actor-persistence, swift-protocol-di-testing | code-reviewer |
| PostgreSQL | postgres-patterns, database-migrations | database-reviewer |
| Perl | perl-patterns, perl-testing, perl-security | code-reviewer |
| C++ | cpp-coding-standards, cpp-testing | code-reviewer |
| 其他 / 未列出 | coding-standards（通用） | code-reviewer |

### 阶段 4：缺失上下文检测

扫描提示词中缺失的关键信息。检查每个项目并标记阶段 0 是否自动检测到或用户必须提供：

- [ ] **技术栈** — 阶段 0 中检测到的，还是用户必须指定？
- [ ] **目标范围** — 是否提到了文件、目录或模块？
- [ ] **验收标准** — 如何知道任务完成？
- [ ] **错误处理** — 边界情况和失败模式是否处理？
- [ ] **安全要求** — 认证、输入验证、密钥？
- [ ] **测试预期** — 单元、集成、E2E？
- [ ] **性能约束** — 负载、延迟、资源限制？
- [ ] **UI/UX 要求** — 设计规格、响应式、无障碍？（如果是前端）
- [ ] **数据库变更** — 模式、迁移、索引？（如果是数据层）
- [ ] **现有模式** — 要遵循的参考文件或约定？
- [ ] **范围边界** — 不做什么？

**如果 3+ 个关键项缺失**，在生成优化提示词之前向用户提出最多 3 个澄清问题。然后将答案纳入优化提示词。

### 阶段 5：工作流和模型推荐

确定此提示词在开发生命周期中的位置：

```
研究 -> 计划 -> 实现（TDD）-> 审查 -> 验证 -> 提交
```

对于中+ 级别的任务，始终以 /plan 开始。对于史诗级别的任务，使用 blueprint 技能。

**模型推荐**（包含在输出中）：

| 范围 | 推荐模型 | 理由 |
|-------|------------------|-----------|
| 微小-低 | Sonnet 4.6 | 快速、成本高效，适合简单任务 |
| 中 | Sonnet 4.6 | 标准工作的最佳编码模型 |
| 高 | Sonnet 4.6（主）+ Opus 4.6（规划） | Opus 用于架构，Sonnet 用于实现 |
| 史诗 | Opus 4.6（蓝图）+ Sonnet 4.6（执行） | 多会话规划的深度推理 |

**多提示词拆分**（用于高/史诗范围）：

对于超过单个会话的任务，拆分为顺序提示词：
- 提示词 1：研究 + 计划（使用 search-first 技能，然后 /plan）
- 提示词 2-N：每个提示词实现一个阶段（每个以 /verify 结束）
- 最终提示词：集成测试 + 跨所有阶段的 /code-review
- 在会话之间使用 /save-session 和 /resume-session 保留上下文

---

## 输出格式

以这种精确结构呈现你的分析。以与用户输入相同的语言回复。

### 第 1 节：提示词诊断

**优点：** 列出原始提示词做得好的地方。

**问题：**

| 问题 | 影响 | 建议修复 |
|-------|--------|---------------|
| （问题） | （后果） | （如何修复） |

**需要澄清：** 用户应该回答的问题编号列表。如果阶段 0 自动检测到答案，则说明它而不是询问。

### 第 2 节：推荐的 ECC 组件

| 类型 | 组件 | 用途 |
|------|-----------|---------|
| 命令 | /plan | 编码前规划架构 |
| 技能 | tdd-workflow | TDD 方法论指导 |
| 智能体 | code-reviewer | 实现后审查 |
| 模型 | Sonnet 4.6 | 此范围推荐 |

### 第 3 节：优化提示词 —— 完整版

在单个围栏代码块内呈现完整的优化提示词。提示词必须自包含且可复制粘贴。包括：
- 带上下文的清晰任务描述
- 技术栈（检测到的或指定的）
- 在正确的工作流阶段调用 /command
- 验收标准
- 验证步骤
- 范围边界（不做什么）

对于引用 blueprint 的项目，写："使用 blueprint 技能来..."（不是 `/blueprint`，因为 blueprint 是技能，不是命令）。

### 第 4 节：优化提示词 —— 快速版

面向有经验的 ECC 用户的紧凑版本。按意图类型变化：

| 意图 | 快速模式 |
|--------|--------------|
| 新功能 | `/plan [功能]. /tdd 实现. /code-review. /verify.` |
| 错误修复 | `/tdd — 为 [bug] 写失败测试. 修复到绿色. /verify.` |
| 重构 | `/refactor-clean [范围]. /code-review. /verify.` |
| 研究 | `使用 search-first 技能研究 [主题]. /plan 基于发现.` |
| 测试 | `/tdd [模块]. /e2e 关键流程. /test-coverage.` |
| 审查 | `/code-review. 然后使用 security-reviewer 智能体.` |
| 文档 | `/update-docs. /update-codemaps.` |
| 史诗 | `使用 blueprint 技能规划"[目标]". 用 /verify 门控执行阶段.` |

### 第 5 节：增强理由

| 增强 | 原因 |
|-------------|--------|
| （添加了什么） | （为什么重要） |

### 页脚

> 不是你需要的？告诉我需要调整什么，或者如果你想要执行而非提示词优化，提出正常的任务请求。

---

## 示例

### 触发示例

- "优化这个提示词给 ECC"
- "重写这个提示词让 Claude Code 使用正确的命令"
- "帮我优化这个指令"
- "我该怎么为这个任务给 ECC 写提示词？"

### 示例 1：模糊的中文提示词（检测到项目）

**用户输入：**
```
帮我写一个用户登录页面
```

**阶段 0 检测到：** `package.json` 含 Next.js 15、TypeScript、Tailwind CSS

**优化提示词（完整版）：**
```
使用项目现有技术栈（Next.js 15 + TypeScript + Tailwind CSS）实现用户登录页面。

技术要求：
- 沿用项目现有的组件结构和路由约定
- 表单验证使用项目中已有的验证方案（检查是否已用 Zod/Yup/其他）
- 认证方式：沿用项目现有认证方案（如无，默认 JWT）
- 包含：邮箱/密码登录表单、表单验证、错误提示、加载状态、响应式布局

工作流：
1. /plan 先规划组件结构和认证流程，参考现有页面的模式
2. /tdd 测试先行：编写登录表单的单元测试和认证流程的集成测试
3. 实现登录页面和认证逻辑
4. /code-review 审查实现
5. /verify 验证所有测试通过且页面正常渲染

安全要求：
- 密码不明文传输
- 防止暴力破解（rate limiting）
- XSS 防护
- CSRF token

验收标准：
- 所有测试通过，覆盖率 80%+
- 页面在移动端和桌面端正常渲染
- 登录成功跳转到 dashboard，失败显示错误信息

不要做：
- 不要实现注册页面
- 不要实现忘记密码功能
- 不要修改现有的路由结构
```

### 示例 2：中等英文提示词

**用户输入：**
```
Add a REST API endpoint for user profile updates with validation
```

**阶段 0 检测到：** `go.mod` 含 Go 1.22、Chi router

**优化提示词（完整版）：**
```
添加一个用于用户资料更新的 REST API 端点（PATCH /api/users/:id）。

技术栈：Go 1.22 + Chi router（从项目检测）

需求：
- PATCH /api/users/:id — 用户资料的部分更新
- 字段输入验证：name, email, avatar_url, bio
- 认证：需要有效 token，用户只能更新自己的资料
- 成功返回 200 和更新后的用户
- 无效输入返回 400 和验证错误
- 认证失败返回 401/403
- 遵循代码库中现有的 API 模式

工作流：
1. /plan 端点结构、中间件链和验证逻辑
2. /tdd — 为成功、验证失败、认证失败、未找到编写表驱动测试
3. 遵循现有处理器模式实现
4. /go-review
5. /verify — 运行完整测试套件，确认无回归

不要做：
- 修改现有端点
- 更改数据库模式（使用现有 user 表）
- 在不先检查现有依赖的情况下添加新依赖（使用 search-first 技能）
```

### 示例 3：史诗项目

**用户输入：**
```
将我们的单体应用迁移到微服务
```

**优化提示词（完整版）：**
```
使用 blueprint 技能规划："将单体应用迁移到微服务架构"

在执行前，在 blueprint 中回答这些问题：
1. 当前单体中有哪些领域边界？
2. 哪个服务应该首先提取（耦合最低）？
3. 通信模式：REST API、gRPC 还是事件驱动（Kafka/RabbitMQ）？
4. 数据库策略：初始共享 DB 还是从一开始就每服务一数据库？
5. 部署目标：Kubernetes、Docker Compose 还是无服务器？

Blueprint 应产出以下阶段：
- 阶段 1：识别服务边界并创建领域图
- 阶段 2：设置基础设施（API 网关、服务网格、每服务 CI/CD）
- 阶段 3：提取第一个服务（绞杀者无花果模式）
- 阶段 4：用集成测试验证，然后提取下一个服务
- 阶段 N：退役单体

每个阶段 = 1 个 PR，阶段之间有 /verify 门控。
阶段之间使用 /save-session。使用 /resume-session 继续。
当依赖允许时使用 git worktrees 进行并行服务提取。

推荐：Opus 4.6 用于 blueprint 规划，Sonnet 4.6 用于阶段执行。
```

---

## 相关组件

| 组件 | 何时参考 |
|-----------|------------------|
| `configure-ecc` | 用户尚未设置 ECC |
| `skill-stocktake` | 审计已安装哪些组件（使用而非硬编码目录） |
| `search-first` | 优化提示词中的研究阶段 |
| `blueprint` | 史诗范围的优化提示词（作为技能调用，不是命令） |
| `strategic-compact` | 长会话上下文管理 |
| `cost-aware-llm-pipeline` | Token 优化推荐 |
