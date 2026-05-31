---
name: flutter-dart-code-review
description: 库无关的 Flutter/Dart 代码审查清单，涵盖 Widget 最佳实践、状态管理模式（BLoC、Riverpod、Provider、GetX、MobX、Signals）、Dart 惯用法、性能、无障碍、安全和整洁架构。
origin: ECC
---

# Flutter/Dart 代码审查最佳实践

全面的、库无关的 Flutter/Dart 应用审查清单。无论使用哪种状态管理方案、路由库或 DI 框架，这些原则都适用。

---

## 1. 通用项目健康

- [ ] 项目遵循一致的文件夹结构（特性优先或层级优先）
- [ ] 适当的关注点分离：UI、业务逻辑、数据层
- [ ] Widget 中没有业务逻辑；Widget 纯粹用于展示
- [ ] `pubspec.yaml` 干净——没有未使用的依赖，版本适当固定
- [ ] `analysis_options.yaml` 包含严格的分析器设置
- [ ] 生产代码中没有 `print()` 语句——使用 `dart:developer` `log()` 或日志包
- [ ] 生成的文件（`.g.dart`、`.freezed.dart`、`.gr.dart`）是最新的或在 `.gitignore` 中
- [ ] 平台特定代码被隔离在抽象之后

---

## 2. Dart 语言陷阱

- [ ] **隐式 dynamic**：缺少类型注解导致 `dynamic`——启用 `strict-casts`、`strict-inference`、`strict-raw-types`
- [ ] **空安全误用**：过度使用 `!`（bang 操作符）而非适当的空值检查或 Dart 3 模式匹配（`if (value case var v?)`）
- [ ] **类型提升失败**：使用 `this.field` 而非局部变量提升
- [ ] **捕获过于宽泛**：`catch (e)` 没有 `on` 子句；始终指定异常类型
- [ ] **捕获 `Error`**：`Error` 子类型表示 bug，不应被捕获
- [ ] **未使用的 `async`**：标记为 `async` 但从不 `await` 的函数——不必要的开销
- [ ] **`late` 过度使用**：在可空或构造函数初始化更安全的地方使用 `late`；将错误推迟到运行时
- [ ] **循环中的字符串拼接**：使用 `StringBuffer` 而非 `+` 进行迭代式字符串构建
- [ ] **`const` 上下文中的可变状态**：`const` 构造函数类中的字段不应可变
- [ ] **忽略 `Future` 返回值**：使用 `await` 或显式调用 `unawaited()` 表明意图
- [ ] **能用 `final` 时用了 `var`**：局部变量优先用 `final`，编译时常量用 `const`
- [ ] **相对导入**：使用 `package:` 导入保持一致性
- [ ] **暴露可变集合**：公共 API 应返回不可修改的视图，而非原始 `List`/`Map`
- [ ] **缺少 Dart 3 模式匹配**：优先用 switch 表达式和 `if-case` 而非冗长的 `is` 检查和手动类型转换
- [ ] **多个返回值的临时类**：使用 Dart 3 记录 `(String, int)` 而非一次性 DTO
- [ ] **生产代码中的 `print()`**：使用 `dart:developer` `log()` 或项目的日志包；`print()` 没有日志级别且无法过滤

---

## 3. Widget 最佳实践

### Widget 分解：
- [ ] 没有单个 Widget 的 `build()` 方法超过约 80-100 行
- [ ] Widget 按封装方式和变更方式拆分（重建边界）
- [ ] 返回 Widget 的私有 `_build*()` 辅助方法被提取为单独的 Widget 类（启用元素复用、const 传播和框架优化）
- [ ] 在不需要可变局部状态时优先使用 StatelessWidget
- [ ] 可复用的提取 Widget 放在单独文件中

### Const 使用：
- [ ] 尽可能使用 `const` 构造函数——防止不必要的重建
- [ ] 不改变的集合使用 `const` 字面量（`const []`、`const {}`）
- [ ] 当所有字段为 final 时构造函数声明为 `const`

