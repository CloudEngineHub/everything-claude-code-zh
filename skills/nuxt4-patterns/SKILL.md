---
name: nuxt4-patterns
description: Nuxt 4 应用模式，涵盖水合安全、性能、路由规则、懒加载和使用 useFetch 和 useAsyncData 的 SSR 安全数据获取。
origin: ECC
---

# Nuxt 4 模式

在构建或调试具有 SSR、混合渲染、路由规则或页面级数据获取的 Nuxt 4 应用时使用。

## 何时使用

- 服务器 HTML 和客户端状态之间的水合不匹配
- 路由级渲染决策，如预渲染、SWR、ISR 或仅客户端部分
- 围绕懒加载、懒水合或负载大小的性能工作
- 使用 `useFetch`、`useAsyncData` 或 `$fetch` 进行页面或组件数据获取
- 与路由参数、中间件或 SSR/客户端差异相关的 Nuxt 路由问题

## 水合安全

- 保持第一次渲染确定性。不要将 `Date.now()`、`Math.random()`、仅浏览器 API 或存储读取直接放入 SSR 渲染的模板状态中。
- 当服务器无法产生相同标记时，将仅浏览器逻辑移至 `onMounted()`、`import.meta.client`、`ClientOnly` 或 `.client.vue` 组件之后。
- 使用 Nuxt 的 `useRoute()` 组合函数，而不是 `vue-router` 中的那个。
- 不要使用 `route.fullPath` 来驱动 SSR 渲染的标记。URL 片段是仅客户端的，这可能会造成水合不匹配。
- 将 `ssr: false` 视为真正仅浏览器区域的逃生舱，而不是不匹配的默认修复。

## 数据获取

- 优先使用 `await useFetch()` 进行 SSR 安全的页面和组件 API 读取。它将服务器获取的数据转发到 Nuxt 负载中，并避免在水合时再次获取。
- 当获取器不是简单的 `$fetch()` 调用、需要自定义键或组合多个异步源时使用 `useAsyncData()`。
- 为 `useAsyncData()` 提供稳定的键以进行缓存重用和可预测的刷新行为。
- 保持 `useAsyncData()` 处理程序无副作用。它们可以在 SSR 和水合期间运行。
- 对用户触发的写入或仅客户端操作使用 `$fetch()`，而不是应该从 SSR 水合的顶级页面数据。
- 对不应阻止导航的非关键数据使用 `lazy: true`、`useLazyFetch()` 或 `useLazyAsyncData()`。在 UI 中处理 `status === 'pending'`。
- 对 SEO 或首次绘制不需要的数据使用 `server: false`。
- 使用 `pick` 修剪负载大小，当深度反应性不必要时优先使用较浅的负载。

```ts
const route = useRoute()

const { data: article, status, error, refresh } = await useAsyncData(
  () => `article:${route.params.slug}`,
  () => $fetch(`/api/articles/${route.params.slug}`),
)

const { data: comments } = await useFetch(`/api/articles/${route.params.slug}/comments`, {
  lazy: true,
  server: false,
})
```

## 路由规则

优先在 `nuxt.config.ts` 中使用 `routeRules` 进行渲染和缓存策略：

```ts
export default defineNuxtConfig({
  routeRules: {
    '/': { prerender: true },
    '/products/**': { swr: 3600 },
    '/blog/**': { isr: true },
    '/admin/**': { ssr: false },
    '/api/**': { cache: { maxAge: 60 * 60 } },
  },
})
```

- `prerender`：构建时的静态 HTML
- `swr`：提供缓存内容并在后台重新验证
- `isr`：在支持的平台上进行增量静态再生成
- `ssr: false`：客户端渲染路由
- `cache` 或 `redirect`：Nitro 级响应行为

按路由组选择路由规则，而不是全局。营销页面、目录、仪表板和 API 通常需要不同的策略。

## 懒加载和性能

- Nuxt 已经按路由拆分了页面代码。在微观优化组件拆分之前保持路由边界有意义。
- 使用 `Lazy` 前缀动态导入非关键组件。
- 使用 `v-if` 有条件地渲染懒组件，以便在 UI 实际需要之前不加载块。
- 对以下内容或非关键交互 UI 使用懒水合。

```vue
<template>
  <LazyRecommendations v-if="showRecommendations" />
  <LazyProductGallery hydrate-on-visible />
</template>
```

- 对于自定义策略，使用 `defineLazyHydrationComponent()` 配合可见性或空闲策略。
- Nuxt 懒水合适用于单文件组件。将新 props 传递给懒水合组件将立即触发水合。
- 使用 `NuxtLink` 进行内部导航，以便 Nuxt 可以预取路由组件和生成的负载。

## 审查清单

- 第一次 SSR 渲染和水合的客户端渲染产生相同的标记
- 页面数据使用 `useFetch` 或 `useAsyncData`，而不是顶级 `$fetch`
- 非关键数据是懒加载的，并具有显式加载 UI
- 路由规则与页面的 SEO 和新鲜度要求匹配
- 繁重的交互式岛屿是懒加载或懒水合的
