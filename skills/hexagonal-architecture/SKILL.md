---
name: hexagonal-architecture
description: 设计、实现和重构端口与适配器系统，具有清晰的域边界、依赖倒置和可测试用例编排，跨 TypeScript、Java、Kotlin 和 Go 服务。
origin: ECC
---

# 六边形架构

六边形架构（端口与适配器）使业务逻辑独立于框架、传输和持久化细节。核心应用程序依赖于抽象端口，适配器在边缘实现这些端口。

## 何时使用

- 构建新功能，其中长期可维护性和可测试性很重要。
- 重构分层或框架繁重的代码，其中域逻辑与 I/O 关注点混合。
- 支持同一用例的多个接口（HTTP、CLI、队列工作器、cron 作业）。
- 在不重写业务规则的情况下替换基础设施（数据库、外部 API、消息总线）。

当请求涉及边界、以域为中心的设计、重构紧密耦合的服务或将应用程序逻辑与特定库解耦时，使用此技能。

## 核心概念

- **域模型**：业务规则和实体/值对象。无框架导入。
- **用例（应用层）**：编排域行为和工作流步骤。
- **入站端口**：描述应用程序可以做什么的契约（命令/查询/用例接口）。
- **出站端口**：应用程序所需的依赖项契约（存储库、网关、事件发布器、时钟、UUID 等）。
- **适配器**：端口的实现（HTTP 控制器、DB 存储库、队列使用者、SDK 包装器）。
- **组合根**：将具体适配器绑定到用例的单一接线位置。

出站端口接口通常位于应用层（或仅在抽象真正是域级别时位于域中），而基础设施适配器实现它们。

依赖方向始终向内：

- 适配器 -> 应用/域
- 应用 -> 端口接口（入站/出站契约）
- 域 -> 仅域抽象（无框架或基础设施依赖）
- 域 -> 无外部内容

## 工作原理

### 步骤 1：建模用例边界

定义具有清晰输入和输出 DTO 的单个用例。将传输详细信息（Express `req`、GraphQL `context`、作业负载包装器）保持在此边界之外。

### 步骤 2：首先定义出站端口

将每个副作用识别为端口：

- 持久化（`UserRepositoryPort`）
- 外部调用（`BillingGatewayPort`）
- 横切关注点（`LoggerPort`、`ClockPort`）

端口应建模能力，而非技术。

### 步骤 3：使用纯编排实现用例

用例类/函数通过构造函数/参数接收端口。它验证应用程序级别的不变量，协调域规则，并返回纯数据结构。

### 步骤 4：在边缘构建适配器

- 入站适配器将协议输入转换为用例输入。
- 出站适配器将应用契约映射到具体 API/ORM/查询构建器。
- 映射保留在适配器中，而非用例内部。

### 步骤 5：在组合根中连接所有内容

实例化适配器，然后将其注入用例。保持此接线集中化，以避免隐藏的服务定位器行为。

### 步骤 6：按边界测试

- 使用假端口对用例进行单元测试。
- 使用真实基础设施工具对适配器进行集成测试。
- 通过入站适配器对面向用户的流程进行端到端测试。

## 架构图

```mermaid
flowchart LR
  Client["客户端 (HTTP/CLI/Worker)"] --> InboundAdapter["入站适配器"]
  InboundAdapter -->|"调用"| UseCase["用例 (应用层)"]
  UseCase -->|"使用"| OutboundPort["出站端口 (接口)"]
  OutboundAdapter["出站适配器"] -->|"实现"| OutboundPort
  OutboundAdapter --> ExternalSystem["数据库/API/队列"]
  UseCase --> DomainModel["域模型"]
```

## 建议的模块布局

使用具有显式边界的功能优先组织：

```text
src/
  features/
    orders/
      domain/
        Order.ts
        OrderPolicy.ts
      application/
        ports/
          inbound/
            CreateOrder.ts
          outbound/
            OrderRepositoryPort.ts
            PaymentGatewayPort.ts
        use-cases/
          CreateOrderUseCase.ts
      adapters/
        inbound/
          http/
            createOrderRoute.ts
        outbound/
          postgres/
            PostgresOrderRepository.ts
          stripe/
            StripePaymentGateway.ts
      composition/
        ordersContainer.ts
```

## TypeScript 示例

### 端口定义

```typescript
export interface OrderRepositoryPort {
  save(order: Order): Promise<void>;
  findById(orderId: string): Promise<Order | null>;
}

export interface PaymentGatewayPort {
  authorize(input: { orderId: string; amountCents: number }): Promise<{ authorizationId: string }>;
}
```

### 用例

```typescript
type CreateOrderInput = {
  orderId: string;
  amountCents: number;
};

type CreateOrderOutput = {
  orderId: string;
  authorizationId: string;
};

export class CreateOrderUseCase {
  constructor(
    private readonly orderRepository: OrderRepositoryPort,
    private readonly paymentGateway: PaymentGatewayPort
  ) {}

  async execute(input: CreateOrderInput): Promise<CreateOrderOutput> {
    const order = Order.create({ id: input.orderId, amountCents: input.amountCents });

    const auth = await this.paymentGateway.authorize({
      orderId: order.id,
      amountCents: order.amountCents,
    });

    // markAuthorized 返回新的 Order 实例；它不就地修改。
    const authorizedOrder = order.markAuthorized(auth.authorizationId);
    await this.orderRepository.save(authorizedOrder);

    return {
      orderId: order.id,
      authorizationId: auth.authorizationId,
    };
  }
}
```

