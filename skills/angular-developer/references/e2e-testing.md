# 端到端（E2E）测试

使用 E2E 测试覆盖真实浏览器中的关键用户旅程。优先使用 Angular 工作区中已配置的框架，如 Cypress 或 Playwright。

## 运行 E2E 测试

检查 `package.json` 和 `angular.json` 获取项目特定的命令。常见模式包括：

```shell
npm run e2e
pnpm e2e
ng e2e
```

当应用需要先构建或先启动时，使用现有的项目脚本，而不是创建并行的测试入口点。

## 测试结构

- 将 E2E 规格放在已配置的测试框架附近，如 `cypress/e2e/` 或 `e2e/`。
- 将可复用的登录/设置辅助函数放在框架支持目录中。
- 保持 fixture 明确且足够小，以便每个测试都能解释其依赖的用户状态。

### Cypress 示例

```typescript
describe('Login flow', () => {
  it('redirects to dashboard on valid credentials', () => {
    cy.visit('/login');
    cy.get('[data-cy=email]').type('user@example.com');
    cy.get('[data-cy=password]').type('password123');
    cy.get('[data-cy=submit]').click();
    cy.url().should('include', '/dashboard');
  });
});
```

### Playwright 示例

```typescript
import {expect, test} from '@playwright/test';

test('redirects to dashboard on valid credentials', async ({page}) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', {name: 'Sign in'}).click();
  await expect(page).toHaveURL(/dashboard/);
});
```

## 最佳实践

- 优先使用无障碍定位器（`getByRole`、`getByLabel`）或稳定的 `data-*` 属性。
- 避免依赖 CSS 类、DOM 深度或附带文本的选择器。
- 等待特定的 UI 状态、路由或网络响应，而不是任意的 sleep。
- 保持冒烟测试简短，将完整的工作流覆盖留给最高价值的路径。
