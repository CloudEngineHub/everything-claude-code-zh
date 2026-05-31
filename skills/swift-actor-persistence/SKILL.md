---
name: swift-actor-persistence
description: 使用 Swift Actor 实现线程安全的数据持久化 — 带文件备份存储的内存缓存，从设计上消除数据竞争。
origin: ECC
---

# Swift Actor 实现线程安全持久化

使用 Swift Actor 构建线程安全数据持久化层的模式。结合内存缓存和文件备份存储，利用 Actor 模型在编译时消除数据竞争。

## 何时激活

- 在 Swift 5.5+ 中构建数据持久化层
- 需要线程安全地访问共享可变状态
- 想要消除手动同步（锁、DispatchQueue）
- 构建带本地存储的离线优先应用

## 核心模式

### 基于 Actor 的仓库

Actor 模型保证序列化访问 — 没有数据竞争，由编译器强制执行。

```swift
public actor LocalRepository<T: Codable & Identifiable> where T.ID == String {
    private var cache: [String: T] = [:]
    private let fileURL: URL

    public init(directory: URL = .documentsDirectory, filename: String = "data.json") {
        self.fileURL = directory.appendingPathComponent(filename)
        // 初始化期间同步加载（Actor 隔离尚未激活）
        self.cache = Self.loadSynchronously(from: fileURL)
    }

    // MARK: - 公共 API

    public func save(_ item: T) throws {
        cache[item.id] = item
        try persistToFile()
    }

    public func delete(_ id: String) throws {
        cache[id] = nil
        try persistToFile()
    }

    public func find(by id: String) -> T? {
        cache[id]
    }

    public func loadAll() -> [T] {
        Array(cache.values)
    }

    // MARK: - 私有方法

    private func persistToFile() throws {
        let data = try JSONEncoder().encode(Array(cache.values))
        try data.write(to: fileURL, options: .atomic)
    }

    private static func loadSynchronously(from url: URL) -> [String: T] {
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([T].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }
}
```

### 用法

由于 Actor 隔离，所有调用自动变为异步：

```swift
let repository = LocalRepository<Question>()

// 读取 — 从内存缓存快速 O(1) 查找
let question = await repository.find(by: "q-001")
let allQuestions = await repository.loadAll()

// 写入 — 更新缓存并原子性地持久化到文件
try await repository.save(newQuestion)
try await repository.delete("q-001")
```

### 与 @Observable ViewModel 结合

```swift
@Observable
final class QuestionListViewModel {
    private(set) var questions: [Question] = []
    private let repository: LocalRepository<Question>

    init(repository: LocalRepository<Question> = LocalRepository()) {
        self.repository = repository
    }

    func load() async {
        questions = await repository.loadAll()
    }

    func add(_ question: Question) async throws {
        try await repository.save(question)
        questions = await repository.loadAll()
    }
}
```

## 关键设计决策

| 决策 | 理由 |
|----------|------|
| Actor（而非类 + 锁） | 编译器强制线程安全，无需手动同步 |
| 内存缓存 + 文件持久化 | 从缓存快速读取，持久写入到磁盘 |
| 同步初始化加载 | 避免异步初始化的复杂性 |
| 以 ID 为键的字典 | O(1) 按标识符查找 |
| 泛型化 `Codable & Identifiable` | 可跨任何模型类型复用 |
| 原子文件写入（`.atomic`） | 防止崩溃时部分写入 |

## 最佳实践

- **使用 `Sendable` 类型**处理所有跨 Actor 边界的数据
- **保持 Actor 的公共 API 最小化** — 只暴露领域操作，不暴露持久化细节
- **使用 `.atomic` 写入**以防止应用在写入中途崩溃时的数据损坏
- **在 `init` 中同步加载** — 异步初始化器增加复杂性但对本地文件好处不大
- **与 `@Observable` ViewModel 结合**以实现响应式 UI 更新

## 应避免的反模式

- 在新的 Swift 并发代码中使用 `DispatchQueue` 或 `NSLock` 而非 Actor
- 将内部缓存字典暴露给外部调用者
- 文件 URL 可配置但没有验证
- 忘记所有 Actor 方法调用都是 `await` — 调用者必须处理异步上下文
- 使用 `nonisolated` 绕过 Actor 隔离（违背了目的）

## 何时使用

- iOS/macOS 应用中的本地数据存储（用户数据、设置、缓存内容）
- 离线优先架构，稍后同步到服务器
- 任何被应用多个部分并发访问的共享可变状态
- 用现代 Swift 并发替代基于 `DispatchQueue` 的传统线程安全方案
