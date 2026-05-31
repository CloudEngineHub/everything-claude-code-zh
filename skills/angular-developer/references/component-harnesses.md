# 使用组件测试工具（Component Harness）

组件测试工具是测试中与组件交互的标准、推荐方式。它们提供了健壮的、以用户为中心的 API，通过隔离组件内部 DOM 结构的变化，使测试更加稳定且易于阅读。

## 为什么使用测试工具？

- **健壮性**：当重构组件的内部 HTML 或 CSS 类时，测试不会中断。
- **可读性**：测试从用户视角描述交互（例如 `button.click()`、`slider.getValue()`），而不是通过 DOM 查询（`fixture.nativeElement.querySelector(...)`）。
- **可复用性**：同一个测试工具可以在单元测试和 E2E 测试中使用。

Angular Material 为其库中的每个组件都提供了测试工具。

## 在单元测试中使用测试工具

`TestbedHarnessEnvironment` 是在单元测试中使用测试工具的入口点。

### 示例：使用 `MatButtonHarness` 进行测试

```ts
import {TestbedHarnessEnvironment} from '@angular/cdk/testing/testbed';
import {MatButtonHarness} from '@angular/material/button/testing';
import {MyButtonContainerComponent} from './my-button-container.component';

describe('MyButtonContainerComponent', () => {
  let fixture: ComponentFixture<MyButtonContainerComponent>;
  let loader: HarnessLoader;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MyButtonContainerComponent, MatButtonModule],
    }).compileComponents();

    fixture = TestBed.createComponent(MyButtonContainerComponent);
    // 为组件的 fixture 创建测试工具加载器
    loader = TestbedHarnessEnvironment.loader(fixture);
  });

  it('should find a button with specific text', async () => {
    // 加载文本为 "Submit" 的 MatButton 的测试工具
    const submitButton = await loader.getHarness(MatButtonHarness.with({text: 'Submit'}));

    // 使用测试工具 API 与组件交互
    expect(await submitButton.isDisabled()).toBe(false);
    await submitButton.click();

    // ... 断言
  });
});
```

### 关键概念

1. **`HarnessLoader`**：用于查找和创建测试工具实例的对象。使用 `TestbedHarnessEnvironment.loader(fixture)` 获取组件 fixture 的加载器。

2. **`loader.getHarness(HarnessClass)`**：异步查找并返回第一个匹配组件的测试工具实例。

3. **`HarnessClass.with({ ... })`**：许多测试工具提供了静态 `with` 方法，返回 `HarnessPredicate`。这允许你根据属性（如文本、选择器或禁用状态）过滤和查找组件。始终使用此方法精确目标组件。

4. **测试工具 API**：获取测试工具实例后，使用其方法（如 `.click()`、`.getText()`、`.getValue()`）与组件交互。这些方法会自动处理等待异步操作和变更检测。
