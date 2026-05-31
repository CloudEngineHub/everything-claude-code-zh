---
name: kotlin-patterns
description: 惯用 Kotlin 模式、最佳实践和约定——使用协程、空安全和 DSL 构建器构建健壮、高效且可维护的 Kotlin 应用。
origin: ECC
---

# Kotlin 开发模式

构建健壮、高效且可维护应用的惯用 Kotlin 模式和最佳实践。

## 何时使用

- 编写新的 Kotlin 代码
- 审查 Kotlin 代码
- 重构现有 Kotlin 代码
- 设计 Kotlin 模块或库
- 配置 Gradle Kotlin DSL 构建

## 工作原理

此技能在七个关键领域强制执行惯用 Kotlin 约定：使用类型系统和安全调用操作符的空安全、通过 `val` 和 data class 的 `copy()` 实现不可变性、用于穷举类型层次结构的密封类和接口、使用协程和 `Flow` 的结构化并发、用于不通过继承添加行为的扩展函数、使用 `@DslMarker` 和 lambda 接收者的类型安全 DSL 构建器，以及用于构建配置的 Gradle Kotlin DSL。

## 示例

**使用 Elvis 操作符的空安全：**
```kotlin
fun getUserEmail(userId: String): String {
    val user = userRepository.findById(userId)
    return user?.email ?: "unknown@example.com"
}
```

**使用密封类的穷举结果：**
```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Failure(val error: AppError) : Result<Nothing>()
    data object Loading : Result<Nothing>()
}
```

**使用 async/await 的结构化并发：**
```kotlin
suspend fun fetchUserWithPosts(userId: String): UserProfile =
    coroutineScope {
        val user = async { userService.getUser(userId) }
        val posts = async { postService.getUserPosts(userId) }
        UserProfile(user = user.await(), posts = posts.await())
    }
```

## 核心原则

### 1. 空安全

Kotlin 的类型系统区分可空和不可空类型。充分利用它。

```kotlin
// 好的做法：默认使用不可空类型
fun getUser(id: String): User {
    return userRepository.findById(id)
        ?: throw UserNotFoundException("User $id not found")
}

// 好的做法：安全调用和 Elvis 操作符
fun getUserEmail(userId: String): String {
    val user = userRepository.findById(userId)
    return user?.email ?: "unknown@example.com"
}

// 坏的做法：强制解包可空类型
fun getUserEmail(userId: String): String {
    val user = userRepository.findById(userId)
    return user!!.email // 如果为 null 会抛出 NPE
}
```

### 2. 默认不可变

优先使用 `val` 而非 `var`，优先使用不可变集合而非可变集合。

```kotlin
// 好的做法：不可变数据
data class User(
    val id: String,
    val name: String,
    val email: String,
)

// 好的做法：使用 copy() 转换
fun updateEmail(user: User, newEmail: String): User =
    user.copy(email = newEmail)

// 好的做法：不可变集合
val users: List<User> = listOf(user1, user2)
val filtered = users.filter { it.email.isNotBlank() }

// 坏的做法：可变状态
var currentUser: User? = null // 避免可变全局状态
val mutableUsers = mutableListOf<User>() // 除非确实需要，否则避免
```

### 3. 表达式体和单表达式函数

使用表达式体编写简洁、可读的函数。

```kotlin
// 好的做法：表达式体
fun isAdult(age: Int): Boolean = age >= 18

fun formatFullName(first: String, last: String): String =
    "$first $last".trim()

fun User.displayName(): String =
    name.ifBlank { email.substringBefore('@') }

// 好的做法：when 作为表达式
fun statusMessage(code: Int): String = when (code) {
    200 -> "OK"
    404 -> "未找到"
    500 -> "内部服务器错误"
    else -> "未知状态：$code"
}

// 坏的做法：不必要的块体
fun isAdult(age: Int): Boolean {
    return age >= 18
}
```

### 4. 使用 Data Class 作为值对象

对主要持有数据的类型使用 data class。

```kotlin
// 好的做法：带有 copy、equals、hashCode、toString 的 data class
data class CreateUserRequest(
    val name: String,
    val email: String,
    val role: Role = Role.USER,
)

// 好的做法：用于类型安全的 value class（运行时零开销）
@JvmInline
value class UserId(val value: String) {
    init {
        require(value.isNotBlank()) { "UserId cannot be blank" }
    }
}

@JvmInline
value class Email(val value: String) {
    init {
        require('@' in value) { "Invalid email: $value" }
    }
}

fun getUser(id: UserId): User = userRepository.findById(id)
```

## 密封类和接口

### 建模受限层次结构

