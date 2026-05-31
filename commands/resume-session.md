---
description: 从 ~/.claude/session-data/ 加载最近的会话文件并恢复工作，保留上次会话结束时的完整上下文。
---

# 恢复会话命令

加载上次保存的会话状态，在进行任何工作之前完全了解上下文。
此命令是 `/save-session` 的对应命令。

## 何时使用

- 开始新会话以继续之前的工作
- 因上下文限制而开始新会话之后
- 从其他来源传递会话文件时（只需提供文件路径）
- 任何你有一个会话文件并希望 Claude 完全吸收它的时候

## 用法

```
/resume-session                                                      # 加载 ~/.claude/session-data/ 中最近的文件
/resume-session 2024-01-15                                           # 加载该日期最近的会话
/resume-session ~/.claude/session-data/2024-01-15-abc123de-session.tmp  # 加载当前短 id 会话文件
/resume-session ~/.claude/sessions/2024-01-15-session.tmp               # 加载特定传统格式文件
```

## 流程

### 步骤 1：查找会话文件

如果没有提供参数：

1. 检查 `~/.claude/session-data/`
2. 选择最近修改的 `*-session.tmp` 文件
3. 如果文件夹不存在或没有匹配文件，告诉用户：
   ```
   在 ~/.claude/session-data/ 中未找到会话文件
   在会话结束时运行 /save-session 来创建一个。
   ```
   然后停止。

如果提供了参数：

- 如果看起来像日期（`YYYY-MM-DD`），先搜索 `~/.claude/session-data/`，然后搜索传统的
  `~/.claude/sessions/`，查找匹配 `YYYY-MM-DD-session.tmp`（传统格式）或
  `YYYY-MM-DD-<shortid>-session.tmp`（当前格式）的文件
  并加载该日期最近修改的版本
- 如果看起来像文件路径，直接读取该文件
- 如果未找到，清楚地报告并停止

### 步骤 2：读取整个会话文件

读取完整文件。暂时不要总结。

### 步骤 3：确认理解

以以下确切格式响应结构化简报：

```
SESSION LOADED: [实际解析的文件路径]
════════════════════════════════════════════════

PROJECT: [文件中的项目名称/主题]

WHAT WE'RE BUILDING:
[用你自己的话总结 2-3 句]

CURRENT STATE:
PASS: Working: [数量] 已确认项目
 In Progress: [正在进行的文件列表]
 Not Started: [已计划但未开始的列表]

WHAT NOT TO RETRY:
[列出每个失败的方法及其原因 — 这很关键]

OPEN QUESTIONS / BLOCKERS:
[列出任何阻碍或未解答的问题]

NEXT STEP:
[如果文件中已定义，确切的下一步]
[如果未定义："No next step defined — recommend reviewing 'What Has NOT Been Tried Yet' together before starting"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### 步骤 4：等待用户

不要自动开始工作。不要触碰任何文件。等待用户说下一步做什么。

如果文件中明确定义了下一步且用户说"继续"或"是"或类似 — 继续执行该确切的下一步。

如果未定义下一步 — 询问用户从哪里开始，并可选地从"What Has NOT Been Tried Yet"部分建议一个方法。

---

## 边界情况

**同一日期的多个会话**（`2024-01-15-session.tmp`、`2024-01-15-abc123de-session.tmp`）：
加载该日期最近修改的匹配文件，无论它使用传统无 id 格式还是当前短 id 格式。

**会话文件引用了已不存在的文件：**
在简报中注明 — "WARNING: `path/to/file.ts` 在会话中引用但磁盘上未找到。"

**会话文件超过 7 天：**
注明间隔 — "WARNING: 此会话来自 N 天前（阈值：7 天）。可能已经发生变化。" — 然后正常继续。

**用户直接提供文件路径（如从队友转发）：**
读取它并遵循相同的简报流程 — 无论来源如何格式式相同。

**会话文件为空或格式错误：**
报告："找到会话文件但似乎为空或无法读取。你可能需要用 /save-session 创建新的。"

---

## 示例输出

```
SESSION LOADED: /Users/you/.claude/session-data/2024-01-15-abc123de-session.tmp
════════════════════════════════════════════════

PROJECT: my-app — JWT Authentication

WHAT WE'RE BUILDING:
用户认证使用 JWT tokens 存储在 httpOnly cookies。
注册和登录端点部分完成。路由保护
通过中间件尚未开始。

CURRENT STATE:
PASS: Working: 3 items (register endpoint, JWT generation, password hashing)
 In Progress: app/api/auth/login/route.ts (token works, cookie not set yet)
 Not Started: middleware.ts, app/login/page.tsx

WHAT NOT TO RETRY:
FAIL: Next-Auth — conflicts with custom Prisma adapter, threw adapter error on every request
FAIL: localStorage for JWT — causes SSR hydration mismatch, incompatible with Next.js

OPEN QUESTIONS / BLOCKERS:
- Does cookies().set() work inside a Route Handler or only Server Actions?

NEXT STEP:
In app/api/auth/login/route.ts — set the JWT as an httpOnly cookie using
cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })
then test with Postman for a Set-Cookie header in the response.

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

---

## 注意事项

- 加载时绝不修改会话文件 — 它是只读的历史记录
- 简报格式是固定的 — 即使部分为空也不要跳过
- "What Not To Retry" 必须始终显示，即使只是说"无" — 它太重要了不能遗漏
- 恢复后，用户可能想在新会话结束时再次运行 `/save-session` 以创建新的日期文件
