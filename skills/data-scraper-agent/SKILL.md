---
name: data-scraper-agent
description: 构建一个完全自动化的 AI 数据采集智能体，适用于任何公开数据源 — 求职板、价格、新闻、GitHub、体育等任何来源。按计划抓取，使用免费 LLM（Gemini Flash）丰富数据，将结果存储到 Notion/Sheets/Supabase，并从用户反馈中学习。在 GitHub Actions 上 100% 免费运行。当用户想要自动监控、收集或跟踪任何公开数据时使用。
origin: community
---

# Data Scraper Agent

为任何公开数据源构建生产就绪、AI 驱动的数据采集智能体。
按计划运行，使用免费 LLM 丰富结果，存储到数据库，并持续改进。

**技术栈：Python · Gemini Flash（免费）· GitHub Actions（免费）· Notion / Sheets / Supabase**

## 何时激活

- 用户想要抓取或监控任何公开网站或 API
- 用户说"构建一个检查...的机器人"、"帮我监控 X"、"从...收集数据"
- 用户想要跟踪职位、价格、新闻、仓库、体育比分、事件、列表
- 用户询问如何在免 hosting 费用的情况下自动化数据采集
- 用户想要一个能根据自身决策变得越来越聪明的智能体

## 核心概念

### 三层架构

每个数据采集智能体都有三层：

```
COLLECT → ENRICH → STORE
  │           │        │
抓取器      AI (LLM)  数据库
按计划      评分/     Notion /
运行        摘要      Sheets /
           & 分类     Supabase
```

### 免费技术栈

| 层 | 工具 | 原因 |
|---|---|---|
| **抓取** | `requests` + `BeautifulSoup` | 零成本，覆盖 80% 的公开网站 |
| **JS 渲染站点** | `playwright`（免费） | 当 HTML 抓取失败时使用 |
| **AI 丰富** | Gemini Flash REST API | 500 请求/天，1M token/天 — 免费 |
| **存储** | Notion API | 免费层，出色的审查 UI |
| **调度** | GitHub Actions cron | 公开仓库免费 |
| **学习** | 仓库中的 JSON 反馈文件 | 零基础设施，在 git 中持久化 |

### AI 模型回退链

构建智能体，在配额耗尽时自动回退到其他 Gemini 模型：

```
gemini-2.0-flash-lite (30 RPM) →
gemini-2.0-flash (15 RPM) →
gemini-2.5-flash (10 RPM) →
gemini-flash-lite-latest（回退）
```

### 批量 API 调用提高效率

永远不要对每个项目单独调用 LLM。始终批量处理：

```python
# 差：33 个项目调用 33 次 API
for item in items:
    result = call_ai(item)  # 33 次调用 → 触达速率限制

# 好：33 个项目调用 7 次 API（批量大小 5）
for batch in chunks(items, size=5):
    results = call_ai(batch)  # 7 次调用 → 保持在免费额度内
```

---

## 工作流

### 步骤 1：理解目标

询问用户：

1. **收集什么：** "什么数据源？URL / API / RSS / 公开端点？"
2. **提取什么：** "哪些字段重要？标题、价格、URL、日期、评分？"
3. **存储到哪里：** "结果应该存在哪里？Notion、Google Sheets、Supabase 还是本地文件？"
4. **如何丰富：** "你希望 AI 对每个项目进行评分、摘要、分类还是匹配？"
5. **频率：** "应该多久运行一次？每小时、每天、每周？"

常见示例提示：
- 求职板 → 根据简历评分相关性
- 产品价格 → 降价时提醒
- GitHub 仓库 → 摘要新版本
- 新闻源 → 按主题 + 情感分类
- 体育结果 → 提取统计数据到追踪器
- 活动日历 → 按兴趣筛选

---

### 步骤 2：设计智能体架构

为用户生成此目录结构：

