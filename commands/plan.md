---
description: 重述需求，评估风险，并创建分步实现计划。在触碰任何代码之前等待用户确认 (CONFIRM)。
argument-hint: "[feature description | path/to/*.prd.md]"
---

# Plan 命令

此命令在编写任何代码之前创建全面的实现计划。它接受自由格式的需求或 PRD markdown 文件。

默认内联运行。默认不调用 Task 工具或任何子 agent。这使得 `/plan` 可用于仅包含命令文件而不包含 agent 文件的插件安装。

## 此命令的作用

1. **重述需求 (Restate Requirements)** - 阐明需要构建什么
2. **识别风险 (Identify Risks)** - 暴露潜在问题和阻碍
3. **创建步骤计划 (Create Step Plan)** - 将实现分解为阶段
4. **等待确认 (Wait for Confirmation)** - 必须在继续之前获得用户批准

## 何时使用

在以下情况下使用 `/plan`：
- 开始一个新功能
- 进行重大的架构更改
- 进行复杂的重构
- 多个文件/组件将受影响
- 需求不明确或模棱两可

## 工作原理

助手将：

1. **分析请求** 并用清晰的术语重述需求
2. **基于代码库模式制定计划** 当仓库可用时
3. **分解为阶段**，包含具体、可操作的步骤
4. **识别依赖关系** 组件之间
5. **评估风险** 和潜在的阻碍因素
6. **估计复杂度** (高/中/低)
7. **展示计划** 并等待你的明确确认

## 输入模式

| 输入 | 模式 | 行为 |
|---|---|---|
| `path/to/name.prd.md` | PRD 产物模式 | 读取 PRD，选择下一个待交付里程碑或实现阶段，并写入 `.claude/plans/{name}.plan.md` |
| 任何其他 markdown 路径 | 参考模式 | 读取文件作为上下文并生成内联计划 |
| 自由格式文本 | 对话模式 | 生成内联计划 |
| 空输入 | 澄清模式 | 询问要规划什么 |

在 PRD 产物模式中，如需要则创建 `.claude/plans/`。如果 PRD 包含 `Delivery Milestones` 表，仅将所选行从 `pending` 更新为 `in-progress` 并将其 `Plan` 单元格设置为生成的计划路径。如果 PRD 使用旧版 `.claude/PRPs/prds/` 格式的 `Implementation Phases`，读取它而不迁移路径。

## 模式基础

在编写计划之前，搜索代码库中实现应该遵循的约定。为每个相关类别捕获最佳示例及文件引用：

| 类别 | 捕获内容 |
|---|---|
| 命名 | 受影响区域的文件、函数、类型、命令或脚本命名 |
| 错误处理 | 失败如何抛出、返回、记录或优雅处理 |
| 日志 | 级别、格式和记录什么 |
| 数据访问 | Repository、service、query 或文件系统模式 |
| 测试 | 测试文件位置、框架、fixture 和断言风格 |

如果不存在类似代码，请明确说明。不要编造模式。

## PRD 产物输出

当使用 `.prd.md` 文件调用时，将计划写入 `.claude/plans/{kebab-case-name}.plan.md`，使用此结构：

````markdown
# Plan: {Feature Name}

**Source PRD**: {path}
**Selected Milestone**: {milestone or phase name}
**Complexity**: {Small | Medium | Large}

## Summary
{2-3 句话}

## Patterns to Mirror
| Category | Source | Pattern |
|---|---|---|
| Naming | `path:line` | {short description} |
| Errors | `path:line` | {short description} |
| Tests | `path:line` | {short description} |

## Files to Change
| File | Action | Why |
|---|---|---|
| `path` | CREATE / UPDATE / DELETE | {reason} |

## Tasks
### Task 1: {name}
- **Action**: {what to do}
- **Mirror**: {pattern to follow}
- **Validate**: {command that proves correctness}

## Validation
```bash
{project-specific validation commands}
```

## Risks
| Risk | Likelihood | Mitigation |
|---|---|---|

## Acceptance
- [ ] All tasks complete
- [ ] Validation passes
- [ ] Patterns mirrored, not reinvented
````

写入产物后，报告其路径并等待确认再编写代码。

## 使用示例

```
User: /plan 我需要添加市场解析时的实时通知

Assistant:
# Implementation Plan: Real-Time Market Resolution Notifications

## Requirements Restatement
- 当用户关注的市场解析时向用户发送通知
- 支持多种通知渠道（应用内、电子邮件、webhook）
- 确保通知可靠投递
- 包含市场结果和用户的持仓结果

## Implementation Phases

### Phase 1: Database Schema
- 添加 notifications 表，包含字段: id, user_id, market_id, type, status, created_at
- 添加 user_notification_preferences 表用于渠道偏好
- 在 user_id 和 market_id 上创建索引以提高性能

### Phase 2: Notification Service
- 在 lib/notifications.ts 中创建通知服务
- 使用 BullMQ/Redis 实现通知队列
- 为失败的投递添加重试逻辑
- 创建通知模板

### Phase 3: Integration Points
- 挂钩到市场解析逻辑（当状态变为 "resolved" 时）
- 查询市场中所有持仓的用户
- 为每个用户入队通知

### Phase 4: Frontend Components
- 在 header 中创建 NotificationBell 组件
- 添加 NotificationList 模态框
- 通过 Supabase subscriptions 实现实时更新
- 添加通知偏好设置页面

## Dependencies
- Redis (用于队列)
- Email service (SendGrid/Resend)
- Supabase real-time subscriptions

## Risks
- HIGH: 邮件送达率 (SPF/DKIM required)
- MEDIUM: 每个市场 1000+ 用户时的性能
- MEDIUM: 如果市场频繁解析会导致通知垃圾邮件
- LOW: 实时订阅开销

## Estimated Complexity: MEDIUM
- Backend: 4-6 hours
- Frontend: 3-4 hours
- Testing: 2-3 hours
- Total: 9-13 hours

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes/no/modify)
```

## 重要说明

**关键**: 此命令**不会**编写任何代码，直到你通过 "yes" 或 "proceed" 或类似的肯定回复明确确认计划。

如果你想要更改，请回复：
- "modify: [你的更改]"
- "different approach: [替代方案]"
- "skip phase 2 and do phase 3 first"

## 与其他命令的集成

计划后：
- 使用 `tdd-workflow` skill 进行测试驱动开发实现
- 如果出现构建错误，使用 `/build-fix`
- 使用 `/code-review` 审查已完成的实现
- 使用 `/pr` 或 `/prp-pr` 打开 pull request

> **需要先制定需求？** 使用 `/plan-prd` 在 `.claude/prds/{name}.prd.md` 创建精益 PRD。
>
> **需要旧版 PRP 流程？** 使用 `/prp-plan` 进行带有 `.claude/PRPs/` 产物的深度 PRP 规划。使用 `/prp-implement` 执行带有严格验证循环的计划。

## 可选的 Planner Agent

ECC 还提供了一个 `planner` agent，适用于包含 agent 文件的手动安装。仅当本地运行时已暴露该子 agent 且用户明确要求委派规划时才使用它。

如果 `planner` 子 agent 不可用，继续内联规划，而不是显示 "Agent type 'planner' not found" 错误。

对于手动安装，源文件位于：
`agents/planner.md`
