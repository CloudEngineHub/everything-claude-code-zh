---
name: ai-regression-testing
description: AI 辅助开发的回归测试策略。无数据库依赖的沙箱模式 API 测试、自动化错误检查工作流，以及捕获相同模型编写和审查代码的 AI 盲点的模式。
origin: ECC
---

# AI 回归测试

专为 AI 辅助开发设计的测试模式，其中同一模型编写代码并审查它 — 创建只有自动化测试才能捕获的系统性盲点。

## 何时激活

- AI 智能体（Claude Code、Cursor、Codex）修改了 API 路由或后端逻辑
- 发现并修复了错误 — 需要防止重新引入
- 项目有可利用于无 DB 测试的沙箱/模拟模式
- 在代码更改后运行 `/bug-check` 或类似审查命令
- 存在多个代码路径（沙箱与生产、功能标志等）

## 核心问题

当 AI 编写代码然后审查自己的工作时，它在两个步骤中带有相同的假设。这创建了一个可预测的失败模式：

```
AI 编写修复 → AI 审查修复 → AI 说"看起来正确" → 错误仍然存在
```

**真实示例**（在生产中观察到）：

```
修复 1：将 notification_settings 添加到 API 响应
  → 忘记将其添加到 SELECT 查询
  → AI 审查并错过了它（相同的盲点）

修复 2：将其添加到 SELECT 查询
  → TypeScript 构建错误（列不在生成的类型中）
  → AI 审查了修复 1 但没有发现 SELECT 问题

修复 3：更改为 SELECT *
  → 修复了生产路径，忘记沙箱路径
  → AI 审查并再次错过（第 4 次出现）

修复 4：测试在第一次运行时立即捕获 通过：
```

模式：**沙箱/生产路径不一致**是 AI 引入的回归的第一大原因。

## 沙箱模式 API 测试

大多数具有 AI 友好架构的项目都有沙箱/模拟模式。这是快速、无 DB API 测试的关键。

### 设置（Vitest + Next.js App Router）

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    environment: "node",
    globals: true,
    include: ["__tests__/**/*.test.ts"],
    setupFiles: ["__tests__/setup.ts"],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
});
```

```typescript
// __tests__/setup.ts
// 强制沙箱模式 — 不需要数据库
process.env.SANDBOX_MODE = "true";
process.env.NEXT_PUBLIC_SUPABASE_URL = "";
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "";
```

### Next.js API 路由的测试助手

```typescript
// __tests__/helpers.ts
import { NextRequest } from "next/server";

export function createTestRequest(
  url: string,
  options?: {
    method?: string;
    body?: Record<string, unknown>;
    headers?: Record<string, string>;
    sandboxUserId?: string;
  },
): NextRequest {
  const { method = "GET", body, headers = {}, sandboxUserId } = options || {};
  const fullUrl = url.startsWith("http") ? url : `http://localhost:3000${url}`;
  const reqHeaders: Record<string, string> = { ...headers };

  if (sandboxUserId) {
    reqHeaders["x-sandbox-user-id"] = sandboxUserId;
  }

  const init: { method: string; headers: Record<string, string>; body?: string } = {
    method,
    headers: reqHeaders,
  };

  if (body) {
    init.body = JSON.stringify(body);
    reqHeaders["content-type"] = "application/json";
  }

  return new NextRequest(fullUrl, init);
}

export async function parseResponse(response: Response) {
  const json = await response.json();
  return { status: response.status, json };
}
```

### 编写回归测试

关键原则：**为发现的错误编写测试，而非为有效的代码**。

```typescript
// __tests__/api/user/profile.test.ts
import { describe, it, expect } from "vitest";
import { createTestRequest, parseResponse } from "../../helpers";
import { GET, PATCH } from "@/app/api/user/profile/route";

// 定义合同 — 响应中必须有哪些字段
const REQUIRED_FIELDS = [
  "id",
  "email",
  "full_name",
  "phone",
  "role",
  "created_at",
  "avatar_url",
  "notification_settings",  // ← 发现错误后添加
];

describe("GET /api/user/profile", () => {
  it("返回所有必需字段", async () => {
    const req = createTestRequest("/api/user/profile");
    const res = await GET(req);
    const { status, json } = await parseResponse(res);

    expect(status).toBe(200);
    for (const field of REQUIRED_FIELDS) {
      expect(json.data).toHaveProperty(field);
    }
  });

  // 回归测试 — AI 引入了 4 次这个确切的错误
  it("notification_settings 不是未定义（BUG-R1 回归）", async () => {
    const req = createTestRequest("/api/user/profile");
    const res = await GET(req);
    const { json } = await parseResponse(res);

    expect("notification_settings" in json.data).toBe(true);
    const ns = json.data.notification_settings;
    expect(ns === null || typeof ns === "object").toBe(true);
  });
});
```

### 测试沙箱/生产奇偶性

最常见的 AI 回归：修复生产路径但忘记沙箱路径（反之亦然）。

```typescript
// 测试沙箱响应匹配预期合同
describe("GET /api/user/messages（对话列表）", () => {
  it("在沙箱模式中包括 partner_name", async () => {
    const req = createTestRequest("/api/user/messages", {
      sandboxUserId: "user-001",
    });
    const res = await GET(req);
    const { json } = await parseResponse(res);

    // 这捕获了一个错误，其中 partner_name 被添加
    // 到生产路径但未添加到沙箱路径
    if (json.data.length > 0) {
      for (const conv of json.data) {
        expect("partner_name" in conv).toBe(true);
      }
    }
  });
});
```

## 将测试集成到错误检查工作流中

### 自定义命令定义

```markdown
<!-- .claude/commands/bug-check.md -->
# Bug 检查

## 步骤 1：自动化测试（强制性，不能跳过）

