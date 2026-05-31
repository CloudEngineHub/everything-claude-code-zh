---
name: java-coding-standards
description: "Java 编码规范——Spring Boot 和 Quarkus 服务：命名、不可变性、Optional 用法、流、异常、泛型、CDI、响应式模式和项目布局。自动应用框架特定的约定。"
origin: ECC
---

# Java 编码规范

Spring Boot 和 Quarkus 服务中可读、可维护的 Java（17+）代码规范。

## 何时使用

- 在 Spring Boot 或 Quarkus 项目中编写或审查 Java 代码
- 强制执行命名、不可变性或异常处理约定
- 使用 record、sealed class 或模式匹配（Java 17+）
- 审查 Optional、流或泛型的使用
- 组织包结构和项目布局
- **[QUARKUS]**：使用 CDI 作用域、Panache 实体或响应式管道

## 工作原理

### 框架检测

在应用规范之前，从构建文件确定框架：

- 构建文件包含 `quarkus` → 应用 **[QUARKUS]** 约定
- 构建文件包含 `spring-boot` → 应用 **[SPRING]** 约定
- 两者均未检测到 → 仅应用共享约定

## 核心原则

- 优先清晰而非巧妙
- 默认不可变；最小化共享可变状态
- 快速失败并提供有意义的异常
- 一致的命名和包结构
- **[QUARKUS]**：优先构建时处理而非运行时处理；尽可能避免运行时反射

## 示例

以下各节展示了命名、不可变性、依赖注入、响应式代码、异常、项目布局、日志、配置和测试的具体 Spring Boot、Quarkus 和共享 Java 示例。

## 命名

```java
// 通过：类/Record：PascalCase
public class MarketService {}
public record Money(BigDecimal amount, Currency currency) {}

// 通过：方法/字段：camelCase
private final MarketRepository marketRepository;
public Market findBySlug(String slug) {}

// 通过：常量：UPPER_SNAKE_CASE
private static final int MAX_PAGE_SIZE = 100;

// 通过：[QUARKUS] JAX-RS 资源命名为 *Resource，而非 *Controller
public class MarketResource {}

// 通过：[SPRING] REST 控制器命名为 *Controller
public class MarketController {}
```

## 不可变性

```java
// 通过：优先使用 record 和 final 字段
public record MarketDto(Long id, String name, MarketStatus status) {}

public class Market {
  private final Long id;
  private final String name;
  // 仅 getter，无 setter
}

// 通过：[QUARKUS] Panache 活动记录实体使用公共字段（Quarkus 约定）
@Entity
public class Market extends PanacheEntity {
  public String name;
  public MarketStatus status;
  // Panache 在构建时生成访问器；此处公共字段是惯用写法
}

// 通过：[QUARKUS] Panache MongoDB 实体
@MongoEntity(collection = "markets")
public class Market extends PanacheMongoEntity {
  public String name;
  public MarketStatus status;
}
```

## Optional 用法

```java
// 通过：从 find* 方法返回 Optional
// [SPRING]
Optional<Market> market = marketRepository.findBySlug(slug);

// [QUARKUS] Panache
Optional<Market> market = Market.find("slug", slug).firstResultOptional();

// 通过：使用 map/flatMap 而非 get()
return market
    .map(MarketResponse::from)
    .orElseThrow(() -> new EntityNotFoundException("Market not found"));
```

## 流最佳实践

```java
// 通过：使用流进行转换，保持管道简短
List<String> names = markets.stream()
    .map(Market::name)
    .filter(Objects::nonNull)
    .toList();

// 失败：避免复杂的嵌套流；优先使用循环以提高清晰度
```

## 依赖注入

