---
name: continuous-learning-v2
description: 基于 Instinct 的学习系统，通过 hooks 观察会话，创建具有置信度评分的原子 instincts，并将其演进为 skills/commands/agents。
version: 2.0.0
---

# Continuous Learning v2 - 基于本能的架构 (Instinct-Based Architecture)

一个先进的学习系统，通过原子 "instincts"（具有置信度评分的小型学习行为），将你的 Claude Code 会话转化为可重用知识。

## v2 新特性

| Feature | v1 | v2 |
|---------|----|----|
| 观察 (Observation) | Stop hook (会话结束) | PreToolUse/PostToolUse (100% 可靠) |
| 分析 (Analysis) | 主上下文 | 后台 agent (Haiku) |
| 粒度 (Granularity) | 完整技能 | 原子 "instincts" (本能) |
| 置信度 (Confidence) | 无 | 0.3-0.9 加权 |
| 演进 (Evolution) | 直接从 skill | Instincts → cluster → skill/command/agent |
| 共享 (Sharing) | 无 | 导出/导入 instincts |

## Instinct 模型

Instinct 是一个小的学习行为：

```yaml
---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
---

# Prefer Functional Style

## Action
Use functional patterns over classes when appropriate.

## Evidence
- Observed 5 instances of functional pattern preference
- User corrected class-based approach to functional on 2025-01-15
```

**属性:**
- **原子性 (Atomic)** — 一个触发器，一个动作
- **置信度加权 (Confidence-weighted)** — 0.3 = 试探性, 0.9 = 几乎确定
- **领域标记 (Domain-tagged)** — code-style, testing, git, debugging, workflow, etc.
- **证据支持 (Evidence-backed)** — 跟踪创建它的观察结果

## 工作原理

```
Session Activity
      │
      │ Hooks capture prompts + tool use (100% reliable)
      ▼
┌─────────────────────────────────────────┐
│         observations.jsonl              │
│   (prompts, tool calls, outcomes)       │
└─────────────────────────────────────────┘
      │
      │ Observer agent reads (background, Haiku)
      ▼
┌─────────────────────────────────────────┐
│          PATTERN DETECTION              │
│   • User corrections → instinct         │
│   • Error resolutions → instinct        │
│   • Repeated workflows → instinct       │
└─────────────────────────────────────────┘
      │
      │ Creates/updates
      ▼
┌─────────────────────────────────────────┐
│         instincts/personal/             │
│   • prefer-functional.md (0.7)          │
│   • always-test-first.md (0.9)          │
│   • use-zod-validation.md (0.6)         │
└─────────────────────────────────────────┘
      │
      │ /evolve clusters
      ▼
┌─────────────────────────────────────────┐
│              evolved/                   │
│   • commands/new-feature.md             │
│   • skills/testing-workflow.md          │
│   • agents/refactor-specialist.md       │
└─────────────────────────────────────────┘
```

## 快速开始

### 1. 启用观察 Hooks

添加到你的 `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh pre"
      }]
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh post"
      }]
    }]
  }
}
```

### 2. 初始化目录结构

```bash
mkdir -p ~/.claude/homunculus/{instincts/{personal,inherited},evolved/{agents,skills,commands}}
touch ~/.claude/homunculus/observations.jsonl
```

### 3. 运行观察者 Agent (可选)

观察者可以在后台运行分析观察结果：

```bash
# Start background observer
~/.claude/skills/continuous-learning-v2/agents/start-observer.sh
```

## 命令

| Command | Description |
|---------|-------------|
| `/instinct-status` | 显示所有已学习的 instincts 及其置信度 |
| `/evolve` | 将相关的 instincts 聚类为 skills/commands |
| `/instinct-export` | 导出 instincts 用于共享 |
| `/instinct-import <file>` | 从其他人导入 instincts |

## 配置

编辑 `config.json`:

```json
{
  "version": "2.0",
  "observation": {
    "enabled": true,
    "store_path": "~/.claude/homunculus/observations.jsonl",
    "max_file_size_mb": 10,
    "archive_after_days": 7
  },
  "instincts": {
    "personal_path": "~/.claude/homunculus/instincts/personal/",
    "inherited_path": "~/.claude/homunculus/instincts/inherited/",
    "min_confidence": 0.3,
    "auto_approve_threshold": 0.7,
    "confidence_decay_rate": 0.05
  },
  "observer": {
    "enabled": true,
    "model": "haiku",
    "run_interval_minutes": 5,
    "patterns_to_detect": [
      "user_corrections",
      "error_resolutions",
      "repeated_workflows",
      "tool_preferences"
    ]
  },
  "evolution": {
    "cluster_threshold": 3,
    "evolved_path": "~/.claude/homunculus/evolved/"
  }
}
```

## 文件结构

```
~/.claude/homunculus/
├── identity.json           # 你的资料，技术水平
├── observations.jsonl      # 当前会话观察结果
├── observations.archive/   # 处理过的观察结果
├── instincts/
│   ├── personal/           # 自动学习的 instincts
│   └── inherited/          # 从其他人导入
└── evolved/
    ├── agents/             # 生成的专家 agents
    ├── skills/             # 生成的 skills
    └── commands/           # 生成的 commands
```

## 与 Skill Creator 集成

当你使用 [Skill Creator GitHub App](https://skill-creator.app) 时，它现在生成 **两者**：
- 传统的 SKILL.md 文件 (为了向后兼容)
- Instinct 集合 (为了 v2 学习系统)

来自 repo 分析的 Instincts 具有 `source: "repo-analysis"` 并包含源仓库 URL。

## 置信度评分

置信度随时间演变：

| Score | Meaning | Behavior |
|-------|---------|----------|
| 0.3 | 试探性 (Tentative) | 建议但不强制 |
| 0.5 | 中等 (Moderate) | 相关时应用 |
| 0.7 | 强 (Strong) | 自动批准应用 |
| 0.9 | 几乎确定 (Near-certain) | 核心行为 |

**置信度增加** 当：
- 模式被重复观察到
- 用户不纠正建议的行为
- 来自其他源的类似 instincts 一致

**置信度降低** 当：
- 用户明确纠正该行为
- 模式长时间未被观察到
- 出现矛盾的证据

## 为什么用 Hooks vs Skills 进行观察？

> "v1 依靠技能进行观察。技能是概率性的——它们根据 Claude 的判断大约 50-80% 的时间触发。"

Hooks **100% 的时间** 确定性地触发。这意味着：
- 每个工具调用都被观察到
- 不会错过任何模式
- 学习是全面的

## 向后兼容性

v2 与 v1 完全兼容：
- 现有的 `~/.claude/skills/learned/` 技能仍然工作
- Stop hook 仍然运行 (但现在也馈送到 v2)
- 渐进式迁移路径：并行运行两者

## 隐私

- 观察结果 **本地** 保留在你的机器上
- 只有 **instincts** (模式) 可以被导出
- 不其实际代码或对话内容被共享
- 你控制导出的内容

## 相关

- [Skill Creator](https://skill-creator.app) - 从 repo 历史生成 instincts
- [Homunculus](https://github.com/humanplane/homunculus) - v2 架构的灵感
- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - 持续学习章节

---

*基于 Instinct 的学习：通过一次一个观察结果，教 Claude 你的模式。*
