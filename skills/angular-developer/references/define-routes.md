# 定义路由

路由是定义特定 URL 路径应渲染哪个组件的对象。

## 基本配置

在 `Routes` 数组中定义路由，并在 `appConfig` 中使用 `provideRouter` 提供。

```ts
// app.routes.ts
export const routes: Routes = [
  {path: '', component: HomePage},
  {path: 'admin', component: AdminPage},
];

// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes)],
};
```

## URL 路径

- **静态**：匹配精确字符串（如 `'admin'`）。
- **路由参数**：以冒号前缀的动态段（如 `'user/:id'`）。
- **通配符**：使用 `**` 匹配任何 URL。用于"未找到"页面。**始终放在数组末尾。**

## 匹配策略

Angular 使用**首次匹配胜出**策略。具体的路由必须放在较不具体的路由之前。

## 重定向

使用 `redirectTo` 将一个路径指向另一个路径。

```ts
{ path: 'articles', redirectTo: '/blog' },
{ path: 'blog', component: Blog },
```

## 页面标题

为路由关联标题以提高无障碍性。标题可以是静态的或动态的（通过 `ResolveFn` 或自定义 `TitleStrategy`）。

```ts
{ path: 'home', component: Home, title: 'Home Page' }
```

## 路由数据和提供者

- **静态数据**：使用 `data` 属性附加元数据。
- **路由提供者**：使用 `providers` 数组将依赖范围限定到特定路由及其子路由。

## 嵌套（子）路由

使用 `children` 属性定义子视图。父组件必须包含 `<router-outlet />`。

```ts
{
  path: 'product/:id',
  component: Product,
  children: [
    { path: 'info', component: ProductInfo },
    { path: 'reviews', component: ProductReviews },
  ],
}
```
