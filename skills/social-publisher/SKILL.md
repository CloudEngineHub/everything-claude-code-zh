---
name: social-publisher
description: 通过 SocialClaw 进行智能体驱动的社交媒体帖子调度和发布，覆盖 13 个平台。当用户想要发布到 X、LinkedIn、Instagram、Facebook Pages、TikTok、Discord、Telegram、YouTube、Reddit、WordPress 或 Pinterest 时使用 — 或在管理活动、上传媒体或监控帖子交付状态时使用。
origin: community
---

# 社交发布器（SocialClaw）

通过单一工作区 API 密钥将 Claude Code 连接到 [SocialClaw](https://getsocialclaw.com)，实现跨 13 个平台的智能体驱动社交媒体发布。

## 何时激活

- 向 X、LinkedIn、Instagram、TikTok 或其他平台发布内容
- 一次性跨多平台调度发布活动
- 上传用于社交媒体帖子的媒体
- 在上线前验证发布计划
- 监控发布运行状态和交付分析

## 设置

```bash
# 必需：从 https://getsocialclaw.com/dashboard 获取工作区 API 密钥
export SC_API_KEY="<workspace-key>"

# 验证访问
curl -sS -H "Authorization: Bearer $SC_API_KEY" https://getsocialclaw.com/v1/keys/validate

# 安装 CLI（可选但推荐）
npm install -g socialclaw@0.1.12
socialclaw login --api-key <workspace-key>
```

## 核心工作流

### 1. 列出已连接的账户
```bash
socialclaw accounts list --json
```

如果未连接：
```bash
socialclaw accounts connect --provider x --open
socialclaw accounts connect --provider linkedin --open
```

### 2. 上传媒体（可选）
```bash
socialclaw assets upload --file ./image.png --json
# → { "asset_id": "..." }
```

### 3. 构建 schedule.json
```json
{
  "posts": [
    {
      "provider": "x",
      "account_id": "<account-id>",
      "text": "帖子文本",
      "scheduled_at": "2026-06-01T10:00:00Z"
    }
  ]
}
```

### 4. 发布前验证
```bash
socialclaw validate -f schedule.json --json
```

### 5. 发布
```bash
socialclaw apply -f schedule.json --json
# → { "run_id": "..." }
```

### 6. 监控
```bash
socialclaw status --run-id <run-id> --json
socialclaw posts list --json
```

## 支持的平台

| 平台 | 键名 |
|----------|-----|
| X（Twitter） | `x` |
| LinkedIn 个人主页 | `linkedin` |
| LinkedIn 公司页面 | `linkedin_page` |
| Instagram 商业版 | `instagram_business` |
| Instagram 独立版 | `instagram` |
| Facebook 页面 | `facebook` |
| TikTok | `tiktok` |
| YouTube | `youtube` |
| Reddit | `reddit` |
| WordPress | `wordpress` |
| Discord | `discord` |
| Telegram | `telegram` |
| Pinterest | `pinterest` |

## 安全

- 出站请求仅发送到 `getsocialclaw.com`
- 平台 OAuth 在 SocialClaw 控制面板中完成 — 没有每个平台的密钥暴露给智能体
- `SC_API_KEY` 是工作区范围的密钥

## 相关技能

- `x-api` — 直接的 X/Twitter API 操作
- `social-graph-ranker` — 用于外联定位的网络分析

## 来源

- npm：`npm install -g socialclaw@0.1.12`
- 控制面板：[SocialClaw 控制面板](https://getsocialclaw.com/dashboard)
