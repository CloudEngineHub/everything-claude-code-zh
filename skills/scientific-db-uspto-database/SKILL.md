---
name: uspto-database
description: USPTO 专利和商标数据工作流，用于官方记录查询、PatentSearch 查询、TSDR 检查、转让数据和可重复的知识产权研究日志。
origin: community
---

# USPTO 数据库

当任务需要从 USPTO 系统获取美国官方专利或商标记录时，使用此技能。

## 何时使用

- 搜索已授权专利或预授权出版物。
- 检查专利申请状态、档案袋数据、转让信息或公开审查历史。
- 查找商标状态、文档或转让历史。
- 构建可重复的现有技术、投资组合或知识产权全景研究日志。
- 将 USPTO 记录与辅助工具（如 Google Patents、Lens.org、Semantic Scholar 或公司专利页面）进行比较。

请勿使用此技能提供法律建议。将其视为数据收集和记录验证工作流。

## 来源选择

优先使用官方 USPTO 或 USPTO 支持的平台：

- 开放数据门户 (ODP)：迁移后的 USPTO 数据集和 API 的当前主页。
- 专利档案袋：公开的专利申请书目数据和档案袋记录。
- PatentSearch API：PatentsView 搜索 API，用于已授权专利和预授权出版物数据集。
- TSDR 数据 API：商标状态和文档检索。
- 专利和商标转让搜索：所有权转移记录。
- ODP 中的 PTAB 数据：专利审判和上诉委员会程序。

仅将辅助来源用作便利索引。当答案很重要时，交叉核对官方记录。

## 认证和密钥

许多 USPTO API 流程需要 API 密钥。将密钥存储在环境变量或密钥管理器中，绝不要放在已提交的文件或粘贴的转录记录中。

常用环境变量名称：

```bash
export USPTO_API_KEY="..."
export PATENTSVIEW_API_KEY="..."
```

对于 PatentSearch，使用 `X-Api-Key` 头发送密钥。对于 TSDR，遵循当前 USPTO API Manager 说明和速率限制指南。

## PatentSearch 工作流

当问题涉及趋势、发明人、受让人、分类、日期或投资组合切片时，使用 PatentSearch 进行广泛的专利和预授权出版物搜索。

工作流：

1. 从当前 PatentSearch 参考文档或 Swagger UI 确定端点。
2. 使用显式过滤器构建 JSON 查询。
3. 仅请求分析所需的字段。
4. 确定性地排序和分页。
5. 记录端点、查询体、日期、数据时效性说明和结果数量。

Python 请求骨架：

```python
import os
import requests

API_KEY = os.environ["PATENTSVIEW_API_KEY"]
BASE = "https://search.patentsview.org/api/v1"

payload = {
    "q": {
        "_and": [
            {"patent_date": {"_gte": "2024-01-01"}},
            {"assignees.assignee_organization": {"_text_any": ["Google", "Alphabet"]}},
        ]
    },
    "f": ["patent_id", "patent_title", "patent_date"],
    "s": [{"patent_date": "desc"}],
    "o": {"per_page": 100, "page": 1},
}

response = requests.post(
    f"{BASE}/patent/",
    headers={"X-Api-Key": API_KEY, "Content-Type": "application/json"},
    json=payload,
    timeout=30,
)
response.raise_for_status()
print(response.json())
```

在重用查询之前，验证当前端点名称、字段路径、请求参数和 API 密钥可用性在最新 PatentSearch 文档中的情况。

## 商标/TSDR 工作流

当任务需要商标案件状态、文档、图片、所有者历史或审查事件时，使用 TSDR。

工作流：

1. 规范化序列号或注册号。
2. 检查当前 TSDR API 说明和所需的 API 密钥头。
3. 先获取状态，然后仅在需要时获取文档。
4. 遵守 PDF、ZIP 和多案件下载的较低速率限制。
5. 在输出中记录检索日期和序列号/注册号标识符。

对于大规模商标提取，优先使用文档化的批量数据流程，而非抓取公开页面。

## 档案袋和审查历史

对于申请状态、交易历史和审查文档：

- 从 ODP 专利档案袋搜索开始。
- 在可用时使用确切标识符：申请号、公开号、专利号或当事人名称。
- 记录该记录是已授权专利、预授权出版物还是待审申请。
- 在引用之前，将文档日期和状态与记录详情页交叉核对。

## 转让工作流

对于专利或商标所有权：

1. 通过专利/申请/注册号、转让人、受让人或卷轴/帧号搜索官方转让数据。
2. 记录转让文本、执行日期、登记日期和各方。
3. 区分转让记录和当前法定所有权结论。
4. 如果所有权具有重要性，标记结果以供律师或主题专家审查。

## 可重复输出

每次 USPTO 研究应包含日志表：

```markdown
| 来源 | 搜索日期 | 标识符/查询 | 过滤器 | 结果数 | 备注 |
| --- | --- | --- | --- | ---: | --- |
| PatentSearch | 2026-05-11 | `assignee=Alphabet AND date>=2024` | 专利端点 | 118 | 运行前检查了 API 文档 |
| TSDR | 2026-05-11 | `serial=90000000` | 仅状态 | 1 | API 密钥流程，无文档批量提取 |
```

对于最终输出，分开：

- 官方记录事实
- 推断分析
- 辅助来源便利匹配
- 未解决的差距或需要法律审查的记录

## 审查清单

- 是否优先使用了官方 USPTO 或 USPTO 支持的来源？
- 是否在运行代码之前验证了当前端点和字段名称？
- API 密钥是否避开了文件、Shell 历史和输出日志？
- 查询日志是否包含搜索日期和确切的请求结构？
- 是否遵守了速率限制？
- 是否避免或明确上报了法律结论？
- 辅助来源是否标记为辅助来源？

## 参考文献

- [USPTO API 目录](https://developer.uspto.gov/api-catalog)
- [USPTO 开放数据门户](https://data.uspto.gov/)
- [PatentSearch API 参考](https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/)
- [PatentSearch API 更新](https://search.patentsview.org/docs/)
- [TSDR API 批量下载常见问题](https://developer.uspto.gov/faq/tsdr-api-bulk-download)
