---
name: fastapi-patterns
description: FastAPI 模式——异步 API、依赖注入、Pydantic 请求与响应模型、OpenAPI 文档、测试、安全性和生产就绪。
origin: community
---

# FastAPI 模式

面向生产的 FastAPI 服务模式。

## 何时使用

- 构建或审查 FastAPI 应用。
- 拆分路由、模式、依赖和数据库访问。
- 编写调用数据库或外部服务的异步端点。
- 添加认证、授权、OpenAPI 文档、测试或部署设置。
- 检查 FastAPI PR 的可复制示例和生产风险。

## 工作原理

将 FastAPI 应用视为显式依赖和服务代码之上的薄 HTTP 层：

- `main.py` 负责应用构建、中间件、异常处理器和路由注册。
- `schemas/` 负责 Pydantic 请求和响应模型。
- `dependencies.py` 负责数据库、认证、分页和请求范围的依赖。
- `services/` 或 `crud/` 负责业务和持久化操作。
- `tests/` 覆盖依赖而非打开生产资源。

优先使用小型路由和显式的 `response_model` 声明。保持原始 ORM 对象、密钥和框架全局变量远离响应模式。

## 项目布局

```text
app/
|-- main.py
|-- config.py
|-- dependencies.py
|-- exceptions.py
|-- api/
|   `-- routes/
|       |-- users.py
|       `-- health.py
|-- core/
|   |-- security.py
|   `-- middleware.py
|-- db/
|   |-- session.py
|   `-- crud.py
|-- models/
|-- schemas/
`-- tests/
```

## 应用工厂

使用工厂模式，以便测试和 worker 可以使用受控设置构建应用。

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import health, users
from app.config import settings
from app.db.session import close_db, init_db
from app.exceptions import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.api_title,
        version=settings.api_version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=bool(settings.cors_origins),
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )

    register_exception_handlers(app)
    app.include_router(health.router, prefix="/health", tags=["health"])
    app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
    return app


app = create_app()
```

不要将 `allow_origins=["*"]` 与 `allow_credentials=True` 一起使用；浏览器会拒绝该组合，Starlette 也不允许带凭据的请求这样做。

## Pydantic 模式

保持请求、更新和响应模型分开。

```python
from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: Annotated[str, Field(min_length=1, max_length=100)]


class UserCreate(UserBase):
    password: Annotated[str, Field(min_length=12, max_length=128)]


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    full_name: Annotated[str | None, Field(min_length=1, max_length=100)] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
```

响应模型绝不能包含密码哈希、访问令牌、刷新令牌或内部授权状态。

## 依赖

使用依赖注入管理请求范围的资源。

```python
from collections.abc import AsyncIterator
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import session_factory
from app.models.user import User


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_db() -> AsyncIterator[AsyncSession]:
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(token)
    user_id = UUID(payload["sub"])
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="无效的令牌")
    return user
```

避免在路由处理器中内联创建会话、客户端或凭证。

## 异步端点

当路由处理器执行 I/O 时保持异步，并在其中使用异步库。

```python
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UserResponse


router = APIRouter()


@router.get("/", response_model=list[UserResponse])
async def list_users(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
    )
    return result.scalars().all()
```

在异步处理器中使用 `httpx.AsyncClient` 进行外部 HTTP 调用。不要在异步路由中调用 `requests`。

## 错误处理

集中域异常并保持响应形状稳定。

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class ApiError(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        self.status_code = status_code
        self.code = code
        self.message = message


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def api_error_handler(request: Request, exc: ApiError):
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message}},
        )
```

## OpenAPI 自定义

将自定义 OpenAPI 可调用对象赋值给 `app.openapi`；不要只调用函数一次。

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi


def install_openapi(app: FastAPI) -> None:
    def custom_openapi():
        if app.openapi_schema:
            return app.openapi_schema
        app.openapi_schema = get_openapi(
            title="Service API",
            version="1.0.0",
            routes=app.routes,
        )
        return app.openapi_schema

    app.openapi = custom_openapi
```

## 测试

覆盖 `Depends` 使用的依赖，而不是路由处理器从未引用的内部辅助函数。

```python
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db
from app.main import create_app


@pytest.fixture
async def client(test_session: AsyncSession):
    app = create_app()

    async def override_get_db():
        yield test_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as test_client:
        yield test_client
    app.dependency_overrides.clear()
```

## 安全检查清单

- 使用 `argon2-cffi`、`bcrypt` 或当前 passlib 兼容的哈希器对密码进行哈希。
- 验证 JWT 签发者、受众、过期时间和签名算法。
- 保持 CORS 来源特定于环境。
- 在认证和写入密集型端点上设置速率限制。
- 对所有请求体使用 Pydantic 模型。
- 使用 ORM 参数绑定或 SQLAlchemy Core 表达式；永远不要用 f-string 构建 SQL。
- 从日志中脱敏令牌、授权头、cookie 和密码。
- 在 CI 中运行依赖审计工具。

## 性能检查清单

- 显式配置数据库连接池。
- 为列表端点添加分页。
- 注意 N+1 查询，有意识地使用预加载。
- 在异步路径中使用异步 HTTP/数据库客户端。
- 在检查有效载荷大小和 CPU 权衡后添加压缩。
- 在显式失效后面缓存稳定的昂贵读取。

## 示例

将这些示例作为模式，而非全项目模板：

- 应用工厂：在 `create_app` 中一次性配置中间件和路由。
- 模式拆分：`UserCreate`、`UserUpdate` 和 `UserResponse` 有不同的职责。
- 依赖覆盖：测试直接覆盖 `get_db`。
- OpenAPI 自定义：赋值 `app.openapi = custom_openapi`。

## 另见

- 智能体：`fastapi-reviewer`
- 命令：`/fastapi-review`
- 技能：`python-patterns`
- 技能：`python-testing`
- 技能：`api-design`
