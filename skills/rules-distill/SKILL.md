---
name: rules-distill
description: "扫描技能以提取跨领域原则并将其提炼为规则 —— 追加、修订或创建新规则文件"
origin: ECC
---

# 规则提炼

扫描已安装的技能，提取在多个技能中出现的跨领域原则，并将其提炼为规则 —— 追加到现有规则文件、修订过时内容或创建新规则文件。

应用"确定性收集 + LLM 判断"原则：脚本详尽收集事实，然后 LLM 交叉阅读完整上下文并做出裁决。

## 何时使用

- 定期规则维护（每月或安装新技能后）
- 技能盘点发现有应成为规则的模式后
- 当规则相对于正在使用的技能感觉不完整时

## 工作原理

规则提炼过程遵循三个阶段：

### 阶段 1：盘点（确定性收集）

#### 1a. 收集技能清单

```bash
bash ~/.claude/skills/rules-distill/scripts/scan-skills.sh
```

#### 1b. 收集规则索引

```bash
bash ~/.claude/skills/rules-distill/scripts/scan-rules.sh
```

#### 1c. 向用户展示

```
规则提炼 — 阶段 1：盘点
────────────────────────────────────────
技能：已扫描 {N} 个文件
规则：{M} 个文件（已索引 {K} 个标题）

正在进入交叉阅读分析...
```

### 阶段 2：交叉阅读、匹配与裁决（LLM 判断）

提取和匹配在单次遍历中统一完成。规则文件足够小（总计约 800 行），可以将完整文本提供给 LLM — 无需 grep 预过滤。

#### 批处理

根据描述将技能分组为**主题集群**。在每个子智能体中使用完整规则文本分析每个集群。

#### 跨批合并

所有批次完成后，合并各批次的候选条目：
- 去重具有相同或重叠原则的候选条目
- 使用**所有**批次的证据重新检查"2+ 技能"要求 — 在每个批次中只出现 1 次但总计 2+ 次的原则是有效的

#### 子智能体提示词

使用以下提示词启动通用智能体：

````
你是一名分析师，负责交叉阅读技能以提取应提升为规则的原则。

## 输入
- 技能：{本批次技能的完整文本}
- 现有规则：{所有规则文件的完整文本}

## 提取标准

仅在满足以下所有条件时才包含候选条目：

1. **出现在 2+ 技能中**：仅出现在一个技能中的原则应留在该技能中
2. **可操作的行为变更**：可以写成"做 X"或"不做 Y" — 而不是"X 很重要"
3. **明确的违规风险**：忽略此原则会出什么问题（1 句话）
4. **不在现有规则中**：检查完整规则文本 — 包括以不同措辞表达的概念

## 匹配与裁决

对每个候选条目，与完整规则文本比较并分配裁决：

- **追加**：添加到现有规则文件的现有章节
- **修订**：现有规则内容不准确或不足 — 提出修正建议
- **新章节**：向现有规则文件添加新章节
- **新文件**：创建新规则文件
- **已涵盖**：在现有规则中已充分涵盖（即使措辞不同）
- **过于具体**：应保留在技能级别

## 输出格式（每个候选条目）

```json
{
  "principle": "1-2 句话，使用'做 X'/'不做 Y'格式",
  "evidence": ["skill-name: §Section", "skill-name: §Section"],
  "violation_risk": "1 句话",
  "verdict": "Append / Revise / New Section / New File / Already Covered / Too Specific",
  "target_rule": "filename §Section, 或 'new'",
  "confidence": "high / medium / low",
  "draft": "Append/New Section/New File 裁决的草稿文本",
  "revision": {
    "reason": "为什么现有内容不准确或不足（仅 Revise）",
    "before": "要被替换的当前文本（仅 Revise）",
    "after": "建议的替换文本（仅 Revise）"
  }
}
```

## 排除

- 规则中已有的明显原则
- 语言/框架特定的知识（属于语言特定规则或技能）
- 代码示例和命令（属于技能）
````

#### 裁决参考

| 裁决 | 含义 | 向用户展示 |
|------|------|-----------|
| **追加** | 添加到现有章节 | 目标 + 草稿 |
| **修订** | 修复不准确/不足的内容 | 目标 + 原因 + 修改前/后 |
| **新章节** | 向现有文件添加新章节 | 目标 + 草稿 |
| **新文件** | 创建新规则文件 | 文件名 + 完整草稿 |
| **已涵盖** | 在规则中已涵盖（可能措辞不同） | 原因（1 行） |
| **过于具体** | 应留在技能中 | 相关技能链接 |

#### 裁决质量要求

