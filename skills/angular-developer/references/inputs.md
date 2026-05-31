# 输入（Inputs）

输入允许数据从父组件流向子组件。Angular 推荐在现代应用中使用基于信号的 `input` API。

## 基于信号的输入

使用 `input()` 函数声明输入。这返回一个 `InputSignal`。

```ts
import {Component, input, computed} from '@angular/core';

@Component({
  selector: 'app-user',
  template: `<p>User: {{ name() }} ({{ age() }})</p>`,
})
export class User {
  // 带默认值的可选输入
  name = input('Guest');

  // 必需输入
  age = input.required<number>();

  // 输入是响应式信号
  label = computed(() => `Name: ${this.name()}`);
}
```

### 在模板中使用

```html
<app-user [name]="userName" [age]="25" />
```

## 配置选项

`input` 函数接受一个配置对象：

- **Alias**：更改模板中使用的属性名。
- **Transform**：在值到达组件之前修改它。

```ts
import { input, booleanAttribute } from '@angular/core';

@Component({...})
export class CustomButton {
  // 别名示例
  label = input('', { alias: 'btnLabel' });

  // 使用内置辅助函数的转换示例
  disabled = input(false, { transform: booleanAttribute });
}
```

## 模型输入（双向绑定）

使用 `model()` 创建支持双向数据绑定的输入。

```ts
@Component({
  selector: 'custom-counter',
  template: `<button (click)="increment()">+</button>`,
})
export class CustomCounter {
  value = model(0);

  increment() {
    this.value.update((v) => v + 1);
  }
}
```

### 使用方法

```html
<!-- 与信号的双向绑定 -->
<custom-counter [(value)]="mySignal" />

<!-- 与普通属性的双向绑定 -->
<custom-counter [(value)]="myProperty" />
```

## 基于装饰器的输入（@Input）

旧版 API 仍然受支持，但不推荐在新代码中使用。

```ts
import { Component, Input } from '@angular/core';

@Component({...})
export class Legacy {
  @Input({ required: true }) value = 0;
  @Input({ transform: trimString }) label = '';
}
```

## 最佳实践

- **优先使用信号**：使用 `input()` 而不是 `@Input()` 以获得更好的响应性和类型安全。
- **必需输入**：对必要数据使用 `input.required()` 以获得构建时错误。
- **纯转换**：确保输入转换函数是纯函数且可静态分析。
- **避免冲突**：不要使用与标准 DOM 属性冲突的输入名（如 `id`、`title`）。