### Key 使用：
- [ ] 列表/网格中使用 `ValueKey` 在重排序时保留状态
- [ ] 谨慎使用 `GlobalKey`——仅在真正需要跨树访问状态时使用
- [ ] `build()` 中避免 `UniqueKey`——它会强制每帧重建
- [ ] 当身份基于数据对象而非单个值时使用 `ObjectKey`

### 主题和设计系统：
- [ ] 颜色来自 `Theme.of(context).colorScheme`——没有硬编码的 `Colors.red` 或十六进制值
- [ ] 文本样式来自 `Theme.of(context).textTheme`——没有带原始字体大小的内联 `TextStyle`
- [ ] 验证了深色模式兼容性——不假设浅色背景
- [ ] 间距和尺寸使用一致的设计令牌或常量，没有魔术数字

### build 方法复杂度：
- [ ] `build()` 中没有网络调用、文件 I/O 或繁重计算
- [ ] `build()` 中没有 `Future.then()` 或 `async` 工作
- [ ] `build()` 中没有创建订阅（`.listen()`）
- [ ] `setState()` 局限于最小的子树

---

## 4. 状态管理（库无关）

这些原则适用于所有 Flutter 状态管理方案（BLoC、Riverpod、Provider、GetX、MobX、Signals、ValueNotifier 等）。

### 架构：
- [ ] 业务逻辑在 Widget 层之外——在状态管理组件中（BLoC、Notifier、Controller、Store、ViewModel 等）
- [ ] 状态管理器通过注入接收依赖，而非内部构造
- [ ] 服务或仓库层抽象数据源——Widget 和状态管理器不应直接调用 API 或数据库
- [ ] 状态管理器具有单一职责——没有处理不相关关注的"上帝"管理器
- [ ] 跨组件依赖遵循方案的约定：
  - **Riverpod**：提供者通过 `ref.watch` 依赖提供者是预期的——仅标记循环或过度纠缠的链
  - **BLoC**：bloc 不应直接依赖其他 bloc——优先使用共享仓库或表现层协调
  - 其他方案：遵循文档化的组件间通信约定

### 不可变性和值相等（用于不可变状态方案：BLoC、Riverpod、Redux）：
- [ ] 状态对象不可变——通过 `copyWith()` 或构造函数创建新实例，从不原地修改
- [ ] 状态类正确实现 `==` 和 `hashCode`（所有字段包含在比较中）
- [ ] 机制在项目中保持一致——手动覆盖、`Equatable`、`freezed`、Dart 记录或其他
- [ ] 状态对象内的集合不作为原始可变 `List`/`Map` 暴露

### 响应性规范（用于响应式修改方案：MobX、GetX、Signals）：
- [ ] 状态仅通过方案的响应式 API 变更（MobX 中的 `@action`、Signals 中的 `.value`、GetX 中的 `.obs`）——直接字段修改绕过变更跟踪
- [ ] 派生值使用方案的计算机制而非冗余存储
- [ ] 响应和清理器被正确清理（MobX 中的 `ReactionDisposer`、Signals 中的 effect 清理）

### 状态形状设计：
- [ ] 互斥状态使用密封类型、联合变体或方案内置的异步状态类型（如 Riverpod 的 `AsyncValue`）——而非布尔标志（`isLoading`、`isError`、`hasData`）
- [ ] 每个异步操作建模加载、成功和错误为不同状态
- [ ] 所有状态变体在 UI 中穷尽处理——没有静默忽略的情况
- [ ] 错误状态携带错误信息用于显示；加载状态不携带过期数据
- [ ] 可空数据不用作加载指示器——状态是显式的

```dart
// 错误——布尔标志组合允许不可能的状态
class UserState {
  bool isLoading = false;
  bool hasError = false; // isLoading && hasError 是可表示的！
  User? user;
}

// 正确（不可变方式）——密封类型使不可能的状态不可表示
sealed class UserState {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final User user;
  const UserLoaded(this.user);
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
}

// 正确（响应式方式）——可观察枚举 + 数据，通过响应式 API 变更
// enum UserStatus { initial, loading, loaded, error }
// 使用你的方案的可观察/信号来分别包装状态和数据
```