```kotlin
// 好的做法：使用密封类实现穷举 when
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Failure(val error: AppError) : Result<Nothing>()
    data object Loading : Result<Nothing>()
}

fun <T> Result<T>.getOrNull(): T? = when (this) {
    is Result.Success -> data
    is Result.Failure -> null
    is Result.Loading -> null
}

fun <T> Result<T>.getOrThrow(): T = when (this) {
    is Result.Success -> data
    is Result.Failure -> throw error.toException()
    is Result.Loading -> throw IllegalStateException("Still loading")
}
```

### 使用密封接口表示 API 响应

```kotlin
sealed interface ApiError {
    val message: String

    data class NotFound(override val message: String) : ApiError
    data class Unauthorized(override val message: String) : ApiError
    data class Validation(
        override val message: String,
        val field: String,
    ) : ApiError
    data class Internal(
        override val message: String,
        val cause: Throwable? = null,
    ) : ApiError
}

fun ApiError.toStatusCode(): Int = when (this) {
    is ApiError.NotFound -> 404
    is ApiError.Unauthorized -> 401
    is ApiError.Validation -> 422
    is ApiError.Internal -> 500
}
```

## 作用域函数

### 每种函数何时使用

```kotlin
// let：转换可空或限定作用域的结果
val length: Int? = name?.let { it.trim().length }

// apply：配置对象（返回对象本身）
val user = User().apply {
    name = "Alice"
    email = "alice@example.com"
}

// also：副作用（返回对象本身）
val user = createUser(request).also { logger.info("Created user: ${it.id}") }

// run：使用接收者执行块（返回结果）
val result = connection.run {
    prepareStatement(sql)
    executeQuery()
}

// with：run 的非扩展形式
val csv = with(StringBuilder()) {
    appendLine("name,email")
    users.forEach { appendLine("${it.name},${it.email}") }
    toString()
}
```

### 反模式

```kotlin
// 坏的做法：嵌套作用域函数
user?.let { u ->
    u.address?.let { addr ->
        addr.city?.let { city ->
            println(city) // 难以阅读
        }
    }
}

// 好的做法：改为链式安全调用
val city = user?.address?.city
city?.let { println(it) }
```

## 扩展函数

### 不通过继承添加功能

```kotlin
// 好的做法：领域特定扩展
fun String.toSlug(): String =
    lowercase()
        .replace(Regex("[^a-z0-9\\s-]"), "")
        .replace(Regex("\\s+"), "-")
        .trim('-')

fun Instant.toLocalDate(zone: ZoneId = ZoneId.systemDefault()): LocalDate =
    atZone(zone).toLocalDate()

// 好的做法：集合扩展
fun <T> List<T>.second(): T = this[1]

fun <T> List<T>.secondOrNull(): T? = getOrNull(1)

// 好的做法：限定作用域的扩展（不污染全局命名空间）
class UserService {
    private fun User.isActive(): Boolean =
        status == Status.ACTIVE && lastLogin.isAfter(Instant.now().minus(30, ChronoUnit.DAYS))

    fun getActiveUsers(): List<User> = userRepository.findAll().filter { it.isActive() }
}
```

## 协程

### 结构化并发

```kotlin
// 好的做法：使用 coroutineScope 实现结构化并发
suspend fun fetchUserWithPosts(userId: String): UserProfile =
    coroutineScope {
        val userDeferred = async { userService.getUser(userId) }
        val postsDeferred = async { postService.getUserPosts(userId) }

        UserProfile(
            user = userDeferred.await(),
            posts = postsDeferred.await(),
        )
    }

// 好的做法：当子任务可以独立失败时使用 supervisorScope
suspend fun fetchDashboard(userId: String): Dashboard =
    supervisorScope {
        val user = async { userService.getUser(userId) }
        val notifications = async { notificationService.getRecent(userId) }
        val recommendations = async { recommendationService.getFor(userId) }

        Dashboard(
            user = user.await(),
            notifications = try {
                notifications.await()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                emptyList()
            },
            recommendations = try {
                recommendations.await()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                emptyList()
            },
        )
    }
```

### 响应式流的 Flow

```kotlin
// 好的做法：带有正确错误处理的冷流
fun observeUsers(): Flow<List<User>> = flow {
    while (currentCoroutineContext().isActive) {
        val users = userRepository.findAll()
        emit(users)
        delay(5.seconds)
    }
}.catch { e ->
    logger.error("Error observing users", e)
    emit(emptyList())
}

// 好的做法：Flow 操作符
fun searchUsers(query: Flow<String>): Flow<List<User>> =
    query
        .debounce(300.milliseconds)
        .distinctUntilChanged()
        .filter { it.length >= 2 }
        .mapLatest { q -> userRepository.search(q) }
        .catch { emit(emptyList()) }
```

### 取消和清理

