---
description: 从脚本、模式、路由和导出等真实来源文件同步文档。
---

# 更新文档 (Update Documentation)

从真实来源文件同步文档，基于代码生成。

## 步骤 1：识别真实来源

| 来源 | 生成内容 |
|--------|-----------|
| `package.json` scripts | 可用命令参考 |
| `.env.example` | 环境变量文档 |
| `openapi.yaml` / 路由文件 | API 端点参考 |
| 源代码导出 | 公共 API 文档 |
| `Dockerfile` / `docker-compose.yml` | 基础设施设置文档 |

## 步骤 2：生成脚本参考

1. 读取 `package.json`（或 `Makefile`、`Cargo.toml`、`pyproject.toml`）
2. 提取所有脚本/命令及其描述
3. 生成参考表：

```markdown
| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Production build with type checking |
| `npm test` | Run test suite with coverage |
```

## 步骤 3：生成环境变量文档

1. 读取 `.env.example`（或 `.env.template`、`.env.sample`）
2. 提取所有变量及其用途
3. 分类为必需 vs 可选
4. 记录预期格式和有效值

```markdown
| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | Yes | PostgreSQL connection string | `postgres://user:pass@host:5432/db` |
| `LOG_LEVEL` | No | Logging verbosity (default: info) | `debug`, `info`, `warn`, `error` |
```

## 步骤 4：更新贡献指南

生成或更新 `docs/CONTRIBUTING.md`，包含：
- 开发环境设置（先决条件、安装步骤）
- 可用脚本及其用途
- 测试流程（如何运行、如何编写新测试）
- 代码风格强制（linter、formatter、pre-commit hooks）
- PR 提交检查清单

## 步骤 5：更新运维手册

生成或更新 `docs/RUNBOOK.md`，包含：
- 部署流程（分步）
- 健康检查端点和监控
- 常见问题及其修复
- 回滚流程
- 告警和升级路径

## 步骤 6：过时检查

1. 查找 90+ 天未修改的文档文件
2. 与最近的源代码更改交叉引用
3. 标记可能过时的文档供人工审查

## 步骤 7：显示摘要

```
Documentation Update
──────────────────────────────
Updated:  docs/CONTRIBUTING.md (scripts table)
Updated:  docs/ENV.md (3 new variables)
Flagged:  docs/DEPLOY.md (142 days stale)
Skipped:  docs/API.md (no changes detected)
──────────────────────────────
```

## 规则

- **单一事实来源**：始终从代码生成，永远不要手动编辑生成的部分
- **保留手动部分**：只更新生成的部分；保留手写文本不变
- **标记生成内容**：在生成部分周围使用 `<!-- AUTO-GENERATED -->` 标记
- **不要主动创建文档**：仅在命令明确请求时才创建新的文档文件