### 重建优化：
- [ ] 状态消费者 Widget（Builder、Consumer、Observer、Obx、Watch 等）范围尽可能窄
- [ ] 使用选择器仅在特定字段变更时重建——而非每次状态发射时
- [ ] 使用 `const` Widget 阻止重建传播穿透树
- [ ] 计算/派生状态响应式计算，而非冗余存储

### 订阅和释放：
- [ ] 所有手动订阅（`.listen()`）在 `dispose()` / `close()` 中取消
- [ ] 流控制器在不再需要时关闭
- [ ] 定时器在释放生命周期中取消
- [ ] 优先使用框架管理的生命周期而非手动订阅（声明式构建器优于 `.listen()`）
- [ ] 异步回调中 `setState` 前检查 `mounted`
- [ ] `await` 后不使用 `BuildContext` 而不检查 `context.mounted`（Flutter 3.7+）——过期上下文导致崩溃
- [ ] 异步间隔后没有导航、对话框或 scaffold 消息，除非验证 Widget 仍挂载
- [ ] `BuildContext` 永远不存储在单例、状态管理器或静态字段中

### 局部与全局状态：
- [ ] 短暂的 UI 状态（复选框、滑块、动画）使用局部状态（`setState`、`ValueNotifier`）
- [ ] 共享状态仅提升到所需高度——不过度全局化
- [ ] 特性范围的状态在特性不再活跃时正确释放

---

## 5. 性能

### 不必要的重建：
- [ ] `setState()` 不在根 Widget 级别调用——局部化状态变更
- [ ] 使用 `const` Widget 阻止重建传播
- [ ] 在独立重绘的复杂子树周围使用 `RepaintBoundary`
- [ ] `AnimatedBuilder` 的 child 参数用于与动画无关的子树

### build() 中的昂贵操作：
- [ ] `build()` 中没有排序、过滤或映射大集合——在状态管理层计算
- [ ] `build()` 中没有正则编译
- [ ] `MediaQuery.of(context)` 使用特定的方法（如 `MediaQuery.sizeOf(context)`）

### 图像优化：
- [ ] 网络图像使用缓存（适合项目的任何缓存方案）
- [ ] 目标设备使用适当的图像分辨率（不为缩略图加载 4K 图像）
- [ ] `Image.asset` 使用 `cacheWidth`/`cacheHeight` 以显示尺寸解码
- [ ] 为网络图像提供占位符和错误 Widget

### 懒加载：
- [ ] 大型或动态列表使用 `ListView.builder` / `GridView.builder` 而非 `ListView(children: [...])`（小型静态列表使用具体构造函数没问题）
- [ ] 大数据集实现分页
- [ ] Web 构建中对重型库使用延迟加载（`deferred as`）

### 其他：
- [ ] 动画中避免 `Opacity` Widget——使用 `AnimatedOpacity` 或 `FadeTransition`
- [ ] 动画中避免裁剪——预裁剪图像
- [ ] 不在 Widget 上重写 `operator ==`——改用 `const` 构造函数
- [ ] 内在尺寸 Widget（`IntrinsicHeight`、`IntrinsicWidth`）谨慎使用（额外布局遍历）

---

## 6. 测试

### 测试类型和期望：
- [ ] **单元测试**：覆盖所有业务逻辑（状态管理器、仓库、工具函数）
- [ ] **Widget 测试**：覆盖单个 Widget 行为、交互和视觉输出
- [ ] **集成测试**：端到端覆盖关键用户流程
- [ ] **Golden 测试**：对设计关键的 UI 组件进行像素级精确比较

