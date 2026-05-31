---
name: vite-patterns
description: Vite 构建工具模式，包括配置、插件、HMR、环境变量、代理设置、SSR、库模式、依赖预打包和构建优化。在处理 vite.config.ts、Vite 插件或基于 Vite 的项目时激活。
origin: ECC
---

# Vite 模式

适用于 Vite 8+ 项目的构建工具和开发服务器模式。涵盖配置、环境变量、代理设置、库模式、依赖预打包和常见生产环境陷阱。

## 何时使用

- 配置 `vite.config.ts` 或 `vite.config.js`
- 设置环境变量或 `.env` 文件
- 为 API 后端配置开发服务器代理
- 优化构建输出（分块、压缩、资产）
- 使用 `build.lib` 发布库
- 排查依赖预打包或 CJS/ESM 互操作问题
- 调试 HMR、开发服务器或构建错误
- 选择或排序 Vite 插件

## 工作原理

- **开发模式**以原生 ESM 方式提供源文件 — 无打包。转换按每个模块请求按需进行，这就是冷启动快和 HMR 精确的原因。
- **构建模式**使用 Rolldown（v7+）或 Rollup（v5-v6）为生产环境打包应用，具有 tree-shaking、代码分割和基于 Oxc 的压缩功能。
- **依赖预打包**通过 esbuild 将 CJS/UMD 依赖一次性转换为 ESM，并将结果缓存在 `node_modules/.vite` 下，后续启动跳过此工作。
- **插件**在开发和构建之间共享统一接口 — 同一个插件对象同时适用于开发服务器的按需转换和生产管道。
- **环境变量**在构建时静态内联。带 `VITE_` 前缀的变量成为包中的公共常量；所有未加前缀的变量对客户端代码不可见。

## 示例

### 配置结构

#### 基本配置

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': new URL('./src', import.meta.url).pathname },
  },
})
```

#### 条件配置

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd())   // 仅 VITE_ 前缀（安全）

  return {
    plugins: [react()],
    server: command === 'serve' ? { port: 3000 } : undefined,
    define: {
      __API_URL__: JSON.stringify(env.VITE_API_URL),
    },
  }
})
```

#### 关键配置选项

| 键 | 默认值 | 描述 |
|-----|---------|-------------|
| `root` | `'.'` | 项目根目录（`index.html` 所在位置） |
| `base` | `'/'` | 部署资产的公共基础路径 |
| `envPrefix` | `'VITE_'` | 客户端暴露的环境变量前缀 |
| `build.outDir` | `'dist'` | 输出目录 |
| `build.minify` | `'oxc'` | 压缩器（`'oxc'`、`'terser'` 或 `false`） |
| `build.sourcemap` | `false` | `true`、`'inline'` 或 `'hidden'` |

### 插件

#### 必备插件

大多数插件需求都可以通过少数维护良好的包来满足。在编写自己的插件之前先尝试这些。

| 插件 | 用途 | 何时使用 |
|--------|---------|-------------|
| `@vitejs/plugin-react-swc` | 通过 SWC 的 React HMR + Fast Refresh | React 应用的默认选择（比 Babel 变体更快） |
| `@vitejs/plugin-react` | 通过 Babel 的 React HMR + Fast Refresh | 仅在你需要 Babel 插件时使用（emotion、MobX 装饰器） |
| `@vitejs/plugin-vue` | Vue 3 SFC 支持 | Vue 应用 |
| `vite-plugin-checker` | 在工作线程中运行 `tsc` + ESLint，带 HMR 覆盖 | **任何 TypeScript 应用** — Vite 在 `vite build` 时不进行类型检查 |
| `vite-tsconfig-paths` | 遵循 `tsconfig.json` 的 `paths` 别名 | 任何时候 `tsconfig.json` 中已有别名 |
| `vite-plugin-dts` | 在库模式中生成 `.d.ts` 文件 | 发布 TypeScript 库 |
| `vite-plugin-svgr` | 将 SVG 作为 React 组件导入 | 使用 SVG 作为组件的 React 应用 |
| `rollup-plugin-visualizer` | 包树形图/旭日图报告 | 定期包大小审计（使用 `enforce: 'post'`） |
| `vite-plugin-pwa` | 零配置 PWA + Workbox | 离线可用应用 |

**关键提醒：** `vite build` 只转译而不进行类型检查。类型错误会静默发布到生产环境，除非你添加 `vite-plugin-checker` 或在 CI 中运行 `tsc --noEmit`。

