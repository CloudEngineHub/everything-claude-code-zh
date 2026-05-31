---
name: pubmed-database
description: 直接使用 PubMed 和 NCBI E-utilities 搜索生物医学文献的工作流，包括 MeSH 查询、PMID 查找、引文检索和 API 支持的文献监控。
origin: community
---

# PubMed 数据库

当任务需要从 PubMed 获取生物医学文献而非一般网络搜索时，使用此技能。

## 何时使用

- 搜索 MEDLINE 或生命科学文献。
- 使用 MeSH 术语、字段标签、日期或文章类型构建 PubMed 查询。
- 查找 PMID、摘要、出版元数据或相关引文。
- 运行需要可重复搜索字符串的系统综述搜索。
- 直接从 Python、Shell 或其他 HTTP 客户端使用 NCBI E-utilities。

## 查询构建

从研究问题开始，将其拆分为概念，然后用布尔运算符组合概念。

```text
concept_1 AND concept_2 AND filter
synonym_a OR synonym_b
NOT exclusion_term
```

常用的 PubMed 字段标签：

- `[ti]`：标题
- `[ab]`：摘要
- `[tiab]`：标题或摘要
- `[au]`：作者
- `[ta]`：期刊标题缩写
- `[mh]`：MeSH 术语
- `[majr]`：主要 MeSH 主题
- `[pt]`：出版物类型
- `[dp]`：出版日期
- `[la]`：语言

示例：

```text
diabetes mellitus[mh] AND treatment[tiab] AND systematic review[pt] AND 2023:2026[dp]
(metformin[nm] OR insulin[nm]) AND diabetes mellitus, type 2[mh] AND randomized controlled trial[pt]
smith ja[au] AND cancer[tiab] AND 2026[dp] AND english[la]
```

## MeSH 和副标题

当概念有稳定的受控词汇术语时优先使用 MeSH。当主题较新或术语变化较大时，将 MeSH 与标题/摘要术语组合使用。

正确的副标题语法将副标题放在字段标签之前：

```text
diabetes mellitus, type 2/drug therapy[mh]
cardiovascular diseases/prevention & control[mh]
```

仅在主题必须是论文核心时使用 `[majr]`。它可以提高精确度，但可能会遗漏相关作品。

## 过滤器

出版物类型：

- `clinical trial[pt]`
- `meta-analysis[pt]`
- `randomized controlled trial[pt]`
- `review[pt]`
- `systematic review[pt]`
- `guideline[pt]`

日期过滤器：

```text
2026[dp]
2020:2026[dp]
2026/03/15[dp]
```

可用性过滤器：

```text
free full text[sb]
hasabstract[text]
```

## E-utilities 工作流

NCBI E-utilities 支持可重复的 API 工作流：

1. `esearch.fcgi`：搜索并返回 PMID。
2. `esummary.fcgi`：返回轻量级文章元数据。
3. `efetch.fcgi`：以 XML、MEDLINE 或文本格式获取摘要或完整记录。
4. `elink.fcgi`：查找相关文章和链接资源。

在生产脚本中使用电子邮件和 API 密钥。将 API 密钥存储在环境变量中，绝不要放在已提交的文件或命令历史记录中。

```python
import os
import time
import requests

BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"


def esearch(query: str, retmax: int = 20) -> list[str]:
    params = {
        "db": "pubmed",
        "term": query,
        "retmode": "json",
        "retmax": retmax,
        "tool": "ecc-pubmed-search",
        "email": os.environ.get("NCBI_EMAIL", ""),
    }
    api_key = os.environ.get("NCBI_API_KEY")
    if api_key:
        params["api_key"] = api_key

    response = requests.get(f"{BASE}/esearch.fcgi", params=params, timeout=30)
    response.raise_for_status()
    time.sleep(0.35)
    return response.json()["esearchresult"]["idlist"]


pmids = esearch("hypertension[mh] AND randomized controlled trial[pt] AND 2024:2026[dp]")
print(pmids)
```

对于批量操作，优先使用 NCBI 历史服务器参数（`usehistory=y`、`WebEnv`、`query_key`），而不是通过 URL 传递很长的 PMID 列表。

## 输出规范

对于每次搜索，记录：

- 精确的搜索字符串
- 搜索的数据库
- 搜索日期
- 使用的过滤器
- 结果数量
- 导出格式
- 任何手动排除项

示例：

```markdown
| 数据库 | 搜索日期 | 查询 | 过滤器 | 结果数 |
| --- | --- | --- | --- | ---: |
| PubMed | 2026-05-11 | `sickle cell disease[mh] AND CRISPR[tiab]` | 2020:2026[dp], English | 42 |
```

## 审查清单

- 字段标签是否为有效的 PubMed 标签？
- 对于较新的主题，MeSH 术语是否与自由文本同义词配对使用？
- 日期范围是否明确且合适？
- 搜索日志是否包含足够的细节以重现查询？
- API 密钥是否从环境变量加载？
- HTTP 代码是否调用 `raise_for_status()` 或以其他方式处理非 200 响应后再解析？
- 是否遵守了速率限制？

## 参考文献

- [PubMed 帮助](https://pubmed.ncbi.nlm.nih.gov/help/)
- [NCBI E-utilities 文档](https://www.ncbi.nlm.nih.gov/books/NBK25501/)
- [NCBI API 密钥指南](https://support.nlm.nih.gov/kbArticle/?pn=KA-05317)
- NCBI 支持：<eutilities@ncbi.nlm.nih.gov>
