# 测试基础

本指南涵盖了编写 Angular 单元和组件测试的基本原则和实践。使用项目中已配置的测试运行器。

## 核心理念：异步优先

现代 Angular 应用通常异步调度状态变更，特别是在使用信号或无 zone 变更检测时。测试应考虑到这一点。

优先使用"操作、等待、断言"模式：

1. **操作**：更新状态或执行操作（如设置组件输入、点击按钮）。
2. **等待**：使用 `await fixture.whenStable()` 让框架处理调度的更新并渲染变更。
3. **断言**：验证结果。

### 基本测试结构示例

```ts
import {ComponentFixture, TestBed} from '@angular/core/testing';
import {MyComponent} from './my.component';

describe('MyComponent', () => {
  let component: MyComponent;
  let fixture: ComponentFixture<MyComponent>;
  let h1: HTMLElement;

  beforeEach(async () => {
    // 1. 配置测试模块
    await TestBed.configureTestingModule({
      imports: [MyComponent],
    }).compileComponents();

    // 2. 创建组件 fixture
    fixture = TestBed.createComponent(MyComponent);
    component = fixture.componentInstance;
    h1 = fixture.nativeElement.querySelector('h1');
  });

  it('should display the default title', async () => {
    // 操作：（隐式）组件以默认状态创建。
    // 等待初始数据绑定。
    await fixture.whenStable();
    // 断言初始状态。
    expect(h1.textContent).toContain('Default Title');
  });

  it('should display a different title after a change', async () => {
    // 操作：更改组件的 title 属性。
    component.title.set('New Test Title');

    // 等待异步更新完成。
    await fixture.whenStable();

    // 断言 DOM 已更新。
    expect(h1.textContent).toContain('New Test Title');
  });
});
```

## TestBed 和 ComponentFixture

- **`TestBed`**：创建测试特定 Angular 模块的主要工具。在 `beforeEach` 中使用 `TestBed.configureTestingModule({...})` 声明组件、提供服务并设置测试所需的导入。
- **`ComponentFixture`**：创建的组件实例及其环境的句柄。
  - `fixture.componentInstance`：访问组件的类实例。
  - `fixture.nativeElement`：访问组件的根 DOM 元素。
  - `fixture.debugElement`：`nativeElement` 的 Angular 特定包装器，提供更安全、平台无关的 DOM 查询方式（如 `debugElement.query(By.css('p'))`）。