```kotlin
// 好的做法：尊重取消
suspend fun processItems(items: List<Item>) {
    items.forEach { item ->
        ensureActive() // 在昂贵操作前检查取消
        processItem(item)
    }
}

// 好的做法：使用 try/finally 清理
suspend fun acquireAndProcess() {
    val resource = acquireResource()
    try {
        resource.process()
    } finally {
        withContext(NonCancellable) {
            resource.release() // 始终释放，即使被取消
        }
    }
}
```

## 委托

### 属性委托

```kotlin
// 延迟初始化
val expensiveData: List<User> by lazy {
    userRepository.findAll()
}

// 可观察属性
var name: String by Delegates.observable("initial") { _, old, new ->
    logger.info("Name changed from '$old' to '$new'")
}

// Map 支持的属性
class Config(private val map: Map<String, Any?>) {
    val host: String by map
    val port: Int by map
    val debug: Boolean by map
}

val config = Config(mapOf("host" to "localhost", "port" to 8080, "debug" to true))
```

### 接口委托

```kotlin
// 好的做法：委托接口实现
class LoggingUserRepository(
    private val delegate: UserRepository,
    private val logger: Logger,
) : UserRepository by delegate {
    // 只覆盖需要添加日志的方法
    override suspend fun findById(id: String): User? {
        logger.info("Finding user by id: $id")
        return delegate.findById(id).also {
            logger.info("Found user: ${it?.name ?: "null"}")
        }
    }
}
```

## DSL 构建器

### 类型安全构建器

```kotlin
// 好的做法：使用 @DslMarker 的 DSL
@DslMarker
annotation class HtmlDsl

@HtmlDsl
class HTML {
    private val children = mutableListOf<Element>()

    fun head(init: Head.() -> Unit) {
        children += Head().apply(init)
    }

    fun body(init: Body.() -> Unit) {
        children += Body().apply(init)
    }

    override fun toString(): String = children.joinToString("\n")
}

fun html(init: HTML.() -> Unit): HTML = HTML().apply(init)

// 用法
val page = html {
    head { title("My Page") }
    body {
        h1("Welcome")
        p("Hello, World!")
    }
}
```

### 配置 DSL

```kotlin
data class ServerConfig(
    val host: String = "0.0.0.0",
    val port: Int = 8080,
    val ssl: SslConfig? = null,
    val database: DatabaseConfig? = null,
)

data class SslConfig(val certPath: String, val keyPath: String)
data class DatabaseConfig(val url: String, val maxPoolSize: Int = 10)

class ServerConfigBuilder {
    var host: String = "0.0.0.0"
    var port: Int = 8080
    private var ssl: SslConfig? = null
    private var database: DatabaseConfig? = null

    fun ssl(certPath: String, keyPath: String) {
        ssl = SslConfig(certPath, keyPath)
    }

    fun database(url: String, maxPoolSize: Int = 10) {
        database = DatabaseConfig(url, maxPoolSize)
    }

    fun build(): ServerConfig = ServerConfig(host, port, ssl, database)
}

fun serverConfig(init: ServerConfigBuilder.() -> Unit): ServerConfig =
    ServerConfigBuilder().apply(init).build()

// 用法
val config = serverConfig {
    host = "0.0.0.0"
    port = 443
    ssl("/certs/cert.pem", "/certs/key.pem")
    database("jdbc:postgresql://localhost:5432/mydb", maxPoolSize = 20)
}
```

## 用于惰性求值的序列

```kotlin
// 好的做法：对具有多个操作的大型集合使用序列
val result = users.asSequence()
    .filter { it.isActive }
    .map { it.email }
    .filter { it.endsWith("@company.com") }
    .take(10)
    .toList()

// 好的做法：生成无限序列
val fibonacci: Sequence<Long> = sequence {
    var a = 0L
    var b = 1L
    while (true) {
        yield(a)
        val next = a + b
        a = b
        b = next
    }
}

val first20 = fibonacci.take(20).toList()
```

## Gradle Kotlin DSL

### build.gradle.kts 配置

```kotlin
// 检查最新版本：https://kotlinlang.org/docs/releases.html
plugins {
    kotlin("jvm") version "2.3.10"
    kotlin("plugin.serialization") version "2.3.10"
    id("io.ktor.plugin") version "3.4.0"
    id("org.jetbrains.kotlinx.kover") version "0.9.7"
    id("io.gitlab.arturbosch.detekt") version "1.23.8"
}

group = "com.example"
version = "1.0.0"

kotlin {
    jvmToolchain(21)
}

dependencies {
    // Ktor
    implementation("io.ktor:ktor-server-core:3.4.0")
    implementation("io.ktor:ktor-server-netty:3.4.0")
    implementation("io.ktor:ktor-server-content-negotiation:3.4.0")
    implementation("io.ktor:ktor-serialization-kotlinx-json:3.4.0")

    // Exposed
    implementation("org.jetbrains.exposed:exposed-core:1.0.0")
    implementation("org.jetbrains.exposed:exposed-dao:1.0.0")
    implementation("org.jetbrains.exposed:exposed-jdbc:1.0.0")
    implementation("org.jetbrains.exposed:exposed-kotlin-datetime:1.0.0")

    // Koin
    implementation("io.insert-koin:koin-ktor:4.2.0")

    // 协程
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")

    // 测试
    testImplementation("io.kotest:kotest-runner-junit5:6.1.4")
    testImplementation("io.kotest:kotest-assertions-core:6.1.4")
    testImplementation("io.kotest:kotest-property:6.1.4")
    testImplementation("io.mockk:mockk:1.14.9")
    testImplementation("io.ktor:ktor-server-test-host:3.4.0")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.2")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

detekt {
    config.setFrom(files("config/detekt/detekt.yml"))
    buildUponDefaultConfig = true
}
```

