---
name: skill-stocktake
description: "在审计 Claude 技能和命令质量时使用。支持快速扫描（仅变更的技能）和完整盘点模式，使用顺序子智能体批量评估。"
origin: ECC
---

# skill-stocktake

斜杠命令（`/skill-stocktake`），使用质量检查清单 + AI 综合判断审计所有 Claude 技能和命令。支持两种模式：快速扫描用于最近变更的技能，完整盘点用于全面审查。

## 范围

该命令针对以下路径，**相对于调用它的目录**：

| 路径 | 描述 |
|------|-------------|
| `~/.claude/skills/` | 全局技能（所有项目） |
| `{cwd}/.claude/skills/` | 项目级技能（如果目录存在） |

**在阶段 1 开始时，命令会明确列出找到和扫描的路径。**

### 针对特定项目

要包含项目级技能，从该项目的根目录运行：

```bash
cd ~/path/to/my-project
/skill-stocktake
```

如果项目没有 `.claude/skills/` 目录，仅评估全局技能和命令。

## 模式

| 模式 | 触发条件 | 持续时间 |
|------|---------|---------|
| 快速扫描 | `results.json` 存在（默认） | 5-10 分钟 |
| 完整盘点 | `results.json` 不存在，或 `/skill-stocktake full` | 20-30 分钟 |

**结果缓存：** `~/.claude/skills/skill-stocktake/results.json`

## 快速扫描流程

仅重新评估自上次运行以来有变更的技能（5-10 分钟）。

1. 读取 `~/.claude/skills/skill-stocktake/results.json`
2. 运行：`bash ~/.claude/skills/skill-stocktake/scripts/quick-diff.sh \
         ~/.claude/skills/skill-stocktake/results.json`
   （项目目录从 `$PWD/.claude/skills` 自动检测；仅在需要时显式传递）
3. 如果输出是 `[]`：报告"自上次运行以来无变更。"并停止
4. 仅使用相同的阶段 2 标准重新评估那些变更的文件
5. 从之前的结果中继承未变更的技能
6. 仅输出差异
7. 运行：`bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
         ~/.claude/skills/skill-stocktake/results.json <<< "$EVAL_RESULTS"`

## 完整盘点流程

### 阶段 1 — 清单

运行：`bash ~/.claude/skills/skill-stocktake/scripts/scan.sh`

该脚本枚举技能文件、提取 frontmatter 并收集 UTC 修改时间。
项目目录从 `$PWD/.claude/skills` 自动检测；仅在需要时显式传递。
从脚本输出呈现扫描摘要和清单表：

```
扫描中：
  ✓ ~/.claude/skills/         (17 个文件)
  ✗ {cwd}/.claude/skills/    (未找到 — 仅全局技能)
```

| 技能 | 7天使用 | 30天使用 | 描述 |
|-------|--------|---------|-------------|

### 阶段 2 — 质量评估

启动一个 Agent 工具子智能体（**通用智能体**），携带完整清单和检查清单：

```text
Agent(
  subagent_type="general-purpose",
  prompt="
根据检查清单评估以下技能清单。

[清单]

[检查清单]

为每个技能返回 JSON：
{ \"verdict\": \"Keep\"|\"Improve\"|\"Update\"|\"Retire\"|\"Merge into [X]\", \"reason\": \"...\" }
"
)
```

子智能体读取每个技能、应用检查清单，并返回每个技能的 JSON：

`{ "verdict": "Keep"|"Improve"|"Update"|"Retire"|"Merge into [X]", "reason": "..." }`

**分块指导：** 每次子智能体调用处理约 20 个技能以保持上下文可管理。每个分块后将中间结果保存到 `results.json`（`status: "in_progress"`）。

所有技能评估完成后：设置 `status: "completed"`，进入阶段 3。

**恢复检测：** 如果启动时发现 `status: "in_progress"`，从第一个未评估的技能恢复。

每个技能根据此检查清单评估：

```
- [ ] 已检查与其他技能的内容重叠
- [ ] 已检查与 MEMORY.md / CLAUDE.md 的重叠
- [ ] 已验证技术参考的新鲜度（如果存在工具名称/CLI 标志/API，使用 WebSearch）
- [ ] 已考虑使用频率
```

