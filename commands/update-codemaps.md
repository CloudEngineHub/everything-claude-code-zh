---
description: 扫描项目结构并生成 token 精简的架构代码地图。
---

# 更新 Codemaps

分析代码库结构并生成 token 精简的架构文档。

## 步骤 1：扫描项目结构

1. 识别项目类型（monorepo、单应用、库、微服务）
2. 查找所有源目录（src/、lib/、app/、packages/）
3. 映射入口点（main.ts、index.ts、app.py、main.go 等）

## 步骤 2：生成 Codemaps

在 `docs/CODEMAPS/`（或 `.reports/codemaps/`）中创建或更新代码地图：

| 文件 | 内容 |
|------|------|
| `architecture.md` | 高层系统图、服务边界、数据流 |
| `backend.md` | API 路由、中间件链、service → repository 映射 |
| `frontend.md` | 页面树、组件层级、状态管理流 |
| `data.md` | 数据库表、关系、迁移历史 |
| `dependencies.md` | 外部服务、第三方集成、共享库 |

### Codemap 格式

每个 codemap 应该是 token 精简的 — 针对 AI 上下文消费进行优化：

```markdown
# Backend Architecture

## Routes
POST /api/users → UserController.create → UserService.create → UserRepo.insert
GET  /api/users/:id → UserController.get → UserService.findById → UserRepo.findById

## Key Files
src/services/user.ts (business logic, 120 lines)
src/repos/user.ts (database access, 80 lines)

## Dependencies
- PostgreSQL (primary data store)
- Redis (session cache, rate limiting)
- Stripe (payment processing)
```

## 步骤 3：差异检测

1. 如果之前的 codemaps 存在，计算差异百分比
2. 如果更改 > 30%，显示差异并在覆盖前请求用户批准
3. 如果更改 <= 30%，原地更新

## 步骤 4：添加元数据

为每个 codemap 添加新鲜度标头：

```markdown
<!-- Generated: 2026-02-11 | Files scanned: 142 | Token estimate: ~800 -->
```

## 步骤 5：保存分析报告

将摘要写入 `.reports/codemap-diff.txt`：
- 自上次扫描以来添加/移除/修改的文件
- 检测到的新依赖
- 架构变更（新路由、新服务等）
- 90+ 天未更新的文档过时警告

## 提示

- 关注**高层结构**，而非实现细节
- 优先使用**文件路径和函数签名**而非完整代码块
- 每个 codemap 保持在 **1000 tokens 以下**以实现高效的上下文加载
- 使用 ASCII 图表展示数据流而非冗长描述
- 在重大功能添加或重构会话后运行
