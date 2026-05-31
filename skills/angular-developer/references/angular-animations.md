# Angular 动画

在 Angular 中为元素添加动画时，**首先分析项目的 Angular 版本**（在 `package.json` 中查看）。
对于现代应用（**Angular v20.2 及以上**），优先使用原生 CSS 配合 `animate.enter` 和 `animate.leave`。对于较旧的应用，可能需要使用已弃用的 `@angular/animations` 包。

## 1. 原生 CSS 动画（v20.2+ 推荐）

现代 Angular 提供了 `animate.enter` 和 `animate.leave`，用于在元素进入或离开 DOM 时添加动画。它们会在适当的时机应用 CSS 类。

### `animate.enter` 和 `animate.leave`

直接在元素上使用这些属性，以便在进入或离开阶段应用 CSS 类。Angular 会在动画完成时自动移除进入类。对于 `animate.leave`，Angular 会等待动画完成后再从 DOM 中移除元素。

`animate.enter` 示例：

```html
@if (isShown()) {
<div class="enter-container" animate.enter="enter-animation">
  <p>The box is entering.</p>
</div>
}
```

```css
/* 使用过渡而非关键帧时，请确保有起始样式 */
.enter-container {
  border: 1px solid #dddddd;
  margin-top: 1em;
  padding: 20px;
  font-weight: bold;
  font-size: 20px;
}
.enter-container p {
  margin: 0;
}
.enter-animation {
  animation: slide-fade 1s;
}
@keyframes slide-fade {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

_注意：`animate.leave` 可以添加到正在被移除的子元素上。_

### 事件绑定和第三方库

你可以绑定到 `(animate.enter)` 和 `(animate.leave)` 来调用函数或使用 JS 库（如 GSAP）。

```html
@if(show()) {
<div (animate.leave)="onLeave($event)">...</div>
}
```

```ts
import { AnimationCallbackEvent } from '@angular/core';

onLeave(event: AnimationCallbackEvent) {
  // 在此编写自定义动画逻辑
  // 关键：完成后必须调用 animationComplete()，以便 Angular 移除元素！
  event.animationComplete();
}
```

## 2. 高级 CSS 动画

CSS 为高级动画序列提供了强大的工具。

### 动画状态和样式

使用属性绑定切换元素的 CSS 类来触发过渡。

```html
<div [class.open]="isOpen">...</div>
```

```css
div {
  transition: height 0.3s ease-out;
  height: 100px;
}
div.open {
  height: 200px;
}
```

### 动画自动高度

你可以使用 `css-grid` 来动画过渡到自动高度。

```css
.container {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 0.3s;
}
.container.open {
  grid-template-rows: 1fr;
}
.container > div {
  overflow: hidden;
}
```

### 交错和平行动画

- **交错**：对列表中的项目使用不同值的 `animation-delay` 或 `transition-delay`。
- **平行**：在 `animation` 简写中应用多个动画（例如 `animation: rotate 3s, fade-in 2s;`）。

### 编程控制

使用标准 Web API 直接获取动画：

```ts
const animations = element.getAnimations();
animations.forEach((anim) => anim.pause());
```

## 3. 旧版动画 DSL（已弃用）

对于较旧的项目（v20.2 之前或已经大量使用 `@angular/animations` 的项目），你可以使用组件元数据 DSL。

**重要：** 不要在同一个组件中混合使用旧版动画和 `animate.enter`/`leave`。

### 设置

```ts
bootstrapApplication(App, {
  providers: [provideAnimationsAsync()],
});
```

### 定义过渡

```ts
import {signal} from '@angular/core';
import {trigger, state, style, animate, transition} from '@angular/animations';

@Component({
  animations: [
    trigger('openClose', [
      state('open', style({opacity: 1})),
      state('closed', style({opacity: 0})),
      transition('open <=> closed', [animate('0.5s')]),
    ]),
  ],
  template: `<div [@openClose]="isOpen() ? 'open' : 'closed'">...</div>`,
})
export class OpenClose {
  isOpen = signal(true);
}
```
