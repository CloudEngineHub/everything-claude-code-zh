# 使用 `linkedSignal` 处理依赖状态

`linkedSignal` 函数允许你创建与其他状态内在关联的可写状态。它非常适合需要一个从输入或其他信号派生的默认值、但仍然可以被用户独立修改的状态。

如果源状态发生变化，`linkedSignal` 会重置为新的计算值。

## 基本用法

当你只需要基于源重新计算时，传递一个计算函数。`linkedSignal` 的工作方式类似 `computed`，但产生的信号是可写的（你可以对其调用 `.set()` 或 `.update()`）。

```ts
import { Component, signal, linkedSignal } from '@angular/core';

@Component({...})
export class ShippingMethodPicker {
  shippingOptions = signal(['Ground', 'Air', 'Sea']);

  // 默认选择第一个选项。
  // 如果 shippingOptions 变化，selectedOption 重置为新的第一个选项。
  selectedOption = linkedSignal(() => this.shippingOptions()[0]);

  changeShipping(index: number) {
    // 我们仍然可以手动更新此信号！
    this.selectedOption.set(this.shippingOptions()[index]);
  }
}
```

## 高级用法：考虑先前状态

有时，当源状态变化时，你想保留用户的手动选择（如果它仍然有效）。为此，使用提供 `source` 和 `computation` 的对象语法。

`computation` 函数接收源的新值和一个包含先前源值和先前 `linkedSignal` 值的 `previous` 对象。

```ts
interface ShippingMethod { id: number; name: string; }

@Component({...})
export class ShippingMethodPicker {
  shippingOptions = signal<ShippingMethod[]>([
    {id: 0, name: 'Ground'}, {id: 1, name: 'Air'}, {id: 2, name: 'Sea'}
  ]);

  selectedOption = linkedSignal<ShippingMethod[], ShippingMethod>({
    source: this.shippingOptions,
    computation: (newOptions, previous) => {
      // 如果新加载的选项仍然包含用户之前选择的选项，
      // 保持其选中状态。否则，重置为第一个选项。
      return newOptions.find(opt => opt.id === previous?.value.id) ?? newOptions[0];
    }
  });
}
```

### 何时使用 `linkedSignal` vs `computed` vs `effect`

- 使用 `computed`：当状态**严格**从其他状态派生且永远不应手动更新。
- 使用 `linkedSignal`：当状态从其他状态派生，但用户**必须**能够覆盖或手动更新它。
- **绝不要**使用 `effect` 将一个状态同步到另一个状态。这是反模式。应使用 `computed` 或 `linkedSignal` 代替。
