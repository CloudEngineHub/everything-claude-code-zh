# 信号表单（Signal Forms）

信号表单推荐用于新表单，当目标 Angular 版本支持时。它们提供了一种使用 Angular 信号的响应式、类型安全的、模型驱动的方式来管理表单状态。

使用信号表单时，不要使用 `null` 作为任何字段的值或类型。

## 导入

你可以从 `@angular/forms/signals` 导入以下内容：

```ts
import {
  form,
  FormField,
  submit,
  // 字段状态规则
  disabled,
  hidden,
  readonly,
  debounce,
  // Schema 辅助函数
  applyWhen,
  applyEach,
  schema,
  // 自定义验证
  validate,
  validateHttp,
  validateStandardSchema,
  // 元数据
  metadata,
} from '@angular/forms/signals';
```

## 创建表单

使用 `form()` 函数配合信号模型。表单的结构直接从模型派生。

```ts
import {Component, signal} from '@angular/core';
import {form, FormField} from '@angular/forms/signals';

@Component({
  // ...
  imports: [FormField],
})
export class Example {
  // 1. 使用初始值定义模型（避免 undefined）
  userModel = signal({
    name: '', // 关键：绝不使用 null 或 undefined 作为初始值
    email: '',
    age: 0, // 数字使用 0，不是 null
    address: {
      street: '',
      city: '',
    },
    hobbies: [] as string[], // 数组使用 []，不是 null
  });

  // 错误 - 不要这样做：
  // badModel = signal({
  //   name: null,      // 错误：使用 '' 代替
  //   age: null,       // 错误：使用 0 代替
  //   items: null      // 错误：使用 [] 代替
  // });

  // 2. 创建表单
  userForm = form(this.userModel);
}
```

## 验证

从 `@angular/forms/signals` 导入验证器。

```ts
import {required, email, min, max, minLength, maxLength, pattern} from '@angular/forms/signals';
```

在传递给 `form()` 的 schema 函数中使用它们：

```ts
userForm = form(this.userModel, (schemaPath) => {
  // 必填
  required(schemaPath.name, {message: 'Name is required'});

  // 条件必填
  required(schemaPath.name, {
    when({valueOf}) {
      return valueOf(schemaPath.age) > 10;
    },
  });
  // when 仅可用于 required
  // 不要这样做：pattern(p.name, /xxx/, {when /* 错误 */)

  // 邮箱
  email(schemaPath.email, {message: 'Invalid email'});

  // 数字的 Min/Max
  min(schemaPath.age, 18);
  max(schemaPath.age, 100);

  // 字符串/数组的 MinLength/MaxLength
  minLength(schemaPath.password, 8);
  maxLength(schemaPath.description, 500);

  // 正则匹配
  pattern(schemaPath.zipCode, /^\d{5}$/);
});
```

## FieldState vs FormField：父级要求

理解 **FormField**（结构）和 **FieldState**（实际数据/信号）之间的区别很重要。

**规则**：你必须**调用**字段作为函数才能访问其状态信号（valid、touched、dirty、hidden 等）。

```ts
// f 是 FormField（结构性的）
const f = form(signal({cat: {name: 'pirojok-the-cat', age: 5}}));

f.cat.name; // FormField：你不能从这里获取标志！
f.cat.name.touched(); // 错误：touched() 在 FormField 上不存在

f.cat.name(); // FieldState：调用它可获得访问信号的权限
f.cat.name().touched(); // 正确：访问信号
f.cat().name.touched(); // 错误：f.cat() 是状态，它没有子项！
```

在模板中也类似：

```html
<!-- 错误：类型 'FormField' 上不存在属性 'hidden' -->
@if (bookingForm.hotelDetails.hidden()) { ... }

<!-- 正确：先调用它 -->
@if (bookingForm.hotelDetails().hidden()) { ... }
```

## 禁用 / 只读 / 隐藏

使用 schema 中的规则控制字段状态。