## 错误处理模式

### 领域操作的 Result 类型

```kotlin
// 好的做法：使用 Kotlin 的 Result 或自定义密封类
suspend fun createUser(request: CreateUserRequest): Result<User> = runCatching {
    require(request.name.isNotBlank()) { "Name cannot be blank" }
    require('@' in request.email) { "Invalid email format" }

    val user = User(
        id = UserId(UUID.randomUUID().toString()),
        name = request.name,
        email = Email(request.email),
    )
    userRepository.save(user)
    user
}

// 好的做法：链式结果
val displayName = createUser(request)
    .map { it.name }
    .getOrElse { "Unknown" }
```

### require、check、error

```kotlin
// 好的做法：带有清晰消息的前置条件
fun withdraw(account: Account, amount: Money): Account {
    require(amount.value > 0) { "Amount must be positive: $amount" }
    check(account.balance >= amount) { "Insufficient balance: ${account.balance} < $amount" }

    return account.copy(balance = account.balance - amount)
}
```

## 集合操作

### 惯用集合处理

```kotlin
// 好的做法：链式操作
val activeAdminEmails: List<String> = users
    .filter { it.role == Role.ADMIN && it.isActive }
    .sortedBy { it.name }
    .map { it.email }

// 好的做法：分组和聚合
val usersByRole: Map<Role, List<User>> = users.groupBy { it.role }

val oldestByRole: Map<Role, User?> = users.groupBy { it.role }
    .mapValues { (_, users) -> users.minByOrNull { it.createdAt } }

// 好的做法：使用 associate 创建映射
val usersById: Map<UserId, User> = users.associateBy { it.id }

// 好的做法：使用 partition 拆分
val (active, inactive) = users.partition { it.isActive }
```

## 快速参考：Kotlin 惯用法

| 惯用法 | 说明 |
|--------|------|
| `val` 优于 `var` | 优先使用不可变变量 |
| `data class` | 用于带有 equals/hashCode/copy 的值对象 |
| `sealed class/interface` | 用于受限类型层次结构 |
| `value class` | 用于零开销的类型安全包装器 |
| 表达式 `when` | 穷举模式匹配 |
| 安全调用 `?.` | 空安全的成员访问 |
| Elvis `?:` | 可空类型的默认值 |
| `let`/`apply`/`also`/`run`/`with` | 用于整洁代码的作用域函数 |
| 扩展函数 | 不通过继承添加行为 |
| `copy()` | data class 上的不可变更新 |
| `require`/`check` | 前置条件断言 |
| 协程 `async`/`await` | 结构化并发执行 |
| `Flow` | 冷响应式流 |
| `sequence` | 惰性求值 |
| 委托 `by` | 不通过继承复用实现 |

## 应避免的反模式

```kotlin
// 坏的做法：强制解包可空类型
val name = user!!.name

// 坏的做法：来自 Java 的平台类型泄漏
fun getLength(s: String) = s.length // 安全
fun getLength(s: String?) = s?.length ?: 0 // 处理来自 Java 的 null

// 坏的做法：可变 data class
data class MutableUser(var name: String, var email: String)

// 坏的做法：使用异常进行控制流
try {
    val user = findUser(id)
} catch (e: NotFoundException) {
    // 不要对预期情况使用异常
}

// 好的做法：使用可空返回或 Result
val user: User? = findUserOrNull(id)

// 坏的做法：忽略协程作用域
GlobalScope.launch { /* 避免 GlobalScope */ }

// 好的做法：使用结构化并发
coroutineScope {
    launch { /* 正确限定作用域 */ }
}

// 坏的做法：深度嵌套作用域函数
user?.let { u ->
    u.address?.let { a ->
        a.city?.let { c -> process(c) }
    }
}

// 好的做法：直接空安全链
user?.address?.city?.let { process(it) }
```

**记住**：Kotlin 代码应该简洁但可读。利用类型系统确保安全，优先不可变性，使用协程处理并发。不确定时，让编译器帮助你。
