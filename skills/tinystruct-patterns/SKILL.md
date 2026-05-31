---
name: tinystruct-patterns
description: 使用 tinystruct Java 框架进行开发的专家指南。在 tinystruct 代码库或任何基于 tinystruct 构建的项目上工作时使用 — 包括创建 Application 类、@Action 映射路由、单元测试、ActionRegistry、HTTP/CLI 双模式处理、内置 HTTP 服务器、事件系统、JSON 与 Builder/Builders、使用 AbstractData 的数据库持久化、POJO 生成、Server-Sent Events (SSE)、文件上传和出站 HTTP 网络。
origin: ECC
---

# tinystruct 开发模式

使用 **tinystruct** Java 框架构建模块的架构和实现模式 — 一个轻量级、高性能的框架，将 CLI 和 HTTP 视为同等公民，不需要 `main()` 方法和最少的配置。

## 核心原则

**CLI 和 HTTP 是同等公民。** 每个用 `@Action` 标注的方法理想情况下应该可以在终端和 Web 浏览器中不加修改地运行。这种"双模式"能力是 tinystruct 的核心设计理念。

## 何时激活

### 何时使用

- 通过扩展 `AbstractApplication` 创建新的 `Application` 模块。
- 使用 `@Action` 定义路由和命令行操作。
- 通过 `Context` 处理每次请求的状态。
- 使用原生 `Builder` 和 `Builders` 组件执行 JSON 序列化。
- 通过 `AbstractData` POJO 处理数据库持久化。
- 使用 `generate` 命令从数据库表生成 POJO。
- 实现 Server-Sent Events (SSE) 用于实时推送。
- 通过 multipart 数据处理文件上传。
- 使用 `URLRequest` 和 `HTTPHandler` 发出出站 HTTP 请求。
- 在 `application.properties` 中配置数据库连接或系统设置。
- 调试路由冲突（Actions）或 CLI 参数解析。

## 工作原理

tinystruct 框架将任何用 `@Action` 标注的方法视为终端和 Web 环境的可路由端点。应用程序通过扩展 `AbstractApplication` 创建，它提供核心生命周期钩子如 `init()` 和对请求 `Context` 的访问。

路由由 `ActionRegistry` 处理，它自动将路径段映射到方法参数并注入依赖。对于仅数据服务，应使用原生 `Builder` 和 `Builders` 组件进行 JSON 序列化以保持零依赖。数据库层使用 `AbstractData` POJO 配合 XML 映射文件进行 CRUD 操作，无需外部 ORM 库。

## 示例

### 基本应用程序（MyService）
```java
public class MyService extends AbstractApplication {
    @Override
    public void init() {
        this.setTemplateRequired(false); // 对数据/API 应用禁用 .view 查找
    }

    @Override public String version() { return "1.0.0"; }

    @Action("greet")
    public String greet() {
        return "Hello from tinystruct!";
    }

    // 路径参数：GET /?q=greet/James  或  bin/dispatcher greet/James
    @Action("greet")
    public String greet(String name) {
        return "Hello, " + name + "!";
    }
}
```

### HTTP 模式消歧（login）
```java
@Action(value = "login", mode = Mode.HTTP_POST)
public String doLogin(Request<?, ?> request) throws ApplicationException {
    request.getSession().setAttribute("userId", "42");
    return "Logged in";
}
```

### 原生 JSON 数据处理（Builder + Builders）
```java
import org.tinystruct.data.component.Builder;
import org.tinystruct.data.component.Builders;

@Action("api/data")
public String getData() throws ApplicationException {
    Builders dataList = new Builders();
    Builder item = new Builder();
    item.put("id", 1);
    item.put("name", "James");
    dataList.add(item);

    Builder response = new Builder();
    response.put("status", "success");
    response.put("data", dataList);
    return response.toString(); // {"status":"success","data":[{"id":1,"name":"James"}]}
}
```

### SSE（Server-Sent Events）
```java
import org.tinystruct.http.SSEPushManager;

@Action("sse/connect")
public String connect() {
    return "{\"type\":\"connect\",\"message\":\"Connected to SSE\"}";
}

// 推送给特定客户端
String sessionId = getContext().getId();
Builder msg = new Builder();
msg.put("text", "Hello, user!");
SSEPushManager.getInstance().push(sessionId, msg);

// 广播给所有人
SSEPushManager.getInstance().broadcast(msg);
```

### 文件上传
```java
import org.tinystruct.data.FileEntity;

@Action(value = "upload", mode = Mode.HTTP_POST)
public String upload(Request<?, ?> request) throws ApplicationException {
    List<FileEntity> files = request.getAttachments();
    if (files != null) {
        for (FileEntity file : files) {
            System.out.println("已上传: " + file.getFilename());
        }
    }
    return "Upload OK";
}
```

