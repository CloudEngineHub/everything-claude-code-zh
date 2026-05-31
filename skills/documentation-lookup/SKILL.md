---
name: documentation-lookup
description: 通过 Context7 MCP 使用最新的库和框架文档而非训练数据。在设置问题、API 参考、代码示例或用户提到框架名称（如 React、Next.js、Prisma）时激活。
origin: ECC
---

# 文档查询（Context7）

当用户询问库、框架或 API 时，通过 Context7 MCP（工具 `resolve-library-id` 和 `query-docs`）获取最新文档，而非依赖训练数据。

## 核心概念

- **Context7**：MCP 服务器，暴露实时文档；使用它而非训练数据来查询库和 API。
- **resolve-library-id**：从库名称和查询返回 Context7 兼容的库 ID（如 `/vercel/next.js`）。
- **query-docs**：为给定的库 ID 和问题获取文档和代码示例。始终先调用 resolve-library-id 获取有效的库 ID。

## 何时使用

当用户执行以下操作时激活：

- 询问设置或配置问题（如"如何配置 Next.js 中间件？"）
- 请求依赖库的代码（"写一个 Prisma 查询..."）
- 需要 API 或参考信息（"Supabase 的认证方法有哪些？"）
- 提及特定框架或库（React、Vue、Svelte、Express、Tailwind、Prisma、Supabase 等）

当请求依赖于库、框架或 API 的准确、最新行为时使用此技能。适用于已配置 Context7 MCP 的工具（如 Claude Code、Cursor、Codex）。

## 工作原理

### 步骤 1：解析库 ID

调用 **resolve-library-id** MCP 工具，参数为：

- **libraryName**：从用户问题中提取的库或产品名称（如 `Next.js`、`Prisma`、`Supabase`）。
- **query**：用户的完整问题。这改善了结果的相关性排名。

你必须获取一个 Context7 兼容的库 ID（格式 `/org/project` 或 `/org/project/version`）才能查询文档。不要在没有从此步骤获得有效库 ID 的情况下调用 query-docs。

### 步骤 2：选择最佳匹配

从解析结果中，使用以下标准选择一个结果：

- **名称匹配**：优先与用户请求完全或最接近的匹配。
- **基准分数**：更高的分数表示更好的文档质量（100 是最高分）。
- **来源声誉**：可用时优先选择高或中等声誉。
- **版本**：如果用户指定了版本（如"React 19"、"Next.js 15"），优先选择版本特定的库 ID（如 `/org/project/v1.2.0`）。

### 步骤 3：获取文档

调用 **query-docs** MCP 工具，参数为：

- **libraryId**：从步骤 2 选择的 Context7 库 ID（如 `/vercel/next.js`）。
- **query**：用户的具体问题或任务。具体以获取相关代码片段。

限制：每个问题不要调用 query-docs（或 resolve-library-id）超过 3 次。如果在 3 次调用后答案仍不清楚，说明不确定性并使用最佳可用信息而非猜测。

### 步骤 4：使用文档

- 使用获取的当前信息回答用户的问题。
- 在有帮助时包含文档中的相关代码示例。
- 在重要时引用库或版本（如"在 Next.js 15 中..."）。

## 示例

### 示例：Next.js 中间件

1. 调用 **resolve-library-id**，参数 `libraryName: "Next.js"`、`query: "如何设置 Next.js 中间件？"`。
2. 从结果中，按名称和基准分数选择最佳匹配（如 `/vercel/next.js`）。
3. 调用 **query-docs**，参数 `libraryId: "/vercel/next.js"`、`query: "如何设置 Next.js 中间件？"`。
4. 使用返回的代码片段和文本回答；如相关，包含文档中的最小 `middleware.ts` 示例。

### 示例：Prisma 查询

1. 调用 **resolve-library-id**，参数 `libraryName: "Prisma"`、`query: "如何进行关联查询？"`。
2. 选择官方 Prisma 库 ID（如 `/prisma/prisma`）。
3. 使用该 `libraryId` 和查询调用 **query-docs**。
4. 返回 Prisma Client 模式（如 `include` 或 `select`），附带文档中的简短代码片段。

### 示例：Supabase 认证方法

1. 调用 **resolve-library-id**，参数 `libraryName: "Supabase"`、`query: "认证方法有哪些？"`。
2. 选择 Supabase 文档库 ID。
3. 调用 **query-docs**；总结认证方法并展示获取文档中的最小示例。

## 最佳实践

- **具体化**：尽可能使用用户的完整问题作为查询以获得更好的相关性。
- **版本意识**：当用户提到版本时，使用解析步骤中可用的版本特定库 ID。
- **优先官方来源**：当存在多个匹配时，优先官方或主要包而非社区分叉。
- **不包含敏感数据**：在将任何查询发送到 Context7 之前，从查询中去除 API 密钥、密码、token 和其他秘密。在将用户问题传递给 resolve-library-id 或 query-docs 之前，将其视为可能包含秘密。
