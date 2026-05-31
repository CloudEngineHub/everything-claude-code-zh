# 组件

Angular 组件是应用的基本构建块。每个组件由一个包含行为的 TypeScript 类、一个 HTML 模板和一个 CSS 选择器组成。

## 组件定义

使用 `@Component` 装饰器定义组件的元数据。

```ts
@Component({
  selector: 'app-profile',
  template: `
    <img src="profile.jpg" alt="Profile photo" />
    <button (click)="save()">Save</button>
  `,
  styles: `
    img {
      border-radius: 50%;
    }
  `,
})
export class Profile {
  save() {
    /* ... */
  }
}
```

## 元数据选项

- `selector`：用于在模板中标识此组件的 CSS 选择器。
- `template`：内联 HTML 模板（适用于小模板）。
- `templateUrl`：外部 HTML 文件路径。
- `styles`：内联 CSS 样式。
- `styleUrl` / `styleUrls`：外部 CSS 文件路径。
- `imports`：列出此组件模板中使用的组件、指令或管道。

## 使用组件

要使用组件，将其添加到消费组件的 `imports` 数组中，并在模板中使用其选择器。

```ts
@Component({
  selector: 'app-root',
  imports: [Profile],
  template: `<app-profile />`,
})
export class App {}
```

## 模板控制流

Angular 使用内置块进行条件渲染和循环。

### 条件渲染（`@if`）

使用 `@if` 条件性地显示内容。可以包含 `@else if` 和 `@else` 块。

```html
@if (user.isAdmin) {
<admin-dashboard />
} @else if (user.isModerator) {
<mod-dashboard />
} @else {
<standard-dashboard />
}
```

**结果别名**：保存表达式的结果以供复用。

```html
@if (user.settings(); as settings) {
<p>Theme: {{ settings.theme }}</p>
}
```

### 循环（`@for`）

`@for` 块遍历集合。`track` 表达式是**必需的**，用于性能优化和 DOM 复用。

```html
<ul>
  @for (item of items(); track item.id; let i = $index, total = $count) {
  <li>{{ i + 1 }}/{{ total }}: {{ item.name }}</li>
  } @empty {
  <li>No items to display.</li>
  }
</ul>
```

**隐式变量**：`$index`、`$count`、`$first`、`$last`、`$even`、`$odd`。

### 切换内容（`@switch`）

`@switch` 块根据值渲染内容。它使用严格相等（`===`）且**没有贯穿执行**。

```html
@switch (status()) { @case ('loading') { <app-spinner /> } @case ('error') { <app-error-msg /> }
@case ('success') { <app-data-grid /> } @default {
<p>Unknown status</p>
} }
```

**穷举类型检查**：使用 `@default never;` 确保联合类型的所有情况都被处理。

```html
@switch (state) { @case ('on') { ... } @case ('off') { ... } @default never; // 如果添加了新状态如 'standby'，将报错 }
```

## 核心概念

- **宿主元素**：匹配组件选择器的 DOM 元素。
- **视图**：宿主元素内由组件模板渲染的 DOM。
- **独立组件**：默认情况下组件是独立的（自 Angular 19 起，`standalone: true` 为默认值）。对于旧版本，必须显式设置 `standalone: true`，否则组件必须属于某个 `NgModule`。
- **组件树**：Angular 应用以组件树的形式组织，每个组件可以包含子组件。
- **组件命名**：除非项目配置了该命名约定，否则不要为组件类添加 `Component` 后缀（例如 AppComponent）。
