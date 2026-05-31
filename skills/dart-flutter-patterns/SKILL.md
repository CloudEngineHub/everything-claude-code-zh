---
name: dart-flutter-patterns
description: 生产就绪的 Dart 和 Flutter 模式，涵盖空安全、不可变状态、异步组合、Widget 架构、主流状态管理框架（BLoC、Riverpod、Provider）、GoRouter 导航、Dio 网络请求、Freezed 代码生成和整洁架构。
origin: ECC
---

# Dart/Flutter 模式

## 何时使用

在以下情况使用此技能：
- 开始新的 Flutter 功能开发，需要状态管理、导航或数据访问的惯用模式
- 审查或编写 Dart 代码，需要空安全、sealed 类型或异步组合方面的指导
- 搭建新的 Flutter 项目，需要在 BLoC、Riverpod 或 Provider 之间做选择
- 实现安全的 HTTP 客户端、WebView 集成或本地存储
- 为 Flutter Widget、Cubit 或 Riverpod Provider 编写测试
- 配置带认证守卫的 GoRouter

## 工作原理

此技能提供可直接复制粘贴的 Dart/Flutter 代码模式，按关注点组织：
1. **空安全** — 避免 `!`，优先使用 `?.`/`??`/模式匹配
2. **不可变状态** — sealed class、`freezed`、`copyWith`
3. **异步组合** — 并发 `Future.wait`、`await` 后安全的 `BuildContext`
4. **Widget 架构** — 提取为类（而非方法）、`const` 传播、作用域重建
5. **状态管理** — BLoC/Cubit 事件、Riverpod notifier 和派生 provider
6. **导航** — 通过 `refreshListenable` 实现响应式认证守卫的 GoRouter
7. **网络请求** — 带拦截器的 Dio、一次性重试守卫的 token 刷新
8. **错误处理** — 全局捕获、`ErrorWidget.builder`、crashlytics 集成
9. **测试** — 单元测试（BLoC test）、Widget 测试（ProviderScope 覆盖）、优先使用 fake 而非 mock

## 示例

```dart
// Sealed 状态 — 防止不可能的状态
sealed class AsyncState<T> {}
final class Loading<T> extends AsyncState<T> {}
final class Success<T> extends AsyncState<T> { final T data; const Success(this.data); }
final class Failure<T> extends AsyncState<T> { final Object error; const Failure(this.error); }

// 带响应式认证重定向的 GoRouter
final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(authCubit.stream),
  redirect: (context, state) {
    final authed = context.read<AuthCubit>().state is AuthAuthenticated;
    if (!authed && !state.matchedLocation.startsWith('/login')) return '/login';
    return null;
  },
  routes: [...],
);

// Riverpod 派生 provider，使用安全的 firstWhereOrNull
@riverpod
double cartTotal(Ref ref) {
  final cart = ref.watch(cartNotifierProvider);
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  return cart.fold(0.0, (total, item) {
    final product = products.firstWhereOrNull((p) => p.id == item.productId);
    return total + (product?.price ?? 0) * item.quantity;
  });
}
```

---

适用于 Dart 和 Flutter 应用的实用、生产就绪模式。尽可能与库无关，同时明确覆盖最常用的生态系统包。

---

## 1. 空安全基础

### 优先使用模式匹配而非强制解包

```dart
// 差 — 如果为 null 会在运行时崩溃
final name = user!.name;

// 好 — 提供回退值
final name = user?.name ?? 'Unknown';

// 好 — Dart 3 模式匹配（复杂情况优先使用）
final display = switch (user) {
  User(:final name, :final email) => '$name <$email>',
  null => 'Guest',
};

// 好 — 守卫提前返回
String getUserName(User? user) {
  if (user == null) return 'Unknown';
  return user.name; // 检查后提升为非空
}
```

### 避免过度使用 `late`

```dart
// 差 — 将 null 错误延迟到运行时
late String userId;

// 好 — 可空类型配合显式初始化
String? userId;

// 可以 — 仅当初始化保证在首次访问之前时使用 late
// （例如在 initState() 中，任何 widget 交互之前）
late final AnimationController _controller;

@override
void initState() {
  super.initState();
  _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
}
```

---

## 2. 不可变状态

### Sealed Class 用于状态层次

