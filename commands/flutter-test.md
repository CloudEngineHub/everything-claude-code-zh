---
description: 运行 Flutter/Dart 测试，报告失败并增量修复测试问题。涵盖单元测试、Widget 测试、Golden 测试和集成测试。
---

# Flutter 测试

此命令运行 Flutter 测试套件并报告结果。当出现失败时，它会诊断并增量修复问题。

## 此命令的作用

1. **运行测试**：执行 `flutter test`（或限定为已更改的文件）
2. **解析失败**：按类型和原因识别失败的测试
3. **增量修复**：在可能的情况下一次修复一个失败
4. **验证**：每次修复后重新运行
5. **报告**：显示覆盖率摘要和剩余失败

## 何时使用

在以下情况使用 `/flutter-test`：
- 实现功能后验证没有破坏
- 运行 `/flutter-build` 后确保测试通过
- 检查新代码的测试覆盖
- 当特定测试文件失败时
- 提交 PR 之前

## 运行的命令

```bash
# 运行所有测试
flutter test 2>&1

# 带覆盖率运行
flutter test --coverage 2>&1

# 运行特定测试文件
flutter test test/unit/domain/usecases/get_user_test.dart 2>&1

# 运行匹配名称模式的测试
flutter test --name "CartBloc" 2>&1

# 运行集成测试（需要设备/模拟器）
flutter test integration_test/ 2>&1

# 当有意的视觉变更时更新 golden 文件
flutter test --update-goldens 2>&1
```

## 示例会话

````text
用户: /flutter-test

智能体:
# Flutter 测试运行

## 测试执行

```
$ flutter test
00:05 +42 -2: Some tests failed.

FAILED: test/unit/data/user_repository_test.dart
  UserRepository getById
    returns null when user not found
    Expected: null
    Actual: User(id: 'test-id', name: 'Test User')

FAILED: test/widget/cart_page_test.dart
  CartPage
    shows empty state when cart is empty
    Expected: exactly one widget with text 'Your cart is empty'
    Found: no widget with text 'Your cart is empty'
```

## 修复 1：仓库测试

文件: test/unit/data/user_repository_test.dart
失败: `getById` 在应该对缺失 ID 返回 null 时返回了用户

根本原因: 测试设置添加了 ID 为 'test-id' 的用户，但查询使用的是 'missing-id'。
修复: 更新测试查询为 'missing-id' — 设置是正确的，查询是错误的。

```
$ flutter test test/unit/data/user_repository_test.dart
1 test passed.
```

## 修复 2：Widget 测试

文件: test/widget/cart_page_test.dart
失败: 空状态文本 widget 未找到

根本原因: 空状态消息在 widget 中从 'Your cart is empty' 重命名为 'Cart is empty'。
修复: 更新测试字符串以匹配当前 widget 副本。

```
$ flutter test test/widget/cart_page_test.dart
1 test passed.
```

## 最终运行

```
$ flutter test --coverage
All 44 tests passed.
Coverage: 84.2% (目标: 80%)
```

## 摘要

| 指标 | 值 |
|------|-----|
| 总测试数 | 44 |
| 通过 | 44 |
| 失败 | 0 |
| 覆盖率 | 84.2% |

测试状态: PASS ✓
````

## 常见测试失败

| 失败 | 典型修复 |
|------|----------|
| `Expected: <X> Actual: <Y>` | 更新断言或修复实现 |
| `Widget not found` | 修复 finder 选择器或在 widget 重命名后更新测试 |
| `Golden file not found` | 运行 `flutter test --update-goldens` 生成 |
| `Golden mismatch` | 检查差异；如果变更是有意的，运行 `--update-goldens` |
| `MissingPluginException` | 在测试设置中 mock 平台通道 |
| `LateInitializationError` | 在 `setUp()` 中初始化 `late` 字段 |
| `pumpAndSettle timed out` | 替换为显式 `pump(Duration)` 调用 |

## 相关命令

- `/flutter-build` — 运行测试前先修复构建错误
- `/flutter-review` — 测试通过后审查代码
- `tdd-workflow` 技能 — 测试驱动开发工作流

## 相关

- 智能体: `agents/flutter-reviewer.md`
- 智能体: `agents/dart-build-resolver.md`
- 技能: `skills/flutter-dart-code-review/`
- 规则: `rules/dart/testing.md`
