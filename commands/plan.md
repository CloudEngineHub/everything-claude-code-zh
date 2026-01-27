---
description: 重述需求，评估风险，并创建分步实现计划。在触碰任何代码之前等待用户确认 (CONFIRM)。
---

# Plan 命令

此命令调用 **planner** agent 来在编写任何代码之前创建全面的实现计划。

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

planner agent 将：

1. **分析请求** 并用清晰的术语重述需求
2. **分解为阶段**，包含具体、可操作的步骤
3. **识别依赖关系** 组件之间
4. **评估风险** 和潜在的阻碍因素
5. **估计复杂度** (高/中/低)
6. **展示计划** 并等待你的明确确认

## 使用示例

```
User: /plan 我需要添加市场解析时的实时通知

Agent (planner):
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

**关键**: planner agent **不会** 编写任何代码，直到你通过 "yes" 或 "proceed" 或类似的肯定回复明确确认计划。

如果你想要更改，请回复：
- "modify: [你的更改]"
- "different approach: [替代方案]"
- "skip phase 2 and do phase 3 first"

## 与其他命令的集成

计划后：
- 使用 `/tdd` 进行测试驱动开发实现
- 如果出现构建错误，使用 `/build-and-fix`
- 使用 `/code-review` 审查已完成的实现

## 相关 Agents

此命令调用 `planner` agent，位于：
`~/.claude/agents/planner.md`