```dart
sealed class UserState {}

final class UserInitial extends UserState {}

final class UserLoading extends UserState {}

final class UserLoaded extends UserState {
  const UserLoaded(this.user);
  final User user;
}

final class UserError extends UserState {
  const UserError(this.message);
  final String message;
}

// 穷尽 switch — 编译器强制检查所有分支
Widget buildFrom(UserState state) => switch (state) {
  UserInitial() => const SizedBox.shrink(),
  UserLoading() => const CircularProgressIndicator(),
  UserLoaded(:final user) => UserCard(user: user),
  UserError(:final message) => ErrorText(message),
};
```

### Freezed 实现无样板代码的不可变性

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @Default(false) bool isAdmin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// 使用
final user = User(id: '1', name: 'Alice', email: 'alice@example.com');
final updated = user.copyWith(name: 'Alice Smith'); // 不可变更新
final json = user.toJson();
final fromJson = User.fromJson(json);
```

---

## 3. 异步组合

### 使用 Future.wait 实现结构化并发

```dart
Future<DashboardData> loadDashboard(UserRepository users, OrderRepository orders) async {
  // 并发运行 — 不要顺序等待
  final (userList, orderList) = await (
    users.getAll(),
    orders.getRecent(),
  ).wait; // Dart 3 record 解构 + Future.wait 扩展

  return DashboardData(users: userList, orders: orderList);
}
```

### Stream 模式

```dart
// Repository 暴露响应式 stream 用于实时数据
Stream<List<Item>> watchCartItems() => _db
    .watchTable('cart_items')
    .map((rows) => rows.map(Item.fromRow).toList());

// 在 Widget 层 — 声明式，无需手动订阅管理
StreamBuilder<List<Item>>(
  stream: cartRepository.watchCartItems(),
  builder: (context, snapshot) => switch (snapshot) {
    AsyncSnapshot(connectionState: ConnectionState.waiting) =>
        const CircularProgressIndicator(),
    AsyncSnapshot(:final error?) => ErrorWidget(error.toString()),
    AsyncSnapshot(:final data?) => CartList(items: data),
    _ => const SizedBox.shrink(),
  },
)
```

### await 后的 BuildContext

```dart
// 关键 — 在 StatefulWidget 中任何 await 之后始终检查 mounted
Future<void> _handleSubmit() async {
  setState(() => _isLoading = true);
  try {
    await authService.login(_email, _password);
    if (!mounted) return; // ← 使用 context 之前的守卫
    context.go('/home');
  } on AuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## 4. Widget 架构

### 提取为类，而非方法

```dart
// 差 — 返回 widget 的私有方法，阻止优化
Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
  );
}

// 好 — 独立的 Widget 类，启用 const，元素复用
class _PageHeader extends StatelessWidget {
  const _PageHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
```

### const 传播

```dart
// 差 — 每次重建都创建新实例
child: Padding(
  padding: EdgeInsets.all(16.0),       // 不是 const
  child: Icon(Icons.home, size: 24.0), // 不是 const
)

// 好 — const 阻止重建传播
child: const Padding(
  padding: EdgeInsets.all(16.0),
  child: Icon(Icons.home, size: 24.0),
)
```

### 作用域重建

```dart
// 差 — 每次计数变化时整个页面重建
class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider); // 重建所有内容
    return Scaffold(
      body: Column(children: [
        const ExpensiveHeader(), // 不必要地被重建
        Text('$count'),
        const ExpensiveFooter(), // 不必要地被重建
      ]),
    );
  }
}

// 好 — 隔离重建部分
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(children: [
        ExpensiveHeader(),        // 永远不会重建 (const)
        _CounterDisplay(),        // 只有这个会重建
        ExpensiveFooter(),        // 永远不会重建 (const)
      ]),
    );
  }
}

class _CounterDisplay extends ConsumerWidget {
  const _CounterDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

---

## 5. 状态管理：BLoC/Cubit

```dart
// Cubit — 同步或简单异步状态
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService) : super(const AuthState.initial());
  final AuthService _authService;

  Future<void> login(String email, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.login(email, password);
      emit(AuthState.authenticated(user));
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    }
  }

  void logout() {
    _authService.logout();
    emit(const AuthState.initial());
  }
}

// 在 Widget 中使用
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) => switch (state) {
    AuthInitial() => const LoginForm(),
    AuthLoading() => const CircularProgressIndicator(),
    AuthAuthenticated(:final user) => HomePage(user: user),
    AuthError(:final message) => ErrorView(message: message),
  },
)
```

---

## 6. 状态管理：Riverpod

```dart
// 自动释放的异步 provider
@riverpod
Future<List<Product>> products(Ref ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAll();
}