### 出站适配器

```typescript
export class PostgresOrderRepository implements OrderRepositoryPort {
  constructor(private readonly db: SqlClient) {}

  async save(order: Order): Promise<void> {
    await this.db.query(
      "insert into orders (id, amount_cents, status, authorization_id) values ($1, $2, $3, $4)",
      [order.id, order.amountCents, order.status, order.authorizationId]
    );
  }

  async findById(orderId: string): Promise<Order | null> {
    const row = await this.db.oneOrNone("select * from orders where id = $1", [orderId]);
    return row ? Order.rehydrate(row) : null;
  }
}
```

### 组合根

```typescript
export const buildCreateOrderUseCase = (deps: { db: SqlClient; stripe: StripeClient }) => {
  const orderRepository = new PostgresOrderRepository(deps.db);
  const paymentGateway = new StripePaymentGateway(deps.stripe);

  return new CreateOrderUseCase(orderRepository, paymentGateway);
};
```

## 多语言映射

跨生态系统使用相同的边界规则；仅语法和接线样式更改。

- **TypeScript/JavaScript**
  - 端口：`application/ports/*` 作为接口/类型。
  - 用例：带有构造函数/参数注入的类/函数。
  - 适配器：`adapters/inbound/*`、`adapters/outbound/*`。
  - 组合：显式工厂/容器模块（无隐藏全局变量）。
- **Java**
  - 包：`domain`、`application.port.in`、`application.port.out`、`application.usecase`、`adapter.in`、`adapter.out`。
  - 端口：`application.port.*` 中的接口。
  - 用例：普通类（Spring `@Service` 是可选的，非必需）。
  - 组合：Spring 配置或手动接线类；保持接线在域/用例类之外。
- **Kotlin**
  - 模块/包镜像 Java 分割（`domain`、`application.port`、`application.usecase`、`adapter`）。
  - 端口：Kotlin 接口。
  - 用例：带有构造函数注入的类（Koin/Dagger/Spring/手动）。
  - 组合：模块定义或专用组合函数；避免服务定位器模式。
- **Go**
  - 包：`internal/<feature>/domain`、`application`、`ports`、`adapters/inbound`、`adapters/outbound`。
  - 端口：由消费应用包拥有的小接口。
  - 用例：带有接口字段加上显式 `New...` 构造函数的结构体。
  - 组合：在 `cmd/<app>/main.go` 中接线（或专用接线包），保持构造函数显式。

## 要避免的反模式

- 导入 ORM 模型、Web 框架类型或 SDK 客户端的域实体。
- 用例直接从 `req`、`res` 或队列元数据读取。
- 从用例返回数据库行而无需域/应用映射。
- 让适配器直接相互调用，而非通过用例端口流动。
- 将依赖接线分散在许多文件中，并带有隐藏的全局单例。

## 迁移策略

1. 选择一个垂直切片（单个端点/作业），具有频繁的变更痛苦。
2. 提取具有显式输入/输出类型的用例边界。
3. 在现有基础设周围引入出站端口。
4. 将编排逻辑从控制器/服务移动到用例。
5. 保留旧适配器，但使其委托给新用例。
6. 在新边界周围添加测试（单元 + 适配器集成）。
7. 逐片重复；避免完全重写。

### 重构现有系统

- **绞杀者方法**：保留当前端点，一次通过新端口/适配器路由一个用例。
- **无大爆炸重写**：每个功能片迁移并保留行为，使用表征测试。
- **外观优先**：在替换内部之前，将旧服务包装在出站端口后。
- **组合冻结**：早期集中接线，以便新依赖不会泄漏到域/用例层。
- **切片选择规则**：首先优先考虑高周转、低爆炸半径的流程。
- **回滚路径**：保留每个迁移切片的可逆切换或路由开关，直到生产经验证行为。

## 测试指导（相同的六边形边界）

- **域测试**：将实体/值对象作为纯业务规则测试（无模拟，无框架设置）。
- **用例单元测试**：使用出站端口的假/存根测试编排；断言业务结果和端口交互。
- **出站适配器合约测试**：在端口级别定义共享合约套件，并对每个适配器实现运行。
- **入站适配器测试**：验证协议映射（HTTP/CLI/队列负载到用例输入和输出/错误映射回协议）。
- **适配器集成测试**：针对真实基础设施（数据库/API/队列）运行序列化、架构/查询行为、重试和超时。
- **端到端测试**：通过入站适配器 -> 用例 -> 出站适配器覆盖关键用户旅程。
- **重构安全**：在提取之前添加表征测试；保持它们直到新边界行为稳定且等效。

## 最佳实践检查清单

- 域和用例层仅导入内部类型和端口。
- 每个外部依赖都由出站端口表示。
- 验证发生在边界（入站适配器 + 用例不变量）。
- 使用不可变转换（返回新值/实体而非修改共享状态）。
- 错误跨边界转换（基础设错误 -> 应用/域错误）。
- 组合根是显式的且易于审计。
- 用例可以使用端口的简单内存假进行测试。
- 重构从具有行为保留测试的单个垂直切片开始。
- 语言/框架细节保留在适配器中，永不保留在域规则中。
