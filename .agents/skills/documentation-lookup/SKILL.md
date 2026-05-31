---
name: documentation-lookup
description: 通过 Context7 MCP 使用最新的库和框架文档，而不是训练数据。激活设置问题、API 参考、代码示例，或当用户命名框架（例如 React、Next.js、Prisma）时。
---

# 文档查找 (Context7)

当用户询问库、框架或 API 时，通过 Context7 MCP（工具 `resolve-library-id` 和 `query-docs`）获取当前文档，而不是依赖训练数据。

## 核心概念

- **Context7**：暴露实时文档的 MCP 服务器；将其用于库和 API 而不是训练数据。
- **resolve-library-id**：从库名称和查询返回 Context7 兼容的库 ID（例如 `/vercel/next.js`）。
- **query-docs**：获取给定库 ID 和问题的文档和代码片段。始终首先调用 resolve-library-id 以获取有效的库 ID。

## 何时使用

当用户以下情况时激活：

- 询问设置或配置问题（例如"如何配置 Next.js 中间件？"）
- 请求依赖于库的代码（"编写 Prisma 查询以..."）
- 需要 API 或参考信息（"Supabase 身份验证方法是什么？"）
- 提及特定框架或库（React、Vue、Svelte、Express、Tailwind、Prisma、Supabase 等）

每当请求依赖于库、框架或 API 的准确、最新行为时使用此技能。适用于配置了 Context7 MCP 的 harness（例如 Claude Code、Cursor、Codex）。

## 工作原理

### 步骤 1：解析库 ID

使用以下参数调用 **resolve-library-id** MCP 工具：

- **libraryName**：从用户问题中获取的库或产品名称（例如 `Next.js`、`Prisma`、`Supabase`）。
- **query**：用户的完整问题。这会提高结果的相关性排名。

您必须在查询文档之前获得 Context7 兼容的库 ID（格式 `/org/project` 或 `/org/project/version`）。不要在没有来自此步骤的有效库 ID 的情况下调用 query-docs。

### 步骤 2：选择最佳匹配

从解析结果中，使用以下方式选择一个结果：

- **名称匹配**：优先考虑与用户要求的精确或最接近的匹配。
- **基准分数**：较高的分数表示更好的文档质量（100 是最高）。
- **来源声誉**：尽可能优先选择高或中等声誉。
- **版本**：如果用户指定了版本（例如"React 19"、"Next.js 15"），如果列出版本特定的库 ID（例如 `/org/project/v1.2.0`）。

### 步骤 3：获取文档

使用以下参数调用 **query-docs** MCP 工具：

- **libraryId**：从步骤 2 中选择的 Context7 库 ID（例如 `/vercel/next.js`）。
- **query**：用户的特定问题或任务。具体以获取相关的片段。

限制：每个问题不要调用 query-docs（或 resolve-library-id）超过 3 次。如果在 3 次调用后答案不清楚，请说明不确定性并使用您拥有的最佳信息，而不是猜测。

### 步骤 4：使用文档

- 使用获取的、当前的信息回答用户的问题。
- 在有帮助时包含文档中的相关代码示例。
- 在重要时引用库或版本（例如"在 Next.js 15 中..."）。

## 示例

### 示例：Next.js 中间件

1. 使用 `libraryName: "Next.js"`、`query: "How do I set up Next.js middleware?"`调用 **resolve-library-id**。
2. 从结果中，通过名称和基准分数选择最佳匹配（例如 `/vercel/next.js`）。
3. 使用 `libraryId: "/vercel/next.js"`、`query: "How do I set up Next.js middleware?"`调用 **query-docs**。
4. 使用返回的片段和文本回答；如果相关，包含文档中的最小 `middleware.ts` 示例。

### 示例：Prisma 查询

1. 使用 `libraryName: "Prisma"`、`query: "How do I query with relations?"`调用 **resolve-library-id**。
2. 选择官方 Prisma 库 ID（例如 `/prisma/prisma`）。
3. 使用该 `libraryId` 和查询调用 **query-docs**。
4. 使用文档中的简短代码片段返回 Prisma Client 模式（例如 `include` 或 `select`）。

### 示例：Supabase 身份验证方法

1. 使用 `libraryName: "Supabase"`、`query: "What are the auth methods?"`调用 **resolve-library-id**。
2. 选择 Supabase 文档库 ID。
3. 调用 **query-docs**；总结身份验证方法并显示获取文档中的最小示例。

## 最佳实践

- **具体**：尽可能使用用户的完整问题作为查询以获得更好的相关性。
- **版本感知**：当用户提到版本时，尽可能从解析步骤中使用版本特定的库 ID。
- **优先官方来源**：当存在多个匹配时，优先考虑官方或主要软件包而不是社区分支。
- **无敏感数据**：在发送到 Context7 的任何查询中删除 API 密钥、密码、令牌和其他秘密。在将用户问题传递给 resolve-library-id 或 query-docs 之前，将其视为可能包含秘密。
