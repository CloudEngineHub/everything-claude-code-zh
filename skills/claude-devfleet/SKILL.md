---
name: claude-devfleet
description: 通过 Claude DevFleet 编排多智能体编码任务 — 规划项目、在隔离的工作树中调度并行智能体、监控进度并读取结构化报告。
origin: community
---

# Claude DevFleet 多智能体编排

## 何时使用

当你需要调度多个 Claude Code 智能体并行处理编码任务时使用此技能。每个智能体在隔离的 git 工作树中运行，拥有完整的工具链。

需要通过 MCP 连接运行中的 Claude DevFleet 实例：
```bash
claude mcp add devfleet --transport http http://localhost:18801/mcp
```

## 工作原理

```
用户 → "构建一个带认证和测试的 REST API"
  ↓
plan_project(prompt) → project_id + 任务 DAG
  ↓
向用户展示计划 → 获得批准
  ↓
dispatch_mission(M1) → 智能体 1 在工作树中生成
  ↓
M1 完成 → 自动合并 → 自动调度 M2（依赖 M1）
  ↓
M2 完成 → 自动合并
  ↓
get_report(M2) → 已变更文件、完成内容、错误、下一步
  ↓
向用户报告
```

### 工具

| 工具 | 用途 |
|------|------|
| `plan_project(prompt)` | AI 将描述分解为带有链式任务的项目 |
| `create_project(name, path?, description?)` | 手动创建项目，返回 `project_id` |
| `create_mission(project_id, title, prompt, depends_on?, auto_dispatch?)` | 添加任务。`depends_on` 是任务 ID 字符串列表（例如 `["abc-123"]`）。设置 `auto_dispatch=true` 可在依赖满足时自动启动。 |
| `dispatch_mission(mission_id, model?, max_turns?)` | 在任务上启动智能体 |
| `cancel_mission(mission_id)` | 停止正在运行的智能体 |
| `wait_for_mission(mission_id, timeout_seconds?)` | 阻塞直到任务完成（见下方说明） |
| `get_mission_status(mission_id)` | 检查任务进度而不阻塞 |
| `get_report(mission_id)` | 读取结构化报告（变更文件、已测试、错误、下一步） |
| `get_dashboard()` | 系统概览：运行中的智能体、统计、最近活动 |
| `list_projects()` | 浏览所有项目 |
| `list_missions(project_id, status?)` | 列出项目中的任务 |

> **关于 `wait_for_mission` 的说明：** 这会阻塞对话最多 `timeout_seconds`（默认 600）。对于长时间运行的任务，建议改为每 30-60 秒使用 `get_mission_status` 轮询，这样用户可以看到进度更新。

### 工作流：规划 → 调度 → 监控 → 报告

1. **规划**：调用 `plan_project(prompt="...")` → 返回 `project_id` + 带有 `depends_on` 链和 `auto_dispatch=true` 的任务列表。
2. **展示计划**：向用户展示任务标题、类型和依赖链。
3. **调度**：在根任务（`depends_on` 为空）上调用 `dispatch_mission(mission_id=<first_mission_id>)`。其余任务在其依赖完成后自动调度（因为 `plan_project` 为它们设置了 `auto_dispatch=true`）。
4. **监控**：调用 `get_mission_status(mission_id=...)` 或 `get_dashboard()` 检查进度。
5. **报告**：任务完成时调用 `get_report(mission_id=...)`。向用户分享要点。

### 并发

DevFleet 默认最多运行 3 个并发智能体（可通过 `DEVFLEET_MAX_AGENTS` 配置）。当所有槽位已满时，设置了 `auto_dispatch=true` 的任务在任务监视器中排队，并在槽位释放时自动调度。使用 `get_dashboard()` 检查当前槽位使用情况。

## 示例

### 全自动：规划和启动

1. `plan_project(prompt="...")` → 显示带有任务和依赖关系的计划。
2. 调度第一个任务（`depends_on` 为空的那个）。
3. 其余任务在依赖解析后自动调度（它们设置了 `auto_dispatch=true`）。
4. 向用户报告项目 ID 和任务数量，让用户知道启动了什么。
5. 定期使用 `get_mission_status` 或 `get_dashboard()` 轮询，直到所有任务达到终态（`completed`、`failed` 或 `cancelled`）。
6. 对每个终态任务调用 `get_report(mission_id=...)` — 总结成功项并用错误和下一步标注失败项。

### 手动：逐步控制

1. `create_project(name="My Project")` → 返回 `project_id`。
2. 为第一个（根）任务调用 `create_mission(project_id=project_id, title="...", prompt="...", auto_dispatch=true)` → 捕获 `root_mission_id`。
   为每个后续任务调用 `create_mission(project_id=project_id, title="...", prompt="...", auto_dispatch=true, depends_on=["<root_mission_id>"])`。
3. `dispatch_mission(mission_id=...)` 启动第一个任务链。
4. 完成时调用 `get_report(mission_id=...)`。

### 顺序执行并审查

1. `create_project(name="...")` → 获取 `project_id`。
2. `create_mission(project_id=project_id, title="实现功能", prompt="...")` → 获取 `impl_mission_id`。
3. `dispatch_mission(mission_id=impl_mission_id)`，然后用 `get_mission_status` 轮询直到完成。
4. `get_report(mission_id=impl_mission_id)` 审查结果。
5. `create_mission(project_id=project_id, title="审查", prompt="...", depends_on=[impl_mission_id], auto_dispatch=true)` — 由于依赖已满足，自动启动。

## 指南

- 除非用户说直接开始，否则在调度前始终与用户确认计划。
- 报告状态时包含任务标题和 ID。
- 如果任务失败，在重试前先阅读其报告。
- 批量调度前使用 `get_dashboard()` 检查智能体槽位可用性。
- 任务依赖关系形成 DAG — 不要创建循环依赖。
- 每个智能体在隔离的 git 工作树中运行，完成后自动合并。如果发生合并冲突，更改保留在智能体的工作树分支上等待手动解决。
- 手动创建任务时，如果希望它们在依赖完成后自动触发，请始终设置 `auto_dispatch=true`。没有此标志，任务将保持 `draft` 状态。
