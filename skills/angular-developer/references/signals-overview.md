# Angular 信号概述

信号是现代 Angular 应用中响应式的基础。**信号**是一个值的包装器，当值变化时会通知感兴趣的消费者。

## 可写信号（`signal`）

使用 `signal()` 创建可以直接更新的状态。

```ts
import {signal} from '@angular/core';

// 创建可写信号
const count = signal(0);

// 读取值（始终需要调用 getter 函数）
console.log(count());

// 直接更新值
count.set(3);

// 基于先前值更新
count.update((value) => value + 1);
```

### 暴露为只读

从服务暴露状态时，最佳实践是暴露只读版本以防止外部修改。

```ts
private readonly _count = signal(0);
// 消费者可以读取，但不能调用 .set() 或 .update()
readonly count = this._count.asReadonly();
```

## 计算信号（`computed`）

使用 `computed()` 创建从其他信号派生值的只读信号。

- **惰性求值**：派生函数在计算信号被读取之前不会运行。
- **记忆化**：结果被缓存。仅当其依赖的信号之一变化时才重新计算。
- **动态依赖**：仅追踪派生过程中_实际读取_的信号。

```ts
import {signal, computed} from '@angular/core';

const count = signal(0);
const doubleCount = computed(() => count() * 2);

// doubleCount 在 count 变化时自动更新。
```

## 响应式上下文

**响应式上下文**是 Angular 监控信号读取以建立依赖的运行时状态。

Angular 在以下情况下自动进入响应式上下文：

- `computed` 信号
- `effect` 回调
- `linkedSignal` 计算
- 组件模板

### 未追踪读取（`untracked`）

如果你需要在响应式上下文中读取信号_而不_创建依赖（这样上下文不会在信号变化时重新运行），使用 `untracked()`。

```ts
import {effect, untracked} from '@angular/core';

effect(() => {
  // 此 effect 仅在 currentUser 变化时运行。
  // 不会在 counter 变化时运行，尽管此处读取了 counter。
  console.log(`User: ${currentUser()}, Count: ${untracked(counter)}`);
});
```

### 响应式上下文中的异步操作

响应式上下文仅对**同步**代码生效。`await` 之后的信号读取不会被追踪。**始终在异步边界之前读取信号。**

```ts
// 错误：theme() 未被追踪，因为它在 await 之后读取
effect(async () => {
  const data = await fetchUserData();
  console.log(theme());
});

// 正确：在 await 之前读取信号
effect(async () => {
  const currentTheme = theme();
  const data = await fetchUserData();
  console.log(currentTheme);
});
```