```
my-agent/
├── config.yaml              # 用户自定义此文件（关键词、过滤器、偏好）
├── profile/
│   └── context.md           # AI 使用的用户上下文（简历、兴趣、标准）
├── scraper/
│   ├── __init__.py
│   ├── main.py              # 编排器：抓取 → 丰富 → 存储
│   ├── filters.py           # 基于规则的预过滤器（快速，在 AI 之前）
│   └── sources/
│       ├── __init__.py
│       └── source_name.py   # 每个数据源一个文件
├── ai/
│   ├── __init__.py
│   ├── client.py            # 带模型回退的 Gemini REST 客户端
│   ├── pipeline.py          # 批量 AI 分析
│   ├── jd_fetcher.py        # 从 URL 获取完整内容（可选）
│   └── memory.py            # 从用户反馈中学习
├── storage/
│   ├── __init__.py
│   └── notion_sync.py       # 或 sheets_sync.py / supabase_sync.py
├── data/
│   └── feedback.json        # 用户决策历史（自动更新）
├── .env.example
├── setup.py                 # 一次性 DB/schema 创建
├── enrich_existing.py       # 为旧行回填 AI 评分
├── requirements.txt
└── .github/
    └── workflows/
        └── scraper.yml      # GitHub Actions 调度
```

---

### 步骤 3：构建抓取器数据源

适用于任何数据源的模板：

```python
# scraper/sources/my_source.py
"""
[数据源名称] — 从 [哪里] 抓取 [什么]。
方法：[REST API / HTML 抓取 / RSS 源]
"""
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from scraper.filters import is_relevant

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; research-bot/1.0)",
}


def fetch() -> list[dict]:
    """
    返回具有一致 schema 的项目列表。
    每个项目至少包含：name、url、date_found。
    """
    results = []

    # ---- REST API 数据源 ----
    resp = requests.get("https://api.example.com/items", headers=HEADERS, timeout=15)
    if resp.status_code == 200:
        for item in resp.json().get("results", []):
            if not is_relevant(item.get("title", "")):
                continue
            results.append(_normalise(item))

    return results


def _normalise(raw: dict) -> dict:
    """将原始 API/HTML 数据转换为标准 schema。"""
    return {
        "name": raw.get("title", ""),
        "url": raw.get("link", ""),
        "source": "MySource",
        "date_found": datetime.now(timezone.utc).date().isoformat(),
        # 在此添加领域特定字段
    }
```

**HTML 抓取模式：**
```python
soup = BeautifulSoup(resp.text, "lxml")
for card in soup.select("[class*='listing']"):
    title = card.select_one("h2, h3").get_text(strip=True)
    link = card.select_one("a")["href"]
    if not link.startswith("http"):
        link = f"https://example.com{link}"
```

**RSS 源模式：**
```python
import xml.etree.ElementTree as ET
root = ET.fromstring(resp.text)
for item in root.findall(".//item"):
    title = item.findtext("title", "")
    link = item.findtext("link", "")
```

---

### 步骤 4：构建 Gemini AI 客户端

```python
# ai/client.py
import os, json, time, requests

_last_call = 0.0

MODEL_FALLBACK = [
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash",
    "gemini-2.5-flash",
    "gemini-flash-lite-latest",
]


def generate(prompt: str, model: str = "", rate_limit: float = 7.0) -> dict:
    """调用 Gemini，429 时自动回退。返回解析后的 JSON 或 {}。"""
    global _last_call

    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        return {}

    elapsed = time.time() - _last_call
    if elapsed < rate_limit:
        time.sleep(rate_limit - elapsed)

    models = [model] + [m for m in MODEL_FALLBACK if m != model] if model else MODEL_FALLBACK
    _last_call = time.time()

    for m in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.3,
                "maxOutputTokens": 2048,
            },
        }
        try:
            resp = requests.post(url, json=payload, timeout=30)
            if resp.status_code == 200:
                return _parse(resp)
            if resp.status_code in (429, 404):
                time.sleep(1)
                continue
            return {}
        except requests.RequestException:
            return {}

    return {}


def _parse(resp) -> dict:
    try:
        text = (
            resp.json()
            .get("candidates", [{}])[0]
            .get("content", {})
            .get("parts", [{}])[0]
            .get("text", "")
            .strip()
        )
        if text.startswith("```"):
            text = text.split("\n", 1)[-1].rsplit("```", 1)[0]
        return json.loads(text)
    except (json.JSONDecodeError, KeyError):
        return {}