#### 编写自定义插件

编写是罕见的 — 大多数需求已被现有插件覆盖。确实需要时，先在 `vite.config.ts` 中内联编写，仅在需要复用时才提取。

```typescript
// vite.config.ts — 最小内联插件
function myPlugin(): Plugin {
  return {
    name: 'my-plugin',                       // 必需，必须唯一
    enforce: 'pre',                           // 'pre' | 'post'（可选）
    apply: 'build',                           // 'build' | 'serve'（可选）
    transform(code, id) {
      if (!id.endsWith('.custom')) return
      return { code: transformCustom(code), map: null }
    },
  }
}
```

**关键钩子：** `transform`（修改源码）、`resolveId` + `load`（虚拟模块）、`transformIndexHtml`（注入 HTML）、`configureServer`（添加开发中间件）、`hotUpdate`（自定义 HMR — 在 v7+ 中替代已弃用的 `handleHotUpdate`）。

**虚拟模块**使用 `\0` 前缀约定 — `resolveId` 返回 `'\0virtual:my-id'` 使其他插件跳过它。用户代码导入 `'virtual:my-id'`。

完整的插件 API，参见 [vite.dev/guide/api-plugin](https://vite.dev/guide/api-plugin)。开发时使用 `vite-plugin-inspect` 调试转换管道。

### HMR API

框架插件（`@vitejs/plugin-react`、`@vitejs/plugin-vue` 等）自动处理 HMR。仅在构建需要在更新间持久化状态的自定义状态存储、开发工具或框架无关工具时，才直接使用 `import.meta.hot`。

```typescript
// src/store.ts — 原生模块的手动 HMR
if (import.meta.hot) {
  // 在更新间持久化状态（必须修改，绝不要重新赋值 .data）
  import.meta.hot.data.count = import.meta.hot.data.count ?? 0

  // 在模块替换前清理副作用
  import.meta.hot.dispose((data) => clearInterval(data.intervalId))

  // 接受此模块自身的更新
  import.meta.hot.accept()
}
```

所有 `import.meta.hot` 代码在生产构建中会被 tree-shaking 移除 — 无需手动移除守卫。

### 环境变量

Vite 按 `.env`、`.env.local`、`.env.[mode]`、`.env.[mode].local` 的顺序加载（后者覆盖前者）；`*.local` 文件被 gitignore，用于本地密钥。

#### 客户端访问

只有带 `VITE_` 前缀的变量会暴露给客户端代码：

```typescript
import.meta.env.VITE_API_URL   // string
import.meta.env.MODE            // 'development' | 'production' | 自定义
import.meta.env.BASE_URL        // base 配置值
import.meta.env.DEV             // boolean
import.meta.env.PROD            // boolean
import.meta.env.SSR             // boolean
```

#### 在配置中使用环境变量

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())          // 仅 VITE_ 前缀（安全）
  return {
    define: {
      __API_URL__: JSON.stringify(env.VITE_API_URL),
    },
  }
})
```

### 安全

#### `VITE_` 前缀不是安全边界

任何带 `VITE_` 前缀的变量都会在构建时**静态内联到客户端包中**。压缩、base64 编码和禁用 source map 都不能隐藏它。有决心的攻击者可以从发布的 JavaScript 中提取任何 `VITE_` 变量。

**规则：** 只有公共值（API URL、功能标志、公钥）才放在 `VITE_` 变量中。密钥（API 令牌、数据库 URL、私钥）必须存在于服务端 API 或无服务器函数之后。

#### `loadEnv('')` 陷阱

```typescript
// 错误：传递 '' 作为第三个参数会加载所有环境变量 — 包括服务端密钥 —
// 并使它们可通过 `define` 内联到客户端代码中。
const env = loadEnv(mode, process.cwd(), '')

