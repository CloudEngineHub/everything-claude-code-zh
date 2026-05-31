# 使用 `resource` 实现异步响应式

> [!IMPORTANT]
> `resource` API 目前在 Angular 中处于实验阶段。

`Resource` 将异步数据获取纳入 Angular 基于信号的响应式系统。当其依赖项变化时，它会执行异步加载器函数，将状态和结果作为同步信号暴露。

## 基本用法

`resource` 函数接受一个包含两个主要属性的选项对象：

1. `params`：响应式计算（如 `computed`）。当此处读取的信号变化时，资源会重新获取。
2. `loader`：基于参数获取数据的异步函数。

```ts
import { Component, resource, signal, computed } from '@angular/core';

@Component({...})
export class UserProfile {
  userId = signal('123');

  userResource = resource({
    // 响应式追踪 userId
    params: () => ({ id: this.userId() }),

    // 当参数变化时执行
    loader: async ({ params, abortSignal }) => {
      const response = await fetch(`/api/users/${params.id}`, { signal: abortSignal });
      if (!response.ok) throw new Error('Network error');
      return response.json();
    }
  });

  // 在计算信号中使用资源值
  userName = computed(() => {
    if (this.userResource.hasValue()) {
      return this.userResource.value()?.name;
    } else {
      return 'Loading...';
    }
  });
}
```

## 中止请求

如果 `params` 信号在前一个加载器仍在运行时发生变化，`Resource` 将使用提供的 `abortSignal` 尝试中止未完成的请求。**始终将 `abortSignal` 传递给你的 `fetch` 调用。**

## 重新加载数据

你可以通过调用 `.reload()` 命令式地强制资源重新运行加载器，无需参数变化。

```ts
this.userResource.reload();
```

## 资源状态信号

`Resource` 对象提供多个信号来读取其当前状态：

- `value()`：已解析的数据，或 `undefined`。
- `hasValue()`：类型守卫布尔值。如果值存在则为 `true`。
- `isLoading()`：表示加载器是否正在运行的布尔值。
- `error()`：加载器抛出的错误，或 `undefined`。
- `status()`：表示精确状态的字符串常量（`'idle'`、`'loading'`、`'resolved'`、`'error'`、`'reloading'`、`'local'`）。

## 本地变更

你可以乐观地直接更新资源的值。这会将状态更改为 `'local'`。

```ts
this.userResource.value.set({name: 'Optimistic Update'});
```

## 使用 `httpResource` 进行响应式数据获取

如果你使用 Angular 的 `HttpClient`，优先使用 `httpResource`。它是一个专用包装器，利用 Angular HTTP 栈（包括拦截器），同时提供相同的基于信号的资源 API。
