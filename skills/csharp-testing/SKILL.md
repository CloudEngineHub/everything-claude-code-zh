---
name: csharp-testing
description: 使用 xUnit、FluentAssertions、mock、集成测试和测试组织最佳实践的 C# 和 .NET 测试模式。
origin: ECC
---

# C# 测试模式

使用 xUnit、FluentAssertions 和现代测试实践的 .NET 应用程序综合测试模式。

## 何时激活

- 为 C# 代码编写新测试
- 审查测试质量和覆盖率
- 为 .NET 项目设置测试基础设施
- 调试不稳定或缓慢的测试

## 测试框架栈

| 工具 | 用途 |
|---|---|
| **xUnit** | 测试框架（.NET 推荐） |
| **FluentAssertions** | 可读的断言语法 |
| **NSubstitute** 或 **Moq** | Mock 依赖 |
| **Testcontainers** | 集成测试中的真实基础设施 |
| **WebApplicationFactory** | ASP.NET Core 集成测试 |
| **Bogus** | 真实的测试数据生成 |

## 单元测试结构

### Arrange-Act-Assert

```csharp
public sealed class OrderServiceTests
{
    private readonly IOrderRepository _repository = Substitute.For<IOrderRepository>();
    private readonly ILogger<OrderService> _logger = Substitute.For<ILogger<OrderService>>();
    private readonly OrderService _sut;

    public OrderServiceTests()
    {
        _sut = new OrderService(_repository, _logger);
    }

    [Fact]
    public async Task PlaceOrderAsync_请求有效时返回成功()
    {
        // Arrange（准备）
        var request = new CreateOrderRequest
        {
            CustomerId = "cust-123",
            Items = [new OrderItem("SKU-001", 2, 29.99m)]
        };

        // Act（执行）
        var result = await _sut.PlaceOrderAsync(request, CancellationToken.None);

        // Assert（断言）
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
        result.Value!.CustomerId.Should().Be("cust-123");
    }

    [Fact]
    public async Task PlaceOrderAsync_无商品时返回失败()
    {
        // Arrange（准备）
        var request = new CreateOrderRequest
        {
            CustomerId = "cust-123",
            Items = []
        };

        // Act（执行）
        var result = await _sut.PlaceOrderAsync(request, CancellationToken.None);

        // Assert（断言）
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain("至少一个商品");
    }
}
```

### 使用 Theory 的参数化测试

```csharp
[Theory]
[InlineData("", false)]
[InlineData("a", false)]
[InlineData("ab@c.d", false)]
[InlineData("user@example.com", true)]
[InlineData("user+tag@example.co.uk", true)]
public void IsValidEmail_返回预期结果(string email, bool expected)
{
    EmailValidator.IsValid(email).Should().Be(expected);
}

[Theory]
[MemberData(nameof(InvalidOrderCases))]
public async Task PlaceOrderAsync_拒绝无效订单(CreateOrderRequest request, string expectedError)
{
    var result = await _sut.PlaceOrderAsync(request, CancellationToken.None);

    result.IsSuccess.Should().BeFalse();
    result.Error.Should().Contain(expectedError);
}

public static TheoryData<CreateOrderRequest, string> InvalidOrderCases => new()
{
    { new() { CustomerId = "", Items = [ValidItem()] }, "CustomerId" },
    { new() { CustomerId = "c1", Items = [] }, "至少一个商品" },
    { new() { CustomerId = "c1", Items = [new("", 1, 10m)] }, "SKU" },
};
```

## 使用 NSubstitute 进行 Mock

```csharp
[Fact]
public async Task GetOrderAsync_未找到时返回Null()
{
    // Arrange（准备）
    var orderId = Guid.NewGuid();
    _repository.FindByIdAsync(orderId, Arg.Any<CancellationToken>())
        .Returns((Order?)null);

    // Act（执行）
    var result = await _sut.GetOrderAsync(orderId, CancellationToken.None);

    // Assert（断言）
    result.Should().BeNull();
}

[Fact]
public async Task PlaceOrderAsync_持久化订单()
{
    // Arrange（准备）
    var request = ValidOrderRequest();

    // Act（执行）
    await _sut.PlaceOrderAsync(request, CancellationToken.None);

    // Assert（断言）— 验证仓储被调用了
    await _repository.Received(1).AddAsync(
        Arg.Is<Order>(o => o.CustomerId == request.CustomerId),
        Arg.Any<CancellationToken>());
}
```

