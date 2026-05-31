---
name: quarkus-patterns
description: Quarkus 3.x LTS 架构模式，包括用于消息传递的 Camel、RESTful API 设计、CDI 服务、Panache 数据访问和异步处理。用于具有事件驱动架构的 Java Quarkus 后端工作。
origin: ECC
---

# Quarkus 开发模式

Quarkus 3.x 架构和 API 模式，用于具有 Apache Camel 的云原生、事件驱动服务。

## 使用时机

- 使用 JAX-RS 或 RESTEasy Reactive 构建 REST API
- 构建 resource → service → repository 层结构
- 使用 Apache Camel 和 RabbitMQ 实现事件驱动模式
- 配置 Hibernate Panache、缓存或响应式流
- 添加验证、异常映射或分页
- 为 dev/staging/production 环境设置配置文件（YAML 配置）
- 使用 LogContext 和 Logback/Logstash 编码器进行自定义日志记录
- 使用 CompletableFuture 进行异步操作
- 实现条件流处理
- 使用 GraalVM 原生编译

## 具有多个依赖的服务层

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class OrderProcessingService {

    private final OrderValidator orderValidator;
    private final EventService eventService;
    private final OrderRepository orderRepository;
    private final FulfillmentPublisher fulfillmentPublisher;
    private final AuditPublisher auditPublisher;

    @Transactional
    public OrderReceipt process(CreateOrderCommand command) {
        ValidationResult validation = orderValidator.validate(command);
        if (!validation.valid()) {
            eventService.createErrorEvent(command, "ORDER_REJECTED", validation.message());
            throw new WebApplicationException(validation.message(), Response.Status.BAD_REQUEST);
        }

        Order order = Order.from(command);
        orderRepository.persist(order);

        OrderReceipt receipt = OrderReceipt.from(order);
        fulfillmentPublisher.publishAsync(receipt);
        auditPublisher.publish("ORDER_ACCEPTED", receipt);
        eventService.createSuccessEvent(receipt, "ORDER_ACCEPTED");

        log.info("Processed order {}", order.id);
        return receipt;
    }
}
```

**关键模式：**
- `@RequiredArgsConstructor` 用于通过 Lombok 进行构造函数注入
- `@Slf4j` 用于 Logback 日志记录
- `@Transactional` 在通过 Panache 或仓库写入的服务方法上
- 在持久化或消息发布前验证输入
- 为成功/错误场景进行事件跟踪
- 异步 Camel 消息发布

## 自定义日志上下文模式（Logback）

```java
@ApplicationScoped
public class ProcessingService {
    
    public void processDocument(Document doc) {
        LogContext logContext = CustomLog.getCurrentContext();
        try (SafeAutoCloseable ignored = CustomLog.startScope(logContext)) {
            // 将上下文添加到所有日志语句
            logContext.put("documentId", doc.getId().toString());
            logContext.put("documentType", doc.getType());
            logContext.put("userId", SecurityContext.getUserId());
            
            log.info("Starting document processing");
            
            // 此范围内的所有日志继承上下文
            processInternal(doc);
            
            log.info("Document processing completed");
        } catch (Exception e) {
            log.error("Document processing failed", e);
            throw e;
        }
    }
}
```

**Logback 配置（logback.xml）：**

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <includeContext>true</includeContext>
            <includeMdc>true</includeMdc>
        </encoder>
    </appender>
    
    <logger name="com.example" level="INFO"/>
    <root level="WARN">
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

## 事件服务模式

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class EventService {
    private final EventRepository eventRepository;
    private final ObjectMapper objectMapper;
    
    public void createSuccessEvent(Object payload, String eventType) {
        Objects.requireNonNull(payload, "Payload cannot be null");
        Event event = new Event();
        event.setType(eventType);
        event.setStatus(EventStatus.SUCCESS);
        event.setPayload(serializePayload(payload));
        event.setTimestamp(Instant.now());
        
        eventRepository.persist(event);
        log.info("Success event created: {}", eventType);
    }
    
    public void createErrorEvent(Object payload, String eventType, String errorMessage) {
        Objects.requireNonNull(payload, "Payload cannot be null");
        if (errorMessage == null || errorMessage.isBlank()) {
            throw new IllegalArgumentException("Error message cannot be blank");
        }
        Event event = new Event();
        event.setType(eventType);
        event.setStatus(EventStatus.ERROR);
        event.setErrorMessage(errorMessage);
        event.setPayload(serializePayload(payload));
        event.setTimestamp(Instant.now());
        
        eventRepository.persist(event);
        log.error("Error event created: {} - {}", eventType, errorMessage);
    }
    
    private String serializePayload(Object payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize event payload", e);
        }
    }
}
```