```ts
import {disabled, readonly, hidden} from '@angular/forms/signals';

userForm = form(this.userModel, (schemaPath) => {
  // 条件禁用
  disabled(schemaPath.password, ({valueOf}) => !valueOf(schemaPath.createAccount));

  // 条件隐藏（不会从模型中移除，只是标记为隐藏）
  hidden(schemaPath.shippingAddress, ({valueOf}) => valueOf(schemaPath.sameAsBilling));

  // 只读
  readonly(schemaPath.username);
});
```

## 绑定

导入 `FormField` 并使用 `[formField]` 指令。

```ts
import {FormField} from '@angular/forms/signals';
```

状态上的所有属性（如 `disabled`、`hidden`、`readonly` 和 `name`）会自动绑定。
_不要_绑定 `name` 字段。

**关键：禁止的属性**
使用 `[formField]` 时，你_不得_在模板中设置以下属性（无论是静态的还是绑定的）：

- `min`、`max`（在 schema 中使用验证器代替）
- `value`、`[value]`、`[attr.value]`（已由 `[formField]` 处理）
- `[attr.min]`、`[attr.max]`
- `[disabled]`、`[readonly]`（已由 `[formField]` 处理）

不要这样做：`<input min="1" [formField]>` 或 `<input [value]="val" [formField]>`。

```html
<!-- 输入框 -->
<input [formField]="userForm.name" />

<!-- 复选框 -->
<input type="checkbox" [formField]="userForm.isAdmin" />

<!-- 下拉选择 -->
<select [formField]="userForm.country">
  <option value="us">US</option>
</select>

<!-- userForm.name 不能为 nullable，因为 input 不接受 null -->
<input [formField]="userForm.name" />
```

## 响应式表单

**不要**从 `@angular/forms` 导入 `FormControl`、`FormGroup`、`FormArray` 或 `FormBuilder`。信号表单完全替代了这些概念。
信号表单没有 builder。

## 访问状态

表单中的每个字段都是一个返回其状态的函数。

```ts
// 通过调用来访问字段
const emailState = this.userForm.email();

// 值（WritableSignal）
const value = this.userForm().value();

// 验证状态（Signals）
const isValid = this.userForm().valid();
const isInvalid = this.userForm().invalid();
const errors = this.userForm().errors(); // 错误数组
const isPending = this.userForm().pending(); // 异步验证待处理

// 交互状态（Signals）
const isTouched = this.userForm().touched();
const isDirty = this.userForm().dirty();

// 可用性状态（Signals）
const isDisabled = this.userForm().disabled();
const isHidden = this.userForm().hidden();
const isReadonly = this.userForm().readonly();
```

重要！：确保调用字段以获取其状态。

```ts
form().invalid()
form.field().dirty()
form.field.subfield().touched()
form.a.b.c.d().value()
form.address.ssn().pending()
form().reset()

// 唯一的例外是 length：
form.children.length
form.length // 注意：没有括号！
form.client.addresses.length  // 没有 "()"

@for (income of form.addresses; track $index) {/**/}
```

## 提交

使用 `submit()` 函数。它在运行操作之前自动将所有字段标记为已触摸。

**关键**：`submit()` 的回调_必须_是 `async` 并且_必须_返回 Promise。

```ts
import { submit } from '@angular/forms/signals';

// 正确 - async 回调
onSubmit() {
  submit(this.userForm, async () => {
    // 仅在表单有效时运行
    await this.apiService.save(this.userModel());
    console.log('Saved!');
  });
}

// 错误 - 缺少 async 关键字
onSubmit() {
  submit(this.userForm, () => {  // 错误：必须是 async
    console.log('Saved!');
  });
}
```

## 处理错误

`field().errors()` 返回 ValidationError 的错误数组：

```ts
interface ValidationError {
  readonly kind: string;
  readonly message?: string;
}
```

_不要_从验证器返回 null。
当没有错误时，返回 undefined

### 上下文

传递给 `validate()`、`disabled()`、`applyWhen` 等规则的函数接受一个上下文对象。理解其结构**至关重要**：

