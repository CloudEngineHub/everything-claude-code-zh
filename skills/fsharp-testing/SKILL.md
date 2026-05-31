---
name: fsharp-testing
description: F# 测试模式——xUnit、FsUnit、Unquote、FsCheck 基于属性的测试、集成测试和测试组织最佳实践。
origin: ECC
---

# F# 测试模式

使用 xUnit、FsUnit、Unquote、FsCheck 和现代 .NET 测试实践的全面 F# 应用测试模式。

## 何时激活

- 为 F# 代码编写新测试
- 审查测试质量和覆盖率
- 为 F# 项目设置测试基础设施
- 调试不稳定或缓慢的测试

## 测试框架栈

| 工具 | 用途 |
|---|---|
| **xUnit** | 测试框架（标准 .NET 生态选择） |
| **FsUnit.xUnit** | F# 友好的 xUnit 断言语法 |
| **Unquote** | 使用 F# 引用的断言库，提供清晰的失败消息 |
| **FsCheck.xUnit** | 与 xUnit 集成的基于属性的测试 |
| **NSubstitute** | .NET 依赖 Mock |
| **Testcontainers** | 集成测试中的真实基础设施 |
| **WebApplicationFactory** | ASP.NET Core 集成测试 |

## 使用 xUnit + FsUnit 的单元测试

### 基本测试结构

```fsharp
module OrderServiceTests

open Xunit
open FsUnit.Xunit

[<Fact>]
let ``create 将状态设置为 Pending`` () =
    let order = Order.create "cust-1" [ validItem ]
    order.Status |> should equal Pending

[<Fact>]
let ``confirm 将状态更改为 Confirmed`` () =
    let order = Order.create "cust-1" [ validItem ]
    let confirmed = Order.confirm order
    confirmed.Status |> should be (ofCase <@ Confirmed @>)
```

### 使用 Unquote 断言

Unquote 使用 F# 引用，使失败消息显示失败的完整表达式，而非仅仅"期望 X 得到 Y"。

```fsharp
module OrderValidationTests

open Xunit
open Swensen.Unquote

[<Fact>]
let ``PlaceOrder 在请求有效时返回成功`` () =
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    test <@ Result.isOk result @>

[<Fact>]
let ``订单总价汇总项目价格`` () =
    let items = [ { Sku = "A"; Quantity = 2; Price = 10m }
                  { Sku = "B"; Quantity = 1; Price = 5m } ]
    let total = Order.calculateTotal items
    test <@ total = 25m @>

[<Fact>]
let ``验证后的邮箱拒绝空输入`` () =
    let result = ValidatedEmail.create ""
    test <@ Result.isError result @>
```

### 异步测试

```fsharp
[<Fact>]
let ``PlaceOrder 在请求有效时返回成功`` () = task {
    let deps = createTestDeps ()
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }

    let! result = OrderService.placeOrder deps request

    test <@ Result.isOk result @>
}

[<Fact>]
let ``PlaceOrder 在项目为空时返回错误`` () = task {
    let deps = createTestDeps ()
    let request = { CustomerId = "cust-123"; Items = [] }

    let! result = OrderService.placeOrder deps request

    test <@ Result.isError result @>
}
```

### 使用 Theory 的参数化测试

```fsharp
[<Theory>]
[<InlineData("")>]
[<InlineData("   ")>]
let ``PlaceOrder 拒绝空的客户 ID`` (customerId: string) =
    let request = { CustomerId = customerId; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    result |> should be (ofCase <@ Error @>)

[<Theory>]
[<InlineData("", false)>]
[<InlineData("a", false)>]
[<InlineData("user@example.com", true)>]
[<InlineData("user+tag@example.co.uk", true)>]
let ``IsValidEmail 返回预期结果`` (email: string, expected: bool) =
    test <@ EmailValidator.isValid email = expected @>
```

## 使用 FsCheck 的基于属性的测试

### 使用 FsCheck.xUnit

```fsharp
open FsCheck
open FsCheck.Xunit

[<Property>]
let ``订单总价始终非负`` (items: NonEmptyList<PositiveInt * decimal>) =
    let orderItems =
        items.Get
        |> List.map (fun (qty, price) ->
            { Sku = "SKU"; Quantity = qty.Get; Price = abs price })
    let total = Order.calculateTotal orderItems
    total >= 0m

[<Property>]
let ``序列化往返`` (order: Order) =
    let json = JsonSerializer.Serialize order
    let deserialized = JsonSerializer.Deserialize<Order> json
    deserialized = order
```