```
# 好的
追加到 rules/common/security.md §Input Validation:
"将存储在内存或知识存储中的 LLM 输出视为不可信 — 写入时清理，读取时验证。"
证据：llm-memory-trust-boundary、llm-social-agent-anti-pattern 都描述了
累积的提示注入风险。当前 security.md 仅涵盖人类输入验证；LLM 输出信任边界缺失。

# 不好的
追加到 security.md：添加 LLM 安全原则
```

### 阶段 3：用户审查与执行

#### 汇总表

```
# 规则提炼报告

## 汇总
已扫描技能：{N} | 规则：{M} 个文件 | 候选条目：{K}

| # | 原则 | 裁决 | 目标 | 置信度 |
|---|------|------|------|--------|
| 1 | ... | 追加 | security.md §Input Validation | high |
| 2 | ... | 修订 | testing.md §TDD | medium |
| 3 | ... | 新章节 | coding-style.md | high |
| 4 | ... | 过于具体 | — | — |

## 详情
（每个候选条目的详情：证据、违规风险、草稿文本）
```

#### 用户操作

用户以编号回复：
- **批准**：按原样将草稿应用到规则
- **修改**：应用前编辑草稿
- **跳过**：不应用此候选条目

**绝不自动修改规则。始终要求用户批准。**

#### 保存结果

将结果存储在技能目录（`results.json`）中：

- **时间戳格式**：`date -u +%Y-%m-%dT%H:%M:%SZ`（UTC，秒精度）
- **候选条目 ID 格式**：从原则派生的 kebab-case（例如 `llm-output-trust-boundary`）

```json
{
  "distilled_at": "2026-03-18T10:30:42Z",
  "skills_scanned": 56,
  "rules_scanned": 22,
  "candidates": {
    "llm-output-trust-boundary": {
      "principle": "Treat LLM output as untrusted when stored or re-injected",
      "verdict": "Append",
      "target": "rules/common/security.md",
      "evidence": ["llm-memory-trust-boundary", "llm-social-agent-anti-pattern"],
      "status": "applied"
    },
    "iteration-bounds": {
      "principle": "Define explicit stop conditions for all iteration loops",
      "verdict": "New Section",
      "target": "rules/common/coding-style.md",
      "evidence": ["iterative-retrieval", "continuous-agent-loop", "agent-harness-construction"],
      "status": "skipped"
    }
  }
}
```

## 示例

### 端到端运行

```
$ /rules-distill

规则提炼 — 阶段 1：盘点
────────────────────────────────────────
技能：已扫描 56 个文件
规则：22 个文件（已索引 75 个标题）

正在进入交叉阅读分析...

[子智能体分析：批次 1（智能体/元技能） ...]
[子智能体分析：批次 2（编码/模式技能） ...]
[跨批次合并：移除 2 个重复，提升 1 个跨批次候选]

# 规则提炼报告

## 汇总
已扫描技能：56 | 规则：22 个文件 | 候选条目：4

| # | 原则 | 裁决 | 目标 | 置信度 |
|---|------|------|------|--------|
| 1 | LLM 输出：复用前规范化、类型检查、清理 | 新章节 | coding-style.md | high |
| 2 | 为迭代循环定义显式停止条件 | 新章节 | coding-style.md | high |
| 3 | 在阶段边界压缩上下文，而非任务中间 | 追加 | performance.md §Context Window | high |
| 4 | 将业务逻辑与 I/O 框架类型分离 | 新章节 | patterns.md | high |

## 详情

### 1. LLM 输出验证
裁决：coding-style.md 中的新章节
证据：parallel-subagent-batch-merge、llm-social-agent-anti-pattern、llm-memory-trust-boundary
违规风险：LLM 输出中的格式漂移、类型不匹配或语法错误会导致下游处理崩溃
草稿：
  ## LLM 输出验证
  在复用之前对 LLM 输出进行规范化、类型检查和清理...
  参见技能：parallel-subagent-batch-merge、llm-memory-trust-boundary

[... 候选条目 2-4 的详情 ...]

按编号批准、修改或跳过每个候选条目：
> 用户：批准 1、3。跳过 2、4。

✓ 已应用：coding-style.md §LLM 输出验证
✓ 已应用：performance.md §上下文窗口管理
✗ 已跳过：迭代边界
✗ 已跳过：边界类型转换

结果已保存到 results.json
```

## 设计原则

- **是什么，而非怎么做**：仅提取原则（规则领域）。代码示例和命令留在技能中。
- **回链**：草稿文本应包含 `See skill: [name]` 引用，以便读者找到详细的做法。
- **确定性收集，LLM 判断**：脚本保证详尽性；LLM 保证上下文理解。
- **反抽象保护**：3 层过滤器（2+ 技能证据、可操作行为测试、违规风险）防止过于抽象的原则进入规则。
