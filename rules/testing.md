# 测试要求 (Testing Requirements)

## 最低测试覆盖率: 80%

测试类型 (全部需要):
1. **单元测试 (Unit Tests)** - 单个函数、实用程序、组件
2. **集成测试 (Integration Tests)** - API 端点、数据库操作
3. **E2E 测试 (E2E Tests)** - 关键用户流程 (Playwright)

## 测试驱动开发 (Test-Driven Development)

强制性工作流:
1. 先写测试 (红)
2. 运行测试 - 它应该失败
3. 编写最小实施 (绿)
4. 运行测试 - 它应该通过
5. 重构 (改进)
6. 验证覆盖率 (80%+)

## 故障排除测试失败

1. 使用 **tdd-guide** agent
2. 检查测试隔离
3. 验证 mocks 是正确的
4. 修复实施，而不是测试 (除非测试是错误的)

## Agent 支持

- **tdd-guide** - 对于新特性主动使用，强制执行先写测试
- **e2e-runner** - Playwright E2E 测试专家