// 带复杂变更的 Notifier
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() => [];

  void add(Product product) {
    final existing = state.where((i) => i.productId == product.id).firstOrNull;
    if (existing != null) {
      state = [
        for (final item in state)
          if (item.productId == product.id) item.copyWith(quantity: item.quantity + 1)
          else item,
      ];
    } else {
      state = [...state, CartItem(productId: product.id, quantity: 1)];
    }
  }

  void remove(String productId) =>
      state = state.where((i) => i.productId != productId).toList();

  void clear() => state = [];
}

// 派生 provider（选择器模式）
@riverpod
int cartCount(Ref ref) => ref.watch(cartNotifierProvider).length;

@riverpod
double cartTotal(Ref ref) {
  final cart = ref.watch(cartNotifierProvider);
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  return cart.fold(0.0, (total, item) {
    // firstWhereOrNull（来自 collection 包）避免 product 缺失时的 StateError
    final product = products.firstWhereOrNull((p) => p.id == item.productId);
    return total + (product?.price ?? 0) * item.quantity;
  });
}
```

---

## 7. 使用 GoRouter 导航

```dart
final router = GoRouter(
  initialLocation: '/',
  // refreshListenable 在认证状态变化时重新评估重定向
  refreshListenable: GoRouterRefreshStream(authCubit.stream),
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthCubit>().state is AuthAuthenticated;
    final isGoingToLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !isGoingToLogin) return '/login';
    if (isLoggedIn && isGoingToLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) =>
              ProductDetailPage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
```

---

## 8. 使用 Dio 进行 HTTP 请求

```dart
final dio = Dio(BaseOptions(
  baseUrl: const String.fromEnvironment('API_URL'),
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Content-Type': 'application/json'},
));

// 添加认证拦截器
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await secureStorage.read(key: 'auth_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  },
  onError: (error, handler) async {
    // 防止无限重试循环：每个请求只尝试刷新一次
    final isRetry = error.requestOptions.extra['_isRetry'] == true;
    if (!isRetry && error.response?.statusCode == 401) {
      final refreshed = await attemptTokenRefresh();
      if (refreshed) {
        error.requestOptions.extra['_isRetry'] = true;
        return handler.resolve(await dio.fetch(error.requestOptions));
      }
    }
    handler.next(error);
  },
));

// 使用 Dio 的 Repository
class UserApiDataSource {
  const UserApiDataSource(this._dio);
  final Dio _dio;

  Future<User> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/users/$id');
    return User.fromJson(response.data!);
  }
}
```

---

## 9. 错误处理架构

```dart
// 全局错误捕获 — 在 main() 中设置
void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const App());
}

// 生产环境自定义 ErrorWidget
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (details) => ProductionErrorWidget(details);
    return MaterialApp.router(routerConfig: router);
  }
}
```

---

## 10. 测试快速参考

```dart
// 单元测试 — 用例
test('GetUserUseCase 对缺失用户返回 null', () async {
  final repo = FakeUserRepository();
  final useCase = GetUserUseCase(repo);
  expect(await useCase('missing-id'), isNull);
});

// BLoC 测试
blocTest<AuthCubit, AuthState>(
  '登录失败时发出 loading 然后 error',
  build: () => AuthCubit(FakeAuthService(throwsOn: 'login')),
  act: (cubit) => cubit.login('user@test.com', 'wrong'),
  expect: () => [const AuthState.loading(), isA<AuthError>()],
);

// Widget 测试
testWidgets('CartBadge 显示商品数量', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [cartNotifierProvider.overrideWith(() => FakeCartNotifier(count: 3))],
      child: const MaterialApp(home: CartBadge()),
    ),
  );
  expect(find.text('3'), findsOneWidget);
});
```

---

## 参考资料

- [Effective Dart: 设计](https://dart.dev/effective-dart/design)
- [Flutter 性能最佳实践](https://docs.flutter.dev/perf/best-practices)
- [Riverpod 文档](https://riverpod.dev/)
- [BLoC 库](https://bloclibrary.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [Freezed](https://pub.dev/packages/freezed)
- 技能：`flutter-dart-code-review` — 综合审查清单
- 规则：`rules/dart/` — 编码风格、模式、安全、测试、钩子
