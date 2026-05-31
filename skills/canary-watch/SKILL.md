---
name: canary-watch
description: 使用此技能在发布后监控和验证已部署的 URL — 检查 HTTP 端点、SSE 流、静态资源、控制台错误和性能退化，适用于部署、合并或依赖升级后的冒烟测试/金丝雀/部署后验证。
origin: ECC
---

# Canary Watch — 部署后监控

## 何时使用

- 部署到生产环境或预发布环境后
- 合并有风险的 PR 后
- 需要验证修复是否真正生效时
- 发布窗口期间的持续监控
- 依赖升级后

## 工作原理

监控已部署 URL 是否出现退化。循环运行直到被停止或监控窗口到期。

### 监控内容

```
1. HTTP 状态 — 页面是否返回 200？
2. 控制台错误 — 是否有之前没有的新错误？
3. 网络失败 — API 调用失败、5xx 响应？
4. 性能 — LCP/CLS/INP 相对于基线是否退化？
5. 内容 — 关键元素是否消失了？（h1、导航、页脚、CTA）
6. API 健康 — 关键端点是否在 SLA 内响应？
7. 静态资源 — JS、CSS、图片和字体请求是否返回 2xx/3xx 且内容类型符合预期？
8. SSE 流 — 事件流端点是否能连接并接收初始事件或心跳？
```

### 监控模式

**快速检查**（默认）：单次通过，报告结果
```
/canary-watch https://myapp.com
```

**持续监控**：每 N 分钟检查一次，持续 M 小时
```
/canary-watch https://myapp.com --interval 5m --duration 2h
```

**对比模式**：对比预发布环境与生产环境
```
/canary-watch --compare https://staging.myapp.com https://myapp.com
```

### 告警阈值

```yaml
critical:  # 立即告警
  - HTTP 状态 != 200
  - 控制台错误数 > 5（仅新错误）
  - LCP > 4s
  - API 端点返回 5xx
  - 静态资源返回 4xx/5xx
  - SSE 端点无法连接或在首次心跳前断开

warning:   # 在报告中标记
  - LCP 相对基线增加 > 500ms
  - CLS > 0.1
  - 新的控制台警告
  - 响应时间 > 基线的 2 倍
  - 静态资源内容类型意外改变
  - SSE 心跳延迟 > 基线的 2 倍

info:      # 仅记录
  - 轻微性能波动
  - 新的网络请求（添加了第三方脚本？）
```

### 通知

当超过严重阈值时：
- 桌面通知（macOS/Linux）
- 可选：Slack/Discord Webhook
- 记录到 `~/.claude/canary-watch.log`

## 输出

```markdown
## 金丝雀报告 — myapp.com — 2026-03-23 03:15 PST

### 状态：健康 ✓

| 检查项 | 结果 | 基线 | 差异 |
|-------|------|------|------|
| HTTP | 200 ✓ | 200 | — |
| 控制台错误 | 0 ✓ | 0 | — |
| LCP | 1.8s ✓ | 1.6s | +200ms |
| CLS | 0.01 ✓ | 0.01 | — |
| API /health | 145ms ✓ | 120ms | +25ms |
| 静态资源 | 42/42 ✓ | 42/42 | — |
| SSE /events | 已连接 ✓ | 已连接 | +80ms 心跳 |

### 未检测到退化。部署正常。
```

## 集成

配合使用：
- `/browser-qa` 用于部署前验证
- 钩子：添加为 `git push` 的 PostToolUse 钩子，在部署后自动检查
- CI：在 GitHub Actions 的部署步骤后运行