### 自定义生成器

```fsharp
type OrderGenerators =
    static member ValidEmail () =
        gen {
            let! user = Gen.elements [ "alice"; "bob"; "carol" ]
            let! domain = Gen.elements [ "example.com"; "test.org" ]
            return $"{user}@{domain}"
        }
        |> Arb.fromGen

[<Property(Arbitrary = [| typeof<OrderGenerators> |])>]
let ``有效邮箱通过验证`` (email: string) =
    EmailValidator.isValid email
```

## Mock 依赖

### 函数 Stub（推荐）

```fsharp
let createTestDeps () =
    let mutable savedOrders = []
    { FindOrder = fun id -> task { return Map.tryFind id testData }
      SaveOrder = fun order -> task { savedOrders <- order :: savedOrders }
      SendNotification = fun _ -> Task.CompletedTask }

[<Fact>]
let ``PlaceOrder 保存已确认的订单`` () = task {
    let mutable saved = []
    let deps =
        { createTestDeps () with
            SaveOrder = fun order -> task { saved <- order :: saved } }

    let! _ = OrderService.placeOrder deps validRequest

    test <@ saved.Length = 1 @>
}
```

### 用于 .NET 接口的 NSubstitute

```fsharp
open NSubstitute

[<Fact>]
let ``使用正确的 ID 调用仓库`` () = task {
    let repo = Substitute.For<IOrderRepository>()
    repo.FindByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
        .Returns(Task.FromResult(Some testOrder))

    let service = OrderService(repo)
    let! _ = service.GetOrder(testOrder.Id, CancellationToken.None)

    do! repo.Received(1).FindByIdAsync(testOrder.Id, Arg.Any<CancellationToken>())
}
```

## ASP.NET Core 集成测试

```fsharp
type OrderApiTests (factory: WebApplicationFactory<Program>) =
    interface IClassFixture<WebApplicationFactory<Program>>

    let client =
        factory.WithWebHostBuilder(fun builder ->
            builder.ConfigureServices(fun services ->
                services.RemoveAll<DbContextOptions<AppDbContext>>() |> ignore
                services.AddDbContext<AppDbContext>(fun options ->
                    options.UseInMemoryDatabase("TestDb") |> ignore) |> ignore))
            .CreateClient()

    [<Fact>]
    member _.``GET 订单未找到时返回 404`` () = task {
        let! response = client.GetAsync($"/api/orders/{Guid.NewGuid()}")
        test <@ response.StatusCode = HttpStatusCode.NotFound @>
    }
```

## 测试组织

```
tests/
  MyApp.Tests/
    Unit/
      OrderServiceTests.fs
      PaymentServiceTests.fs
    Integration/
      OrderApiTests.fs
      OrderRepositoryTests.fs
    Properties/
      OrderPropertyTests.fs
    Helpers/
      TestData.fs
      TestDeps.fs
```

## 常见反模式

| 反模式 | 修复 |
|---|---|
| 测试实现细节 | 测试行为和结果 |
| 可变的共享测试状态 | 每个测试使用新状态 |
| 异步测试中的 `Thread.Sleep` | 使用带超时的 `Task.Delay` 或轮询辅助 |
| 对 `sprintf` 输出断言 | 对类型化值和模式匹配断言 |
| 忽略 `CancellationToken` | 始终传递并验证取消 |
| 跳过基于属性的测试 | 对有清晰不变量的函数使用 FsCheck |

## 相关技能

- `dotnet-patterns` - 惯用的 .NET 模式、依赖注入和架构
- `csharp-testing` - C# 测试模式（共享的基础设施如 WebApplicationFactory 和 Testcontainers 也适用于 F#）

## 运行测试

```bash
# 运行所有测试
dotnet test

# 带覆盖率运行
dotnet test --collect:"XPlat Code Coverage"

# 运行特定项目
dotnet test tests/MyApp.Tests/

# 按测试名称过滤
dotnet test --filter "FullyQualifiedName~OrderService"

# 开发期间的监听模式
dotnet watch test --project tests/MyApp.Tests/
```