```

---

### 步骤 5：构建 AI 管道（批量）

```python
# ai/pipeline.py
import json
import yaml
from pathlib import Path
from ai.client import generate

def analyse_batch(items: list[dict], context: str = "", preference_prompt: str = "") -> list[dict]:
    """批量分析项目。返回带 AI 字段丰富的项目。"""
    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    model = config.get("ai", {}).get("model", "gemini-2.5-flash")
    rate_limit = config.get("ai", {}).get("rate_limit_seconds", 7.0)
    min_score = config.get("ai", {}).get("min_score", 0)
    batch_size = config.get("ai", {}).get("batch_size", 5)

    batches = [items[i:i + batch_size] for i in range(0, len(items), batch_size)]
    print(f"  [AI] {len(items)} 个项目 → {len(batches)} 次 API 调用")

    enriched = []
    for i, batch in enumerate(batches):
        print(f"  [AI] 批次 {i + 1}/{len(batches)}...")
        prompt = _build_prompt(batch, context, preference_prompt, config)
        result = generate(prompt, model=model, rate_limit=rate_limit)

        analyses = result.get("analyses", [])
        for j, item in enumerate(batch):
            ai = analyses[j] if j < len(analyses) else {}
            if ai:
                score = max(0, min(100, int(ai.get("score", 0))))
                if min_score and score < min_score:
                    continue
                enriched.append({**item, "ai_score": score, "ai_summary": ai.get("summary", ""), "ai_notes": ai.get("notes", "")})
            else:
                enriched.append(item)

    return enriched


def _build_prompt(batch, context, preference_prompt, config):
    priorities = config.get("priorities", [])
    items_text = "\n\n".join(
        f"Item {i+1}: {json.dumps({k: v for k, v in item.items() if not k.startswith('_')})}"
        for i, item in enumerate(batch)
    )

    return f"""分析这 {len(batch)} 个项目并返回一个 JSON 对象。

# 项目
{items_text}

# 用户上下文
{context[:800] if context else "未提供"}

# 用户优先级
{chr(10).join(f"- {p}" for p in priorities)}

{preference_prompt}

# 指示
返回：{{"analyses": [{{"score": <0-100>, "summary": "<2 句话>", "notes": "<为什么匹配或不匹配>"}} 按顺序对应每个项目]}}
简洁为要。评分 90+=优秀匹配，70-89=良好，50-69=一般，<50=较弱。"""
```

---

### 步骤 6：构建反馈学习系统

```python
# ai/memory.py
"""从用户决策中学习以改进未来评分。"""
import json
from pathlib import Path

FEEDBACK_PATH = Path(__file__).parent.parent / "data" / "feedback.json"


def load_feedback() -> dict:
    if FEEDBACK_PATH.exists():
        try:
            return json.loads(FEEDBACK_PATH.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"positive": [], "negative": []}


def save_feedback(fb: dict):
    FEEDBACK_PATH.parent.mkdir(parents=True, exist_ok=True)
    FEEDBACK_PATH.write_text(json.dumps(fb, indent=2))


def build_preference_prompt(feedback: dict, max_examples: int = 15) -> str:
    """将反馈历史转换为提示偏差部分。"""
    lines = []
    if feedback.get("positive"):
        lines.append("# 用户喜欢的项目（正向信号）：")
        for e in feedback["positive"][-max_examples:]:
            lines.append(f"- {e}")
    if feedback.get("negative"):
        lines.append("\n# 用户跳过/拒绝的项目（负向信号）：")
        for e in feedback["negative"][-max_examples:]:
            lines.append(f"- {e}")
    if lines:
        lines.append("\n使用这些模式来偏置新项目的评分。")
    return "\n".join(lines)