## Camel 消息发布（RabbitMQ）

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class BusinessRulesPublisher {
    private final ProducerTemplate producerTemplate;
    
    public void publishSync(BusinessRulesPayload payload) {
        producerTemplate.sendBody(
            "direct:business-rules-publisher", 
            payload
        );
    }
}
```

**Camel 路由配置：**

```java
@ApplicationScoped
public class BusinessRulesRoute extends RouteBuilder {
    
    @ConfigProperty(name = "camel.rabbitmq.queue.business-rules")
    String businessRulesQueue;
    
    @ConfigProperty(name = "rabbitmq.host")
    String rabbitHost;
    
    @ConfigProperty(name = "rabbitmq.port")
    Integer rabbitPort;
    
    @Override
    public void configure() {
        from("direct:business-rules-publisher")
            .routeId("business-rules-publisher")
            .log("Publishing message to RabbitMQ: ${body}")
            .marshal().json(JsonLibrary.Jackson)
            .toF("spring-rabbitmq:%s?hostname=%s&portNumber=%d", 
                businessRulesQueue, rabbitHost, rabbitPort);
    }
}
```

## Camel Direct 路由（内存）

```java
@ApplicationScoped
public class DocumentProcessingRoute extends RouteBuilder {
    
    @Override
    public void configure() {
        // 错误处理
        onException(ValidationException.class)
            .handled(true)
            .to("direct:validation-error-handler")
            .log("Validation error: ${exception.message}");
        
        // 主处理路由
        from("direct:process-document")
            .routeId("document-processing")
            .log("Processing document: ${header.documentId}")
            .bean(DocumentValidator.class, "validate")
            .bean(DocumentTransformer.class, "transform")
            .choice()
                .when(header("documentType").isEqualTo("INVOICE"))
                    .to("direct:process-invoice")
                .when(header("documentType").isEqualTo("CREDIT_NOTE"))
                    .to("direct:process-credit-note")
                .otherwise()
                    .to("direct:process-generic")
            .end();
        
        from("direct:validation-error-handler")
            .bean(EventService.class, "createErrorEvent")
            .log("Validation error handled");
    }
}
```

## Camel 文件处理

```java
@ApplicationScoped
public class FileMonitoringRoute extends RouteBuilder {
    
    @ConfigProperty(name = "file.input.directory")
    String inputDirectory;
    
    @ConfigProperty(name = "file.processed.directory")
    String processedDirectory;
    
    @ConfigProperty(name = "file.error.directory")
    String errorDirectory;
    
    @Override
    public void configure() {
        from("file:" + inputDirectory + "?move=" + processedDirectory + 
             "&moveFailed=" + errorDirectory + "&delay=5000")
            .routeId("file-monitor")
            .log("Processing file: ${header.CamelFileName}")
            .to("direct:process-file");
        
        from("direct:process-file")
            .bean(OrderProcessingService.class, "processFile")
            .log("File processing completed");
    }
}
```

## Camel Bean 调用

```java
@ApplicationScoped
public class InvoiceRoute extends RouteBuilder {
    
    @Override
    public void configure() {
        from("direct:invoice-validation")
            .bean(InvoiceFlowValidator.class, "validateFlowWithConfig")
            .log("Validation result: ${body}");
        
        from("direct:persist-and-publish")
            .bean(DocumentJobService.class, "createDocumentAndJobEntities")
            .bean(BusinessRulesPublisher.class, "publishAsync")
            .bean(EventService.class, "createSuccessEvent(${body}, 'PUBLISHED')");
    }
}
```

## REST API 结构

```java
@Path("/api/documents")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiredArgsConstructor
public class DocumentResource {
  private final DocumentService documentService;

  @GET
  public Response list(
      @QueryParam("page") @DefaultValue("0") int page,
      @QueryParam("size") @DefaultValue("20") int size) {
    List<Document> documents = documentService.list(page, size);
    return Response.ok(documents).build();
  }

  @POST
  public Response create(@Valid CreateDocumentRequest request, @Context UriInfo uriInfo) {
    Document document = documentService.create(request);
    URI location = uriInfo.getAbsolutePathBuilder()
        .path(String.valueOf(document.id))
        .build();
    return Response.created(location).entity(DocumentResponse.from(document)).build();
  }

  @GET
  @Path("/{id}")
  public Response getById(@PathParam("id") Long id) {
    return documentService.findById(id)
        .map(DocumentResponse::from)
        .map(Response::ok)
        .orElse(Response.status(Response.Status.NOT_FOUND))
        .build();
  }
}
```

## 仓库模式（Panache Repository）

```java
@ApplicationScoped
public class DocumentRepository implements PanacheRepository<Document> {
  
  public List<Document> findByStatus(DocumentStatus status, int page, int size) {
    return find("status = ?1 order by createdAt desc", status)
        .page(page, size)
        .list();
  }

