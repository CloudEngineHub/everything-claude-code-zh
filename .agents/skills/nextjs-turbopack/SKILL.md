---
name: nextjs-turbopack
description: Next.js 16+ 和 Turbopack — 增量打包、FS 缓存、开发速度，以及何时使用 Turbopack vs webpack。
---

# Next.js 和 Turbopack

Next.js 16+ 默认在本地开发中使用 Turbopack：一个用 Rust 编写的增量打包器，显著加快开发启动和热更新。

## 何时使用

- **Turbopack（默认开发）**：用于日常开发。更快的冷启动和 HMR，特别是在大型应用中。
- **Webpack（传统开发）**：仅在您遇到 Turbopack 错误或在开发中依赖仅限 webpack 的插件时使用。使用 `--webpack`（或 `--no-turbopack`，取决于您的 Next.js 版本；查看文档了解您的版本）禁用。
- **生产**：生产构建行为（`next build`）可能使用 Turbopack 或 webpack，取决于 Next.js 版本；查看您的版本的官方 Next.js 文档。

在以下情况使用：开发或调试 Next.js 16+ 应用、诊断缓慢的开发启动或 HMR，或优化生产包。

## 工作原理

- **Turbopack**：Next.js 开发的增量打包器。使用文件系统缓存，因此重启快得多（例如，在大型项目上 5-14 倍）。
- **默认开发**：从 Next.js 16 开始，`next dev` 使用 Turbopack 运行，除非被禁用。
- **文件系统缓存**：重启重用先前工作；缓存通常在 `.next` 下；基本使用无需额外配置。
- **Bundle 分析器（Next.js 16.1+）**：实验性 Bundle 分析器用于检查输出并查找繁重依赖；通过配置或实验标志启用（查看您的版本的 Next.js 文档）。

## 示例

### 命令

```bash
next dev
next build
next start
```

### 使用

运行 `next dev` 进行带有 Turbopack 的本地开发。使用 Bundle 分析器（查看 Next.js 文档）优化代码分割和修剪大型依赖。尽可能使用 App Router 和服务端组件。

## 最佳实践

- 保持在最近的 Next.js 16.x 上，以实现稳定的 Turbopack 和缓存行为。
- 如果开发缓慢，确保您在 Turbopack（默认）上，并且缓存没有被不必要地清除。
- 对于生产包大小问题，使用您版本的官方 Next.js bundle 分析工具。
