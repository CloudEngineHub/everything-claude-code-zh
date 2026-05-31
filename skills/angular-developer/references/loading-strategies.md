# 路由加载策略

Angular 支持两种主要策略来加载路由和组件，以平衡初始加载时间和导航响应速度。

## 预加载（Eager Loading）

组件被打包到初始 JavaScript 有效载荷中，立即可用。

```ts
{ path: 'home', component: Home }
```

- **优点**：无缝切换。
- **缺点**：增加初始包大小。

## 懒加载（Lazy Loading）

组件或路由仅在用户导航到它们时加载。这会创建单独的 JavaScript "块"。

### 懒加载组件

使用 `loadComponent` 按需获取组件。

```ts
{
  path: 'admin',
  loadComponent: () => import('./admin/admin.component').then(m => m.AdminComponent)`,
}
```

### 懒加载子路由

使用 `loadChildren` 获取一组路由。

```ts
{
  path: 'settings',
  loadChildren: () => import('./settings/settings.routes'),
}
```

## 注入上下文和懒加载

加载函数在当前路由的**注入上下文**中运行。这允许你调用 `inject()` 做出上下文感知的加载决策。

```ts
{
  path: 'dashboard',
  loadComponent: () => {
    const flags = inject(FeatureFlags);
    return flags.isPremium
      ? import('./premium-dashboard')
      : import('./basic-dashboard');
  },
}
```

## 建议

- 对主要着陆页使用**预加载**。
- 对所有其他功能区域使用**懒加载**以保持初始包较小。