```ts
validate(
  schemaPath.username,
  ({
    value, // Signal<T>: 字段的可写当前值
    fieldTree, // FieldTree<T>: 子字段（如果是组/数组）
    state, // FieldState<T>: 访问标志如 state.valid(), state.dirty()
    valueOf, // (path) => T: 读取其他字段的值（追踪依赖），如 valueOf(schemaPath.password)
    stateOf, // (path) => FieldState: 访问其他字段的状态（valid/dirty），如 stateOf(schemaPath.password).valid()
    pathKeys, // Signal<string[]>: 从根到此字段的路径
  }) => {
    // 错误：if (touched()) ...（touched 不在上下文中）
    // 正确：if (state.touched()) ...

    if (value() === 'admin') {
      return {kind: 'reserved', message: 'Username admin is reserved'};
    }
  },
);
```

### 重要：路径不是信号

在 `form()` 回调内部，`schemaPath` 及其子项（如 `schemaPath.user.name`）**不是**信号，也**不可调用**。

```ts
// 错误 - 这将抛出异常：
applyWhen(p.ssn, () => p.ssn().touched(), (ssnField) => { ... });

// 正确 - 使用 stateOf() 获取路径的状态：
applyWhen(p.ssn, ({ stateOf }) => stateOf(p.ssn).touched(), (ssnField) => { ... });

// 正确 - 使用 valueOf() 获取路径的值：
applyWhen(p.ssn, ({ valueOf }) => valueOf(p.ssn) !== '', (ssnField) => { ... });
```

### 多个项目

- 使用 `applyEach` 为每个项目应用规则。
- **关键**：`applyEach` 回调只接受一个参数（项目路径），不是两个：

```ts
// 正确 - 单参数
applyEach(s.items, (item) => {
  required(item.name);
});

// 错误 - 不要传递索引
applyEach(s.items, (item, index) => {
  // 错误：回调接受 1 个参数
  required(item.name);
});
```

- 在模板中使用 `@for` 遍历项目。
- 要从数组中移除项目，只需从数据中的数组移除相应项目。
- **`select` 绑定**：你可以绑定到 `<select [formField]="form.country">`。确保选项有 `value` 属性。

### 嵌套 @for 循环

**关键**：Angular 没有 `$parent`。在嵌套循环中，将外部索引存储在变量中：

```html
<!-- 错误 - $parent 不存在 -->
@for (item of form.items; track $index) { @for (option of item.options; track $index) {
<button (click)="removeOption($parent.$index, $index)">Remove</button>
<!-- 错误 -->
} }

<!-- 正确 - 使用 let 存储外部索引 -->
@for (item of form.items; track $index; let outerIndex = $index) { @for (option of item.options;
track $index) {
<button (click)="removeOption(outerIndex, $index)">Remove</button>
} }
```

### 禁用表单按钮

```html
<button [disabled]="form().invalid() || form().pending()" />
<!-- 或 -->
<button [disabled]="taxForm.invalid()" />
```

不要在 input 上使用 `[disabled]`。`[formField]` 会处理这个。
不要在 input 上使用 `[readonly]`。`[formField]` 会处理这个。
如果你需要禁用或将字段设为只读，在 schema 中使用 `disabled()` 或 `readonly()` 规则。

### 异步验证

不要使用 `validate()` 进行异步验证，而是使用 `validateAsync()`：

**关键**：

1. `params` 选项必须是返回要验证的值的函数。
2. `onError` 处理器是**必需的** - 不是可选的！

```ts
import {resource} from '@angular/core';
import {validateAsync} from '@angular/forms/signals';

userForm = form(this.userModel, (s) => {
  validateAsync(s.username, {
    // 1. 必须是函数 - params 接受上下文并返回值
    params: ({value}) => value(),

    // 2. 创建资源 - 工厂接收 Signal
    factory: (username) =>
      resource({
        params: username, // 在 resource() 中使用 'params'
        loader: async ({params: value}) => {
          await new Promise((resolve) => setTimeout(resolve, 1000));
          return value === 'taken';
        },
      }),

    // 3. 将成功映射为错误
    onSuccess: (isTaken) =>
      isTaken ? {kind: 'taken', message: 'Username is already taken'} : undefined,

    // 4. 处理错误 - 这是必需的！
    onError: () => ({kind: 'error', message: 'Validation failed'}),
  });
});
```

