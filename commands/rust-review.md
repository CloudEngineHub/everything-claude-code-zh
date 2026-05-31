---
description: 全面的 Rust 代码审查，涵盖所有权、生命周期、错误处理、unsafe 使用和惯用模式。调用 rust-reviewer 智能体。
---

# Rust 代码审查

此命令调用 **rust-reviewer** 智能体，进行全面的 Rust 特定代码审查。

## 此命令的功能

1. **验证自动检查**：运行 `cargo check`、`cargo clippy -- -D warnings`、`cargo fmt --check` 和 `cargo test` — 任何失败则停止
2. **识别 Rust 变更**：通过 `git diff HEAD~1`（或 PR 使用 `git diff main...HEAD`）查找已修改的 `.rs` 文件
3. **运行安全审计**：如可用则执行 `cargo audit`
4. **安全扫描**：检查 unsafe 使用、命令注入、硬编码密钥
5. **所有权审查**：分析不必要的 clone、生命周期问题、借用模式
6. **生成报告**：按严重程度分类问题

## 何时使用

在以下情况下使用 `/rust-review`：
- 编写或修改 Rust 代码后
- 提交 Rust 变更前
- 审查包含 Rust 代码的拉取请求
- 入职新的 Rust 代码库
- 学习惯用的 Rust 模式

## 审查类别

### CRITICAL（必须修复）
- 生产代码路径中未检查的 `unwrap()`/`expect()`
- `unsafe` 没有 `// SAFETY:` 注释说明不变量
- 通过字符串插值的 SQL 注入
- 通过未验证输入在 `std::process::Command` 中的命令注入
- 硬编码凭据
- 通过原始指针的 use-after-free

### HIGH（应该修复）
- 为满足借用检查器而不必要的 `.clone()`
- `String` 参数而 `&str` 或 `impl AsRef<str>` 就够了
- 异步上下文中的阻塞（`std::thread::sleep`、`std::fs`）
- 共享类型缺少 `Send`/`Sync` 约束
- 业务关键枚举上的通配符 `_ =>` 匹配
- 大函数（>50 行）

### MEDIUM（考虑）
- 热路径中不必要的分配
- 大小已知时缺少 `with_capacity`
- 无理由抑制 clippy 警告
- 公共 API 缺少 `///` 文档
- 考虑在忽略值可能是 bug 的非 `must_use` 返回类型上添加 `#[must_use]`

## 运行的自动检查

```bash
# 构建门控（审查前必须通过）
cargo check

# Lint 和建议
cargo clippy -- -D warnings

# 格式化
cargo fmt --check

# 测试
cargo test

# 安全审计（如可用）
if command -v cargo-audit >/dev/null; then cargo audit; else echo "cargo-audit not installed"; fi
```

## 示例用法

````text
用户：/rust-review

智能体：
# Rust 代码审查报告

## 审查的文件
- src/service/user.rs (已修改)
- src/handler/api.rs (已修改)

## 静态分析结果
- 构建：成功
- Clippy：无警告
- 格式化：通过
- 测试：全部通过

## 发现的问题

[CRITICAL] 生产路径中未检查的 unwrap
文件：src/service/user.rs:28
问题：在数据库查询结果上使用 `.unwrap()`
```rust
let user = db.find_by_id(id).unwrap();  // 用户不存在时 panic
```
修复：带上下文传播错误
```rust
let user = db.find_by_id(id)
    .context("failed to fetch user")?;
```

[HIGH] 不必要的 Clone
文件：src/handler/api.rs:45
问题：为满足借用检查器克隆 String
```rust
let name = user.name.clone();
process(&user, &name);
```
修复：重构以避免 clone
```rust
let result = process_name(&user.name);
use_user(&user, result);
```

## 总结
- CRITICAL：1
- HIGH：1
- MEDIUM：0

建议：阻止合并，直到 CRITICAL 问题修复
````

## 审批标准

| 状态 | 条件 |
|------|------|
| 批准 | 无 CRITICAL 或 HIGH 问题 |
| 警告 | 仅 MEDIUM 问题（谨慎合并） |
| 阻止 | 发现 CRITICAL 或 HIGH 问题 |

## 与其他命令集成

- 先使用 `/rust-test` 确保测试通过
- 如有构建错误使用 `/rust-build`
- 提交前使用 `/rust-review`
- 对非 Rust 特定问题使用 `/code-review`

## 相关

- 智能体：`agents/rust-reviewer.md`
- 技能：`skills/rust-patterns/`、`skills/rust-testing/`