### 覆盖率目标：
- [ ] 业务逻辑目标 80%+ 行覆盖率
- [ ] 所有状态转换有对应测试（加载 -> 成功、加载 -> 错误、重试等）
- [ ] 边缘案例已测试：空状态、错误状态、加载状态、边界值

### 测试隔离：
- [ ] 外部依赖（API 客户端、数据库、服务）被 mock 或 fake
- [ ] 每个测试文件只测试一个类/单元
- [ ] 测试验证行为，而非实现细节
- [ ] Stub 仅定义每个测试所需的行为（最小 stub）
- [ ] 测试用例之间没有共享的可变状态

### Widget 测试质量：
- [ ] 正确使用 `pumpWidget` 和 `pump` 进行异步操作
- [ ] 适当使用 `find.byType`、`find.text`、`find.byKey`
- [ ] 没有依赖时序的不稳定测试——使用 `pumpAndSettle` 或显式 `pump(Duration)`
- [ ] 测试在 CI 中运行，失败阻止合并

---

## 7. 无障碍

### 语义化 Widget：
- [ ] 使用 `Semantics` Widget 在自动标签不足处提供屏幕阅读器标签
- [ ] 对纯装饰元素使用 `ExcludeSemantics`
- [ ] 使用 `MergeSemantics` 将相关 Widget 合并为单个可访问元素
- [ ] 图像设置了 `semanticLabel` 属性

### 屏幕阅读器支持：
- [ ] 所有交互元素可聚焦且有意义描述
- [ ] 焦点顺序符合逻辑（遵循视觉阅读顺序）

### 视觉无障碍：
- [ ] 文本与背景的对比度 >= 4.5:1
- [ ] 可点击目标至少 48x48 像素
- [ ] 颜色不是状态的唯一指示器（使用图标/文本并列）
- [ ] 文本随系统字体大小设置缩放

### 交互无障碍：
- [ ] 没有空操作 `onPressed` 回调——每个按钮执行操作或被禁用
- [ ] 错误字段建议纠正
- [ ] 用户输入数据时上下文不会意外改变

---

## 8. 平台特定关注

### iOS/Android 差异：
- [ ] 适当时使用平台自适应 Widget
- [ ] 正确处理返回导航（Android 返回按钮、iOS 滑动返回）
- [ ] 通过 `SafeArea` Widget 处理状态栏和安全区域
- [ ] 平台特定权限在 `AndroidManifest.xml` 和 `Info.plist` 中声明

### 响应式设计：
- [ ] 使用 `LayoutBuilder` 或 `MediaQuery` 进行响应式布局
- [ ] 断点定义一致（手机、平板、桌面）
- [ ] 文本在小屏幕上不溢出——使用 `Flexible`、`Expanded`、`FittedBox`
- [ ] 测试或显式锁定横屏方向
- [ ] Web 特定：支持鼠标/键盘交互，存在悬停状态

---

## 9. 安全

### 安全存储：
- [ ] 敏感数据（令牌、凭证）使用平台安全存储（iOS Keychain、Android EncryptedSharedPreferences）
- [ ] 永远不在明文存储中保存密钥
- [ ] 敏感操作考虑生物识别认证门控

### API 密钥处理：
- [ ] API 密钥未硬编码在 Dart 源码中——使用 `--dart-define`、排除在 VCS 外的 `.env` 文件或编译时配置
- [ ] 密钥未提交到 git——检查 `.gitignore`
- [ ] 真正机密的密钥使用后端代理（客户端不应持有服务器密钥）

### 输入验证：
- [ ] 所有用户输入在发送到 API 前验证
- [ ] 表单验证使用适当的验证模式
- [ ] 没有原始 SQL 或用户输入的字符串插值
- [ ] 深度链接 URL 在导航前验证和清理

### 网络安全：
- [ ] 所有 API 调用强制 HTTPS
- [ ] 高安全性应用考虑证书固定
- [ ] 认证令牌正确刷新和过期
- [ ] 没有敏感数据被记录或打印

---

## 10. 包/依赖审查

