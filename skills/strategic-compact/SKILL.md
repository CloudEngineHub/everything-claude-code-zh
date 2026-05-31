---
name: strategic-compact
description: 建议在逻辑间隔进行手动上下文压缩，以保留任务阶段的上下文，而不是依赖任意的自动压缩。
origin: ECC
---

# 策略压缩技能 (Strategic Compact Skill)

建议在工作流中的战略点手动 `/compact`，而不是依赖任意的自动压缩。

## 何时激活

- 运行接近上下文限制的长会话（200K+ tokens）
- 处理多阶段任务（研究 → 规划 → 实现 → 测试）
- 在同一会话中切换不相关的任务
- 完成主要里程碑后开始新工作
- 当响应变慢或变得不够连贯时（上下文压力）

## 为什么需要策略压缩？

自动压缩在任意点触发：
- 通常在任务中间，丢失重要上下文
- 无法意识到逻辑任务边界
- 可能中断复杂的多步操作

在逻辑边界进行策略压缩：
- **在探索之后，执行之前** — 压缩研究上下文，保留实施计划
- **在完成里程碑之后** — 为下一阶段重新开始
- **在主要上下文转换之前** — 在不同任务之前清除探索上下文

## 工作原理

`suggest-compact.js` 脚本在 PreToolUse（Edit/Write）上运行：

1. **跟踪工具调用** — 统计会话中的工具调用次数
2. **阈值检测** — 在可配置阈值建议（默认：50 次调用）
3. **定期提醒** — 在阈值后每 25 次调用提醒一次

## Hook 设置

添加到你的 `~/.claude/settings.json`：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [{ "type": "command", "command": "node ~/.claude/scripts/hooks/suggest-compact.js" }]
      },
      {
        "matcher": "Write",
        "hooks": [{ "type": "command", "command": "node ~/.claude/scripts/hooks/suggest-compact.js" }]
      }
    ]
  }
}
```

## 配置

环境变量：
- `COMPACT_THRESHOLD` — 首次建议前的工具调用次数（默认：50）

## 压缩决策指南

使用此表决定何时压缩：

| 阶段转换 | 压缩？ | 原因 |
|-----------------|----------|-----|
| 研究 → 规划 | 是 | 研究上下文体积大；规划是提炼后的输出 |
| 规划 → 实现 | 是 | 规划在 TodoWrite 或文件中；释放上下文给代码 |
| 实现 → 测试 | 可能 | 如果测试引用近期代码则保留；如果切换焦点则压缩 |
| 调试 → 下一个功能 | 是 | 调试痕迹会污染不相关工作的上下文 |
| 实现中途 | 否 | 丢失变量名、文件路径和部分状态的代价很高 |
| 失败的方法之后 | 是 | 在尝试新方法之前清除死胡同推理 |

## 压缩后保留的内容

了解什么会持续存在有助于你自信地压缩：

| 保留 | 丢失 |
|----------|------|
| CLAUDE.md 指令 | 中间推理和分析 |
| TodoWrite 任务列表 | 之前读取的文件内容 |
| 记忆文件（`~/.claude/memory/`） | 多步对话上下文 |
| Git 状态（提交、分支） | 工具调用历史和计数 |
| 磁盘上的文件 | 口头表达的细微用户偏好 |

## 最佳实践

1. **规划后压缩** — 计划确定在 TodoWrite 中后，压缩以重新开始
2. **调试后压缩** — 在继续之前清除错误解决上下文
3. **不要在实现中途压缩** — 保留相关更改的上下文
4. **阅读建议** — Hook 告诉你*何时*，你决定*是否*
5. **压缩前先写入** — 在压缩前将重要上下文保存到文件或记忆中
6. **使用带摘要的 `/compact`** — 添加自定义消息：`/compact 接下来专注于实现认证中间件`

## Token 优化模式

### 触发表延迟加载
不是在会话开始时加载完整的 skill 内容，而是使用将关键字映射到 skill 路径的触发表。Skills 仅在触发时加载，将基线上下文减少 50%+：

| 触发词 | Skill | 加载时机 |
|---------|-------|-----------|
| "test"、"tdd"、"coverage" | tdd-workflow | 用户提到测试 |
| "security"、"auth"、"xss" | security-review | 安全相关工作 |
| "deploy"、"ci/cd" | deployment-patterns | 部署上下文 |

### 上下文组合感知
监控什么在消耗你的上下文窗口：
- **CLAUDE.md 文件** — 始终加载，保持精简
- **已加载的 skills** — 每个 skill 增加 1-5K tokens
- **对话历史** — 随每次交流增长
- **工具结果** — 文件读取、搜索结果增加体积

### 重复指令检测
重复上下文的常见来源：
- `~/.claude/rules/` 和项目 `.claude/rules/` 中的相同规则
- Skills 重复 CLAUDE.md 指令
- 多个 skills 覆盖重叠的领域

### 上下文优化工具
- `token-optimizer` MCP — 通过内容去重实现 95%+ 的 token 减少
- `context-mode` — 上下文虚拟化（演示从 315KB 到 5.4KB）

## 相关

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) — Token 优化章节
- Memory persistence hooks — 用于在压缩后保留状态
- `continuous-learning` skill — 在会话结束前提取模式
