---
name: error-handling
description: TypeScript、Python 和 Go 中的健壮错误处理模式。涵盖类型化错误、错误边界、重试、熔断器和面向用户的错误消息。
origin: ECC
---

# 错误处理模式

适用于生产应用的一致、健壮的错误处理模式。

## 何时激活

- 为新模块或服务设计错误类型或异常层次结构
- 为不可靠的外部依赖添加重试逻辑或熔断器
- 审查 API 端点的错误处理缺失
- 实现面向用户的错误消息和反馈
- 调试级联故障或静默错误吞没

## 核心原则

1. **快速且大声地失败**——在错误发生的边界暴露错误；不要埋没它们
2. **类型化错误优于字符串消息**——错误是具有结构的一等值
3. **用户消息 ≠ 开发者消息**——向用户显示友好文本，在服务端记录完整上下文
4. **永远不要静默吞没错误**——每个 `catch` 块必须处理、重新抛出或记录
5. **错误是 API 契约的一部分**——记录客户端可能收到的每个错误码

## TypeScript / JavaScript

### 类型化错误类

```typescript
// 为你的领域定义错误层次结构
export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly details?: unknown,
  ) {
    super(message)
    this.name = this.constructor.name
    // 在转译的 ES5 JavaScript 中保持正确的原型链。
    // `instanceof` 检查（如 `error instanceof NotFoundError`）正确工作所必需
    Object.setPrototypeOf(this, new.target.prototype)
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} 未找到: ${id}`, 'NOT_FOUND', 404)
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details: { field: string; message: string }[]) {
    super(message, 'VALIDATION_ERROR', 422, details)
  }
}

export class UnauthorizedError extends AppError {
  constructor(reason = '需要认证') {
    super(reason, 'UNAUTHORIZED', 401)
  }
}

export class RateLimitError extends AppError {
  constructor(public readonly retryAfterMs: number) {
    super('超出速率限制', 'RATE_LIMITED', 429)
  }
}
```

### Result 模式（非抛出风格）

对于失败是预期且常见的操作（解析、外部调用）：

```typescript
type Result<T, E = AppError> =
  | { ok: true; value: T }
  | { ok: false; error: E }

function ok<T>(value: T): Result<T> {
  return { ok: true, value }
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error }
}

// 用法
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.users.findUnique({ where: { id } })
    if (!user) return err(new NotFoundError('User', id))
    return ok(user)
  } catch (e) {
    return err(new AppError('数据库错误', 'DB_ERROR'))
  }
}

const result = await fetchUser('abc-123')
if (!result.ok) {
  // TypeScript 在这里知道 result.error
  logger.error('获取用户失败', { error: result.error })
  return
}
// TypeScript 在这里知道 result.value
console.log(result.value.email)
```

### API 错误处理器（Next.js / Express）

```typescript
import { NextRequest, NextResponse } from 'next/server'

function handleApiError(error: unknown): NextResponse {
  // 已知的应用错误
  if (error instanceof AppError) {
    return NextResponse.json(
      {
        error: {
          code: error.code,
          message: error.message,
          ...(error.details ? { details: error.details } : {}),
        },
      },
      { status: error.statusCode },
    )
  }

  // Zod 验证错误
  if (error instanceof z.ZodError) {
    return NextResponse.json(
      {
        error: {
          code: 'VALIDATION_ERROR',
          message: '请求验证失败',
          details: error.issues.map(i => ({
            field: i.path.join('.'),
            message: i.message,
          })),
        },
      },
      { status: 422 },
    )
  }

  // 意外错误 — 记录详情，返回通用消息
  console.error('意外错误:', error)
  return NextResponse.json(
    { error: { code: 'INTERNAL_ERROR', message: '发生意外错误' } },
    { status: 500 },
  )
}

export async function POST(req: NextRequest) {
  try {
    // ... 处理器逻辑
  } catch (error) {
    return handleApiError(error)
  }
}
```

### React 错误边界

```typescript
import { Component, ErrorInfo, ReactNode } from 'react'

interface Props {
  fallback: ReactNode
  onError?: (error: Error, info: ErrorInfo) => void
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    this.props.onError?.(error, info)
    console.error('未处理的 React 错误:', error, info)
  }

  render() {
    if (this.state.hasError) return this.props.fallback
    return this.props.children
  }
}

// 用法
<ErrorBoundary fallback={<p>出了点问题。请刷新页面。</p>}>
  <MyComponent />