### 评估 pub.dev 包：
- [ ] 检查 **pub points 评分**（目标 130+/160）
- [ ] 检查 **likes** 和 **popularity** 作为社区信号
- [ ] 验证发布者在 pub.dev 上已 **验证**
- [ ] 检查最后发布日期——过时的包（>1 年）有风险
- [ ] 审查未解决问题和维护者响应时间
- [ ] 检查许可证与项目的兼容性
- [ ] 验证平台支持覆盖你的目标

### 版本约束：
- [ ] 使用脱字符语法（`^1.2.3`）——允许兼容更新
- [ ] 仅在绝对必要时固定精确版本
- [ ] 定期运行 `flutter pub outdated` 跟踪过时依赖
- [ ] 生产 `pubspec.yaml` 中没有依赖覆盖——仅用于临时修复并附注释/issue 链接
- [ ] 最小化传递依赖数量——每个依赖都是攻击面

### Monorepo 特定（melos/workspace）：
- [ ] 内部包仅从公共 API 导入——不使用 `package:other/src/internal.dart`（破坏 Dart 包封装）
- [ ] 内部包依赖使用 workspace 解析，而非硬编码的 `path: ../../` 相对字符串
- [ ] 所有子包共享或继承根 `analysis_options.yaml`

---

## 11. 导航和路由

### 通用原则（适用于任何路由方案）：
- [ ] 一致使用一种路由方式——不混合命令式 `Navigator.push` 和声明式路由器
- [ ] 路由参数是类型化的——没有 `Map<String, dynamic>` 或 `Object?` 类型转换
- [ ] 路由路径定义为常量、枚举或生成的——没有散布在代码中的魔术字符串
- [ ] 认证守卫/重定向集中——不在单个屏幕中重复
- [ ] Android 和 iOS 都配置了深度链接
- [ ] 深度链接 URL 在导航前验证和清理
- [ ] 导航状态可测试——路由变更可在测试中验证
- [ ] 所有平台上返回行为正确

---

## 12. 错误处理

### 框架错误处理：
- [ ] 覆写 `FlutterError.onError` 捕获框架错误（build、layout、paint）
- [ ] 设置 `PlatformDispatcher.instance.onError` 处理 Flutter 未捕获的异步错误
- [ ] 自定义 `ErrorWidget.builder` 用于发布模式（用户友好而非红色屏幕）
- [ ] `runApp` 周围的全局错误捕获包装器（如 `runZonedGuarded`、Sentry/Crashlytics 包装器）

### 错误报告：
- [ ] 集成错误报告服务（Firebase Crashlytics、Sentry 或等效服务）
- [ ] 非致命错误附堆栈跟踪报告
- [ ] 状态管理错误观察者连接到错误报告（如 BlocObserver、ProviderObserver 或你方案的等效项）
- [ ] 错误报告附用户可识别信息（用户 ID）用于调试

### 优雅降级：
- [ ] API 错误导致用户友好的错误 UI，而非崩溃
- [ ] 瞬态网络故障有重试机制
- [ ] 离线状态优雅处理
- [ ] 状态管理中的错误状态携带错误信息用于显示
- [ ] 原始异常（网络、解析）在到达 UI 前映射为用户友好的、本地化的消息——永远不向用户显示原始异常字符串

---

## 13. 国际化（l10n）

### 设置：
- [ ] 配置了本地化方案（Flutter 内置 ARB/l10n、easy_localization 或等效方案）
- [ ] 在应用配置中声明支持的语言环境

### 内容：
- [ ] 所有用户可见字符串使用本地化系统——Widget 中没有硬编码字符串
- [ ] 模板文件包含翻译者的描述/上下文
- [ ] 复数、性别、选择使用 ICU 消息语法
- [ ] 占位符定义了类型
- [ ] 语言环境之间没有缺失键

### 代码审查：
- [ ] 项目中一致使用本地化访问器
- [ ] 日期、时间、数字和货币格式是语言环境感知的
- [ ] 文本方向（RTL）支持如果面向阿拉伯语、希伯来语等
- [ ] 本地化文本没有字符串拼接——使用参数化消息