```java
// 通过：[SPRING] 构造器注入（优先于字段上的 @Autowired）
@Service
public class MarketService {
  private final MarketRepository marketRepository;

  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// 通过：[QUARKUS] 构造器注入
@ApplicationScoped
public class MarketService {
  private final MarketRepository marketRepository;

  @Inject
  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// 通过：[QUARKUS] 包私有字段注入（在 Quarkus 中可接受 — 避免代理问题）
@ApplicationScoped
public class MarketService {
  @Inject
  MarketRepository marketRepository;
}

// 失败：[SPRING] 使用 @Autowired 的字段注入
@Autowired
private MarketRepository marketRepository; // 使用构造器注入

// 失败：[QUARKUS] 需要拦截或延迟初始化时使用 @Singleton
@Singleton // 不可代理 — 改用 @ApplicationScoped
public class MarketService {}
```

## 响应式模式 [QUARKUS]

```java
// 通过：从响应式端点返回 Uni/Multi
@GET
@Path("/{slug}")
public Uni<Market> findBySlug(@PathParam("slug") String slug) {
  return Market.find("slug", slug)
      .<Market>firstResult()
      .onItem().ifNull().failWith(() -> new MarketNotFoundException(slug));
}

// 通过：非阻塞管道组合
public Uni<OrderConfirmation> placeOrder(OrderRequest req) {
  return validateOrder(req)
      .chain(valid -> persistOrder(valid))
      .chain(order -> notifyFulfillment(order));
}

// 失败：在 Uni/Multi 管道中阻塞调用
public Uni<Market> find(String slug) {
  Market m = Market.find("slug", slug).firstResult(); // 阻塞 — 破坏事件循环
  return Uni.createFrom().item(m);
}

// 失败：对共享 Uni 多次订阅
Uni<Market> shared = fetchMarket(slug);
shared.subscribe().with(m -> log(m));
shared.subscribe().with(m -> cache(m)); // 双重订阅 — 使用 Uni.memoize()
```

## 异常

- 对领域错误使用非受检异常；用上下文包装技术异常
- 创建领域特定异常（例如 `MarketNotFoundException`）
- 避免宽泛的 `catch (Exception ex)`，除非是集中重新抛出/记录日志

```java
throw new MarketNotFoundException(slug);
```

### 集中异常处理

```java
// [SPRING]
@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(MarketNotFoundException.class)
  public ResponseEntity<ErrorResponse> handle(MarketNotFoundException ex) {
    return ResponseEntity.status(404).body(ErrorResponse.from(ex));
  }
}

// [QUARKUS] 方案 A：ExceptionMapper
@Provider
public class MarketNotFoundMapper implements ExceptionMapper<MarketNotFoundException> {
  @Override
  public Response toResponse(MarketNotFoundException ex) {
    return Response.status(404).entity(ErrorResponse.from(ex)).build();
  }
}

// [QUARKUS] 方案 B：@ServerExceptionMapper（RESTEasy Reactive）
@ServerExceptionMapper
public RestResponse<ErrorResponse> handle(MarketNotFoundException ex) {
  return RestResponse.status(Status.NOT_FOUND, ErrorResponse.from(ex));
}
```

## 泛型和类型安全

- 避免原始类型；声明泛型参数
- 对可复用工具优先使用有界泛型

```java
public <T extends Identifiable> Map<Long, T> indexById(Collection<T> items) { ... }
```

## 项目结构

### [SPRING] Maven/Gradle

```
src/main/java/com/example/app/
  config/
  controller/
  service/
  repository/
  domain/
  dto/
  util/
src/main/resources/
  application.yml
src/test/java/...（镜像 main）
```

### [QUARKUS] Maven/Gradle

```
src/main/java/com/example/app/
  config/              # @ConfigMapping、@ConfigProperty bean、Producer
  resource/            # JAX-RS 资源（不是 "controller"）
  service/
  repository/          # PanacheRepository 实现（如果不使用活动记录）
  domain/              # JPA/Panache 实体、MongoDB 实体
  dto/
  util/
  mapper/              # MapStruct 映射器（如果使用）
src/main/resources/
  application.properties   # Quarkus 约定（通过 quarkus-config-yaml 支持 YAML）
  import.sql               # Hibernate 自动导入，用于开发/测试
src/test/java/...（镜像 main）
```

