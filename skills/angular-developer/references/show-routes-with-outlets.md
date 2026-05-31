# 使用 Outlet 显示路由

`RouterOutlet` 指令是一个占位符，Angular 在其中渲染当前 URL 对应的组件。

## 基本用法

在模板中包含 `<router-outlet />`。Angular 将路由组件作为紧接在 outlet 后面的兄弟元素插入。

```html
<app-header /> <router-outlet />
<!-- 路由内容出现在此处 -->
<app-footer />
```

## 嵌套 Outlet

子路由需要在父组件模板中有自己的 `<router-outlet />`。

```ts
// 父组件模板
<h1>Settings</h1>
<router-outlet /> <!-- Profile 或 Security 等子组件在此渲染 -->
```

## 命名 Outlet（辅助路由）

页面可以有多个 outlet。为 outlet 分配 `name` 以专门定位它。默认名称为 `'primary'`。

```html
<router-outlet />
<!-- 主要 -->
<router-outlet name="sidebar" />
<!-- 辅助 -->
```

在路由配置中定义 `outlet`：

```ts
{
  path: 'chat',
  component: Chat,
  outlet: 'sidebar'
}
```

## Outlet 生命周期事件

`RouterOutlet` 在组件变更时发射事件：

- `activate`：新组件实例化。
- `deactivate`：组件销毁。
- `attach` / `detach`：与 `RouteReuseStrategy` 一起使用。

```html
<router-outlet (activate)="onActivate($event)" />
```

## 通过 `routerOutletData` 传递数据

你可以使用 `routerOutletData` 输入将上下文数据传递给路由组件。组件通过 `ROUTER_OUTLET_DATA` 注入令牌以信号方式访问它。

```ts
// 在父组件中
<router-outlet [routerOutletData]="{ theme: 'dark' }" />

// 在路由组件中
outletData = inject(ROUTER_OUTLET_DATA) as Signal<{ theme: string }>;
```