**错误示例：**

```ts
// 错误 - params 必须是函数
validateAsync(s.username, {
  params: s.username, // 错误：必须是 ({ value }) => value()
  // ...
});

// 错误 - 缺少 onError（它是必需的！）
validateAsync(s.username, {
  params: ({value}) => value(),
  factory: (username) =>
    resource({
      /* ... */
    }),
  onSuccess: (result) => (result ? {kind: 'error'} : undefined),
  // 错误：'onError' 缺失但是必需的！
});
```

### 使用 Resource

**关键**：在 Angular 的 `resource()` 中，使用 `params` 作为输入信号。

```ts
// 正确
resource({
  params: mySignal,
  loader: async ({params: value}) => {
    /* ... */
  },
});

// 错误
resource({
  request: mySignal, // 错误：应该是 'params'
  loader: async ({request}) => {
    /* ... */
  },
});
```

使用 `debounce()` 延迟 UI 和模型之间的同步。

```ts
import {debounce} from '@angular/forms/signals';

userForm = form(this.userModel, (s) => {
  // 延迟模型更新 300ms
  debounce(s.username, 300);
});
```

### 条件验证

```ts
form(
  data,
  (path) => {
    applyWhen(
      name,
      ({value}) => value() !== 'admin',
      (namePath) => {
        validate(namePath.last /* ... */);
        disable(namePath.last /* ... */);
      },
    );
  },
  {injector: TestBed.inject(Injector)},
);
```

`applyWhen` 传递映射到第一个参数的路径。
如果你需要父字段，只需将其传递给 `applyWhen`：

```ts
form(
  data,
  (path) => {
    applyWhen(
      cat,
      ({value}) => value().name !== 'admin',
      (catPath) => {
        require(cat.catPath /* ... */);
      },
    );
  },
  {injector: TestBed.inject(Injector)},
);
```

## 常见陷阱（不要这样做）

| 错误场景             | 错误（常见错误）                                | 正确（正确方式）                                            |
| :------------------- | :---------------------------------------------- | :---------------------------------------------------------- |
| **访问标志**         | `form.field.valid()`                            | `form.field().valid()`                                      |
| **访问值**           | `form.field.value()`                            | `form.field().value()`                                      |
| **设置值**           | `form.field.set(x)`                             | 更新模型信号：`this.model.update(...)`                       |
| **表单根标志**       | `form.invalid()`                                | `form().invalid()`                                          |
| **双重调用**         | `form.field()()`                                | `form.field().value()`                                      |
| **规则上下文**       | `({ touched }) => touched()`                    | `({ state }) => state.touched()`                            |
| **调用路径**         | `applyWhen(p.foo, () => p.foo() === 'x')`       | `applyWhen(p.foo, ({ valueOf }) => valueOf(p.foo) === 'x')` |
| **applyWhen 参数**   | `applyWhen(condition, () => {...})`             | `applyWhen(path, condition, schemaFn)` - 需要 3 个参数       |
| **数组长度**         | `form.items().length`                           | `form.items.length`（结构性的）                              |
| **多选数组**         | `<select [formField]="form.tags">` (string[])   | 数组字段使用复选框                                          |
| **readonly 属性**    | `<input readonly [formField]>`                  | 在 schema 中使用 `readonly()` 规则                           |
| **min/max 属性**     | `<input min="1" max="10">`                      | 在 schema 中使用 `min()` 和 `max()` 规则                     |
| **value 绑定**       | `<input [value]="val">`                         | 不要将 `[value]` 与 `[formField]` 一起使用                   |
| **when 选项**        | `pattern(p.x, /.../, {when: ...})`              | `when` 仅与 `required()` 一起使用                            |
| **Submit 回调**      | `submit(form, () => { ... })`                   | `submit(form, async () => { ... })`                          |
| **Async params**     | `params: s.field`                               | `params: ({ value }) => value()`                             |
| **Async onError**    | 省略 `onError`                                  | `onError` 在 `validateAsync` 中是必需的                     |
| **resource() API**   | `request: signal`                               | `params: signal`                                            |
| **applyEach 参数**   | `applyEach(s.items, (item, index) => ...)`      | `applyEach(s.items, (item) => ...)`                          |
| **嵌套 @for**        | `$parent.$index`                                | 使用 `let outerIndex = $index`                               |
| **FormState 导入**   | `import { FormState }`                          | `FormState` 不存在，使用 `FieldState`                        |
| **模型中的 Null**    | `signal({ name: null })`                        | `signal({ name: '' })` 或 `signal({ age: 0 })`              |
| **Validate 语法**    | `validate(s.field, { value } => ...)`           | `validate(s.field, ({ value }) => ...)`                      |
| **复选框数组**       | `[formField]="form.tags"` (string[])            | 复选框仅绑定到 `boolean`                                    |

