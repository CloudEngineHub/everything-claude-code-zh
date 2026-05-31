---
description: 修复 React 构建失败（Vite、webpack、Next.js、CRA、Parcel、esbuild、Bun）— JSX/TSX 编译错误、hydration 不匹配、服务器/客户端组件边界失败、缺失类型。调用 react-build-resolver 智能体进行最小化、精准的修复。
---

# React 构建与修复

此命令调用 **react-build-resolver** 智能体，以最小化变更增量修复 React 构建错误。

## 此命令的功能

1. **检测构建系统**：识别 Vite、webpack、Next.js、CRA、Parcel、esbuild 或 Bun
2. **运行构建**：执行项目的构建脚本
3. **解析错误**：按层级分组（TypeScript / 打包器配置 / 运行时 / hydration）
4. **增量修复**：每次修复一个错误，每次变更后重新运行构建
5. **报告总结**：显示已修复和剩余问题

## 何时使用

在以下情况下使用 `/react-build`：

- `npm run build`（或 pnpm/yarn/bun 等效命令）失败
- TypeScript 或 React 升级后的 JSX/TSX 编译错误
- Next.js 运行时 hydration 不匹配错误
- App Router 中服务器/客户端组件边界错误
- 安装或升级 `react`、`react-dom`、`@types/react` 或打包器后
- 涉及 React 的缺失类型或"module not found"错误

## 范围

此命令负责 **React 构建/打包器/运行时 hydration** 失败。对于不涉及 React 的纯 TypeScript 类型错误，使用 `/build-fix`（通用）代替。

## 运行的诊断命令

```bash
# 项目构建脚本（优先）
npm run build --if-present
pnpm build 2>/dev/null
yarn build 2>/dev/null
bun run build 2>/dev/null

# 独立类型检查
npm run typecheck --if-present
tsc --noEmit -p tsconfig.json

# 打包器特定回退
next build                          # Next.js
vite build                          # Vite
react-scripts build                 # CRA
webpack --mode=production           # webpack
parcel build src/index.html         # Parcel
bun build ./src/index.tsx --outdir=dist
```

## 示例会话

````text
用户：/react-build

智能体：
# React 构建修复

## 检测到的构建系统
Vite（存在 vite.config.ts，依赖中有 @vitejs/plugin-react）

## 初始诊断

```bash
$ npm run build
> tsc -b && vite build

src/components/UserCard.tsx:1:8 - error TS6133: 'React' is declared but its value is never read.
src/components/Modal.tsx:12:15 - error TS7016: Could not find a declaration file for module 'react-portal'.
src/pages/Home.tsx:42:5 - error: 'useState' is not defined
```

发现错误：3 个

## 修复 1：旧 JSX 转换残留

文件：src/components/UserCard.tsx:1
原因：`tsconfig.json` 已使用 `"jsx": "react-jsx"`；显式的 `import React` 未使用。

```tsx
// 已移除
- import React from 'react';
```

```bash
$ npm run build
# 剩余 2 个错误
```

## 修复 2：缺失类型

文件：src/components/Modal.tsx
原因：未安装 `@types/react-portal`。

```bash
$ npm i -D @types/react-portal
added 1 package
```

```bash
$ npm run build
# 剩余 1 个错误
```

## 修复 3：缺失 hook 导入

文件：src/pages/Home.tsx
原因：引用了 `useState` 但未导入。

```tsx
- import { useEffect } from "react";
+ import { useEffect, useState } from "react";
```

```bash
$ npm run build
# 构建成功！
```

## 最终验证

```bash
$ npm run build
✓ built in 2.34s

$ npm test
✓ 47 tests passed
```

## 总结

| 指标 | 数量 |
|------|------|
| 修复的构建错误 | 3 |
| 修改的文件 | 2 |
| 添加的依赖 | 1 (@types/react-portal) |
| 剩余问题 | 0 |

构建状态：PASS: SUCCESS
````

## 常见错误修复

| 错误 | 典型修复 |
|---|---|
| `'React' is not defined` | 在 tsconfig 中设置 `"jsx": "react-jsx"`（React 17+） |
| Missing `@types/react` | `npm i -D @types/react @types/react-dom` |
| `Unexpected token '<'` | 添加 `@vitejs/plugin-react` / `babel-loader` |
| `You're importing a component that needs useState`（Next.js） | 添加 `"use client"` 或将 hook 移到客户端组件子组件 |
| `Module not found: Can't resolve 'fs'`（Next.js） | 移除 `fs` 导入或将逻辑移入服务器组件 / API 路由 |
| `Hydration failed because the initial UI does not match` | 将 `Date.now()`/`Math.random()`/`window.*` 移到 `useEffect` |
| `Invalid hook call` | 多个 React 副本 — 通过 `resolutions`/`overrides` 去重 |
| `Element type is invalid` | 默认 vs 命名导入不匹配 |

## 修复策略

1. **编译错误优先** — 代码必须能构建
2. **Hydration 错误其次** — 影响生产正确性
3. **打包器配置第三** — 恢复插件/加载器正确性
4. **每次修复一个** — 验证每次变更
5. **最小化变更** — 绝不无解释地使用 `// @ts-ignore`
6. **每次修复后重新运行** — 立即暴露新错误

## 停止条件

智能体将在以下情况停止并报告：

- 同一错误在 3 次尝试后仍然存在
- 修复引入的错误比解决的多
- 需要超出构建修复的架构变更（如重新设计 RSC 边界）
- 打包器版本不再支持已安装的 React 主版本

## 相关命令

- `/react-test` — 构建通过后运行测试
- `/react-review` — 构建成功后审查代码质量
- `/build-fix` — 通用构建修复器（非 React）
- `verification-loop` 技能 — 完整验证循环

## 相关

- 智能体：`agents/react-build-resolver.md`
- 技能：`skills/react-patterns/`、`skills/frontend-patterns/`
- 规则：`rules/react/coding-style.md`、`rules/react/patterns.md`
