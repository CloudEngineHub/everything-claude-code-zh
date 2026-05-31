---
description: 审查 FastAPI 应用的架构、异步正确性、依赖注入、Pydantic 模式、安全性、性能和可测试性。
---

# FastAPI 审查

调用 `fastapi-reviewer` 智能体进行聚焦的 FastAPI 审查。

## 用法

```text
/fastapi-review [文件或目录]
```

## 审查领域

- 应用工厂、路由边界、中间件和异常处理器。
- Pydantic 请求和响应模式分离。
- 数据库会话、认证、分页和设置的依赖注入。
- 异步数据库和外部 HTTP 模式。
- CORS、认证、速率限制、日志记录和密钥处理。
- OpenAPI 元数据和文档化的响应模型。
- 测试客户端设置和依赖覆盖。

## 预期输出

```text
[严重程度] 简短问题标题
文件: path/to/file.py:42
问题: 哪里出了问题以及为什么重要。
修复: 需要做的具体更改。
```

## 相关

- 智能体: `fastapi-reviewer`
- 技能: `fastapi-patterns`
- 命令: `/python-review`
- 技能: `security-scan`