---

## 14. 依赖注入

### 原则（适用于任何 DI 方式）：
- [ ] 类依赖于抽象（接口），而非层边界处的具体实现
- [ ] 依赖通过构造函数、DI 框架或提供者图外部提供——而非内部创建
- [ ] 注册区分生命周期：单例 vs 工厂 vs 懒单例
- [ ] 环境特定绑定（开发/预发/生产）使用配置，而非运行时 `if` 检查
- [ ] DI 图中没有循环依赖
- [ ] 服务定位器调用（如果使用）不散布在业务逻辑中

---

## 15. 静态分析

### 配置：
- [ ] 存在 `analysis_options.yaml` 并启用了严格设置
- [ ] 严格分析器设置：`strict-casts: true`、`strict-inference: true`、`strict-raw-types: true`
- [ ] 包含全面的 lint 规则集（very_good_analysis、flutter_lints 或自定义严格规则）
- [ ] Monorepo 中所有子包继承或共享根分析选项

### 执行：
- [ ] 提交的代码中没有未解决的分析器警告
- [ ] Lint 抑制（`// ignore:`）有注释解释原因
- [ ] `flutter analyze` 在 CI 中运行，失败阻止合并

### 无论使用哪个 lint 包都应验证的关键规则：
- [ ] `prefer_const_constructors` — Widget 树中的性能
- [ ] `avoid_print` — 使用适当的日志
- [ ] `unawaited_futures` — 防止即发即忘的异步 bug
- [ ] `prefer_final_locals` — 变量级别的不可变性
- [ ] `always_declare_return_types` — 显式契约
- [ ] `avoid_catches_without_on_clauses` — 特定的错误处理
- [ ] `always_use_package_imports` — 一致的导入风格

---

## 状态管理快速参考

下表将通用原则映射到流行方案中的实现。使用此表将审查规则调整为项目使用的方案。

| 原则 | BLoC/Cubit | Riverpod | Provider | GetX | MobX | Signals | 内置 |
|-----------|-----------|----------|----------|------|------|---------|----------|
| 状态容器 | `Bloc`/`Cubit` | `Notifier`/`AsyncNotifier` | `ChangeNotifier` | `GetxController` | `Store` | `signal()` | `StatefulWidget` |
| UI 消费者 | `BlocBuilder` | `ConsumerWidget` | `Consumer` | `Obx`/`GetBuilder` | `Observer` | `Watch` | `setState` |
| 选择器 | `BlocSelector`/`buildWhen` | `ref.watch(p.select(...))` | `Selector` | N/A | computed | `computed()` | N/A |
| 副作用 | `BlocListener` | `ref.listen` | `Consumer` 回调 | `ever()`/`once()` | `reaction` | `effect()` | 回调 |
| 释放 | 通过 `BlocProvider` 自动 | `.autoDispose` | 通过 `Provider` 自动 | `onClose()` | `ReactionDisposer` | 手动 | `dispose()` |
| 测试 | `blocTest()` | `ProviderContainer` | 直接 `ChangeNotifier` | 测试中 `Get.put` | 直接 store | 直接 signal | Widget 测试 |

---

## 来源

- [Effective Dart: 风格](https://dart.dev/effective-dart/style)
- [Effective Dart: 用法](https://dart.dev/effective-dart/usage)
- [Effective Dart: 设计](https://dart.dev/effective-dart/design)
- [Flutter 性能最佳实践](https://docs.flutter.dev/perf/best-practices)
- [Flutter 测试概览](https://docs.flutter.dev/testing/overview)
- [Flutter 无障碍](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Flutter 国际化](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [Flutter 导航和路由](https://docs.flutter.dev/ui/navigation)
- [Flutter 错误处理](https://docs.flutter.dev/testing/errors)
- [Flutter 状态管理选项](https://docs.flutter.dev/data-and-backend/state-mgmt/options)
