# 路由过渡动画

Angular 路由器支持浏览器的 **View Transitions API**，用于路由之间的平滑视觉过渡。

## 启用视图过渡

在路由器配置中添加 `withViewTransitions()`。

```ts
provideRouter(routes, withViewTransitions());
```

这是一种**渐进增强**。在不支持该 API 的浏览器中，路由器仍然可以工作，只是没有过渡动画。

## 工作原理

1. 浏览器对旧状态截图。
2. 路由器更新 DOM（激活新组件）。
3. 浏览器对新状态截图。
4. 浏览器在两个状态之间动画过渡。

## 使用 CSS 自定义

过渡在**全局 CSS 文件**中自定义（不是组件作用域的 CSS）。

使用 `::view-transition-old()` 和 `::view-transition-new()` 伪元素。

```css
/* 示例：交叉淡入 + 滑动 */
::view-transition-old(root) {
  animation: 90ms cubic-bezier(0.4, 0, 1, 1) both fade-out;
}
::view-transition-new(root) {
  animation: 210ms cubic-bezier(0, 0, 0.2, 1) 90ms both fade-in;
}
```

## 高级控制

使用 `onViewTransitionCreated` 根据导航上下文跳过过渡或自定义行为。

```ts
withViewTransitions({
  onViewTransitionCreated: ({transition, from, to}) => {
    // 对特定路由跳过动画
    if (to.url === '/no-animation') {
      transition.skipTransition();
    }
  },
});
```

## 最佳实践

- **全局样式**：始终在 `styles.css` 中定义过渡动画，以避免视图封装问题。
- **视图过渡名称**：为需要跨路由平滑过渡的元素分配唯一的 `view-transition-name`（如头部图片）。