判决标准：

| 判决 | 含义 |
|---------|---------|
| Keep | 有用且最新 |
| Improve | 值得保留，但需要具体改进 |
| Update | 引用的技术已过时（用 WebSearch 验证） |
| Retire | 质量低、过时或成本不对称 |
| Merge into [X] | 与另一个技能有实质性重叠；命名合并目标 |

评估是**综合 AI 判断** — 不是数字评分标准。指导维度：
- **可操作性**：代码示例、命令或步骤让你能立即行动
- **范围匹配**：名称、触发条件和内容对齐；不太宽泛或太窄
- **独特性**：不可被 MEMORY.md / CLAUDE.md / 其他技能替代的价值
- **时效性**：技术参考在当前环境中可用

**原因质量要求** — `reason` 字段必须自包含且支持决策：
- 不要只写"未更改" — 始终重述核心证据
- 对于 **Retire**：说明 (1) 发现了什么具体缺陷，(2) 什么覆盖了相同需求
  - 差：`"已被替代"`
  - 好：`"disable-model-invocation: true 已设置；被 continuous-learning-v2 替代，后者涵盖所有相同模式加上置信度评分。没有剩余的独特内容。"`
- 对于 **Merge**：命名目标并描述要集成什么内容
  - 差：`"与 X 重叠"`
  - 好：`"42 行薄弱内容；chatlog-to-article 的步骤 4 已涵盖相同工作流。将'article angle'提示作为注释集成到该技能中。"`
- 对于 **Improve**：描述需要的具体更改（哪个部分、什么行动、目标大小如果相关）
  - 差：`"太长"`
  - 好：`"276 行；'框架比较'部分（L80-140）与 ai-era-architecture-principles 重复；删除以达到约 150 行。"`
- 对于 **Keep**（快速扫描中仅 mtime 变更）：重述原始判决理由，不要写"未更改"
  - 差：`"未更改"`
  - 好：`"mtime 已更新但内容未更改。独特的 Python 参考被 rules/python/ 显式导入；未发现重叠。"`

### 阶段 3 — 汇总表

| 技能 | 7天使用 | 判决 | 原因 |
|-------|--------|---------|--------|

### 阶段 4 — 整合

1. **Retire / Merge**：在与用户确认之前呈现每个文件的详细理由：
   - 发现了什么具体问题（重叠、过时、损坏的引用等）
   - 什么替代方案覆盖了相同功能（对于 Retire：哪个现有技能/规则；对于 Merge：目标文件和要集成什么内容）
   - 移除的影响（任何依赖的技能、MEMORY.md 引用或受影响的工作流）
2. **Improve**：呈现具体的改进建议及理由：
   - 要更改什么以及为什么（例如，"将 430 行精简到 200 行，因为 X/Y 部分与 python-patterns 重复"）
   - 用户决定是否行动
3. **Update**：呈现检查了来源的更新内容
4. 检查 MEMORY.md 行数；如果超过 100 行建议压缩

## 结果文件模式

`~/.claude/skills/skill-stocktake/results.json`：

**`evaluated_at`**：必须设置为评估完成的实际 UTC 时间。
通过 Bash 获取：`date -u +%Y-%m-%dT%H:%M:%SZ`。绝不使用仅日期的近似值如 `T00:00:00Z`。

```json
{
  "evaluated_at": "2026-02-21T10:00:00Z",
  "mode": "full",
  "batch_progress": {
    "total": 80,
    "evaluated": 80,
    "status": "completed"
  },
  "skills": {
    "skill-name": {
      "path": "~/.claude/skills/skill-name/SKILL.md",
      "verdict": "Keep",
      "reason": "具体、可操作、对 X 工作流有独特价值",
      "mtime": "2026-01-15T08:30:00Z"
    }
  }
}
```

## 注意事项

- 评估是盲目的：相同的检查清单适用于所有技能，无论来源（ECC、自编写、自动提取）
- 归档/删除操作始终需要明确的用户确认
- 不根据技能来源进行判决分支
