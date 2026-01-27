---
name: strategic-compact
description: 建议在逻辑间隔进行手动上下文压缩，以保留任务阶段的上下文，而不是依赖任意的自动压缩。
---

# 策略紧缩技能 (Strategic Compact Skill)

建议在工作流中的战略点手动 `/compact`，而不是依赖任意的自动压缩。

## 为什么需要策略紧缩？

自动压缩在任意点触发：
- 通常在任务中间，丢失重要上下文
- 无法意识到逻辑任务边界
- 可能会中断复杂的多步操作

在逻辑边界进行策略紧缩：
- **在探索之后，执行之前** - 压缩研究上下文，保留实施计划
- **在完成里程碑之后** - 为下一阶段重新开始
- **在主要上下文转换之前** - 在不同任务之前清除探索上下文

## 工作原理

`suggest-compact.sh` 脚本在 PreToolUse (Edit/Write) 上运行，并且：

1. **跟踪工具调用** - 统计会话中的工具调用
2. **阈值检测** - 在可配置阈值建议（默认：50 次调用）
3. **定期提醒** - 在阈值后每 25 次调用提醒一次

## Hook 设置

添加到你的 `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "tool == \"Edit\" || tool == \"Write\"",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/strategic-compact/suggest-compact.sh"
      }]
    }]
  }
}
```

## 配置

环境变量：
- `COMPACT_THRESHOLD` - 首次建议前的工具调用数（默认：50）

## 最佳实践

1. **在规划后紧缩** - 计划确定后，紧缩以重新开始
2. **在调试后紧缩** - 在继续之前清除错误解决上下文
3. **不要在实施中途紧缩** - 保留相关更改的上下文
4. **阅读建议** - Hook 告诉你 *何时*，你决定 *是否*

## 相关

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - Token 优化章节
- Memory persistence hooks - 用于在紧缩后保留状态