## 大型表单示例

### `src/app/app.ts`

```ts
import {Component, signal, ChangeDetectionStrategy} from '@angular/core';
import {
  form,
  FormField,
  submit,
  required,
  email,
  min,
  hidden,
  applyEach,
  validate,
} from '@angular/forms/signals';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [FormField],
  templateUrl: './app.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {
  model = signal({
    personalInfo: {
      firstName: '',
      lastName: '',
      email: '',
      age: 0,
    },
    tripDetails: {
      destination: 'Mars',
      launchDate: '',
    },
    package: {
      tier: 'economy',
      extras: [] as string[],
    },
    companions: [] as Array<{name: string; relation: string}>,
  });

  bookingForm = form(this.model, (s) => {
    required(s.personalInfo.firstName, {message: 'First name is required'});
    required(s.personalInfo.lastName, {message: 'Last name is required'});
    required(s.personalInfo.email, {message: 'Email is required'});
    email(s.personalInfo.email, {message: 'Invalid email address'});
    required(s.personalInfo.age, {message: 'Age is required'});
    min(s.personalInfo.age, 18, {message: 'Must be at least 18'});

    required(s.tripDetails.destination);
    required(s.tripDetails.launchDate);
    validate(s.tripDetails.launchDate, ({value}) => {
      const date = new Date(value());
      if (isNaN(date.getTime())) return undefined;
      const today = new Date();
      if (date < today) {
        return {kind: 'pastData', message: 'Launch date must be in the future'};
      }
      return undefined;
    });

    // valueOf 用于在规则中访问其他字段的值
    hidden(s.package.extras, ({valueOf}) => valueOf(s.package.tier) === 'economy');

    applyEach(s.companions, (companion) => {
      required(companion.name, {message: 'Companion name required'});
      required(companion.relation, {message: 'Relation required'});
    });
  });

  addCompanion() {
    this.model.update((m) => ({
      ...m,
      companions: [...m.companions, {name: '', relation: ''}],
    }));
  }

  removeCompanion(index: number) {
    this.model.update((m) => ({
      ...m,
      companions: m.companions.filter((_, i) => i !== index),
    }));
  }

  onSubmit() {
    // 关键：submit 回调必须是 async
    submit(this.bookingForm, async () => {
      console.log('Booking Confirmed:', this.model());
      // 如果需要异步操作：
      // await this.apiService.save(this.model());
    });
  }
}
```

### `src/app/app.html`

