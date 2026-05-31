---
name: x-api
description: X/Twitter API 集成，用于发布推文、线程、阅读时间线、搜索和分析。涵盖 OAuth 认证模式、速率限制和平台原生内容发布。当用户想要以编程方式与 X 交互时使用。
---

# X API

与 X（Twitter）的编程交互，用于发布、阅读、搜索和分析。

## 何时激活

- 用户想要以编程方式发布推文或线程
- 从 X 阅读时间线、提及或用户数据
- 搜索 X 内容、趋势或对话
- 构建 X 集成或机器人
- 分析和参与跟踪
- 用户说"发布到 X"、"tweet"、"X API"或"Twitter API"

## 认证

### OAuth 2.0 持有者令牌（仅应用）

最适合：重度读取操作、搜索、公共数据。

```bash
# 环境设置
export X_BEARER_TOKEN="your-bearer-token"
```

```python
import os
import requests

bearer = os.environ["X_BEARER_TOKEN"]
headers = {"Authorization": f"Bearer {bearer}"}

# 搜索最近的推文
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={"query": "claude code", "max_results": 10}
)
tweets = resp.json()
```

### OAuth 1.0a（用户上下文）

需要用于：发布推文、管理账户、DM 和任何写入流。

```bash
# 环境设置 — 使用前获取
export X_CONSUMER_KEY="your-consumer-key"
export X_CONSUMER_SECRET="your-consumer-secret"
export X_ACCESS_TOKEN="your-access-token"
export X_ACCESS_TOKEN_SECRET="your-access-token-secret"
```

旧设置中的遗留别名如 `X_API_KEY`、`X_API_SECRET` 和 `X_ACCESS_SECRET` 可能存在。在记录或连接新流时，优先使用 `X_CONSUMER_*` 和 `X_ACCESS_TOKEN_SECRET` 名称。

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
    json={"text": "来自 Claude Code 的你好"}
)
resp.raise_for_status()
tweet_id = resp.json()["data"]["id"]
```

### 发布线程

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

### 阅读用户时间线

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

### 拉取用于语音建模的最近原创帖子

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

X API 速率限制因端点、认证方法和账户层级而异，并且它们随时间变化。始终：
- 在对假设进行硬编码之前查看当前 X 开发者文档
- 在运行时读取 `x-rate-limit-remaining` 和 `x-rate-limit-reset` 头
- 自动回退，而不是依赖代码中的静态表

```python
import time

remaining = int(resp.headers.get("x-rate-limit-remaining", 0))
if remaining < 5:
    reset = int(resp.headers.get("x-rate-limit-reset", 0))
    wait = max(0, reset - int(time.time()))
    print(f"接近速率限制。在 {wait}s 后重置")
```

## 错误处理

```python
resp = oauth.post("https://api.x.com/2/tweets", json={"text": content})
if resp.status_code == 201:
    return resp.json()["data"]["id"]
elif resp.status_code == 429:
    reset = int(resp.headers["x-rate-limit-reset"])
    raise Exception(f"速率限制。在 {reset} 重置")
elif resp.status_code == 403:
    raise Exception(f"禁止：{resp.json().get('detail', '检查权限')}")
else:
    raise Exception(f"X API 错误 {resp.status_code}：{resp.text}")
```

## 安全

- **永远不要硬编码令牌。** 使用环境变量或 `.env` 文件。
- **永远不要提交 `.env` 文件。** 添加到 `.gitignore`。
- 如果暴露则**轮换令牌**。在 developer.x.com 重新生成。
- **当不需要写入访问时使用只读令牌。**
- **安全存储 OAuth 机密** — 不在源代码或日志中。

## 与内容引擎集成

使用 `brand-voice` 加上 `content-engine` 生成平台原生内容，然后通过 X API 发布：
1. 当语音匹配重要时提取最近的原创帖子
2. 构建或重用 `语音配置文件`
3. 使用 `content-engine` 以 X 原生格式生成内容
4. 验证长度和线程结构
5. 除非用户明确要求立即发布，否则返回草稿以供批准
6. 仅在批准后通过 X API 发布
7. 通过 public_metrics 跟踪参与度

## 相关技能

- `brand-voice` — 从真实 X 和站点/来源材料构建可重用的语音配置文件
- `content-engine` — 为 X 生成平台原生内容
- `crosspost` — 跨 X、LinkedIn 和其他平台分发内容
- `connections-optimizer` — 在起草网络驱动的外联之前重新组织 X 图表
