# 层级注入器

Angular 的依赖注入系统是层级的，意味着服务可以限定在应用的不同层级。

## 注入器层级类型

1. **`EnvironmentInjector` 层级**：通过引导期间的 `@Injectable({ providedIn: 'root' })` 或 `ApplicationConfig.providers` 配置。这些是全局单例。
2. **`ElementInjector` 层级**：在每个 DOM 元素处隐式创建。通过 `@Component()` 或 `@Directive()` 中的 `providers` 或 `viewProviders` 数组配置。

## 解析规则

当请求依赖时，Angular 分两个阶段解析：

1. 沿 **`ElementInjector`** 树向上搜索，从请求的组件/指令开始直到根元素。
2. 如果未找到，沿 **`EnvironmentInjector`** 树搜索，从最近的环境注入器开始直到根。
3. 如果仍未找到，抛出错误（除非标记为可选）。

## 解析修饰符

你可以使用 `inject()` 中的选项对象来改变 Angular 搜索依赖的方式：

- **`optional`**：如果依赖未找到，返回 `null` 而不是抛出错误。
- **`self`**：仅检查当前 `ElementInjector`。不向上查找父树。
- **`skipSelf`**：从父 `ElementInjector` 开始搜索，跳过当前元素。
- **`host`**：到达宿主组件的视图边界时停止搜索。

```ts
@Component({...})
export class Example {
  // 如果未找到返回 null 而不是崩溃
  optionalService = inject(MyService, { optional: true });

  // 跳过此组件的提供者，查看父级
  parentService = inject(ParentService, { skipSelf: true });
}
```

## `providers` 与 `viewProviders`

在组件级别提供服务时：

- **`providers`**：服务对组件、其视图（模板）和任何**投射内容**（`<ng-content>`）可用。
- **`viewProviders`**：服务对组件及其视图可用，但对投射内容**不可用**。用于将服务与消费者传入的内容隔离。
