---
name: nextjs-turbopack
description: Next.js 16+ 和 Turbopack — 增量打包、文件系统缓存、开发速度，以及何时使用 Turbopack 与 webpack。
origin: ECC
---

# Next.js 和 Turbopack

Next.js 16+ 默认在本地开发中使用 Turbopack：一个用 Rust 编写的增量打包器，显著加快开发启动和热更新。

## 何时使用

- **Turbopack（默认开发）**：用于日常开发。更快的冷启动和 HMR，尤其是在大型应用中。
- **Webpack（旧开发）**：仅在遇到 Turbopack 错误或在开发中依赖仅限 webpack 的插件时使用。使用 `--webpack`（或 `--no-turbopack`，具体取决于您的 Next.js 版本；查看您版本的文档）禁用。
- **生产**：生产构建行为（`next build`）可能使用 Turbopack 或 webpack，具体取决于 Next.js 版本；查看官方 Next.js 文档以获取您的版本。

用于：开发或调试 Next.js 16+ 应用、诊断慢开发启动或 HMR，或优化生产包。

## 工作原理

- **Turbopack**：Next.js 开发的增量打包器。使用文件系统缓存，因此重启快得多（例如，大型项目上快 5–14 倍）。
- **开发中的默认**：从 Next.js 16 开始，`next dev` 使用 Turbopack 运行，除非禁用。
- **文件系统缓存**：重启重用以前的工作；缓存通常在 `.next` 下；基本使用不需要额外配置。
- **Bundle Analyzer（Next.js 16.1+）**：实验性 Bundle Analyzer 用于检查输出并查找繁重的依赖项；通过配置或实验标志启用（请参阅您版本的 Next.js 文档）。

## 示例

### 命令

```bash
next dev
next build
next start
```

### 使用

运行 `next dev` 使用 Turbopack 进行本地开发。使用 Bundle Analyzer（请参阅 Next.js 文档）优化代码拆分并修剪大型依赖项。尽可能使用 App Router 和服务器组件。

## 中间件文件命名

Next.js 16 引入了 `proxy.ts` 作为中间件文件名，取代了较旧的 `middleware.ts` 约定：

- **Next.js 16+**：在项目根目录使用 `proxy.ts`
- **Next.js 16 之前**：在项目根目录使用 `middleware.ts`

文件名更改与 **Next.js 版本**相关联，而不是与使用的打包器（Turbopack 或 webpack）相关。始终查看您正在审查的版本的官方文档。

**不要在 Next.js 16 项目中将 `proxy.ts` 标记为错误命名或缺少的中间件文件。** 文件是正确且有意为之。建议重命名为 `middleware.ts` 会破坏中间件执行。

参考：[Next.js proxy 文档](https://nextjs.org/docs/app/getting-started/proxy)

## 最佳实践

- 保持最新的 Next.js 16.x 以获得稳定的 Turbopack 和缓存行为。
- 如果开发缓慢，请确保您使用的是 Turbopack（默认）并且缓存没有被不必要地清除。
- 对于生产包大小问题，请使用您版本的官方 Next.js 包分析工具。