## ASP.NET Core 集成测试

### WebApplicationFactory 设置

```csharp
public sealed class OrderApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public OrderApiTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // 用内存数据库替换真实数据库
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb"));
            });
        }).CreateClient();
    }

    [Fact]
    public async Task GetOrder_未找到时返回404()
    {
        var response = await _client.GetAsync($"/api/orders/{Guid.NewGuid()}");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task CreateOrder_有效请求时返回201()
    {
        var request = new CreateOrderRequest
        {
            CustomerId = "cust-1",
            Items = [new("SKU-001", 1, 19.99m)]
        };

        var response = await _client.PostAsJsonAsync("/api/orders", request);

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        response.Headers.Location.Should().NotBeNull();
    }
}
```

### 使用 Testcontainers 测试

```csharp
public sealed class PostgresOrderRepositoryTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .Build();

    private AppDbContext _db = null!;

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(_postgres.GetConnectionString())
            .Options;
        _db = new AppDbContext(options);
        await _db.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        await _db.DisposeAsync();
        await _postgres.DisposeAsync();
    }

    [Fact]
    public async Task AddAsync_持久化订单()
    {
        var repo = new SqlOrderRepository(_db);
        var order = Order.Create("cust-1", [new OrderItem("SKU-001", 2, 10m)]);

        await repo.AddAsync(order, CancellationToken.None);

        var found = await repo.FindByIdAsync(order.Id, CancellationToken.None);
        found.Should().NotBeNull();
        found!.Items.Should().HaveCount(1);
    }
}
```

## 测试组织

```
tests/
  MyApp.UnitTests/
    Services/
      OrderServiceTests.cs
      PaymentServiceTests.cs
    Validators/
      EmailValidatorTests.cs
  MyApp.IntegrationTests/
    Api/
      OrderApiTests.cs
    Repositories/
      OrderRepositoryTests.cs
  MyApp.TestHelpers/
    Builders/
      OrderBuilder.cs
    Fixtures/
      DatabaseFixture.cs
```

## 测试数据构建器

```csharp
public sealed class OrderBuilder
{
    private string _customerId = "cust-default";
    private readonly List<OrderItem> _items = [new("SKU-001", 1, 10m)];

    public OrderBuilder WithCustomer(string customerId)
    {
        _customerId = customerId;
        return this;
    }

    public OrderBuilder WithItem(string sku, int quantity, decimal price)
    {
        _items.Add(new OrderItem(sku, quantity, price));
        return this;
    }

    public Order Build() => Order.Create(_customerId, _items);
}

// 在测试中使用
var order = new OrderBuilder()
    .WithCustomer("cust-vip")
    .WithItem("SKU-PREMIUM", 3, 99.99m)
    .Build();
```

## 常见反模式

| 反模式 | 修复 |
|---|---|
| 测试实现细节 | 测试行为和结果 |
| 共享可变测试状态 | 每个测试使用新实例（xUnit 通过构造函数实现） |
| 异步测试中的 `Thread.Sleep` | 使用带超时的 `Task.Delay` 或轮询辅助方法 |
| 断言 `ToString()` 输出 | 断言类型化属性 |
| 每个测试一个巨大断言 | 每个测试一个逻辑断言 |
| 测试名称描述实现 | 按行为命名：`Method_预期结果_当条件` |
| 忽略 `CancellationToken` | 始终传递并验证取消 |

## 运行测试

```bash
# 运行所有测试
dotnet test

# 带覆盖率运行
dotnet test --collect:"XPlat Code Coverage"

# 运行特定项目
dotnet test tests/MyApp.UnitTests/

# 按测试名称过滤
dotnet test --filter "FullyQualifiedName~OrderService"

# 开发期间的监视模式
dotnet watch test --project tests/MyApp.UnitTests/
```
