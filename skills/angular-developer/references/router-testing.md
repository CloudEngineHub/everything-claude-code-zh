# 使用 RouterTestingHarness 进行测试

在测试涉及路由的组件时，**不要模拟 Router 或相关服务**。而是使用 `RouterTestingHarness`，它提供了一种健壮可靠的方式来在接近真实应用的环境中测试路由逻辑。

使用测试工具可以确保你在测试实际的路由器配置、守卫和解析器，从而产生更有意义的测试。

## 路由测试设置

`RouterTestingHarness` 是测试路由场景的主要工具。你还需要在 `TestBed` 配置中使用 `provideRouter` 函数提供测试路由。

### 示例设置

```ts
import {TestBed} from '@angular/core/testing';
import {provideRouter} from '@angular/router';
import {RouterTestingHarness} from '@angular/router/testing';
import {Dashboard} from './dashboard.component';
import {HeroDetail} from './hero-detail.component';

describe('Dashboard Component Routing', () => {
  let harness: RouterTestingHarness;

  beforeEach(async () => {
    // 1. 使用测试路由配置 TestBed
    await TestBed.configureTestingModule({
      providers: [
        // 使用 provideRouter 配置测试特定路由
        provideRouter([
          {path: '', component: Dashboard},
          {path: 'heroes/:id', component: HeroDetail},
        ]),
      ],
    }).compileComponents();

    // 2. 创建 RouterTestingHarness
    harness = await RouterTestingHarness.create();
  });
});
```

### 关键概念

1. **`provideRouter([...])`**：提供测试特定的路由配置。应包含被测组件正常运行所需的路由。
2. **`RouterTestingHarness.create()`**：异步创建并初始化测试工具，执行到根 URL（`/`）的初始导航。

## 编写路由测试

创建测试工具后，你可以使用它来驱动导航并对路由器和激活组件的状态进行断言。

### 示例：测试导航

```ts
it('should navigate to a hero detail when a hero is selected', async () => {
  // 1. 导航到初始组件并获取其实例
  const dashboard = await harness.navigateByUrl('/', Dashboard);

  // 假设仪表板有一个选择英雄的方法
  const heroToSelect = {id: 42, name: 'Test Hero'};
  dashboard.selectHero(heroToSelect);

  // 等待触发导航的操作后的稳定
  await harness.fixture.whenStable();

  // 2. 对 URL 进行断言
  expect(harness.router.url).toEqual('/heroes/42');

  // 3. 获取导航后的激活组件
  const heroDetail = await harness.getHarness(HeroDetail);

  // 4. 对新组件的状态进行断言
  expect(await heroDetail.componentInstance.hero.name).toBe('Test Hero');
});

it('should get the activated component directly', async () => {
  // 一步完成导航并获取组件实例
  const dashboardInstance = await harness.navigateByUrl('/', Dashboard);

  expect(dashboardInstance).toBeInstanceOf(Dashboard);
});
```

### 最佳实践

- **使用测试工具导航**：始终使用 `harness.navigateByUrl()` 模拟导航。此方法返回一个 promise，解析为激活组件的实例。
- **访问路由器状态**：使用 `harness.router` 访问实时路由器实例并对其状态进行断言（如 `harness.router.url`）。
- **获取激活组件**：使用 `harness.getHarness(ComponentType)` 获取当前激活路由组件的组件测试工具实例，或使用 `harness.routeDebugElement` 获取 `DebugElement`。
- **等待稳定**：执行导致导航的操作后，始终 `await harness.fixture.whenStable()` 确保路由完成后再进行断言。