</ErrorBoundary>
```

## Python

### 自定义异常层次结构

```python
class AppError(Exception):
    """基础应用错误。"""
    def __init__(self, message: str, code: str, status_code: int = 500):
        super().__init__(message)
        self.code = code
        self.status_code = status_code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str):
        super().__init__(f"{resource} 未找到: {id}", "NOT_FOUND", 404)

class ValidationError(AppError):
    def __init__(self, message: str, details: list[dict] | None = None):
        super().__init__(message, "VALIDATION_ERROR", 422)
        self.details = details or []
```

### FastAPI 全局异常处理器

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": str(exc)}},
    )

@app.exception_handler(Exception)
async def generic_error_handler(request: Request, exc: Exception) -> JSONResponse:
    # 记录完整详情，返回通用消息
    logger.exception("意外错误", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={"error": {"code": "INTERNAL_ERROR", "message": "发生意外错误"}},
    )
```

## Go

### 哨兵错误和错误包装

```go
package domain

import "errors"

// 用于类型检查的哨兵错误
var (
    ErrNotFound    = errors.New("未找到")
    ErrUnauthorized = errors.New("未授权")
    ErrConflict     = errors.New("冲突")
)

// 用上下文包装错误——永远不要丢失原始错误
func (r *UserRepository) FindByID(ctx context.Context, id string) (*User, error) {
    user, err := r.db.QueryRow(ctx, "SELECT * FROM users WHERE id = $1", id)
    if errors.Is(err, sql.ErrNoRows) {
        return nil, fmt.Errorf("用户 %s: %w", id, ErrNotFound)
    }
    if err != nil {
        return nil, fmt.Errorf("查询用户 %s: %w", id, err)
    }
    return user, nil
}

// 在处理器层面，解包以确定响应
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.service.GetUser(r.Context(), chi.URLParam(r, "id"))
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrNotFound):
            writeError(w, http.StatusNotFound, "not_found", err.Error())
        case errors.Is(err, domain.ErrUnauthorized):
            writeError(w, http.StatusForbidden, "forbidden", "访问被拒绝")
        default:
            slog.Error("意外错误", "err", err)
            writeError(w, http.StatusInternalServerError, "internal_error", "发生意外错误")
        }
        return
    }
    writeJSON(w, http.StatusOK, user)
}
```

## 指数退避重试

```typescript
interface RetryOptions {
  maxAttempts?: number
  baseDelayMs?: number
  maxDelayMs?: number
  retryIf?: (error: unknown) => boolean
}

async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const {
    maxAttempts = 3,
    baseDelayMs = 500,
    maxDelayMs = 10_000,
    retryIf = () => true,
  } = options

  let lastError: unknown

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error
      if (attempt === maxAttempts || !retryIf(error)) throw error

      const jitter = Math.random() * baseDelayMs
      const delay = Math.min(baseDelayMs * 2 ** (attempt - 1) + jitter, maxDelayMs)
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }

  throw lastError
}

// 用法：重试瞬态网络错误，不重试 4xx
const data = await withRetry(() => fetch('/api/data').then(r => r.json()), {
  maxAttempts: 3,
  retryIf: (error) => !(error instanceof AppError && error.statusCode < 500),
})
```

## 面向用户的错误消息

将错误码映射为人类可读的消息。技术细节不要出现在用户可见的文本中。

```typescript
const USER_ERROR_MESSAGES: Record<string, string> = {
  NOT_FOUND: '无法找到请求的项目。',
  UNAUTHORIZED: '请登录以继续。',
  FORBIDDEN: '您没有执行此操作的权限。',
  VALIDATION_ERROR: '请检查您的输入并重试。',
  RATE_LIMITED: '请求过于频繁。请稍后再试。',
  INTERNAL_ERROR: '我们的系统出了问题。请稍后再试。',
}

export function getUserMessage(code: string): string {
  return USER_ERROR_MESSAGES[code] ?? USER_ERROR_MESSAGES.INTERNAL_ERROR
}
```

## 错误处理检查清单

在合并任何涉及错误处理的代码之前：

- [ ] 每个 `catch` 块都有处理、重新抛出或记录——没有静默吞没
- [ ] API 错误遵循标准信封格式 `{ error: { code, message } }`
- [ ] 面向用户的消息不包含堆栈跟踪或内部细节
- [ ] 完整的错误上下文已在服务端记录
- [ ] 自定义错误类继承基础 `AppError` 并带有 `code` 字段
- [ ] 异步函数向调用者暴露错误——不允许没有后备的即发即忘
- [ ] 重试逻辑仅重试可重试的错误（不是 4xx 客户端错误）
- [ ] React 组件被 `ErrorBoundary` 包裹以处理渲染错误