在任何代码审查之前首先运行这些命令：

    npm run test       # Vitest 测试套件
    npm run build      # TypeScript 类型检查 + 构建

- 如果测试失败 → 将报告为最高优先级错误
- 如果构建失败 → 将类型错误报告为最高优先级
- 仅在两者都通过时继续进行步骤 2

## 步骤 2：代码审查（AI 审查）

1. 沙箱 / 生产路径一致性
2. API 响应形状匹配前端期望
3. SELECT 子句完整性
4. 具有回滚的错误处理
5. 乐观更新竞争条件

## 步骤 3：对于每个修复的错误，提议回归测试
```

### 工作流程

```
用户："バグチェックして" (or "/bug-check")
  │
  ├─ 步骤 1：npm run test
  │   ├─ FAIL → 机械发现错误（无需 AI 判断）
  │   └─ PASS → 继续
  │
  ├─ 步骤 2：npm run build
  │   ├─ FAIL → 机械发现类型错误
  │   └─ PASS → 继续
  │
  ├─ 步骤 3：AI 代码审查（记住已知盲点）
  │   └─ 报告发现
  │
  └─ 步骤 4：对于每个修复，编写回归测试
      └─ 下次 bug 检查捕获修复是否中断
```

## 常见 AI 回归模式

### 模式 1：沙箱/生产路径不匹配

**频率**：最常见（在 4 次回归中观察到 3 次）

```typescript
// FAIL：AI 仅将字段添加到生产路径
if (isSandboxMode()) {
  return { data: { id, email, name } };  // 缺少新字段
}
// 生产路径
return { data: { id, email, name, notification_settings } };

// PASS：两条路径必须返回相同的形状
if (isSandboxMode()) {
  return { data: { id, email, name, notification_settings: null } };
}
return { data: { id, email, name, notification_settings } };
```

**捕获它的测试**：

```typescript
it("沙箱和生产返回相同的字段", async () => {
  // 在测试环境中，沙箱模式被强制开启
  const res = await GET(createTestRequest("/api/user/profile"));
  const { json } = await parseResponse(res);

  for (const field of REQUIRED_FIELDS) {
    expect(json.data).toHaveProperty(field);
  }
});
```

### 模式 2：SELECT 子句遗漏

**频率**：在使用 Supabase/Prisma 添加新列时常见

```typescript
// FAIL：新列添加到响应但未添加到 SELECT
const { data } = await supabase
  .from("users")
  .select("id, email, name")  // notification_settings 不在这里
  .single();

return { data: { ...data, notification_settings: data.notification_settings } };
// → notification_settings 始终未定义

// PASS：使用 SELECT * 或明确包含新列
const { data } = await supabase
  .from("users")
  .select("*")
  .single();
```

### 模式 3：错误状态泄漏

**频率**：中等 — 向现有组件添加错误处理时

```typescript
// FAIL：设置了错误状态但未清除旧数据
catch (err) {
  setError("加载失败");
  // 预订仍显示来自上一个选项卡的数据！
}

// PASS：清除错误时的相关状态
catch (err) {
  setReservations([]);  // 清除陈旧数据
  setError("加载失败");
}
```

### 模式 4：没有适当回滚的乐观更新

```typescript
// FAIL：失败时没有回滚
const handleRemove = async (id: string) => {
  setItems(prev => prev.filter(i => i.id !== id));
  await fetch(`/api/items/${id}`, { method: "DELETE" });
  // 如果 API 失败，项目从 UI 中消失但仍在 DB 中
};

// PASS：捕获先前状态并在失败时回滚
const handleRemove = async (id: string) => {
  const prevItems = [...items];
  setItems(prev => prev.filter(i => i.id !== id));
  try {
    const res = await fetch(`/api/items/${id}`, { method: "DELETE" });
    if (!res.ok) throw new Error("API 错误");
  } catch {
    setItems(prevItems);  // 回滚
    alert("削除に失敗しました");
  }
};
```

## 策略：在发现错误的地方测试

不要以 100% 覆盖为目标。相反：

```
在 /api/user/profile 中发现错误     → 为 profile API 编写测试
在 /api/user/messages 中发现错误    → 为 messages API 编写测试
在 /api/user/favorites 中发现错误   → 为 favorites API 编写测试
/api/user/notifications 中没有错误  → 尚未编写测试
```

**为什么这对 AI 开发有效：**

1. AI 倾向于反复犯**相同类别的错误**
2. 错误集中在复杂区域（身份验证、多路径逻辑、状态管理）
3. 一旦测试，确切的回归**不能再发生**
4. 测试数量随错误修复有机增长 — 无浪费努力

## 快速参考

| AI 回归模式 | 测试策略 | 优先级 |
|---|---|---|
| 沙箱/生产不匹配 | 在沙箱模式中断言相同的响应形状 | 高 |
| SELECT 子句遗漏 | 断言响应中的所有必需字段 | 高 |
| 错误状态泄漏 | 断言错误时的状态清理 | 中 |
| 缺少回滚 | 断言 API 失败时恢复的状态 | 中 |
| 类型转换掩盖 null | 断言字段未定义 | 中 |

## 做 / 不做

**做：**
- 在发现错误后立即编写测试（如果可能在修复之前）
- 测试 API 响应形状，而非实施
- 将测试作为每次 bug 检查的第一步运行
- 保持测试快速（使用沙箱模式总计 < 1 秒）
- 以它们防止的错误命名测试（例如，"BUG-R1 回归"）

**不做：**
- 为从未有错误的代码编写测试
- 信任 AI 自我审查作为自动化测试的替代品
- 跳过沙箱路径测试，因为"这只是模拟数据"
- 当单元测试足够时编写集成测试
- 以覆盖百分比为目标 — 以回归预防为目标
