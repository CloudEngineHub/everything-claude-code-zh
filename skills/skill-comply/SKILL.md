---
name: skill-comply
description: 可视化技能、规则和智能体定义是否被真正遵循 — 自动生成 3 个提示严格度级别的场景，运行智能体，分类行为序列，并报告合规率及完整工具调用时间线
origin: ECC
tools: Read, Bash
---

# skill-comply：自动化合规度量

衡量编码智能体是否真正遵循技能、规则或智能体定义，通过：
1. 从任何 .md 文件自动生成预期行为序列（规格）
2. 自动生成递减提示严格度的场景（支持性 → 中性 → 竞争性）
3. 运行 `claude -p` 并通过 stream-json 捕获工具调用追踪
4. 使用 LLM（而非正则表达式）将工具调用与规格步骤进行分类
5. 确定性地检查时序排列
6. 生成包含规格、提示和时间线的自包含报告

## 支持的目标

- **技能**（`skills/*/SKILL.md`）：工作流技能如 search-first、TDD 指南
- **规则**（`rules/common/*.md`）：强制规则如 testing.md、security.md、git-workflow.md
- **智能体定义**（`agents/*.md`）：智能体是否在预期时被调用（内部工作流验证尚未支持）

## 何时激活

- 用户运行 `/skill-comply <path>`
- 用户询问"这条规则真的被遵循了吗？"
- 添加新规则/技能后，验证智能体合规性
- 作为质量维护的定期检查

## 用法

```bash
# 完整运行
uv run python -m scripts.run ~/.claude/rules/common/testing.md

# 试运行（无成本，仅规格 + 场景）
uv run python -m scripts.run --dry-run ~/.claude/skills/search-first/SKILL.md

# 自定义模型
uv run python -m scripts.run --gen-model haiku --model sonnet <path>
```

## 核心概念：提示独立性

衡量即使提示没有明确支持某项技能/规则时，该技能/规则是否仍被遵循。

## 报告内容

报告是自包含的，包括：
1. 预期行为序列（自动生成的规格）
2. 场景提示（每个严格度级别被问到的内容）
3. 每个场景的合规分数
4. 带 LLM 分类标签的工具调用时间线

### 高级（可选）

对于熟悉钩子的用户，报告还包括对合规率低的步骤的钩子推广建议。这是信息性的 — 主要价值在于合规可见性本身。
