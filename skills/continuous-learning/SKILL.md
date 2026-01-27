---
name: continuous-learning
description: 自动从 Claude Code 会话中提取可重用模式，并将其保存为 learned skills 供将来使用。
---

# 持续学习技能 (Continuous Learning Skill)

自动在结束时评估 Claude Code 会话，以提取可重用模式并将其保存为 learned skills。

## 工作原理

此技能作为 **Stop hook** 在每个会话结束时运行：

1. **会话评估**: 检查会话是否有足够的消息 (默认: 10+)
2. **模式检测**: 识别会话中可提取的模式
3. **技能提取**: 将有用的模式保存到 `~/.claude/skills/learned/`

## 配置

编辑 `config.json` 进行自定义：

```json
{
  "min_session_length": 10,
  "extraction_threshold": "medium",
  "auto_approve": false,
  "learned_skills_path": "~/.claude/skills/learned/",
  "patterns_to_detect": [
    "error_resolution",
    "user_corrections",
    "workarounds",
    "debugging_techniques",
    "project_specific"
  ],
  "ignore_patterns": [
    "simple_typos",
    "one_time_fixes",
    "external_api_issues"
  ]
}
```

## 模式类型

| Pattern | Description |
|---------|-------------|
| `error_resolution` | 特定错误是如何解决的 |
| `user_corrections` | 来自用户纠正的模式 |
| `workarounds` | 框架/库怪癖的解决方案 |
| `debugging_techniques` | 有效的调试方法 |
| `project_specific` | 项目特定约定 |

## Hook 设置

添加到你的 `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning/evaluate-session.sh"
      }]
    }]
  }
}
```

## 为什么使用 Stop Hook?

- **轻量级**: 会话结束时运行一次
- **非阻塞**: 不会给每条消息增加延迟
- **完整上下文**: 可以访问完整的会话记录

## 相关

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - 持续学习章节
- `/learn` 命令 - 会话中手动提取模式

---

## 比较说明 (Research: Jan 2025)

### vs Homunculus (github.com/humanplane/homunculus)

Homunculus v2 采取了更复杂的方法：

| Feature | Our Approach | Homunculus v2 |
|---------|--------------|---------------|
| 观察 (Observation) | Stop hook (会话结束) | PreToolUse/PostToolUse hooks (100% 可靠) |
| 分析 (Analysis) | 主上下文 | 后台 agent (Haiku) |
| 粒度 (Granularity) | 完整技能 | 原子 "instincts" (本能) |
| 置信度 (Confidence) | 无 | 0.3-0.9 加权 |
| 演进 (Evolution) | 直接从 skill | Instincts → cluster → skill/command/agent |
| 共享 (Sharing) | 无 | 导出/导入 instincts |

**来自 homunculus 的关键见解:**
> "v1 依靠技能进行观察。技能是概率性的——它们大约 50-80% 的时间触发。v2 使用 hooks 进行观察（100% 可靠）并将 instincts 作为学习行为的原子单位。"

### 潜在 v2 增强功能

1. **基于 Instinct 的学习** - 具有置信度评分的更小、原子行为
2. **后台观察者** - 并行分析的 Haiku agent
3. **置信度衰减** - 如果 instincts 被反驳，置信度会降低
4. **领域标记** - code-style, testing, git, debugging, etc.
5. **演进路径** - 将相关的 instincts 聚类为 skills/commands

参见: `/Users/affoon/Documents/tasks/12-continuous-learning-v2.md` 获取完整规范。