## 格式和风格

- 统一使用 2 或 4 个空格（按项目标准）
- 每个文件一个公共顶层类型
- 保持方法简短且专注；提取辅助方法
- 成员顺序：常量、字段、构造器、公共方法、受保护方法、私有方法

## 应避免的代码异味

- 过长的参数列表 → 使用 DTO/构建器
- 深层嵌套 → 提前返回
- 魔法数字 → 命名常量
- 静态可变状态 → 优先使用依赖注入
- 静默的 catch 块 → 记录日志并处理或重新抛出
- **[QUARKUS]**：在应该用 `@ApplicationScoped` 的地方使用 `@Singleton` — 破坏代理和拦截
- **[QUARKUS]**：混合使用 `quarkus-resteasy-reactive` 和 `quarkus-resteasy`（经典版）— 选择一个技术栈
- **[QUARKUS]**：在同一个限界上下文中混合使用 Panache 活动记录 + 仓库模式 — 选择一种

## 日志

```java
// [SPRING] SLF4J
private static final Logger log = LoggerFactory.getLogger(MarketService.class);
log.info("fetch_market slug={}", slug);
log.error("failed_fetch_market slug={}", slug, ex);

// [QUARKUS] JBoss Logging（默认，构建时零成本）
private static final Logger log = Logger.getLogger(MarketService.class);
log.infof("fetch_market slug=%s", slug);
log.errorf(ex, "failed_fetch_market slug=%s", slug);

// [QUARKUS] 替代方案：使用 @Inject 简化日志
@Inject
Logger log; // CDI 注入，作用域限定为声明类
```

## 空值处理

- 仅在不可避免时接受 `@Nullable`；否则使用 `@NonNull`
- 在输入上使用 Bean Validation（`@NotNull`、`@NotBlank`）
- **[QUARKUS]**：在 `@BeanParam`、`@RestForm` 和请求体参数上应用 `@Valid`

## 配置

```java
// [SPRING] @ConfigurationProperties
@ConfigurationProperties(prefix = "market")
public record MarketProperties(int maxPageSize, Duration cacheTtl) {}

// [QUARKUS] @ConfigMapping（类型安全，构建时验证）
@ConfigMapping(prefix = "market")
public interface MarketConfig {
  int maxPageSize();
  Duration cacheTtl();
}

// [QUARKUS] 使用 @ConfigProperty 的简单值
@ConfigProperty(name = "market.max-page-size", defaultValue = "100")
int maxPageSize;
```

## 测试期望

### 共享
- JUnit 5 + AssertJ 进行流畅断言
- Mockito 进行模拟；尽可能避免部分模拟
- 优先确定性测试；不使用隐藏的 sleep

### [SPRING]
- `@WebMvcTest` 用于控制器切片，`@DataJpaTest` 用于仓库切片
- `@SpringBootTest` 仅用于完整集成测试
- `@MockBean` 用于替换 Spring 上下文中的 bean

### [QUARKUS]
- 普通 JUnit 5 + Mockito 用于单元测试（不使用 `@QuarkusTest`）
- `@QuarkusTest` 仅用于 CDI 集成测试
- `@InjectMock` 用于在集成测试中替换 CDI bean
- Dev Services 用于数据库/Kafka/Redis — 当 Dev Services 足够时避免手动 Testcontainers 设置
- `@QuarkusTestResource` 用于自定义外部服务生命周期

```java
// [SPRING] 控制器测试
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;
}

// [QUARKUS] 集成测试
@QuarkusTest
class MarketResourceTest {
  @InjectMock
  MarketService marketService;

  @Test
  void should_return_404_when_market_not_found() {
    given().when().get("/markets/unknown").then().statusCode(404);
  }
}

// [QUARKUS] 单元测试（无 CDI，无 @QuarkusTest）
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository marketRepository;
  @InjectMocks MarketService marketService;
}
```

**记住**：保持代码有意为之、类型化且可观察。除非证明必要，否则优先优化可维护性而非微优化。
