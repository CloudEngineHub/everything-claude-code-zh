# 组件样式

Angular 组件可以定义仅应用于其模板的样式，实现封装和模块化。

## 定义样式

样式可以内联定义或在单独的文件中定义。

```ts
@Component({
  selector: 'app-photo',
  // 内联样式
  styles: `
    img {
      border-radius: 50%;
    }
  `,
  // 或外部文件
  styleUrl: 'photo.component.css',
})
export class Photo {}
```

## 视图封装

每个组件都有一个视图封装设置，决定样式的作用域方式。

| 模式                            | 行为                                                                                         |
| :------------------------------ | :------------------------------------------------------------------------------------------- |
| `Emulated`（默认）              | 使用唯一 HTML 属性将样式限定在组件内。全局样式仍可能泄漏进来。                                |
| `ShadowDom`                     | 使用浏览器原生 Shadow DOM API 完全隔离样式。                                                  |
| `None`                          | 禁用封装。组件样式变为全局样式。                                                               |
| `ExperimentalIsolatedShadowDom` | 严格保证只应用组件自身的样式。                                                                 |

### 使用方法

```ts
import { ViewEncapsulation } from '@angular/core';

@Component({
  ...,
  encapsulation: ViewEncapsulation.None,
})
export class GlobalStyled {}
```

## 特殊选择器

### `:host`

定位组件的宿主元素（匹配组件选择器的元素）。

```css
:host {
  display: block;
  border: 1px solid black;
}
```

### `:host-context()`

根据宿主元素的祖先条件定位宿主元素。

```css
/* 当任何祖先具有 'theme-dark' 类时应用样式 */
:host-context(.theme-dark) {
  background-color: #333;
}
```

### `::ng-deep`

禁用特定规则的视图封装，允许其"泄漏"到子组件中。
**注意：Angular 团队强烈不鼓励使用 `::ng-deep`。** 它仅为了向后兼容而保留。

## 模板中的样式

你可以直接在组件模板中使用 `<style>` 元素。视图封装规则仍然适用。

```html
<style>
  .dynamic-class {
    color: red;
  }
</style>
<div class="dynamic-class">Hello</div>
```

## 外部样式

在 CSS 中使用 `<link>` 或 `@import` 被视为外部样式。**外部样式不受模拟视图封装的影响。**