// 正确：显式前缀列表
const env = loadEnv(mode, process.cwd(), ['VITE_', 'APP_'])
```

#### 生产环境 Source Map

生产环境的 source map 会泄露你的原始源代码。除非你上传到错误跟踪器（Sentry、Bugsnag）并在之后删除本地副本，否则禁用它们：

```typescript
build: {
  sourcemap: false,                                  // 默认 — 保持这样
}
```

#### `.gitignore` 检查清单

- `.env.local`、`.env.*.local` — 本地密钥覆盖
- `dist/` — 构建输出
- `node_modules/.vite` — 预打包缓存（过期条目导致幽灵错误）

### 服务器代理

```typescript
// vite.config.ts — server.proxy
server: {
  proxy: {
    '/foo': 'http://localhost:4567',                    // 字符串简写

    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true,                               // 虚拟主机后端需要
      rewrite: (path) => path.replace(/^\/api/, ''),
    },
  },
}
```

对于 WebSocket 代理，在路由配置中添加 `ws: true`。

### 构建优化

#### 手动分块

```typescript
// vite.config.ts — build.rolldownOptions
build: {
  rolldownOptions: {
    output: {
      // 对象形式：分组特定包
      manualChunks: {
        'react-vendor': ['react', 'react-dom'],
        'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-popover'],
      },
    },
  },
}
```

```typescript
// 函数形式：按启发式分割
manualChunks(id) {
  if (id.includes('node_modules/react')) return 'react-vendor'
  if (id.includes('node_modules')) return 'vendor'
}
```

### 性能

#### 避免桶文件

桶文件（从目录中重新导出所有内容的 `index.ts`）会强制 Vite 加载每个重新导出的文件，即使你只导入一个符号。这是官方文档标记的头号开发服务器减速问题。

```typescript
// 错误 — 导入一个工具函数会强制 Vite 加载整个桶
import { slash } from '@/utils'

// 正确 — 直接导入，只加载一个文件
import { slash } from '@/utils/slash'
```

#### 明确指定导入扩展名

每个隐式扩展名会强制最多 6 次文件系统检查（通过 `resolve.extensions`）。在大型代码库中，这会累积。

```typescript
// 错误
import Component from './Component'

// 正确
import Component from './Component.tsx'
```

缩小 `tsconfig.json` 的 `allowImportingTsExtensions` + `resolve.extensions`，仅包含你实际使用的扩展名。

#### 预热热路径路由

`server.warmup.clientFiles` 在浏览器请求之前预转换已知的热入口 — 消除大型应用上的冷加载请求瀑布。

```typescript
// vite.config.ts
server: {
  warmup: {
    clientFiles: ['./src/main.tsx', './src/routes/**/*.tsx'],
  },
}
```

#### 分析慢开发服务器

当 `vite dev` 感觉慢时，以 `vite --profile` 启动，与应用交互，然后按 `p+enter` 保存 `.cpuprofile`。加载到 [Speedscope](https://www.speedscope.app) 中查找哪些插件在消耗时间 — 通常是社区插件的 `buildStart`、`config` 或 `configResolved` 钩子。

### 库模式

发布 npm 包时，使用 `build.lib`。两个比配置细节更重要的问题：

1. **类型不会被生成** — 添加 `vite-plugin-dts` 或单独运行 `tsc --emitDeclarationOnly`。
2. **对等依赖必须外部化** — 未列出的对等依赖会被打包到你的库中，导致消费者出现重复运行时错误。

```typescript
// vite.config.ts
build: {
  lib: {
    entry: 'src/index.ts',
    formats: ['es', 'cjs'],
    fileName: (format) => `my-lib.${format}.js`,
  },
  rolldownOptions: {
    external: ['react', 'react-dom', 'react/jsx-runtime'],  // 每个对等依赖
  },
}
```

### SSR 外部化

裸 `createServer({ middlewareMode: true })` 设置是框架作者领域。大多数应用应使用 Nuxt、Remix、SvelteKit、Astro 或 TanStack Start。作为框架用户，你会在依赖项在 SSR 中出错时调整外部化配置：

```typescript
// vite.config.ts — ssr 选项
ssr: {
  external: ['node-native-package'],           // 在 SSR 包中保持为 require()
  noExternal: ['esm-only-package'],            // 强制打包到 SSR 输出（修复大多数 SSR 错误）
  target: 'node',                              // 'node' 或 'webworker'
}
```

### 依赖预打包

Vite 预打包依赖项以将 CJS/UMD 转换为 ESM 并减少请求数。

```typescript
// vite.config.ts — optimizeDeps
optimizeDeps: {
  include: [
    'lodash-es',                              // 强制预打包已知重型依赖
    'cjs-package',                            // 导致互操作问题的 CJS 依赖
    'deep-lib/components/**',                 // 深度导入的 glob 模式
  ],
  exclude: ['local-esm-package'],             // 排除的必须是有效 ESM
  force: true,                                // 忽略缓存，重新优化（临时调试）
}
```

### 常见陷阱

#### 开发与构建不匹配

开发使用 esbuild/Rolldown 进行转换；构建使用 Rolldown 进行打包。CJS 库在两者之间可能有不同表现。部署前始终用 `vite build && vite preview` 验证。

#### 部署后的过期分块

新构建产生新的分块哈希。有活跃会话的用户请求不再存在的旧文件名。Vite 没有内置解决方案。缓解措施：

- 保持旧 `dist/assets/` 文件在一个部署窗口内可用
- 在路由器中捕获动态导入错误并强制页面重新加载

#### Docker 和容器

Vite 默认绑定到 `localhost`，从容器外部无法访问：

```typescript
// vite.config.ts — Docker/容器设置
server: {
  host: true,                                  // 绑定 0.0.0.0
  hmr: { clientPort: 3000 },                   // 如果在反向代理后面
}
```

#### Monorepo 文件访问

Vite 限制文件服务到项目根目录。根目录之外的包被阻止：

```typescript
// vite.config.ts — monorepo 文件访问
server: {
  fs: {
    allow: ['..'],                             // 允许父目录（工作区根）
  },
}
```

### 反模式

```typescript
// 错误：将 envPrefix 设为 '' 会向客户端暴露所有环境变量（包括密钥）
envPrefix: ''