```

**与存储层集成：** 每次运行后，查询数据库中具有正向/负向状态的项目，并使用提取的模式调用 `save_feedback()`。

---

### 步骤 7：构建存储（Notion 示例）

```python
# storage/notion_sync.py
import os
from notion_client import Client
from notion_client.errors import APIResponseError

_client = None

def get_client():
    global _client
    if _client is None:
        _client = Client(auth=os.environ["NOTION_TOKEN"])
    return _client

def get_existing_urls(db_id: str) -> set[str]:
    """获取所有已存储的 URL — 用于去重。"""
    client, seen, cursor = get_client(), set(), None
    while True:
        resp = client.databases.query(database_id=db_id, page_size=100, **{"start_cursor": cursor} if cursor else {})
        for page in resp["results"]:
            url = page["properties"].get("URL", {}).get("url", "")
            if url: seen.add(url)
        if not resp["has_more"]: break
        cursor = resp["next_cursor"]
    return seen

def push_item(db_id: str, item: dict) -> bool:
    """将一个项目推送到 Notion。成功时返回 True。"""
    props = {
        "Name": {"title": [{"text": {"content": item.get("name", "")[:100]}}]},
        "URL": {"url": item.get("url")},
        "Source": {"select": {"name": item.get("source", "Unknown")}},
        "Date Found": {"date": {"start": item.get("date_found")}},
        "Status": {"select": {"name": "New"}},
    }
    # AI 字段
    if item.get("ai_score") is not None:
        props["AI Score"] = {"number": item["ai_score"]}
    if item.get("ai_summary"):
        props["Summary"] = {"rich_text": [{"text": {"content": item["ai_summary"][:2000]}}]}
    if item.get("ai_notes"):
        props["Notes"] = {"rich_text": [{"text": {"content": item["ai_notes"][:2000]}}]}

    try:
        get_client().pages.create(parent={"database_id": db_id}, properties=props)
        return True
    except APIResponseError as e:
        print(f"[notion] 推送失败：{e}")
        return False

def sync(db_id: str, items: list[dict]) -> tuple[int, int]:
    existing = get_existing_urls(db_id)
    added = skipped = 0
    for item in items:
        if item.get("url") in existing:
            skipped += 1; continue
        if push_item(db_id, item):
            added += 1; existing.add(item["url"])
        else:
            skipped += 1
    return added, skipped
```

---

### 步骤 8：在 main.py 中编排

```python
# scraper/main.py
import os, sys, yaml
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

from scraper.sources import my_source          # 添加你的数据源

# 注意：此示例使用 Notion。如果 storage.provider 是 "sheets" 或 "supabase"，
# 将此导入替换为 storage.sheets_sync 或 storage.supabase_sync，并相应更新
# 环境变量和 sync() 调用。
from storage.notion_sync import sync

SOURCES = [
    ("My Source", my_source.fetch),
]

def ai_enabled():
    return bool(os.environ.get("GEMINI_API_KEY"))

def main():
    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    provider = config.get("storage", {}).get("provider", "notion")

    # 根据 provider 从环境变量解析存储目标标识符
    if provider == "notion":
        db_id = os.environ.get("NOTION_DATABASE_ID")
        if not db_id:
            print("错误：NOTION_DATABASE_ID 未设置"); sys.exit(1)
    else:
        # 在此扩展 sheets (SHEET_ID) 或 supabase (SUPABASE_TABLE) 等
        print(f"错误：provider '{provider}' 尚未在 main.py 中接入"); sys.exit(1)

    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    all_items = []

    for name, fetch_fn in SOURCES:
        try:
            items = fetch_fn()
            print(f"[{name}] {len(items)} 个项目")
            all_items.extend(items)
        except Exception as e:
            print(f"[{name}] 失败：{e}")

    # 按 URL 去重
    seen, deduped = set(), []
    for item in all_items:
        if (url := item.get("url", "")) and url not in seen:
            seen.add(url); deduped.append(item)

    print(f"唯一项目：{len(deduped)}")

    if ai_enabled() and deduped:
        from ai.memory import load_feedback, build_preference_prompt
        from ai.pipeline import analyse_batch

        # load_feedback() 读取由你的反馈同步脚本写入的 data/feedback.json。
        # 要保持最新，实现一个单独的 feedback_sync.py，查询你的
        # 存储提供者中具有正向/负向状态的项目并调用 save_feedback()。
        feedback = load_feedback()
        preference = build_preference_prompt(feedback)
        context_path = Path(__file__).parent.parent / "profile" / "context.md"
        context = context_path.read_text() if context_path.exists() else ""
        deduped = analyse_batch(deduped, context=context, preference_prompt=preference)
    else:
        print("[AI] 已跳过 — GEMINI_API_KEY 未设置")

    added, skipped = sync(db_id, deduped)
    print(f"完成 — {added} 个新增，{skipped} 个已存在")

