# 使用 `effect` 和 `afterRenderEffect` 处理副作用

在 Angular 中，**effect** 是一种操作，当它追踪的一个或多个信号值发生变化时运行。

## 何时使用 `effect`

Effect 用于将信号状态同步到命令式的、非信号 API。

**有效用例：**

- 日志分析。
- 将状态同步到 `localStorage` 或 `sessionStorage`。
- 执行自定义渲染到 `<canvas>` 或第三方图表库。

**关键规则：不要使用 effect 传播状态。**
如果你发现自己在 effect 内部使用 `.set()` 或 `.update()` 来保持两个信号同步，你犯了一个错误。这会导致 `ExpressionChangedAfterItHasBeenChecked` 错误和无限循环。**始终使用 `computed()` 或 `linkedSignal()` 来派生状态。**

## 基本用法

Effect 在变更检测过程中异步执行。它们至少运行一次。

```ts
import { Component, signal, effect } from '@angular/core';

@Component({...})
export class Example {
  count = signal(0);

  constructor() {
    // Effect 必须在注入上下文中创建（例如构造函数）
    effect((onCleanup) => {
      console.log(`Count changed to ${this.count()}`);

      const timer = setTimeout(() => console.log('Timer finished'), 1000);

      // 清理函数在下一次执行前或销毁时运行
      onCleanup(() => clearTimeout(timer));
    });
  }
}
```

## 使用 `afterRenderEffect` 操作 DOM

标准 `effect` 在 Angular 更新 DOM _之前_ 运行。如果你需要根据信号变化手动检查或修改 DOM（例如集成第三方 UI 库），请使用 `afterRenderEffect`。

`afterRenderEffect` 在 Angular 完成 DOM 渲染后运行。

### 渲染阶段

为了防止回流（强制布局抖动），`afterRenderEffect` 强制你将 DOM 读取和写入分为特定阶段。

```ts
import { Component, afterRenderEffect, viewChild, ElementRef } from '@angular/core';

@Component({...})
export class Chart {
  canvas = viewChild.required<ElementRef>('canvas');

  constructor() {
    afterRenderEffect({
      // 1. 从 DOM 读取
      earlyRead: () => {
        return this.canvas().nativeElement.getBoundingClientRect().width;
      },
      // 2. 写入 DOM（接收上一阶段的结果）
      write: (width) => {
        // 绝不要在写入阶段读取 DOM
        setupChart(this.canvas().nativeElement, width);
      }
    });
  }
}
```

**可用阶段（按此顺序执行）：**

1. `earlyRead`
2. `write`（绝不要在这里读取）
3. `mixedReadWrite`（尽量避免）
4. `read`（绝不要在这里写入）

_注意：`afterRenderEffect` 仅在客户端运行，从不在服务端渲染（SSR）期间运行。_
