---
description: 增量修复 Go 构建错误、go vet 警告和 linter 问题。调用 go-build-resolver agent 进行最小化的、外科手术式的修复。
---

# Go 构建与修复 (Go Build and Fix)

此命令调用 **go-build-resolver** agent 以最小的更改增量修复 Go 构建错误。

## 此命令的作用

1. **运行诊断**: 执行 `go build`, `go vet`, `staticcheck`
2. **解析错误**: 按文件分组并按严重程度排序
3. **增量修复**: 一次一个错误
4. **验证每个修复**: 每次更改后重新运行构建
5. **报告摘要**: 显示已修复的内容和剩余内容

## 何时使用

在以下情况下使用 `/go-build`：
- `go build ./...` 失败报错
- `go vet ./...` 报告问题
- `golangci-lint run` 显示警告
- 模块依赖项损坏
- 拉取了破坏构建的更改后

## 运行的诊断命令

```bash
# 主要构建检查
go build ./...

# 静态分析
go vet ./...

# 扩展 linting (如果可用)
staticcheck ./...
golangci-lint run

# 模块问题
go mod verify
go mod tidy -v
```

## 示例会话

```text
User: /go-build

Agent:
# Go Build Resolution

## Initial Diagnostics

```bash
$ go build ./...
internal/service/user.go:25:15: undefined: UserRepository
internal/handler/api.go:42:9: cannot use x (type string) as type int
internal/handler/api.go:58:2: missing return at end of function
```

Errors found: 3

## Fix 1: Undefined Identifier

File: internal/service/user.go:25
Error: undefined: UserRepository
Cause: Missing import

```go
// Added import
import "project/internal/repository"

// Changed
var repo UserRepository
// To
var repo repository.UserRepository
```

```bash
$ go build ./...
# 2 errors remaining
```

## Fix 2: Type Mismatch

File: internal/handler/api.go:42
Error: cannot use x (type string) as type int

```go
// Changed
count := params.Get("count")
// To
countStr := params.Get("count")
count, _ := strconv.Atoi(countStr)
```

```bash
$ go build ./...
# 1 error remaining
```

## Fix 3: Missing Return

File: internal/handler/api.go:58
Error: missing return at end of function

```go
func GetUser(id string) (*User, error) {
    if id == "" {
        return nil, ErrInvalidID
    }
    user := findUser(id)
    // Added missing return
    return user, nil
}
```

```bash
$ go build ./...
# Build successful!
```

## Final Verification

```bash
$ go vet ./...
# No issues

$ go test ./...
ok      project/internal/service   0.015s
ok      project/internal/handler   0.023s
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Vet warnings fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: ✅ SUCCESS
```

## 修复的常见错误

| 错误 | 典型修复 |
|-------|-------------|
| `undefined: X` | 添加 import 或修复拼写错误 |
| `cannot use X as Y` | 类型转换或修复赋值 |
| `missing return` | 添加 return 语句 |
| `X does not implement Y` | 添加缺失的方法 |
| `import cycle` | 重组包 |
| `declared but not used` | 移除或使用变量 |
| `cannot find package` | `go get` 或 `go mod tidy` |

## 修复策略

1. **构建错误优先** - 代码必须能编译
2. **Vet 警告其次** - 修复可疑的结构
3. **Lint 警告再次** - 风格和最佳实践
4. **一次修复一个** - 验证每次更改
5. **最小化更改** - 不要重构，只修复

## 停止条件

agent 将在以下情况下停止并报告：
- 尝试 3 次后同一错误仍然存在
- 修复引入了更多错误
- 需要架构变更
- 缺少外部依赖

## 相关命令

- `/go-test` - 构建成功后运行测试
- `/go-review` - 审查代码质量
- `/verify` - 完整验证循环

## 相关内容

- Agent: `agents/go-build-resolver.md`
- Skill: `skills/golang-patterns/`
