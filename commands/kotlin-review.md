---
description: 全面的 Kotlin 代码审查，涵盖惯用模式、空安全、协程安全和安全性。调用 kotlin-reviewer 智能体。
---

# Kotlin 代码审查

此命令调用 **kotlin-reviewer** 智能体，进行全面的 Kotlin 特定代码审查。

## 此命令的功能

1. **识别 Kotlin 变更**：通过 `git diff` 查找已修改的 `.kt` 和 `.kts` 文件
2. **运行构建和静态分析**：执行 `./gradlew build`、`detekt`、`ktlintCheck`
3. **安全扫描**：检查 SQL 注入、命令注入、硬编码密钥
4. **空安全审查**：分析 `!!` 用法、平台类型处理、不安全转换
5. **协程审查**：检查结构化并发、调度器用法、取消操作
6. **生成报告**：按严重程度分类问题

## 何时使用

在以下情况下使用 `/kotlin-review`：
- 编写或修改 Kotlin 代码后
- 提交 Kotlin 变更前
- 审查包含 Kotlin 代码的拉取请求
- 入职新的 Kotlin 代码库
- 学习惯用的 Kotlin 模式

## 审查类别

### CRITICAL（必须修复）
- SQL/命令注入漏洞
- 无理由的强制解包 `!!`
- 平台类型空安全违规
- GlobalScope 使用（结构化并发违规）
- 硬编码凭据
- 不安全的反序列化

### HIGH（应该修复）
- 可使用不可变状态却使用了可变状态
- 协程上下文中的阻塞调用
- 长循环中缺少取消检查
- sealed 类型上非穷尽的 `when`
- 大函数（>50 行）
- 深层嵌套（>4 层）

### MEDIUM（考虑）
- 非惯用 Kotlin（Java 风格模式）
- 缺少尾随逗号
- 作用域函数误用或嵌套
- 大型集合链缺少 sequence
- 冗余的显式类型

## 运行的自动检查

```bash
# 构建检查
./gradlew build

# 静态分析
./gradlew detekt

# 格式检查
./gradlew ktlintCheck

# 测试
./gradlew test
```

## 示例用法

````text
用户：/kotlin-review

智能体：
# Kotlin 代码审查报告

## 审查的文件
- src/main/kotlin/com/example/service/UserService.kt (已修改)
- src/main/kotlin/com/example/routes/UserRoutes.kt (已修改)

## 静态分析结果
✓ 构建：成功
✓ detekt：无问题
WARNING: ktlint：2 个格式警告

## 发现的问题

[CRITICAL] 强制解包空安全
文件：src/main/kotlin/com/example/service/UserService.kt:28
问题：在可空的仓库结果上使用 !!
```kotlin
val user = repository.findById(id)!!  // NPE 风险
```
修复：使用安全调用加错误处理
```kotlin
val user = repository.findById(id)
    ?: throw UserNotFoundException("User $id not found")
```

[HIGH] GlobalScope 使用
文件：src/main/kotlin/com/example/routes/UserRoutes.kt:45
问题：使用 GlobalScope 破坏了结构化并发
```kotlin
GlobalScope.launch {
    notificationService.sendWelcome(user)
}
```
修复：使用调用的协程作用域
```kotlin
launch {
    notificationService.sendWelcome(user)
}
```

## 总结
- CRITICAL：1
- HIGH：1
- MEDIUM：0

建议：FAIL：阻止合并，直到 CRITICAL 问题修复
````

## 审批标准

| 状态 | 条件 |
|------|------|
| PASS：批准 | 无 CRITICAL 或 HIGH 问题 |
| WARNING：警告 | 仅 MEDIUM 问题（谨慎合并） |
| FAIL：阻止 | 发现 CRITICAL 或 HIGH 问题 |

## 与其他命令集成

- 先使用 `/kotlin-test` 确保测试通过
- 如有构建错误使用 `/kotlin-build`
- 提交前使用 `/kotlin-review`
- 对非 Kotlin 特定问题使用 `/code-review`

## 相关

- 智能体：`agents/kotlin-reviewer.md`
- 技能：`skills/kotlin-patterns/`、`skills/kotlin-testing/`
