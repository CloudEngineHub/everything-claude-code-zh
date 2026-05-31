---
description: 增量修复 Dart 分析器错误和 Flutter 构建失败。调用 dart-build-resolver 智能体进行最小化、精准的修复。
---

# Flutter 构建和修复

此命令调用 **dart-build-resolver** 智能体，以最小变更增量修复 Dart/Flutter 构建错误。

## 此命令的作用

1. **运行诊断**：执行 `flutter analyze`、`flutter pub get`
2. **解析错误**：按文件分组并按严重程度排序
3. **增量修复**：一次修复一个错误
4. **验证每次修复**：每次更改后重新运行分析
5. **报告摘要**：显示已修复和剩余的问题

## 何时使用

在以下情况使用 `/flutter-build`：
- `flutter analyze` 报告错误
- `flutter build` 在任何平台失败
- `dart pub get` / `flutter pub get` 因版本冲突失败
- `build_runner` 代码生成失败
- 拉取更改后构建失败

## 运行的诊断命令

```bash
# 分析
flutter analyze 2>&1

# 依赖
flutter pub get 2>&1

# 代码生成（如果项目使用 build_runner）
dart run build_runner build --delete-conflicting-outputs 2>&1

# 平台构建
flutter build apk 2>&1
flutter build web 2>&1
```

## 示例会话

````text
用户: /flutter-build

智能体:
# Flutter 构建修复

## 初始诊断

```
$ flutter analyze
Analyzing project...

  error • lib/features/user/data/user_repository_impl.dart:34:16 •
    A value of type 'String?' can't be assigned to a variable of type 'String'. •
    invalid_assignment

  error • lib/features/cart/presentation/cart_page.dart:58:5 •
    The method 'add' isn't defined for the type 'List<Item>'.
    Try correcting the name to the name of an existing method, or defining a method named 'add'. •
    undefined_method

2 errors found.
```

## 修复 1：空安全

文件: lib/features/user/data/user_repository_impl.dart:34
错误: A value of type 'String?' can't be assigned to type 'String'

修改前：
```dart
final id = response.id;
```
修改后：
```dart
final id = response.id ?? '';
```

```
$ flutter analyze
1 error found.
```

## 修复 2：不可变列表

文件: lib/features/cart/presentation/cart_page.dart:58
错误: The method 'add' isn't defined for the type 'List<Item>'
原因: State 持有不可修改的列表；变更应通过 Cubit 进行

修改前：
```dart
state.items.add(item);
```
修改后：
```dart
context.read<CartCubit>().addItem(item);
// 注意: Cubit 暴露命名方法（addItem, removeItem）；
// .add(event) 是 BLoC 事件 API —— 不要混淆使用。
```

```
$ flutter analyze
No issues found!
```

## 最终验证

```
$ flutter test
All tests passed.
```

## 摘要

| 指标 | 数量 |
|------|------|
| 已修复分析错误 | 2 |
| 已修改文件 | 2 |
| 剩余问题 | 0 |

构建状态: PASS ✓
````

## 常见修复的错误

| 错误 | 典型修复 |
|------|----------|
| `A value of type 'X?' can't be assigned to 'X'` | 添加 `?? default` 或空值守卫 |
| `The name 'X' isn't defined` | 添加 import 或修复拼写错误 |
| `Non-nullable instance field must be initialized` | 添加初始化器或 `late` |
| `Version solving failed` | 调整 pubspec.yaml 中的版本约束 |
| `Missing concrete implementation of 'X'` | 实现缺失的接口方法 |
| `build_runner: Part of X expected` | 删除过时的 `.g.dart` 并重新构建 |

## 修复策略

1. **分析错误优先** - 代码必须无错误
2. **警告分类其次** - 修复可能导致运行时 bug 的警告
3. **pub 冲突第三** - 修复依赖解析
4. **每次只修复一个** - 验证每项更改
5. **最小变更** - 不重构，只修复

## 停止条件

智能体将在以下情况停止并报告：
- 同一错误在 3 次尝试后仍然存在
- 修复引入了更多错误
- 需要架构变更
- 包升级冲突需要用户决定

## 相关命令

- `/flutter-test` — 构建成功后运行测试
- `/flutter-review` — 审查代码质量
- `verification-loop` 技能 — 完整验证循环

## 相关

- 智能体: `agents/dart-build-resolver.md`
- 技能: `skills/flutter-dart-code-review/`
