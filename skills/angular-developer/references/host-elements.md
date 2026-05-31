# 组件宿主元素

**宿主元素**是匹配组件选择器的 DOM 元素。组件的模板在此元素内渲染。

## 绑定到宿主元素

在 `@Component` 装饰器中使用 `host` 属性来绑定属性、特性、样式和事件到宿主元素。这是**推荐的方式**，优于旧版装饰器。

```ts
@Component({
  selector: 'custom-slider',
  host: {
    'role': 'slider', // 静态特性
    '[attr.aria-valuenow]': 'value', // 特性绑定
    '[class.active]': 'isActive()', // 类绑定
    '[style.color]': 'color()', // 样式绑定
    '[tabIndex]': 'disabled ? -1 : 0', // 属性绑定
    '(keydown)': 'onKeyDown($event)', // 事件绑定
  },
})
export class CustomSlider {
  value = 0;
  disabled = false;
  isActive = signal(false);
  color = signal('blue');

  onKeyDown(event: KeyboardEvent) {
    /* ... */
  }
}
```

## 旧版装饰器

`@HostBinding` 和 `@HostListener` 为向后兼容而保留，但在新代码中应避免使用。

```ts
export class CustomSlider {
  @HostBinding('tabIndex')
  get tabIndex() {
    return this.disabled ? -1 : 0;
  }

  @HostListener('keydown', ['$event'])
  onKeyDown(event: KeyboardEvent) {
    /* ... */
  }
}
```

## 绑定冲突

如果组件（宿主绑定）和消费者（模板绑定）都绑定了同一属性：

1. **静态 vs 静态**：实例（消费者）绑定胜出。
2. **静态 vs 动态**：动态绑定胜出。
3. **动态 vs 动态**：组件的宿主绑定胜出。

## 注入宿主特性

使用 `HostAttributeToken` 配合 `inject` 函数在构造时读取宿主元素的静态特性。

```ts
import {Component, HostAttributeToken, inject} from '@angular/core';

@Component({
  selector: 'app-btn',
  template: `<ng-content />`,
})
export class AppButton {
  // 如果 'type' 缺失则抛出错误，除非使用 { optional: true } 注入
  type = inject(new HostAttributeToken('type'));
}
```

使用方法：

```html
<app-btn type="primary">Click Me</app-btn>
```
