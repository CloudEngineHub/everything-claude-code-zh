# 注入上下文

`inject()` 函数只能在代码执行处于**注入上下文**中时使用。

## 注入上下文在哪里可用？

注入上下文在以下位置自动可用：

1. 由 DI 实例化的类的**字段初始化器**（`@Injectable`、`@Component`、`@Directive`、`@Pipe`）。
2. 由 DI 实例化的类的**构造函数**。
3. 在 `useFactory` 或 `InjectionToken` 配置中指定的**工厂函数**。
4. 由 Angular 执行的**函数式 API**（如函数式路由守卫、解析器、拦截器）。

```ts
@Component({...})
export class Example {
  // 有效：字段初始化器
  private router = inject(Router);

  constructor() {
    // 有效：构造函数
    const http = inject(HttpClient);
  }

  onClick() {
    // 无效：不是注入上下文
    // const auth = inject(AuthService);
  }
}
```

## `runInInjectionContext`

如果你需要在注入上下文中运行函数（通常用于动态组件创建或测试），使用 `runInInjectionContext`。这需要访问现有的注入器（如 `EnvironmentInjector` 或 `Injector`）。

```ts
import {Injectable, inject, EnvironmentInjector, runInInjectionContext} from '@angular/core';

@Injectable({providedIn: 'root'})
export class MyService {
  private injector = inject(EnvironmentInjector);

  doSomethingDynamic() {
    runInInjectionContext(this.injector, () => {
      // 现在可以在这里使用 inject()
      const router = inject(Router);
    });
  }
}
```

## `assertInInjectionContext`

在工具函数中使用 `assertInInjectionContext` 来保证它们从有效的上下文调用。如果不是，它会抛出清晰的错误。

```ts
import {assertInInjectionContext, inject, ElementRef} from '@angular/core';

export function injectNativeElement<T extends Element>(): T {
  assertInInjectionContext(injectNativeElement);
  return inject(ElementRef).nativeElement;
}
```