```html
<form (submit)="onSubmit(); $event.preventDefault()">
  <h1>Interstellar Booking</h1>

  <section>
    <h2>Personal Info</h2>

    <label>
      First Name
      <input [formField]="bookingForm.personalInfo.firstName" />
      @if (bookingForm.personalInfo.firstName().touched() &&
      bookingForm.personalInfo.firstName().errors().length) {
      <span>{{ bookingForm.personalInfo.firstName().errors()[0].message }}</span>
      }
    </label>

    <label>
      Last Name
      <input [formField]="bookingForm.personalInfo.lastName" />
      @if (bookingForm.personalInfo.lastName().touched() &&
      bookingForm.personalInfo.lastName().errors().length) {
      <span>{{ bookingForm.personalInfo.lastName().errors()[0].message }}</span>
      }
    </label>

    <label>
      Email
      <input type="email" [formField]="bookingForm.personalInfo.email" />
      @if (bookingForm.personalInfo.email().touched() &&
      bookingForm.personalInfo.email().errors().length) {
      <span>{{ bookingForm.personalInfo.email().errors()[0].message }}</span>
      }
    </label>

    <label>
      Age
      <input type="number" [formField]="bookingForm.personalInfo.age" />
      @if (bookingForm.personalInfo.age().touched() &&
      bookingForm.personalInfo.age().errors().length) {
      <span>{{ bookingForm.personalInfo.age().errors()[0].message }}</span>
      }
    </label>
  </section>

  <section>
    <h2>Trip Details</h2>

    <label>
      Destination
      <select [formField]="bookingForm.tripDetails.destination">
        <option value="Mars">Mars</option>
        <option value="Moon">Moon</option>
        <option value="Titan">Titan</option>
      </select>
    </label>

    <label>
      Launch Date
      <input type="date" [formField]="bookingForm.tripDetails.launchDate" />
      @if (bookingForm.tripDetails.launchDate().touched() &&
      bookingForm.tripDetails.launchDate().errors().length) {
      <span>{{ bookingForm.tripDetails.launchDate().errors()[0].message }}</span>
      }
    </label>
  </section>

  <section>
    <h2>Package</h2>

    <label>
      <input type="radio" value="economy" [formField]="bookingForm.package.tier" />
      Economy
    </label>
    <label>
      <input type="radio" value="business" [formField]="bookingForm.package.tier" />
      Business
    </label>
    <label>
      <input type="radio" value="first" [formField]="bookingForm.package.tier" />
      First Class
    </label>

    @if (!bookingForm.package.extras().hidden()) {
    <div>
      <h3>Extras</h3>
      <!-- 数组的多选必须使用 select multiple -->
      <select multiple [formField]="bookingForm.package.extras">
        <option value="wifi">WiFi</option>
        <option value="gym">Gym</option>
      </select>
    </div>
    }
  </section>

  <section>
    <h2>Companions</h2>
    <button type="button" (click)="addCompanion()">Add Companion</button>

    @for (companion of bookingForm.companions; track $index) {
    <div>
      <input [formField]="companion.name" placeholder="Name" />
      @if (companion.name().touched() && companion.name().errors().length) {
      <span>{{ companion.name().errors()[0].message }}</span>
      }

      <input [formField]="companion.relation" placeholder="Relation" />
      @if (companion.relation().touched() && companion.relation().errors().length) {
      <span>{{ companion.relation().errors()[0].message }}</span>
      }

      <button type="button" (click)="removeCompanion($index)">Remove</button>
    </div>
    }
  </section>

  <button [disabled]="bookingForm().invalid()">Submit</button>
</form>
```

## 从构建错误中恢复

如果遇到构建错误，以下是最常见的修复方法：

### `Property 'value' does not exist on type 'FieldTree'`

**问题**：直接在字段上访问 `.value()` 而没有先调用它。

```ts
// 错误
const val = this.form.field.value();
// 正确
const val = this.form.field().value();
```

### `Property 'set' does not exist on type 'FieldTree'`

**问题**：试图在表单树上设置值。信号表单是模型驱动的。

```ts
// 错误
this.form.address.street.set('Main St');
// 正确 - 改为更新模型信号
this.model.update((m) => ({...m, address: {...m.address, street: 'Main St'}}));
```

### `Type 'string[]' is not assignable to type 'string'`

**问题**：将 `[formField]` 绑定到数组字段时使用了单值 `<select>`。

```html
<!-- 错误 - assignees 是 string[]，select 期望 string -->
<select [formField]="form.assignees">
  ...
</select>

<!-- 正确 - 数组字段使用 select multiple -->
<select multiple [formField]="form.assignees">
  <option value="us">US</option>
</select>
```
