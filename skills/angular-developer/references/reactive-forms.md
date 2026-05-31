# 响应式表单

响应式表单提供了一种模型驱动的方法来处理表单输入。它们围绕可观察流构建，并提供对数据模型的同步访问，使其比模板驱动表单更具可扩展性和可测试性。

## 核心类

响应式表单使用 `@angular/forms` 中的以下基本类构建：

- `FormControl`：管理单个输入的值和有效性。
- `FormGroup`：管理一组控件（类对象结构）。
- `FormArray`：管理数字索引的控件数组。
- `FormBuilder`：提供创建控件实例的工厂方法的服务。

## 设置

将 `ReactiveFormsModule` 导入组件。

```ts
import {Component, inject} from '@angular/core';
import {ReactiveFormsModule, FormGroup, FormControl, Validators, FormBuilder} from '@angular/forms';

@Component({
  selector: 'app-profile-editor',
  imports: [ReactiveFormsModule],
  templateUrl: './profile-editor.component.html',
})
export class ProfileEditor {
  private fb = inject(FormBuilder);

  // 使用 FormBuilder 进行简洁定义
  profileForm = this.fb.group({
    firstName: ['', Validators.required],
    lastName: [''],
    address: this.fb.group({
      street: [''],
      city: [''],
    }),
    aliases: this.fb.array([this.fb.control('')]),
  });

  onSubmit() {
    console.warn(this.profileForm.value);
  }
}
```

## 模板绑定

使用指令将模型绑定到视图：

- `[formGroup]`：将 `FormGroup` 绑定到 `<form>` 或 `<div>`。
- `formControlName`：将组内命名控件绑定到输入。
- `formGroupName`：绑定嵌套的 `FormGroup`。
- `formArrayName`：绑定嵌套的 `FormArray`。
- `[formControl]`：绑定独立的 `FormControl`。

```html
<form [formGroup]="profileForm" (ngSubmit)="onSubmit()">
  <input type="text" formControlName="firstName" />

  <div formGroupName="address">
    <input type="text" formControlName="street" />
  </div>

  <div formArrayName="aliases">
    @for (alias of aliases.controls; track $index) {
    <input type="text" [formControlName]="$index" />
    }
  </div>

  <button type="submit" [disabled]="!profileForm.valid">Submit</button>
</form>
```

## 访问控件

使用 getter 方便地访问控件，特别是 `FormArray`。

```ts
get aliases() {
  return this.profileForm.get('aliases') as FormArray;
}

addAlias() {
  this.aliases.push(this.fb.control(''));
}
```

## 更新值

- `patchValue()`：仅更新指定属性。结构不匹配时静默失败。
- `setValue()`：替换整个模型。严格执行表单结构。

```ts
updateProfile() {
  this.profileForm.patchValue({
    firstName: 'Nancy',
    address: { street: '123 Drew Street' }
  });
}
```

## 统一变更事件

现代 Angular（v18+）在所有控件上提供单一的 `events` 可观察对象，用于追踪值、状态、原始、触摸、重置和提交事件。

```ts
import {ValueChangeEvent, StatusChangeEvent} from '@angular/forms';

this.profileForm.events.subscribe((event) => {
  if (event instanceof ValueChangeEvent) {
    console.log('New value:', event.value);
  }
});
```

## 手动状态管理

- `markAsTouched()` / `markAllAsTouched()`：用于在提交时显示验证错误。
- `markAsDirty()` / `markAsPristine()`：追踪值是否已被修改。
- `updateValueAndValidity()`：手动触发票值和状态的重新计算。
- 选项 `{ emitEvent: false }` 或 `{ onlySelf: true }` 可以传递给大多数方法以控制传播。