if __name__ == "__main__":
    main()
```

---

### 步骤 9：GitHub Actions 工作流

```yaml
# .github/workflows/scraper.yml
name: Data Scraper Agent

on:
  schedule:
    - cron: "0 */3 * * *"  # 每 3 小时 — 根据需要调整
  workflow_dispatch:        # 允许手动触发

permissions:
  contents: write   # 反馈历史提交步骤所需

jobs:
  scrape:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - run: pip install -r requirements.txt

      # 如果在 requirements.txt 中启用了 Playwright，取消注释
      # - name: 安装 Playwright 浏览器
      #   run: python -m playwright install chromium --with-deps

      - name: 运行智能体
        env:
          NOTION_TOKEN: ${{ secrets.NOTION_TOKEN }}
          NOTION_DATABASE_ID: ${{ secrets.NOTION_DATABASE_ID }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: python -m scraper.main

      - name: 提交反馈历史
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add data/feedback.json || true
          git diff --cached --quiet || git commit -m "chore: 更新反馈历史"
          git push
```

---

### 步骤 10：config.yaml 模板

```yaml
# 自定义此文件 — 无需修改代码

# 收集什么（AI 之前预过滤）
filters:
  required_keywords: []      # 项目必须包含至少一个
  blocked_keywords: []       # 项目不得包含任何

# 你的优先级 — AI 用这些进行评分
priorities:
  - "示例优先级 1"
  - "示例优先级 2"

# 存储
storage:
  provider: "notion"         # notion | sheets | supabase | sqlite

# 反馈学习
feedback:
  positive_statuses: ["Saved", "Applied", "Interested"]
  negative_statuses: ["Skip", "Rejected", "Not relevant"]

# AI 设置
ai:
  enabled: true
  model: "gemini-2.5-flash"
  min_score: 0               # 过滤低于此评分的项目
  rate_limit_seconds: 7      # API 调用之间的秒数
  batch_size: 5              # 每次 API 调用的项目数
```

---

## 常见抓取模式

### 模式 1：REST API（最简单）
```python
resp = requests.get(url, params={"q": query}, headers=HEADERS, timeout=15)
items = resp.json().get("results", [])
```

### 模式 2：HTML 抓取
```python
soup = BeautifulSoup(resp.text, "lxml")
for card in soup.select(".listing-card"):
    title = card.select_one("h2").get_text(strip=True)
    href = card.select_one("a")["href"]
```

### 模式 3：RSS 源
```python
import xml.etree.ElementTree as ET
root = ET.fromstring(resp.text)
for item in root.findall(".//item"):
    title = item.findtext("title", "")
    link = item.findtext("link", "")
    pub_date = item.findtext("pubDate", "")
```

### 模式 4：分页 API
```python
page = 1
while True:
    resp = requests.get(url, params={"page": page, "limit": 50}, timeout=15)
    data = resp.json()
    items = data.get("results", [])
    if not items:
        break
    for item in items:
        results.append(_normalise(item))
    if not data.get("has_more"):
        break
    page += 1
```

### 模式 5：JS 渲染页面（Playwright）
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto(url)
    page.wait_for_selector(".listing")
    html = page.content()
    browser.close()

soup = BeautifulSoup(html, "lxml")
```

---

## 需要避免的反模式

| 反模式 | 问题 | 修复 |
|---|---|---|
| 每个项目一次 LLM 调用 | 立即触达速率限制 | 每次调用批量 5 个项目 |
| 代码中硬编码关键词 | 不可复用 | 将所有配置移到 `config.yaml` |
| 不限速的抓取 | IP 封禁 | 在请求之间添加 `time.sleep(1)` |
| 在代码中存储密钥 | 安全风险 | 始终使用 `.env` + GitHub Secrets |
| 不去重 | 重复行堆积 | 推送前始终检查 URL |
| 忽略 `robots.txt` | 法律/道德风险 | 遵守爬取规则；优先使用公开 API |
| 用 `requests` 抓取 JS 渲染站点 | 空响应 | 使用 Playwright 或查找底层 API |
| `maxOutputTokens` 过低 | JSON 截断，解析错误 | 批量响应使用 2048+ |

---

## 免费层限制参考

| 服务 | 免费额度 | 典型用量 |
|---|---|---|
| Gemini Flash Lite | 30 RPM, 1500 RPD | 3 小时间隔约 56 请求/天 |
| Gemini 2.0 Flash | 15 RPM, 1500 RPD | 良好的回退选择 |
| Gemini 2.5 Flash | 10 RPM, 500 RPD | 节约使用 |
| GitHub Actions | 无限制（公开仓库） | 约 20 分钟/天 |
| Notion API | 无限制 | 约 200 次写入/天 |
| Supabase | 500MB 数据库, 2GB 流量 | 对大多数智能体足够 |
| Google Sheets API | 300 请求/分钟 | 适用于小型智能体 |

---

## 依赖模板

```
requests==2.31.0
beautifulsoup4==4.12.3
lxml==5.1.0
python-dotenv==1.0.1
pyyaml==6.0.2
notion-client==2.2.1   # 如果使用 Notion
# playwright==1.40.0   # 为 JS 渲染站点取消注释
```

---

## 质量检查清单

在标记智能体完成之前：

- [ ] `config.yaml` 控制所有面向用户的设置 — 没有硬编码值
- [ ] `profile/context.md` 保存用户特定上下文用于 AI 匹配
- [ ] 每次存储推送前按 URL 去重
- [ ] Gemini 客户端有模型回退链（4 个模型）
- [ ] 批量大小 ≤ 5 个项目每次 API 调用
- [ ] `maxOutputTokens` ≥ 2048
- [ ] `.env` 在 `.gitignore` 中
- [ ] 提供 `.env.example` 用于上手引导
- [ ] `setup.py` 在首次运行时创建 DB schema
- [ ] `enrich_existing.py` 为旧行回填 AI 评分
- [ ] GitHub Actions 工作流在每次运行后提交 `feedback.json`
- [ ] README 涵盖：5 分钟内完成设置、所需密钥、自定义方式

---

## 真实世界示例

```
"帮我构建一个监控 Hacker News 上 AI 创业融资新闻的智能体"
"从 3 个电商网站抓取产品价格，降价时提醒"
"跟踪标记为 'llm' 或 'agents' 的新 GitHub 仓库 — 摘要每一个"
"从 LinkedIn 和 Cutshort 收集 Chief of Staff 职位列表到 Notion"
"监控一个提到我公司的子论坛 — 分类情感"
"每天从 arXiv 抓取我关心的主题的新学术论文"
"跟踪体育比赛结果并在 Google Sheets 中维护运行表格"
"构建一个房产列表观察器 — 低于 1000 万的新房产时提醒"
```

---

## 参考实现

一个使用此精确架构构建的完整工作智能体会抓取 4+ 个数据源，
批量调用 Gemini，从 Notion 中存储的 Applied/Rejected 决策中学习，并
在 GitHub Actions 上 100% 免费运行。按照上述步骤 1-9 构建你自己的。
