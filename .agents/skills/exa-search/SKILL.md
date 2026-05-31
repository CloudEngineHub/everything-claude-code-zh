---
name: exa-search
description: 通过 Exa MCP 进行网络、代码和公司研究的神经搜索。当用户需要网络搜索、代码示例、公司情报、人员查找或使用 Exa 的神经搜索引擎进行 AI 驱动的深度研究时使用。
---

# Exa 搜索

通过 Exa MCP 服务器进行网络内容、代码、公司和人员的神经搜索。

## 何时激活

- 用户需要当前网络信息或新闻
- 搜索代码示例、API 文档或技术参考
- 研究公司、竞争对手或市场参与者
- 查找专业资料或领域内的人员
- 为任何开发任务运行背景研究
- 用户说"search for"、"look up"、"find"或"最新情况是什么"

## MCP 要求

必须配置 Exa MCP 服务器。添加到 `~/.claude.json`：

```json
"exa-web-search": {
  "command": "npx",
  "args": ["-y", "exa-mcp-server"],
  "env": { "EXA_API_KEY": "YOUR_EXA_API_KEY_HERE" }
}
```

在 [exa.ai](https://exa.ai) 获取 API 密钥。

## 核心工具

### web_search_exa
用于当前信息、新闻或事实的通用网络搜索。

```
web_search_exa(query: "latest AI developments 2026", numResults: 5)
```

**参数：**

| 参数 | 类型 | 默认值 | 说明 |
|-------|------|---------|-------|
| `query` | string | 必需 | 搜索查询 |
| `numResults` | number | 8 | 结果数量 |

### web_search_advanced_exa
具有域和日期约束的过滤搜索。

```
web_search_advanced_exa(
  query: "React Server Components best practices",
  numResults: 5,
  includeDomains: ["github.com", "react.dev"],
  startPublishedDate: "2025-01-01"
)
```

**参数：**

| 参数 | 类型 | 默认值 | 说明 |
|-------|------|---------|-------|
| `query` | string | 必需 | 搜索查询 |
| `numResults` | number | 8 | 结果数量 |
| `includeDomains` | string[] | 无 | 限制到特定域 |
| `excludeDomains` | string[] | 无 | 排除特定域 |
| `startPublishedDate` | string | 无 | ISO 日期过滤器（开始） |
| `endPublishedDate` | string | 无 | ISO 日期过滤器（结束） |

### get_code_context_exa
从 GitHub、Stack Overflow 和文档站点查找代码示例和文档。

```
get_code_context_exa(query: "Python asyncio patterns", tokensNum: 3000)
```

**参数：**

| 参数 | 类型 | 默认值 | 说明 |
|-------|------|---------|-------|
| `query` | string | 必需 | 代码或 API 搜索查询 |
| `tokensNum` | number | 5000 | 内容令牌（1000-50000） |

### company_research_exa
为公司进行商业智能和新闻研究。

```
company_research_exa(companyName: "Anthropic", numResults: 5)
```

**参数：**

| 参数 | 类型 | 默认值 | 说明 |
|-------|------|---------|-------|
| `companyName` | string | 必需 | 公司名称 |
| `numResults` | number | 5 | 结果数量 |

### people_search_exa
查找专业资料和简介。

```
people_search_exa(query: "AI safety researchers at Anthropic", numResults: 5)
```

### crawling_exa
从 URL 提取完整页面内容。

```
crawling_exa(url: "https://example.com/article", tokensNum: 5000)
```

**参数：**

| 参数 | 类型 | 默认值 | 说明 |
|-------|------|---------|-------|
| `url` | string | 必需 | 要提取的 URL |
| `tokensNum` | number | 5000 | 内容令牌 |

### deep_researcher_start / deep_researcher_check
启动异步运行的 AI 研究代理。

```
# 启动研究
deep_researcher_start(query: "comprehensive analysis of AI code editors in 2026")

# 检查状态（完成后返回结果）
deep_researcher_check(researchId: "<id from start>")
```

## 使用模式

### 快速查找
```
web_search_exa(query: "Node.js 22 new features", numResults: 3)
```

### 代码研究
```
get_code_context_exa(query: "Rust error handling patterns Result type", tokensNum: 3000)
```

### 公司尽职调查
```
company_research_exa(companyName: "Vercel", numResults: 5)
web_search_advanced_exa(query: "Vercel funding valuation 2026", numResults: 3)
```

### 技术深度研究
```
# 启动异步研究
deep_researcher_start(query: "WebAssembly component model status and adoption")
# ... 做其他工作 ...
deep_researcher_check(researchId: "<id>")
```

## 提示

- 对广泛查询使用 `web_search_exa`，对过滤结果使用 `web_search_advanced_exa`
- 对于专注的代码片段，使用较低的 `tokensNum`（1000-2000），对于全面上下文，使用较高的（5000+）
- 将 `company_research_exa` 与 `web_search_advanced_exa` 结合进行全面的公司分析
- 使用 `crawling_exa` 从搜索结果中找到的特定 URL 获取完整内容
- `deep_researcher_start` 最适合受益于 AI 综合的全面主题

## 相关技能

- `deep-research` — 使用 firecrawl + exa 一起的完整研究工作流
- `market-research` — 具有决策框架的面向商业的研究
