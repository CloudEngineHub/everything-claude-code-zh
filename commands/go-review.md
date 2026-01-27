---
description: 全面的 Go 代码审查，涵盖惯用模式、并发安全、错误处理和安全性。调用 go-reviewer agent。
---

# Go 代码审查 (Go Code Review)

此命令调用 **go-reviewer** agent 进行针对 Go 的全面代码审查。

## 此命令的作用

1. **识别 Go 更改**: 通过 `git diff` 查找修改过的 `.go` 文件
2. **运行静态分析**: 执行 `go vet`, `staticcheck`, 和 `golangci-lint`
3. **安全扫描**: 检查 SQL 注入、命令注入、竞态条件 (race conditions)
4. **并发审查**: 分析 goroutine 安全性、channel 使用、mutex 模式
5. **惯用 Go 检查**: 验证代码是否遵循 Go 约定和最佳实践
6. **生成报告**: 按严重程度对问题进行分类

## 何时使用

在以下情况下使用 `/go-review`：
- 编写或修改 Go 代码后
- 提交 Go 更改前
- 审查包含 Go 代码的 PR
- 接手新的 Go 代码库
- 学习惯用的 Go 模式 (idiomatic Go patterns)

## 审查类别

### CRITICAL (必须修复)
- SQL/命令注入漏洞
- 无同步的竞态条件
- Goroutine 泄漏
- 硬编码凭据
- 不安全的指针使用
- 关键路径中忽略错误

### HIGH (应该修复)
- 错误返回时缺少上下文包装
- 使用 panic 而不是返回 error
- Context 未传播
- 导致死锁的无缓冲 channel
- 接口未满足错误
- 缺失 mutex 保护

### MEDIUM (考虑)
- 非惯用的代码模式
- 导出的内容缺少 godoc 注释
- 低效的字符串拼接
- Slice 未预分配
- 未使用表格驱动测试

## 运行的自动检查

```bash
# 静态分析
go vet ./...

# 高级检查 (如果已安装)
staticcheck ./...
golangci-lint run

# 竞态检测
go build -race ./...

# 安全漏洞
govulncheck ./...
```

## 使用示例

```text
User: /go-review

Agent:
# Go Code Review Report

## Files Reviewed
- internal/handler/user.go (modified)
- internal/service/auth.go (modified)

## Static Analysis Results
✓ go vet: No issues
✓ staticcheck: No issues

## Issues Found

[CRITICAL] Race Condition
File: internal/service/auth.go:45
Issue: Shared map accessed without synchronization
```go
var cache = map[string]*Session{}  // Concurrent access!

func GetSession(id string) *Session {
    return cache[id]  // Race condition
}
```
Fix: Use sync.RWMutex or sync.Map
```go
var (
    cache   = map[string]*Session{}
    cacheMu sync.RWMutex
)

func GetSession(id string) *Session {
    cacheMu.RLock()
    defer cacheMu.RUnlock()
    return cache[id]
}
```

[HIGH] Missing Error Context
File: internal/handler/user.go:28
Issue: Error returned without context
```go
return err  // No context
```
Fix: Wrap with context
```go
return fmt.Errorf("get user %s: %w", userID, err)
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: ❌ Block merge until CRITICAL issue is fixed
```

## 批准标准

| 状态 | 条件 |
|--------|-----------|
| ✅ Approve (批准) | 无 CRITICAL 或 HIGH 问题 |
| ⚠️ Warning (警告) | 仅有 MEDIUM 问题 (谨慎合并) |
| ❌ Block (阻止) | 发现 CRITICAL 或 HIGH 问题 |

## 与其他命令的集成

- 首先使用 `/go-test` 确保测试通过
- 如果出现构建错误，使用 `/go-build`
- 在提交前使用 `/go-review`
- 对于非 Go 具体的关注点，使用 `/code-review`

## 相关内容

- Agent: `agents/go-reviewer.md`
- Skills: `skills/golang-patterns/`, `skills/golang-testing/`
