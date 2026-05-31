---
name: x-api
description: X/Twitter API 集成，用于发布推文、主题串、阅读时间线、搜索和分析。涵盖 OAuth 认证模式、速率限制和平台原生内容发布。当用户想要以编程方式与 X 交互时使用。
origin: ECC
---

# X API

> **易变技能。** X API 端点、访问层级、配额和写入权限变更频繁。
> 在引用速率限制或实现发布/搜索流程之前，验证当前的开发者文档和账户访问权限。

以编程方式与 X (Twitter) 交互，用于发布、阅读、搜索和分析。

## 何时激活

- 用户想要以编程方式发布推文或主题串
- 从 X 读取时间线、提及或用户数据
- 在 X 中搜索内容、趋势或对话
- 构建 X 集成或机器人
- 分析和参与度跟踪
- 用户说"发布到 X"、"发推"、"X API"或"Twitter API"

## 认证

### OAuth 2.0 Bearer Token（仅应用）

最适合：读取密集型操作、搜索、公共数据。

```bash
# 环境设置
export X_BEARER_TOKEN="your-bearer-token"
```

```python
import os
import requests

bearer = os.environ["X_BEARER_TOKEN"]
headers = {"Authorization": f"Bearer {bearer}"}

# 搜索最近推文
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={"query": "claude code", "max_results": 10}
)
tweets = resp.json()
```

### OAuth 1.0a（用户上下文）

用于：发布推文、管理账户、私信和任何写入流程。

```bash
# 环境设置 — 使用前导出
export X_CONSUMER_KEY="your-consumer-key"
export X_CONSUMER_SECRET="your-consumer-secret"
export X_ACCESS_TOKEN="your-access-token"
export X_ACCESS_TOKEN_SECRET="your-access-token-secret"
```

旧版别名如 `X_API_KEY`、`X_API_SECRET` 和 `X_ACCESS_SECRET` 可能存在于旧设置中。在文档记录或连接新流程时，优先使用 `X_CONSUMER_*` 和 `X_ACCESS_TOKEN_SECRET` 名称。

```python
import os
from requests_oauthlib import OAuth1Session

oauth = OAuth1Session(
    os.environ["X_CONSUMER_KEY"],
    client_secret=os.environ["X_CONSUMER_SECRET"],
    resource_owner_key=os.environ["X_ACCESS_TOKEN"],
    resource_owner_secret=os.environ["X_ACCESS_TOKEN_SECRET"],
)
```

## 核心操作

### 发布推文

```python
resp = oauth.post(
    "https://api.x.com/2/tweets",
    json={"text": "来自 Claude Code 的问候"}
)
resp.raise_for_status()
tweet_id = resp.json()["data"]["id"]
```

### 发布主题串

```python
def post_thread(oauth, tweets: list[str]) -> list[str]:
    ids = []
    reply_to = None
    for text in tweets:
        payload = {"text": text}
        if reply_to:
            payload["reply"] = {"in_reply_to_tweet_id": reply_to}
        resp = oauth.post("https://api.x.com/2/tweets", json=payload)
        tweet_id = resp.json()["data"]["id"]
        ids.append(tweet_id)
        reply_to = tweet_id
    return ids
```

### 读取用户时间线

```python
resp = requests.get(
    f"https://api.x.com/2/users/{user_id}/tweets",
    headers=headers,
    params={
        "max_results": 10,
        "tweet.fields": "created_at,public_metrics",
    }
)
```

### 搜索推文

```python
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={
        "query": "from:affaanmustafa -is:retweet",
        "max_results": 10,
        "tweet.fields": "public_metrics,created_at",
    }
)
```

### 拉取最近原创帖子用于语声建模

```python
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={
        "query": "from:affaanmustafa -is:retweet -is:reply",
        "max_results": 25,
        "tweet.fields": "created_at,public_metrics",
    }
)
voice_samples = resp.json()
```

### 按用户名获取用户

```python
resp = requests.get(
    "https://api.x.com/2/users/by/username/affaanmustafa",
    headers=headers,
    params={"user.fields": "public_metrics,description,created_at"}
)
```

### 上传媒体并发布

```python
# 媒体上传使用 v1.1 端点

# 步骤 1：上传媒体
media_resp = oauth.post(
    "https://upload.twitter.com/1.1/media/upload.json",
    files={"media": open("image.png", "rb")}
)
media_id = media_resp.json()["media_id_string"]

# 步骤 2：带媒体发布
resp = oauth.post(
    "https://api.x.com/2/tweets",
    json={"text": "看看这个", "media": {"media_ids": [media_id]}}
)
```

## 速率限制

X API 速率限制因端点、认证方法和账户层级而异，且随时间变化。始终：
- 在硬编码假设之前检查当前 X 开发者文档
- 运行时读取 `x-rate-limit-remaining` 和 `x-rate-limit-reset` 头
- 自动退避而非依赖代码中的静态表

```python
import time

remaining = int(resp.headers.get("x-rate-limit-remaining", 0))
if remaining < 5:
    reset = int(resp.headers.get("x-rate-limit-reset", 0))
    wait = max(0, reset - int(time.time()))
    print(f"接近速率限制。{wait}秒后重置")
```

## 错误处理

```python
resp = oauth.post("https://api.x.com/2/tweets", json={"text": content})
if resp.status_code == 201:
    return resp.json()["data"]["id"]
elif resp.status_code == 429:
    reset = int(resp.headers["x-rate-limit-reset"])
    raise Exception(f"速率限制。在 {reset} 时重置")
elif resp.status_code == 403:
    raise Exception(f"禁止访问: {resp.json().get('detail', '检查权限')}")
else:
    raise Exception(f"X API 错误 {resp.status_code}: {resp.text}")
```

## 安全

- **绝不硬编码令牌。** 使用环境变量或 `.env` 文件。
- **绝不提交 `.env` 文件。** 添加到 `.gitignore`。
- **令牌暴露时立即轮换。** 在 developer.x.com 重新生成。
- **不需要写入权限时使用只读令牌。**
- **安全存储 OAuth 密钥** — 不在源代码或日志中。

## 与内容引擎集成

使用 `brand-voice` 加 `content-engine` 生成平台原生内容，然后通过 X API 发布：
1. 当语声匹配重要时，拉取最近的原创帖子
2. 构建或复用 `语声档案`
3. 使用 `content-engine` 以 X 原生格式生成内容
4. 验证长度和主题串结构
5. 返回草稿供审批，除非用户明确要求立即发布
6. 审批后通过 X API 发布
7. 通过 public_metrics 跟踪参与度

## 相关技能

- `brand-voice` — 从真实 X 和站点/源材料构建可复用的语声档案
- `content-engine` — 为 X 生成平台原生内容
- `crosspost` — 跨 X、LinkedIn 和其他平台分发内容
- `connections-optimizer` — 在起草网络驱动的外联之前重新组织 X 关系图