  public Optional<Document> findByReferenceNumber(String referenceNumber) {
    return find("referenceNumber", referenceNumber).firstResultOptional();
  }
  
  public long countByStatusAndDate(DocumentStatus status, LocalDate date) {
    return count("status = ?1 and createdAt >= ?2", status, date.atStartOfDay());
  }
}
```

## 带事务的服务层

```java
@ApplicationScoped
@RequiredArgsConstructor
public class DocumentService {
  private final DocumentRepository repo;
  private final EventService eventService;

  @Transactional
  public Document create(CreateDocumentRequest request) {
    Document document = new Document();
    document.setReferenceNumber(request.referenceNumber());
    document.setDescription(request.description());
    document.setStatus(DocumentStatus.PENDING);
    document.setCreatedAt(Instant.now());
    
    repo.persist(document);
    
    eventService.createSuccessEvent(document, "DOCUMENT_CREATED");
    
    return document;
  }

  public Optional<Document> findById(Long id) {
    return repo.findByIdOptional(id);
  }

  public List<Document> list(int page, int size) {
    return repo.findAll()
        .page(page, size)
        .list();
  }
}
```

## DTO 和验证

```java
public record CreateDocumentRequest(
    @NotBlank @Size(max = 200) String referenceNumber,
    @NotBlank @Size(max = 2000) String description,
    @NotNull @FutureOrPresent Instant validUntil,
    @NotEmpty List<@NotBlank String> categories) {}

public record DocumentResponse(Long id, String referenceNumber, DocumentStatus status) {
  public static DocumentResponse from(Document document) {
    return new DocumentResponse(document.getId(), document.getReferenceNumber(), 
        document.getStatus());
  }
}
```

## 异常映射

```java
@Provider
public class ValidationExceptionMapper implements ExceptionMapper<ConstraintViolationException> {
  @Override
  public Response toResponse(ConstraintViolationException exception) {
    String message = exception.getConstraintViolations().stream()
        .map(cv -> cv.getPropertyPath() + ": " + cv.getMessage())
        .collect(Collectors.joining(", "));
    
    return Response.status(Response.Status.BAD_REQUEST)
        .entity(Map.of("error", "validation_error", "message", message))
        .build();
  }
}

@Provider
@Slf4j
public class GenericExceptionMapper implements ExceptionMapper<Exception> {

  @Override
  public Response toResponse(Exception exception) {
    log.error("Unhandled exception", exception);
    return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
        .entity(Map.of("error", "internal_error", "message", "An unexpected error occurred"))
        .build();
  }
}
```

## CompletableFuture 异步操作

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class FileStorageService {
    private final S3Client s3Client;
    private final ExecutorService executorService;
    
    @ConfigProperty(name = "storage.bucket-name")
    String bucketName;
    
    public CompletableFuture<StoredDocumentInfo> uploadOriginalFile(
            InputStream inputStream, 
            long size, 
            LogContext logContext,
            InvoiceFormat format) {
        
        return CompletableFuture.supplyAsync(() -> {
            try (SafeAutoCloseable ignored = CustomLog.startScope(logContext)) {
                String path = generateStoragePath(format);
                
                PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(path)
                    .contentLength(size)
                    .build();
                
                s3Client.putObject(request, RequestBody.fromInputStream(inputStream, size));
                
                log.info("File uploaded to S3: {}", path);
                
                return new StoredDocumentInfo(path, size, Instant.now());
            } catch (Exception e) {
                log.error("Failed to upload file to S3", e);
                throw new StorageException("Upload failed", e);
            }
        }, executorService);
    }
}
```

## 缓存

```java
@ApplicationScoped
@RequiredArgsConstructor
public class DocumentCacheService {
  private final DocumentRepository repo;

  @CacheResult(cacheName = "document-cache")
  public Optional<Document> getById(@CacheKey Long id) {
    return repo.findByIdOptional(id);
  }

  @CacheInvalidate(cacheName = "document-cache")
  public void evict(@CacheKey Long id) {}

  @CacheInvalidateAll(cacheName = "document-cache")
  public void evictAll() {}
}
```

## YAML 配置

```yaml
# application.yml
"%dev":
  quarkus:
    datasource:
      jdbc:
        url: jdbc:postgresql://localhost:5432/dev_db
      username: dev_user
      password: ${DB_PASSWORD}
    hibernate-orm:
      database:
        generation: drop-and-create
  
  rabbitmq:
    host: localhost
    port: 5672
    username: ${RABBITMQ_USER}
    password: ${RABBITMQ_PASSWORD}

"%test":
  quarkus:
    datasource:
      jdbc:
        url: jdbc:h2:mem:test
    hibernate-orm:
      database:
        generation: drop-and-create

"%prod":
  quarkus:
    datasource:
      jdbc:
        url: ${DATABASE_URL}
      username: ${DB_USER}
      password: ${DB_PASSWORD}
    hibernate-orm:
      database:
        generation: validate
  
  rabbitmq:
    host: ${RABBITMQ_HOST}
    port: ${RABBITMQ_PORT}
    username: ${RABBITMQ_USER}
    password: ${RABBITMQ_PASSWORD}

# Camel 配置
camel:
  rabbitmq:
    queue:
      business-rules: business-rules-queue
      invoice-processing: invoice-processing-queue
```

