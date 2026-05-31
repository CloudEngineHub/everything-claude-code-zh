---
description: 对抗性双审查收敛循环 — 两个独立的模型审查者都必须批准后代码才能发布。
---

# Santa Loop

使用 santa-method 技能的对抗性双审查收敛循环。两个独立的审查者 — 不同模型、无共享上下文 — 都必须返回 NICE 才能发布代码。

## 目的

运行两个独立审查者（Claude Opus + 外部模型）对当前任务输出进行审查。两者都必须返回 NICE 才能推送代码。如果任一返回 NAUGHTY，修复所有标记的问题，提交，然后用全新审查者重新运行 — 最多 3 轮。

## 用法

```
/santa-loop [file-or-glob | description]
```

## 工作流

### 步骤 1：确定审查范围

从 `$ARGUMENTS` 确定范围，或回退到未提交的变更：

```bash
git diff --name-only HEAD
```

读取所有变更文件以构建完整审查上下文。如果 `$ARGUMENTS` 指定了路径、文件或描述，使用它作为范围。

### 步骤 2：构建评分标准

构建适合审查文件类型的评分标准。每条标准必须有客观的 PASS/FAIL 条件。至少包含：

| 标准 | 通过条件 |
|------|----------|
| 正确性 | 逻辑合理，无 Bug，处理边界情况 |
| 安全性 | 无密钥泄露、注入、XSS 或 OWASP Top 10 问题 |
| 错误处理 | 错误被明确处理，无静默吞没 |
| 完整性 | 所有需求已处理，无遗漏 |
| 内部一致性 | 文件或部分之间无矛盾 |
| 无回归 | 变更不会破坏现有行为 |

根据文件类型添加领域特定标准（如 TS 的类型安全、Rust 的内存安全、SQL 的迁移安全）。

### 步骤 3：双独立审查

使用 Agent 工具**并行**启动两个审查者（在单条消息中同时发起以实现并发执行）。两者都必须完成后才能进入裁决门。

每个审查者将每条标准评估为 PASS 或 FAIL，然后返回结构化 JSON：

```json
{
  "verdict": "PASS" | "FAIL",
  "checks": [
    {"criterion": "...", "result": "PASS|FAIL", "detail": "..."}
  ],
  "critical_issues": ["..."],
  "suggestions": ["..."]
}
```

裁决门（步骤 4）将这些映射为 NICE/NAUGHTY：两者都 PASS → NICE，任一 FAIL → NAUGHTY。

#### 审查者 A：Claude Agent（始终运行）

启动一个 Agent（subagent_type：`code-reviewer`，model：`opus`），包含完整评分标准 + 所有审查文件。提示必须包含：
- 完整评分标准
- 所有审查的文件内容
- "你是一个独立的质量审查者。你没有看过任何其他审查。你的工作是发现问题，而不是批准。"
- 返回上述结构化 JSON 裁决

#### 审查者 B：外部模型（仅在无外部 CLI 安装时回退到 Claude）

首先，检测哪些 CLI 可用：
```bash
command -v codex >/dev/null 2>&1 && echo "codex" || true
command -v gemini >/dev/null 2>&1 && echo "gemini" || true
```

构建审查者提示（与审查者 A 相同的评分标准 + 指令）并写入唯一临时文件：
```bash
PROMPT_FILE=$(mktemp /tmp/santa-reviewer-b-XXXXXX.txt)
cat > "$PROMPT_FILE" << 'EOF'
... 完整评分标准 + 文件内容 + 审查者指令 ...
EOF
```

使用第一个可用的 CLI：

**Codex CLI**（如果已安装）
```bash
codex exec --sandbox read-only -m gpt-5.4 -C "$(pwd)" - < "$PROMPT_FILE"
rm -f "$PROMPT_FILE"
```

**Gemini CLI**（如果已安装且 codex 不可用）
```bash
gemini -p "$(cat "$PROMPT_FILE")" -m gemini-2.5-pro
rm -f "$PROMPT_FILE"
```

**Claude Agent 回退**（仅当 `codex` 和 `gemini` 都未安装时）
启动第二个 Claude Agent（subagent_type：`code-reviewer`，model：`opus`）。记录警告，两个审查者共享相同的模型系列 — 未实现真正的模型多样性，但上下文隔离仍然得到执行。

在所有情况下，审查者必须返回与审查者 A 相同的结构化 JSON 裁决。

### 步骤 4：裁决门

- **两者都 PASS** → **NICE** — 继续步骤 6（推送）
- **任一 FAIL** → **NAUGHTY** — 合并两个审查者的所有 critical 问题，去重，继续步骤 5

### 步骤 5：修复循环（NAUGHTY 路径）

1. 展示两个审查者的所有 critical 问题
2. 修复每个标记的问题 — 仅修改被标记的内容，不做附带重构
3. 在单个提交中提交所有修复：
   ```
   fix: address santa-loop review findings (round N)
   ```
4. 用**全新审查者**重新运行步骤 3（无前几轮记忆）
5. 重复直到两者都返回 PASS

**最多 3 次迭代。** 如果 3 轮后仍然 NAUGHTY，停止并展示剩余问题：

```
SANTA LOOP 升级（超过 3 次迭代）

3 轮后仍存在的问题：
- [列出所有未解决的 critical 问题]

需要手动审查后才能继续。
```

不要推送。

### 步骤 6：推送（NICE 路径）

当两个审查者都返回 PASS：

```bash
git push -u origin HEAD
```

### 步骤 7：最终报告

打印输出报告（参见下方输出部分）。

## 输出

```
SANTA 裁决: [NICE / NAUGHTY (已升级)]

审查者 A (Claude Opus):   [PASS/FAIL]
审查者 B ([使用的模型]):  [PASS/FAIL]

一致性：
  两者都标记：      [两个都发现的问题]
  仅审查者 A：   [只有 A 发现的问题]
  仅审查者 B：   [只有 B 发现的问题]

迭代次数：[N]/3
结果：     [已推送 / 已升级给用户]
```

## 注意事项

- 审查者 A（Claude Opus）始终运行 — 无论工具配置如何，保证至少有一个强审查者。
- 模型多样性是审查者 B 的目标。GPT-5.4 或 Gemini 2.5 Pro 提供真正的独立性 — 不同的训练数据、不同的偏见、不同的盲点。仅使用 Claude 的回退仍通过上下文隔离提供价值，但失去了模型多样性。
- 使用可用的最强模型：审查者 A 使用 Opus，审查者 B 使用 GPT-5.4 或 Gemini 2.5 Pro。
- 外部审查者使用 `--sandbox read-only`（Codex）运行，以防止审查期间仓库被修改。
- 每轮全新审查者防止对前次发现的锚定偏见。
- 评分标准是最重要的输入。如果审查者过度放行或标记主观风格问题，收紧它。
- 在 NAUGHTY 轮次进行提交，这样即使循环被中断也能保留修复。
- 仅在 NICE 后推送 — 绝不在循环中间推送。
