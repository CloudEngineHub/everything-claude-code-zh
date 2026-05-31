# 输出（自定义事件）

输出允许子组件发射父组件可以监听的自定义事件。Angular 推荐在现代应用中使用新的 `output()` 函数。

## 基于函数的输出

使用 `output()` 函数声明输出。这返回一个 `OutputEmitterRef`。

```ts
import {Component, output} from '@angular/core';

@Component({
  selector: 'custom-slider',
  template: `<button (click)="changeValue(50)">Set to 50</button>`,
})
export class CustomSlider {
  // 无事件数据的输出
  panelClosed = output<void>();

  // 带事件数据的输出（数字）
  valueChanged = output<number>();

  changeValue(newValue: number) {
    this.valueChanged.emit(newValue);
  }
}
```

### 在模板中使用

使用圆括号 `()` 绑定到输出事件。如果事件发射数据，使用特殊的 `$event` 变量访问它。

```html
<custom-slider (panelClosed)="savePanelState()" (valueChanged)="logValue($event)" />
```

## 配置选项

`output` 函数接受一个配置对象来指定别名。

```ts
@Component({...})
export class CustomSlider {
  // 模板中事件名为 'valueChanged'，
  // 但在组件类中作为 'changed' 访问。
  changed = output<number>({ alias: 'valueChanged' });
}
```

## 编程式订阅

动态创建组件时，你可以编程式订阅输出：

```ts
const componentRef = viewContainerRef.createComponent(CustomSlider);

const subscription = componentRef.instance.valueChanged.subscribe((val) => {
  console.log('Value changed:', val);
});

// 如需手动清理（Angular 会自动清理已销毁的组件）
subscription.unsubscribe();
```

## 基于装饰器的输出（@Output）

旧版 API 使用 `@Output()` 装饰器和 `EventEmitter`。仍然受支持但不推荐在新代码中使用。

```ts
import { Component, Output, EventEmitter } from '@angular/core';

@Component({...})
export class LegacyExample {
  @Output() valueChanged = new EventEmitter<number>();

  // 带别名
  @Output('customEventName') changed = new EventEmitter<void>();
}
```

## 最佳实践

- **优先使用 `output()`**：使用基于函数的 `output()` 而不是 `@Output()` 和 `EventEmitter`。
- **命名**：使用 `camelCase` 命名输出。避免使用 `on` 前缀（例如使用 `valueChanged` 而不是 `onValueChanged`）。
- **无 DOM 冒泡**：Angular 自定义事件不会像原生事件那样在 DOM 树上冒泡。
- **避免冲突**：不要选择与原生 DOM 事件冲突的名称（如 `click` 或 `submit`）。
