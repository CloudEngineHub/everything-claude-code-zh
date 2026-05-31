---
name: agent-payment-x402
description: 为 AI 智能体添加 x402 支付执行，包含每任务预算、支出控制和托管钱包。通过 agentwallet-sdk 支持 Base，通过 OKX Payments / OKX Agent Payments Protocol 支持 X Layer。
origin: community
---

# 智能体支付执行 (x402)

使 AI 智能体能够进行策略门控的支付，并内置支出控制。使用 x402 HTTP 支付协议和 MCP 工具，因此智能体可以在没有托管风险的情况下支付外部服务、API 或其他智能体。

## 何时使用

当以下情况使用：您的智能体需要支付 API 调用、购买服务、与另一个智能体结算、强制执行每任务支出限制或管理托管钱包。与 cost-aware-llm-pipeline 和 security-review 技能自然配对。

## 决策树

根据您的智能体是购买付费 API 访问还是向其他人收费来选择集成路径：

| 需求 | 推荐路径 |
|------|------------------|
| 智能体在 Base 或其他 agentwallet-sdk 支持的链上支付 402 限门的 API | 使用 `agentwallet-sdk` 作为 MCP 支付服务器，具有严格的支出策略 |
| 智能体在 X Layer 上支付 402 限门的 API | 使用 `okx/onchainos-skills` 中的 OKX Agent Payments Protocol；`okx-x402-payment` 是已弃用的旧别名 |
| TypeScript API 向智能体收费 | 使用 OKX Payments TypeScript 销售商 SDK 文档，适用于 Express、Hono、Fastify 或 Next.js |
| Go API 向智能体收费 | 使用 OKX Payments Go 销售商 SDK 文档，适用于 Gin、Echo 或 `net/http` |
| Rust API 向智能体收费 | 使用 OKX Payments Rust 销售商 SDK 文档，适用于 Axum |
| Java API 向智能体收费 | 使用 OKX Payments Java 销售商 SDK 文档，适用于 Spring Boot 2/3、Java EE 或 Jakarta |
| Python API 向智能体收费 | 实施前检查当前 OKX Payments 存储库；Python 销售商指南可能不可用 |

## 支持的网络

- `agentwallet-sdk`：在生产前使用包文档确认当前网络覆盖。Base Sepolia 是最安全的开发默认值；Base 主网是原始技能指定的生产路径。
- OKX Payments / X Layer：当前销售商文档针对 X Layer (`eip155:196`) 和 USDT0 结算。在生成生产代码之前获取当前 SDK 文档，因为支付包和促进者行为可能会快速变化。

## 工作原理

### x402 协议
x402 将 HTTP 402（需要支付）扩展为机器可协商流。当服务器返回 `402` 时，智能体的支付工具协商价格、检查预算、签署交易，并且仅在协调器设置的策略和确认边界内重试。

### 支出控制
每次支付工具调用强制执行 `SpendingPolicy`：
- **每任务预算** — 单个智能体操作的最大支出
- **每会话预算** — 整个会话的累计限制
- **允许接收者** — 限制智能体可以支付的地址/服务
- **速率限制** — 每分钟/小时的最大交易数

### 托管钱包
智能体通过 ERC-4337 智能账户持有自己的密钥。协调器在委派之前设置策略；智能体只能在范围内支出。没有 pooled 资金，没有托管风险。

## MCP 集成

支付层暴露标准 MCP 工具，可插入任何 Claude Code 或智能体工具设置。

> **安全提示**：始终固定包版本。此工具管理私钥 — 未固定的 `npx` 安装会引入供应链风险。

### 选项 A：agentwallet-sdk (Base / 多链)

```json
{
  "mcpServers": {
    "agentpay": {
      "command": "npx",
      "args": ["agentwallet-sdk@6.0.0"]
    }
  }
}
```

### 可用工具（智能体可调用）

| 工具 | 目的 |
|------|---------|
| `get_balance` | 检查智能体钱包余额 |
| `send_payment` | 向地址或 ENS 发送支付 |
| `check_spending` | 查询剩余预算 |
| `list_transactions` | 所有支付的审计跟踪 |

> **注意**：支出策略由**协调器**在委派给智能体之前设置 — 而非智能体本身。这防止智能体提升自己的支出限制。通过编排层中的 `set_policy` 或任务前挂钩配置策略，切勿作为智能体可调用工具。

### 选项 B：OKX Agent Payments Protocol (X Layer)

将此路径用于 X Layer x402、多方支付 (MPP)、会话支付、收费和 A2A 收费流。

对于买方智能体流：

1. 安装或引用当前 `okx/onchainos-skills` 存储库。
2. 使用 `skills/okx-agent-payments-protocol/SKILL.md` 作为调度器。
3. 将 `skills/okx-x402-payment/SKILL.md` 视为已弃用的兼容性别名，而非规范技能。
4. 在钱包状态检查或支付操作之前需要明确的用户确认。不要将支付执行隐藏在通用工具调用之后。

对于卖方 API 流，在生成代码之前获取最新的特定语言指南：

| 运行时 | 当前指南 |
|---------|---------------|
| TypeScript | `https://raw.githubusercontent.com/okx/payments/main/typescript/SELLER.md` |
| Go | `https://raw.githubusercontent.com/okx/payments/main/go/x402/SELLER.md` |
| Rust | `https://raw.githubusercontent.com/okx/payments/main/rust/x402/SELLER.md` |
| Java | `https://raw.githubusercontent.com/okx/payments/main/java/SELLER.md` |