// 错误：假设 require() 在应用源代码中可用 — Vite 是 ESM 优先的
const lib = require('some-lib')                // 改用 import

// 错误：将每个 node_module 拆分成单独的块 — 创建数百个小文件
manualChunks(id) {
  if (id.includes('node_modules')) {
    return id.split('node_modules/')[1].split('/')[0]   // 每个包一个块
  }
}

// 错误：在库模式中未外部化对等依赖 — 导致重复运行时错误
// build.lib 没有 rolldownOptions.external

// 错误：使用已弃用的 esbuild 压缩器
build: { minify: 'esbuild' }                  // 使用 'oxc'（默认）或 'terser'

// 错误：通过重新赋值修改 import.meta.hot.data
import.meta.hot.data = { count: 0 }           // 错误：必须修改属性，不能重新赋值
import.meta.hot.data.count = 0                 // 正确
```

**流程反模式：**

- **`vite preview` 不是生产服务器** — 它是构建包的冒烟测试。将 `dist/` 部署到真正的静态主机（NGINX、Cloudflare Pages、Vercel static）或使用多阶段 Dockerfile。
- **期望 `vite build` 进行类型检查** — 它只转译。类型错误会静默发布到生产环境。添加 `vite-plugin-checker` 或在 CI 中运行 `tsc --noEmit`。
- **默认附带 `@vitejs/plugin-legacy`** — 它会使包膨胀约 40%，破坏 source map 包分析器，对 95%+ 使用现代浏览器的用户来说是不必要的。基于真实分析数据而非假设来启用它。
- **手动编写 30+ 个与 `tsconfig.json` paths 重复的 `resolve.alias` 条目** — 改用 `vite-tsconfig-paths`。在 Excalidraw 和 PostHog 中观察到此问题；新项目中避免使用。
- **在依赖变更后留下过期的 `node_modules/.vite`** — 预打包缓存导致幽灵错误。切换分支或修补依赖后清除它。

## 快速参考

| 模式 | 何时使用 |
|---------|-------------|
| `defineConfig` | 始终使用 — 提供类型推断 |
| `loadEnv(mode, root, ['VITE_'])` | 在配置中访问环境变量（显式前缀） |
| `vite-plugin-checker` | 任何 TypeScript 应用（填补类型检查空白） |
| `vite-tsconfig-paths` | 替代手动编写的 `resolve.alias` |
| `optimizeDeps.include` | 导致互操作问题的 CJS 依赖 |
| `server.proxy` | 在开发中将 API 请求路由到后端 |
| `server.host: true` | Docker、容器、远程访问 |
| `server.warmup.clientFiles` | 预转换热路径路由 |
| `build.lib` + `external` | 发布 npm 包 |
| `manualChunks`（对象） | 厂商包分割 |
| `vite --profile` | 调试慢开发服务器 |
| `vite build && vite preview` | 本地冒烟测试生产包（不是生产服务器） |

## 相关技能

- `frontend-patterns` — React 组件模式
- `docker-patterns` — 使用 Vite 的容器化开发
- `nextjs-turbopack` — Next.js 的替代打包器
