---
name: swift-concurrency-6-2
description: Swift 6.2 Approachable Concurrency — 默认单线程执行，@concurrent 用于显式后台卸载，MainActor 类型的隔离一致性。
---

# Swift 6.2 Approachable Concurrency

采用 Swift 6.2 并发模型的模式，代码默认单线程执行，并发需要显式引入。在不牺牲性能的情况下消除常见的数据竞争错误。

## 何时激活

- 将 Swift 5.x 或 6.0/6.1 项目迁移到 Swift 6.2
- 解决数据竞争安全编译器错误
- 设计基于 MainActor 的应用架构
- 将 CPU 密集型工作卸载到后台线程
- 在 MainActor 隔离的类型上实现协议一致性
- 在 Xcode 26 中启用 Approachable Concurrency 构建设置

## 核心问题：隐式后台卸载

在 Swift 6.1 及更早版本中，async 函数可能被隐式卸载到后台线程，导致即使看似安全的代码也会出现数据竞争错误：

```swift
// Swift 6.1: 错误
@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }

        // 错误：发送 'self.photoProcessor' 存在数据竞争风险
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

Swift 6.2 修复了这个问题：async 函数默认留在调用者的 Actor 上。

```swift
// Swift 6.2: 正确 — async 留在 MainActor 上，没有数据竞争
@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

## 核心模式 — 隔离一致性

MainActor 类型现在可以安全地遵循非隔离协议：

```swift
protocol Exportable {
    func export()
}

// Swift 6.1: 错误 — 跨越到主 Actor 隔离的代码
// Swift 6.2: 通过隔离一致性解决
extension StickerModel: @MainActor Exportable {
    func export() {
        photoProcessor.exportAsPNG()
    }
}
```

编译器确保一致性只在主 Actor 上使用：

```swift
// 正确 — ImageExporter 也是 @MainActor
@MainActor
struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // 安全：相同的 Actor 隔离
    }
}

// 错误 — 非隔离上下文不能使用 MainActor 一致性
nonisolated struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // 错误：主 Actor 隔离的一致性不能在此使用
    }
}
```

## 核心模式 — 全局和静态变量

使用 MainActor 保护全局/静态状态：

```swift
// Swift 6.1: 错误 — 非 Sendable 类型可能有共享可变状态
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // 错误
}

// 修复：使用 @MainActor 标注
@MainActor
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // 正确
}
```

### MainActor 默认推断模式

Swift 6.2 引入了一种模式，MainActor 默认被推断 — 不需要手动标注：

```swift
// 启用 MainActor 默认推断后：
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // 隐式 @MainActor
}

final class StickerModel {
    let photoProcessor: PhotoProcessor
    var selection: [PhotosPickerItem]  // 隐式 @MainActor
}

extension StickerModel: Exportable {  // 隐式 @MainActor 一致性
    func export() {
        photoProcessor.exportAsPNG()
    }
}
```

此模式是可选的，推荐用于应用、脚本和其他可执行目标。

## 核心模式 — @concurrent 用于后台工作

当你需要真正的并行性时，使用 `@concurrent` 显式卸载：

> **重要：** 此示例需要 Approachable Concurrency 构建设置 — SE-0466（MainActor 默认隔离）和 SE-0461（NonisolatedNonsendingByDefault）。启用这些设置后，`extractSticker` 留在调用者的 Actor 上，使可变状态访问安全。**没有这些设置，此代码存在数据竞争** — 编译器会标记它。

```swift
nonisolated final class PhotoProcessor {
    private var cachedStickers: [String: Sticker] = [:]

    func extractSticker(data: Data, with id: String) async -> Sticker {
        if let sticker = cachedStickers[id] {
            return sticker
        }

        let sticker = await Self.extractSubject(from: data)
        cachedStickers[id] = sticker
        return sticker
    }

    // 将昂贵的工作卸载到并发线程池
    @concurrent
    static func extractSubject(from data: Data) async -> Sticker { /* ... */ }
}

// 调用者必须 await
let processor = PhotoProcessor()
processedPhotos[item.id] = await processor.extractSticker(data: data, with: item.id)
```

使用 `@concurrent` 的步骤：
1. 将包含类型标记为 `nonisolated`
2. 给函数添加 `@concurrent`
3. 如果尚未是异步的，添加 `async`
4. 在调用点添加 `await`

## 关键设计决策

| 决策 | 理由 |
|----------|------|
| 默认单线程 | 最自然的代码是数据竞争自由的；并发是可选的 |
| Async 留在调用 Actor 上 | 消除导致数据竞争错误的隐式卸载 |
| 隔离一致性 | MainActor 类型可以遵循协议而无需不安全的变通方案 |
| `@concurrent` 显式选择加入 | 后台执行是刻意的性能选择，而非意外的 |
| MainActor 默认推断 | 减少应用目标的样板 `@MainActor` 标注 |
| 可选采用 | 非破坏性迁移路径 — 逐步启用功能 |

## 迁移步骤

1. **在 Xcode 中启用**：Build Settings 中的 Swift Compiler > Concurrency 部分
2. **在 SPM 中启用**：在 package manifest 中使用 `SwiftSettings` API
3. **使用迁移工具**：通过 swift.org/migration 自动代码更改
4. **从 MainActor 默认值开始**：为应用目标启用推断模式
5. **在需要时添加 `@concurrent`**：先分析，再卸载热路径
6. **彻底测试**：数据竞争问题变为编译时错误

## 最佳实践

- **从 MainActor 开始** — 先写单线程代码，稍后优化
- **只在 CPU 密集型工作上使用 `@concurrent`** — 图像处理、压缩、复杂计算
- **为大多数是单线程的应用目标启用 MainActor 推断模式**
- **卸载前先分析** — 使用 Instruments 查找实际瓶颈
- **用 MainActor 保护全局变量** — 全局/静态可变状态需要 Actor 隔离
- **使用隔离一致性**而非 `nonisolated` 变通方案或 `@Sendable` 包装器
- **增量迁移** — 在构建设置中一次启用一个功能

## 应避免的反模式

- 对每个 async 函数都应用 `@concurrent`（大多数不需要后台执行）
- 使用 `nonisolated` 来抑制编译器错误而不理解隔离
- 在 Actor 提供相同安全性的情况下保留遗留 `DispatchQueue` 模式
- 在并发相关的 Foundation Models 代码中跳过 `model.availability` 检查
- 与编译器对抗 — 如果它报告数据竞争，代码确实有真实的并发问题
- 假设所有 async 代码都在后台运行（Swift 6.2 默认：留在调用 Actor 上）

## 何时使用

- 所有新的 Swift 6.2+ 项目（Approachable Concurrency 是推荐的默认设置）
- 从 Swift 5.x 或 6.0/6.1 并发迁移现有应用
- 在采用 Xcode 26 期间解决数据竞争安全编译器错误
- 构建以 MainActor 为中心的应用架构（大多数 UI 应用）
- 性能优化 — 将特定重型计算卸载到后台