## 配置

设置在 `src/main/resources/application.properties` 中管理。

```properties
# 数据库
driver=org.h2.Driver
database.url=jdbc:h2:~/mydb
database.user=sa
database.password=

# 服务器
default.home.page=hello
server.port=8080

# 区域设置
default.language=en_US

# 会话（集群环境使用 Redis）
# default.session.repository=org.tinystruct.http.RedisSessionRepository
# redis.host=127.0.0.1
# redis.port=6379
```

在应用程序中访问配置值：
```java
String port = this.getConfiguration("server.port");
```

## 红旗与反模式

| 症状 | 正确模式 |
|---|---|
| 导入 `com.google.gson` 或 `com.fasterxml.jackson` | 使用 `org.tinystruct.data.component.Builder` / `Builders`。 |
| 使用 `List<Builder>` 处理 JSON 数组 | 使用 `Builders` 避免泛型类型擦除问题。 |
| `ApplicationRuntimeException: template not found` | 在 `init()` 中为纯 API 应用调用 `setTemplateRequired(false)`。 |
| 用 `@Action` 标注 `private` 方法 | Actions 必须是 `public` 才能被框架注册。 |
| 在应用中硬编码 `main(String[] args)` | 使用 `bin/dispatcher` 作为所有模块的入口点。 |
| 手动 `ActionRegistry` 注册 | 优先使用 `@Action` 注解进行自动发现。 |
| 运行时找不到 Action | 确保类通过 `--import` 导入或在 `application.properties` 中列出。 |
| CLI 参数不可见 | 使用 `--key value` 传递；通过 `getContext().getAttribute("--key")` 访问。 |
| 两个方法同路径，触发了错误的那个 | 设置显式 `mode`（如 `HTTP_GET` vs `HTTP_POST`）来消歧。 |

## 最佳实践

1. **细粒度应用程序**：将逻辑拆分为更小、聚焦的应用程序，而非一个庞大的类。
2. **在 `init()` 中设置**：利用 `init()` 进行设置（配置、数据库）而非构造器。不要调用 `setAction()` — 使用 `@Action` 注解。
3. **模式感知**：在 `@Action` 中使用 `Mode` 参数将敏感操作限制为仅 `CLI` 或特定的 HTTP 方法。
4. **Context 优于参数**：对于可选的 CLI 标志，使用 `getContext().getAttribute("--flag")` 而非添加参数到方法签名。
5. **异步事件**：对于事件触发的重型任务，在事件处理器中使用 `CompletableFuture.runAsync()`。

## 技术参考

详细指南可在 `references/` 目录中找到：

- [架构与配置](references/architecture.md) — 抽象、包映射、属性
- [路由与 @Action](references/routing.md) — 注解详情、模式、参数
- [数据处理](references/data-handling.md) — Builder、Builders、JSON 序列化与解析
- [数据库持久化](references/database.md) — AbstractData POJO、CRUD、映射 XML、POJO 生成
- [系统与用法](references/system-usage.md) — Context、Sessions、SSE、文件上传、事件、网络
- [测试模式](references/testing.md) — JUnit 5 单元和 HTTP 集成测试

## 参考源文件（内部）

- `src/main/java/org/tinystruct/AbstractApplication.java` — 带生命周期钩子的核心基类
- `src/main/java/org/tinystruct/system/annotation/Action.java` — 注解与模式
- `src/main/java/org/tinystruct/application/ActionRegistry.java` — 路由引擎
- `src/main/java/org/tinystruct/data/component/Builder.java` — JSON 对象序列化器
- `src/main/java/org/tinystruct/data/component/Builders.java` — JSON 数组序列化器
- `src/main/java/org/tinystruct/data/component/AbstractData.java` — 带 CRUD 的基础 POJO 类
- `src/main/java/org/tinystruct/data/Mapping.java` — 映射 XML 解析器
- `src/main/java/org/tinystruct/data/tools/MySQLGenerator.java` — POJO 生成器参考
- `src/main/java/org/tinystruct/data/component/FieldType.java` — SQL 到 Java 类型映射
- `src/main/java/org/tinystruct/data/component/Condition.java` — 流式 SQL 查询构建器
- `src/main/java/org/tinystruct/http/SSEPushManager.java` — SSE 连接管理
- `src/test/java/org/tinystruct/application/ActionRegistryTest.java` — Registry 测试示例
- `src/test/java/org/tinystruct/system/HttpServerHttpModeTest.java` — HTTP 集成测试模式
