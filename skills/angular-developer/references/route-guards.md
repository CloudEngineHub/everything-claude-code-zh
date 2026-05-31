# 路由守卫

路由守卫控制用户是否可以导航到或离开某个路由。

## 守卫类型

- **`CanActivate`**：用户可以访问此路由吗？（如认证检查）。
- **`CanActivateChild`**：用户可以访问此路由的子路由吗？
- **`CanDeactivate`**：用户可以离开此路由吗？（如未保存更改）。
- **`CanMatch`**：此路由是否应该被考虑匹配？（如功能标志）。如果返回 `false`，路由器继续检查其他路由。

## 创建守卫

自 Angular 15 起，守卫通常是函数式的。

```ts
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isLoggedIn()) {
    return true;
  }

  // 重定向到登录页
  return router.parseUrl('/login');
};
```

## 应用守卫

将守卫作为数组添加到路由配置中。它们按顺序执行。

```ts
{
  path: 'admin',
  component: Admin,
  canActivate: [authGuard],
  canActivateChild: [adminChildGuard],
  canDeactivate: [unsavedChangesGuard]
}
```

## 返回值

- `boolean`：`true` 允许，`false` 阻止。
- `UrlTree` 或 `RedirectCommand`：重定向到不同的路由。
- `Observable` 或 `Promise`：解析为上述类型。

## 安全说明

**客户端守卫不是服务端安全的替代品。** 始终在服务器上验证权限。