## 健康检查

```java
@Readiness
@ApplicationScoped
@RequiredArgsConstructor
public class DatabaseHealthCheck implements HealthCheck {
  private final AgroalDataSource dataSource;

  @Override
  public HealthCheckResponse call() {
    try (Connection conn = dataSource.getConnection()) {
      boolean valid = conn.isValid(2);
      return HealthCheckResponse.named("Database connection")
          .status(valid)
          .build();
    } catch (SQLException e) {
      return HealthCheckResponse.down("Database connection");
    }
  }
}

@Liveness
@ApplicationScoped
public class CamelHealthCheck implements HealthCheck {
  @Inject
  CamelContext camelContext;

  @Override
  public HealthCheckResponse call() {
    boolean isStarted = camelContext.getStatus().isStarted();
    return HealthCheckResponse.named("Camel Context")
        .status(isStarted)
        .build();
  }
}
```

## 依赖项（Maven）

```xml
<properties>
    <quarkus.platform.version>3.27.0</quarkus.platform.version>
    <lombok.version>1.18.42</lombok.version>
    <assertj-core.version>3.24.2</assertj-core.version>
    <jacoco-maven-plugin.version>0.8.13</jacoco-maven-plugin.version>
    <maven.compiler.release>17</maven.compiler.release>
</properties>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>io.quarkus.platform</groupId>
            <artifactId>quarkus-bom</artifactId>
            <version>${quarkus.platform.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>io.quarkus.platform</groupId>
            <artifactId>quarkus-camel-bom</artifactId>
            <version>${quarkus.platform.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <!-- Quarkus 核心 -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-arc</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-config-yaml</artifactId>
    </dependency>
    
    <!-- Camel 扩展 -->
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-spring-rabbitmq</artifactId>
    </dependency>
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-direct</artifactId>
    </dependency>
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-bean</artifactId>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
        <scope>provided</scope>
    </dependency>
    
    <!-- 日志记录 -->
    <dependency>
        <groupId>io.quarkiverse.logging.logback</groupId>
        <artifactId>quarkus-logging-logback</artifactId>
    </dependency>
    <dependency>
        <groupId>net.logstash.logback</groupId>
        <artifactId>logstash-logback-encoder</artifactId>
    </dependency>
</dependencies>
```

## 最佳实践

### 架构
- 使用 `@RequiredArgsConstructor` 和 Lombok 进行构造函数注入
- 保持服务层精简；将复杂逻辑委托给专门类
- 使用 Camel 路由进行消息路由和集成模式
- 优先使用 Panache Repository 模式进行数据访问

### 事件驱动
- 始终使用 EventService 跟踪操作（成功/失败事件）
- 使用 Camel `direct:` 端点进行内存路由
- 使用 `spring-rabbitmq` 组件进行 RabbitMQ 集成
- 使用 `ProducerTemplate.asyncSendBody()` 实现异步发布

### 日志记录
- 使用 Logback 和 Logstash 编码器进行结构化日志记录
- 使用 `SafeAutoCloseable` 通过服务调用传播 LogContext
- 将上下文信息添加到 LogContext 以进行请求跟踪
- 使用 `@Slf4j` 而非手动实例化 logger

### 异步操作
- 使用 CompletableFuture 进行非阻塞 I/O 操作
- 需要等待完成时调用 `.join()`
- 正确处理 CompletableFuture 异常
- 将 LogContext 传递给异步操作以进行跟踪

### 配置
- 使用 YAML 配置（`quarkus-config-yaml`）
- dev/test/prod 环境的配置文件感知配置
- 将敏感配置外部化到环境变量
- 使用 `@ConfigProperty` 进行类型安全的配置注入

### 验证
- 使用 `@Valid` 在资源层验证
- 在 DTO 上使用 Bean Validation 注解
- 使用 `@Provider` 将异常映射到适当的 HTTP 响应

### 事务
- 在修改数据的服务方法上使用 `@Transactional`
- 保持事务简短和专注
- 避免在事务内调用异步操作

### 测试
- 使用 `camel-quarkus-junit5` 进行路由测试
- 使用 AssertJ 进行断言
- 模拟所有外部依赖
- 彻底测试条件流逻辑

### Quarkus 特定
- 保持最新 LTS 版本（3.x）
- 使用 Quarkus 开发模式进行热重载
- 为生产就绪性添加健康检查
- 定期测试原生编译兼容性
