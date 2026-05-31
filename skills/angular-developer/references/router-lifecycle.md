# 路由器生命周期和事件

Angular 路由器通过 `Router.events` 可观察对象发射事件，允许你从头到尾追踪导航生命周期。

## 常见路由器事件（按时间顺序）

1. **`NavigationStart`**：导航开始。
2. **`RoutesRecognized`**：路由器将 URL 匹配到路由。
3. **`GuardsCheckStart` / `End`**：评估 `canActivate`、`canMatch` 等。
4. **`ResolveStart` / `End`**：数据解析阶段（通过解析器获取数据）。
5. **`NavigationEnd`**：导航成功完成。
6. **`NavigationCancel`**：导航被取消（如守卫返回 `false`）。
7. **`NavigationError`**：导航失败（如解析器中出错）。

## 订阅事件

注入 `Router` 并过滤 `events` 可观察对象。

```ts
import {Router, NavigationStart, NavigationEnd} from '@angular/router';

export class MyService {
  private router = inject(Router);

  constructor() {
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)).subscribe((event) => {
      console.log('Navigated to:', event.url);
    });
  }
}
```

## 调试

在应用引导期间启用所有路由事件的详细控制台日志。

```ts
provideRouter(routes, withDebugTracing());
```

## 常见用例

- **加载指示器**：在 `NavigationStart` 触发时显示加载动画，在 `NavigationEnd`/`Cancel`/`Error` 时隐藏。
- **分析**：通过监听 `NavigationEnd` 追踪页面浏览。
- **滚动管理**：响应 `Scroll` 事件进行自定义滚动行为。
