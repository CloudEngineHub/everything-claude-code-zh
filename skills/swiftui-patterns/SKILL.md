---
name: swiftui-patterns
description: SwiftUI 架构模式、使用 @Observable 的状态管理、视图组合、导航、性能优化和现代 iOS/macOS UI 最佳实践。
---

# SwiftUI 模式

用于在 Apple 平台上构建声明式、高性能用户界面的现代 SwiftUI 模式。涵盖 Observation 框架、视图组合、类型安全导航和性能优化。

## 何时激活

- 构建 SwiftUI 视图和管理状态（`@State`、`@Observable`、`@Binding`）
- 使用 `NavigationStack` 设计导航流程
- 构建视图模型和数据流
- 优化列表和复杂布局的渲染性能
- 使用环境值和 SwiftUI 中的依赖注入

## 状态管理

### 属性包装器选择

选择最简单的适用包装器：

| 包装器 | 用例 |
|---------|------|
| `@State` | 视图局部值类型（开关、表单字段、Sheet 展示） |
| `@Binding` | 对父级 `@State` 的双向引用 |
| `@Observable` 类 + `@State` | 拥有多个属性的自有模型 |
| `@Observable` 类（无包装器） | 从父级传递的只读引用 |
| `@Bindable` | 对 `@Observable` 属性的双向绑定 |
| `@Environment` | 通过 `.environment()` 注入的共享依赖 |

### @Observable ViewModel

使用 `@Observable`（而非 `ObservableObject`）— 它跟踪属性级别的变更，使 SwiftUI 只重新渲染读取了变更属性的视图：

```swift
@Observable
final class ItemListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    var searchText = ""

    private let repository: any ItemRepository

    init(repository: any ItemRepository = DefaultItemRepository()) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await repository.fetchAll()) ?? []
    }
}
```

### 使用 ViewModel 的视图

```swift
struct ItemListView: View {
    @State private var viewModel: ItemListViewModel

    init(viewModel: ItemListViewModel = ItemListViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
        .searchable(text: $viewModel.searchText)
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.load() }
    }
}
```

### 环境注入

用 `@Environment` 替代 `@EnvironmentObject`：

```swift
// 注入
ContentView()
    .environment(authManager)

// 消费
struct ProfileView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Text(auth.currentUser?.name ?? "Guest")
    }
}
```

## 视图组合

### 提取子视图以限制失效范围

将视图拆分为小型、聚焦的结构体。当状态变更时，只有读取了该状态的子视图会重新渲染：

```swift
struct OrderView: View {
    @State private var viewModel = OrderViewModel()

    var body: some View {
        VStack {
            OrderHeader(title: viewModel.title)
            OrderItemList(items: viewModel.items)
            OrderTotal(total: viewModel.total)
        }
    }
}
```

### ViewModifier 用于可复用的样式

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

## 导航

### 类型安全的 NavigationStack

使用 `NavigationStack` 配合 `NavigationPath` 实现程序化的类型安全路由：

```swift
@Observable
final class Router {
    var path = NavigationPath()

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

enum Destination: Hashable {
    case detail(Item.ID)
    case settings
    case profile(User.ID)
}

struct RootView: View {
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Destination.self) { dest in
                    switch dest {
                    case .detail(let id): ItemDetailView(itemID: id)
                    case .settings: SettingsView()
                    case .profile(let id): ProfileView(userID: id)
                    }
                }
        }
        .environment(router)
    }
}
```

## 性能

### 为大型集合使用惰性容器

`LazyVStack` 和 `LazyHStack` 只在可见时创建视图：

```swift
ScrollView {
    LazyVStack(spacing: 8) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### 稳定的标识符

始终在 `ForEach` 中使用稳定的唯一 ID — 避免使用数组索引：

```swift
// 使用 Identifiable 一致性或显式 id
ForEach(items, id: \.stableID) { item in
    ItemRow(item: item)
}
```

### 避免在 body 中执行昂贵操作

- 绝不在 `body` 中执行 I/O、网络调用或重度计算
- 使用 `.task {}` 进行异步工作 — 当视图消失时自动取消
- 在滚动视图中谨慎使用 `.sensoryFeedback()` 和 `.geometryGroup()`
- 在列表中最小化 `.shadow()`、`.blur()` 和 `.mask()` — 它们触发离屏渲染

### Equatable 一致性

对于具有昂贵 body 的视图，遵循 `Equatable` 以跳过不必要的重新渲染：

```swift
struct ExpensiveChartView: View, Equatable {
    let dataPoints: [DataPoint] // DataPoint 必须遵循 Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dataPoints == rhs.dataPoints
    }

    var body: some View {
        // 复杂的图表渲染
    }
}
```

## 预览

使用 `#Preview` 宏配合内联模拟数据进行快速迭代：

```swift
#Preview("空状态") {
    ItemListView(viewModel: ItemListViewModel(repository: EmptyMockRepository()))
}

#Preview("已加载") {
    ItemListView(viewModel: ItemListViewModel(repository: PopulatedMockRepository()))
}
```

## 应避免的反模式

- 在新代码中使用 `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` — 迁移到 `@Observable`
- 在 `body` 或 `init` 中直接放入异步工作 — 使用 `.task {}` 或显式加载方法
- 在不拥有数据的子视图中将视图模型创建为 `@State` — 应从父级传递
- 使用 `AnyView` 类型擦除 — 对条件视图优先使用 `@ViewBuilder` 或 `Group`
- 在向/从 Actor 传递数据时忽略 `Sendable` 要求

## 参考文献

参见技能：`swift-actor-persistence` 了解基于 Actor 的持久化模式。
参见技能：`swift-protocol-di-testing` 了解基于协议的依赖注入和 Swift Testing 测试。
