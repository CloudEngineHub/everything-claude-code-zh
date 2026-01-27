---
description: 强制执行 Go 的 TDD 工作流。首先编写表格驱动测试，然后实现。使用 go test -cover 验证 80%+ 的覆盖率。
---

# Go TDD 命令

此命令使用惯用的 Go 测试模式，强制执行 Go 代码的测试驱动开发 (TDD) 方法论。

## 此命令的作用

1. **定义类型/接口**: 首先搭建函数签名脚手架
2. **编写表格驱动测试**: 创建全面的测试用例 (红/RED)
3. **运行测试**: 验证测试因正确的原因而失败
4. **实现代码**: 编写最少量的代码以通过测试 (绿/GREEN)
5. **重构**: 改进代码同时保持测试通过
6. **检查覆盖率**: 确保 80%+ 的覆盖率

## 何时使用

在以下情况下使用 `/go-test`：
- 实现新的 Go 函数
- 为现有代码添加测试覆盖
- 修复 bug（先编写失败的测试）
- 构建关键业务逻辑
- 学习 Go 中的 TDD 工作流

## TDD 循环

```
RED (红)      → 编写失败的表格驱动测试
GREEN (绿)    → 实现最少量的代码以通过测试
REFACTOR (重构) → 改进代码，测试保持通过
REPEAT (重复)   → 下一个测试用例
```

## 示例会话

```text
User: /go-test 我需要一个验证电子邮件地址的函数

Agent:
# TDD Session: Email Validator

## Step 1: Define Interface

```go
// validator/email.go
package validator

// ValidateEmail checks if the given string is a valid email address.
// Returns nil if valid, error describing the issue otherwise.
func ValidateEmail(email string) error {
    panic("not implemented")
}
```

## Step 2: Write Table-Driven Tests (RED)

```go
// validator/email_test.go
package validator

import (
    "testing"
)

func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        // Valid emails
        {"simple email", "user@example.com", false},
        {"with subdomain", "user@mail.example.com", false},
        {"with plus", "user+tag@example.com", false},
        {"with dots", "first.last@example.com", false},

        // Invalid emails
        {"empty string", "", true},
        {"no at sign", "userexample.com", true},
        {"no domain", "user@", true},
        {"no local part", "@example.com", true},
        {"double at", "user@@example.com", true},
        {"spaces", "user @example.com", true},
        {"no tld", "user@example", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr && err == nil {
                t.Errorf("ValidateEmail(%q) = nil; want error", tt.email)
            }
            if !tt.wantErr && err != nil {
                t.Errorf("ValidateEmail(%q) = %v; want nil", tt.email, err)
            }
        })
    }
}
```

## Step 3: Run Tests - Verify FAIL

```bash
$ go test ./validator/...

--- FAIL: TestValidateEmail (0.00s)
    --- FAIL: TestValidateEmail/simple_email (0.00s)
        panic: not implemented

FAIL
```

✓ Tests fail as expected (panic).

## Step 4: Implement Minimal Code (GREEN)

```go
// validator/email.go
package validator

import (
    "errors"
    "regexp"
)

var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

var (
    ErrEmailEmpty   = errors.New("email cannot be empty")
    ErrEmailInvalid = errors.New("email format is invalid")
)

func ValidateEmail(email string) error {
    if email == "" {
        return ErrEmailEmpty
    }
    if !emailRegex.MatchString(email) {
        return ErrEmailInvalid
    }
    return nil
}
```

## Step 5: Run Tests - Verify PASS

```bash
$ go test ./validator/...

PASS
ok      project/validator    0.003s
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ go test -cover ./validator/...

PASS
coverage: 100.0% of statements
ok      project/validator    0.003s
```

✓ Coverage: 100%

## TDD Complete!
```

## 测试模式

### 表格驱动测试 (Table-Driven Tests)
```go
tests := []struct {
    name     string
    input    InputType
    want     OutputType
    wantErr  bool
}{
    {"case 1", input1, want1, false},
    {"case 2", input2, want2, true},
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got, err := Function(tt.input)
        // assertions
    })
}
```

### 并行测试 (Parallel Tests)
```go
for _, tt := range tests {
    tt := tt // Capture
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        // test body
    })
}
```

### 测试助手 (Test Helpers)
```go
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db := createDB()
    t.Cleanup(func() { db.Close() })
    return db
}
```

## 覆盖率命令

```bash
# 基本覆盖率
go test -cover ./...

# 覆盖率 profile
go test -coverprofile=coverage.out ./...

# 在浏览器中查看
go tool cover -html=coverage.out

# 按函数查看覆盖率
go tool cover -func=coverage.out

# 带有竞态检测
go test -race -cover ./...
```

## 覆盖率目标

| 代码类型 | 目标 |
|-----------|--------|
| 关键业务逻辑 | 100% |
| 公共 API | 90%+ |
| 通用代码 | 80%+ |
| 生成的代码 | 排除 |

## TDD 最佳实践

**DO (建议):**
- **首先**编写测试，在任何实现之前
- 每次更改后运行测试
- 使用表格驱动测试以获得全面覆盖
- 测试行为，而不是实现细节
- 包含边缘情况（空值、nil、最大值）

**DON'T (不建议):**
- 在测试之前编写实现
- 跳过 RED (红) 阶段
- 直接测试私有函数
- 在测试中使用 `time.Sleep`
- 忽略不稳定测试

## 相关命令

- `/go-build` - 修复构建错误
- `/go-review` - 实现后审查代码
- `/verify` - 运行完整验证循环

## 相关内容

- Skill: `skills/golang-testing/`
- Skill: `skills/tdd-workflow/`
