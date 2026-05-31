---
name: bun-runtime
description: Bun 作为运行时、包管理器、打包器和测试运行器。何时选择 Bun 与 Node、迁移说明以及 Vercel 支持。
---

# Bun 运行时

Bun 是一个快速的全方位 JavaScript 运行时和工具包：运行时、包管理器、打包器和测试运行器。

## 何时使用

- **优先使用 Bun**：新的 JS/TS 项目、安装/运行速度很重要的脚本、使用 Bun 运行时的 Vercel 部署，以及当您想要单一工具链（运行 + 安装 + 测试 + 构建）时。
- **优先使用 Node**：最大的生态系统兼容性、假设 Node 的遗留工具，或当依赖项有已知的 Bun 问题时。

在以下情况下使用：采用 Bun、从 Node 迁移、编写或调试 Bun 脚本/测试，或在 Vercel 或其他平台上配置 Bun。

## 工作原理

- **运行时**：即插即用的 Node 兼容运行时（构建于 JavaScriptCore，用 Zig 实现）。
- **包管理器**：`bun install` 明显快于 npm/yarn。锁定文件默认为 `bun.lock`（文本）在当前 Bun 中；旧版本使用 `bun.lockb`（二进制）。
- **打包器**：用于应用程序和库的内置打包器和转译器。
- **测试运行器**：内置 `bun test`，具有类似 Jest 的 API。

**从 Node 迁移**：将 `node script.js` 替换为 `bun run script.js` 或 `bun script.js`。在 `npm install` 的位置运行 `bun install`；大多数包都可以工作。对 npm 脚本使用 `bun run`；对 npx 风格的一次性运行使用 `bun x`。支持 Node 内置；在存在 Bun API 的地方优先使用它们以获得更好的性能。

**Vercel**：在项目设置中将运行时设置为 Bun。构建：`bun run build` 或 `bun build ./src/index.ts --outdir=dist`。安装：`bun install --frozen-lockfile` 用于可重现部署。

## 示例

### 运行和安装

```bash
# 安装依赖（创建/更新 bun.lock 或 bun.lockb）
bun install

# 运行脚本或文件
bun run dev
bun run src/index.ts
bun src/index.ts
```

### 脚本和环境

```bash
bun run --env-file=.env dev
FOO=bar bun run script.ts
```

### 测试

```bash
bun test
bun test --watch
```

```typescript
// test/example.test.ts
import { expect, test } from "bun:test";

test("add", () => {
  expect(1 + 2).toBe(3);
});
```

### 运行时 API

```typescript
const file = Bun.file("package.json");
const json = await file.json();

Bun.serve({
  port: 3000,
  fetch(req) {
    return new Response("Hello");
  },
});
```

## 最佳实践

- 提交锁定文件（`bun.lock` 或 `bun.lockb`）以进行可重现安装。
- 对脚本优先使用 `bun run`。对于 TypeScript，Bun 原生运行 `.ts`。
- 保持依赖项最新；Bun 和生态系统发展很快。