不要在不检查当前 OKX 存储库的情况下从旧文档复制示例。当前 OKX 指南使用 `okx-agent-payments-protocol` 作为调度器，Java 销售商文档现已可用。

## 示例

### MCP 客户端中的预算强制执行

构建调用 agentpay MCP 服务器的协调器时，在分派付费工具调用之前强制执行预算。

> **前提条件**：在添加 MCP 配置之前安装包 — 没有 `-y` 的 `npx` 将在非交互环境中提示确认，导致服务器挂起：`npm install -g agentwallet-sdk@6.0.0`

```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

async function main() {
  // 1. 在构建传输之前验证凭据。
  //    缺失密钥必须立即失败 — 永远不要让子进程在没有身份验证的情况下启动。
  const walletKey = process.env.WALLET_PRIVATE_KEY;
  if (!walletKey) {
    throw new Error("WALLET_PRIVATE_KEY 未设置 — 拒绝启动支付服务器");
  }

  // 通过 stdio 传输连接到 agentpay MCP 服务器。
  // 仅白名单服务器需要的环境变量 — 永远不要将所有 process.env
  // 转发到管理私密的第三方子进程。
  const transport = new StdioClientTransport({
    command: "npx",
    args: ["agentwallet-sdk@6.0.0"],
    env: {
      PATH: process.env.PATH ?? "",
      NODE_ENV: process.env.NODE_ENV ?? "production",
      WALLET_PRIVATE_KEY: walletKey,
    },
  });
  const agentpay = new Client({ name: "orchestrator", version: "1.0.0" });
  await agentpay.connect(transport);

  // 2. 在委派给智能体之前设置支出策略。
  //    始终验证成功 — 静默失败意味着没有激活控制。
  const policyResult = await agentpay.callTool({
    name: "set_policy",
    arguments: {
      per_task_budget: 0.50,
      per_session_budget: 5.00,
      allowlisted_recipients: ["api.example.com"],
    },
  });
  if (policyResult.isError) {
    throw new Error(
      `设置支出策略失败 — 不要委派：${JSON.stringify(policyResult.content)}`
    );
  }

  // 3. 在任何付费操作之前使用 preToolCheck
  await preToolCheck(agentpay, 0.01);
}

// 预工具挂钩：具有四个不同错误路径的失败关闭预算强制执行。
async function preToolCheck(agentpay: Client, apiCost: number): Promise<void> {
  // 路径 1：拒绝无效输入（NaN/Infinity 绕过 < 比较）
  if (!Number.isFinite(apiCost) || apiCost < 0) {
    throw new Error(`无效的 apiCost：${apiCost} — 操作被阻止`);
  }

  // 路径 2：传输/连接失败
  let result;
  try {
    result = await agentpay.callTool({ name: "check_spending" });
  } catch (err) {
    throw new Error(`支付服务无法访问 — 操作被阻止：${err}`);
  }

  // 路径 3：工具返回错误（例如，身份验证失败、钱包未初始化）
  if (result.isError) {
    throw new Error(
      `check_spending 失败 — 操作被阻止：${JSON.stringify(result.content)}`
    );
  }

  // 路径 4：解析并验证响应形状
  let remaining: number;
  try {
    const parsed = JSON.parse(
      (result.content as Array<{ text: string }>)[0].text
    );
    if (!Number.isFinite(parsed?.remaining)) {
      throw new TypeError("缺失或非有限的 'remaining' 字段");
    }
    remaining = parsed.remaining;
  } catch (err) {
    throw new Error(
      `check_spending 返回意外格式 — 操作被阻止：${err}`
    );
  }

  // 路径 5：超出预算
  if (remaining < apiCost) {
    throw new Error(
      `预算超出：需要 $${apiCost} 但仅剩 $${remaining}`
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
```

## 最佳实践

- **委派前设置预算**：生成子智能体时，通过编排层附加 SpendingPolicy。永远不要给智能体无限的支出。
- **固定依赖项**：始终在 MCP 配置中指定确切的版本（例如，`agentwallet-sdk@6.0.0`）。在部署到生产环境之前验证包完整性。
- **审计跟踪**：在任务后挂钩中使用 `list_transactions` 记录支出了什么以及为什么。
- **失败关闭**：如果支付工具无法访问，阻止付费操作 — 不要回退到无限访问。
- **与 security-review 配对**：支付工具是高权限。应用与 shell 访问相同的审查。
- **首先在测试网中测试**：使用 Base Sepolia 进行开发；切换到 Base 主网进行生产。

## 生产参考

- **npm**：[`agentwallet-sdk`](https://www.npmjs.com/package/agentwallet-sdk)
- **合并到 NVIDIA NeMo Agent Toolkit**：[PR #17](https://github.com/NVIDIA/NeMo-Agent-Toolkit-Examples/pull/17) — NVIDIA 智能体示例的 x402 支付工具
- **协议规范**：[x402.org](https://x402.org)
- **OKX Payments SDK**：[`okx/payments`](https://github.com/okx/payments) — X Layer x402 的 TypeScript、Go、Rust 和 Java 销售商集成
- **OKX Agent Payments Protocol 技能**：[`okx/onchainos-skills`](https://github.com/okx/onchainos-skills/tree/main/skills/okx-agent-payments-protocol)
- **OKX Payments 概述**：[web3.okx.com/onchainos/dev-docs/payments/overview](https://web3.okx.com/onchainos/dev-docs/payments/overview)
