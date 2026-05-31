---
description: 审查 Flutter/Dart 代码的惯用模式、Widget 最佳实践、状态管理、性能、可访问性和安全性。调用 flutter-reviewer 智能体。
---

# Flutter 代码审查

此命令调用 **flutter-reviewer** 智能体审查 Flutter/Dart 代码变更。

## 此命令的作用

1. **收集上下文**：审查 `git diff --staged` 和 `git diff`
2. **检查项目**：检查 `pubspec.yaml`、`analysis_options.yaml`、状态管理方案
3. **安全预扫描**：检查硬编码密钥和关键安全问题
4. **全面审查**：应用完整审查清单
5. **报告发现**：按严重程度分组输出问题并提供修复指导

## 前提条件

运行 `/flutter-review` 之前，请确保：
1. **构建通过** — 先运行 `/flutter-build`；对有错误的代码进行审查是不完整的
2. **测试通过** — 运行 `/flutter-test` 确认无回归
3. **无合并冲突** — 解决所有冲突，使 diff 仅反映有意变更
4. **`flutter analyze` 无警告** — 在审查前修复分析器警告

## 何时使用

在以下情况使用 `/flutter-review`：
- 提交包含 Flutter/Dart 变更的 PR 之前（构建和测试通过后）
- 实现新功能后及早发现问题
- 审查他人的 Flutter 代码时
- 审计 Widget、状态管理组件或服务类时
- 生产发布之前

## 审查领域

| 领域 | 严重程度 |
|------|----------|
| 硬编码密钥、明文 HTTP | CRITICAL |
| 架构违规、状态管理反模式 | CRITICAL |
| Widget 重建问题、资源泄漏 | HIGH |
| 缺少 `dispose()`、await 后使用 `BuildContext` | HIGH |
| Dart 空安全、缺少错误/加载状态 | HIGH |
| const 传播、Widget 组合 | HIGH |
| 性能：`build()` 中的昂贵操作 | HIGH |
| 可访问性、语义标签 | MEDIUM |
| 状态转换缺少测试 | HIGH |
| 硬编码字符串（国际化） | MEDIUM |
| Pub 依赖规范 | LOW |

## 示例会话

````text
用户: /flutter-review

智能体:
# Flutter 代码审查

## 上下文

变更文件:
- lib/features/auth/presentation/login_page.dart
- lib/features/auth/data/auth_repository_impl.dart

状态管理: Riverpod（从 pubspec.yaml 检测）
架构: 功能优先

## 安全预扫描

✓ 未检测到硬编码密钥
✓ 无明文 HTTP 调用

## 审查发现

[HIGH] async 间隙后使用 BuildContext 但未检查 mounted
文件: lib/features/auth/presentation/login_page.dart:67
问题: `context.go('/home')` 在 `await auth.login(...)` 之后调用，没有 `mounted` 检查。
修复: 在 await 之后的任何导航前添加 `if (!context.mounted) return;`（Flutter 3.7+）。

[HIGH] AsyncValue 错误状态未处理
文件: lib/features/auth/presentation/login_page.dart:42
问题: `ref.watch(authProvider)` 在 loading/data 上切换但没有 `error` 分支。
修复: 在 switch 表达式或 `when()` 调用中添加 error 情况，以显示面向用户的错误消息。

[MEDIUM] 硬编码字符串未本地化
文件: lib/features/auth/presentation/login_page.dart:89
问题: `Text('Login')` — 用户可见字符串未使用本地化系统。
修复: 使用项目的 l10n 访问器: `Text(context.l10n.loginButton)`。

## 审查摘要

| 严重程度 | 数量 | 状态 |
|----------|------|------|
| CRITICAL | 0     | pass |
| HIGH     | 2     | block |
| MEDIUM   | 1     | info |
| LOW      | 0     | note |

结论: BLOCK — HIGH 问题必须在合并前修复。
````

## 批准标准

- **批准**: 无 CRITICAL 或 HIGH 问题
- **阻止**: 任何 CRITICAL 或 HIGH 问题必须在合并前修复

## 相关命令

- `/flutter-build` — 先修复构建错误
- `/flutter-test` — 审查前运行测试
- `/code-review` — 通用代码审查（语言无关）

## 相关

- 智能体: `agents/flutter-reviewer.md`
- 技能: `skills/flutter-dart-code-review/`
- 规则: `rules/dart/`
