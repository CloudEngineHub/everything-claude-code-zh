# 模板驱动表单

模板驱动表单使用双向数据绑定（`[(ngModel)]`）在模板中修改时更新组件中的数据模型，反之亦然。它们适用于简单表单，使用 HTML 模板中的指令管理表单状态和验证。

## 核心指令

模板驱动表单依赖 `FormsModule`，它提供以下关键指令：

- `NgModel`：协调表单元素中的值变更与数据模型（`[(ngModel)]`）。
- `NgForm`：自动创建绑定到 `<form>` 标签的顶级 `FormGroup`。
- `NgModelGroup`：创建绑定到 DOM 元素的嵌套 `FormGroup`。

## 设置

首先，将 `FormsModule` 导入组件或模块。

```ts
import {Component} from '@angular/core';
import {FormsModule} from '@angular/forms';

@Component({
  selector: 'app-user-form',
  imports: [FormsModule],
  templateUrl: './user-form.component.html',
})
export class UserForm {
  user = {name: '', role: 'Guest'};

  onSubmit() {
    console.log('Form submitted!', this.user);
  }
}
```

## 构建表单模板

### 使用 `[(ngModel)]` 双向绑定

在输入元素上使用 `[(ngModel)]`。**每个使用 `[(ngModel)]` 的元素都必须有 `name` 属性。** Angular 使用 `name` 属性向父 `NgForm` 注册控件。

```html
<form #userForm="ngForm" (ngSubmit)="onSubmit()">
  <!-- 基本输入 -->
  <div>
    <label for="name">Name:</label>
    <input type="text" id="name" required [(ngModel)]="user.name" name="name" #nameCtrl="ngModel" />
  </div>

  <!-- 选择框 -->
  <div>
    <label for="role">Role:</label>
    <select id="role" [(ngModel)]="user.role" name="role">
      <option value="Admin">Admin</option>
      <option value="Guest">Guest</option>
    </select>
  </div>

  <!-- 提交按钮（表单无效时禁用） -->
  <button type="submit" [disabled]="!userForm.form.valid">Submit</button>
</form>
```

## 表单和控件状态

Angular 根据状态自动为控件和表单应用 CSS 类：

| 状态          | 为真时的类                       | 为假时的类    |
| :------------ | :------------------------------- | :------------ |
| 已访问        | `ng-touched`                     | `ng-untouched`|
| 值已变更      | `ng-dirty`                       | `ng-pristine` |
| 值有效        | `ng-valid`                       | `ng-invalid`  |
| 表单已提交    | `ng-submitted`（仅在 `<form>` 上）| -             |

你可以使用这些类在 CSS 中提供视觉反馈：

```css
.ng-valid[required],
.ng-valid.required {
  border-left: 5px solid #42a948; /* green */
}
.ng-invalid:not(form) {
  border-left: 5px solid #a94442; /* red */
}
```

## 验证和错误消息

要条件性地显示错误消息，将 `ngModel` 指令导出到模板引用变量（如 `#nameCtrl="ngModel"`）。

```html
<input type="text" id="name" required [(ngModel)]="user.name" name="name" #nameCtrl="ngModel" />

<!-- 仅在控件无效且（已触摸或已修改）时显示错误 -->
@if (nameCtrl.invalid && (nameCtrl.dirty || nameCtrl.touched)) {
<div class="alert alert-danger">
  @if (nameCtrl.errors?.['required']) {
  <div>Name is required.</div>
  }
</div>
}
```

## 提交表单

1. 在 `<form>` 元素上使用 `(ngSubmit)` 事件。
2. 使用 `NgForm` 模板引用变量（如 `[disabled]="!userForm.form.valid"`）将提交按钮的禁用状态绑定到整体表单有效性。

## 重置表单

要以编程方式将表单重置为初始状态（清除值和验证标志），使用 `NgForm` 实例上的 `reset()` 方法。

```html
<button type="button" (click)="userForm.reset()">Reset</button>
```
