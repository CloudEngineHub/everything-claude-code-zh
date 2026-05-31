---
description: 运行面向前端的多模型工作流，用于组件、布局、动画和 UI 打磨。
---

# 前端 - 面向前端的开发

面向前端的工作流（研究 → 构思 → 规划 → 执行 → 优化 → 审查），由 Gemini 主导。

## 用法

```bash
/frontend <UI 任务描述>
```

## 上下文

- 前端任务：$ARGUMENTS
- Gemini 主导，Codex 作为辅助参考
- 适用范围：组件设计、响应式布局、UI 动画、样式优化

## 你的角色

你是**前端协调者**，协调多模型协作完成 UI/UX 任务（研究 → 构思 → 规划 → 执行 → 优化 → 审查）。

**协作模型**：
- **Gemini** – 前端 UI/UX（**前端权威，值得信赖**）
- **Codex** – 后端视角（**前端意见仅供参考**）
- **Claude（自身）** – 协调、规划、执行、交付

---

## 多模型调用规范

**调用语法**：

```
# 新会话调用
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend gemini --gemini-model gemini-3-pro-preview - \"$PWD\" <<'EOF'
ROLE_FILE: <角色提示路径>
<TASK>
需求：<增强需求（或未增强时使用 $ARGUMENTS）>
上下文：<来自前序阶段的项目上下文和分析>
</TASK>
OUTPUT: 预期输出格式
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "简要描述"
})

# 恢复会话调用
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend gemini --gemini-model gemini-3-pro-preview resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <角色提示路径>
<TASK>
需求：<增强需求（或未增强时使用 $ARGUMENTS）>
上下文：<来自前序阶段的项目上下文和分析>
</TASK>
OUTPUT: 预期输出格式
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "简要描述"
})
```

**角色提示**：

| 阶段 | Gemini |
|------|--------|
| 分析 | `~/.claude/.ccg/prompts/gemini/analyzer.md` |
| 规划 | `~/.claude/.ccg/prompts/gemini/architect.md` |
| 审查 | `~/.claude/.ccg/prompts/gemini/reviewer.md` |

**会话复用**：每次调用返回 `SESSION_ID: xxx`，后续阶段使用 `resume xxx`。在阶段 2 保存 `GEMINI_SESSION`，在阶段 3 和 5 中使用 `resume`。

---

## 通信指南

1. 以模式标签 `[Mode: X]` 开始响应，初始为 `[Mode: Research]`
2. 遵循严格序列：`Research → Ideation → Plan → Execute → Optimize → Review`
3. 需要用户交互时使用 `AskUserQuestion` 工具（如确认/选择/审批）

---

## 核心工作流

### 阶段 0：提示增强（可选）

`[Mode: Prepare]` - 如果 ace-tool MCP 可用，调用 `mcp__ace-tool__enhance_prompt`，**用增强结果替换原始 $ARGUMENTS 用于后续 Gemini 调用**。如果不可用，原样使用 `$ARGUMENTS`。

### 阶段 1：研究

`[Mode: Research]` - 理解需求并收集上下文

1. **代码检索**（如果 ace-tool MCP 可用）：调用 `mcp__ace-tool__search_context` 检索现有组件、样式、设计系统。如果不可用，使用内置工具：`Glob` 发现文件、`Grep` 搜索组件/样式、`Read` 收集上下文、`Task`（Explore 智能体）进行深度探索。
2. 需求完整度评分（0-10）：>=7 继续，<7 停止并补充

### 阶段 2：构思

`[Mode: Ideation]` - Gemini 主导分析

**必须调用 Gemini**（遵循上述调用规范）：
- ROLE_FILE：`~/.claude/.ccg/prompts/gemini/analyzer.md`
- 需求：增强需求（或未增强时使用 $ARGUMENTS）
- 上下文：阶段 1 的项目上下文
- OUTPUT：UI 可行性分析、推荐方案（至少 2 个）、UX 评估

**保存 SESSION_ID**（`GEMINI_SESSION`）用于后续阶段复用。

输出方案（至少 2 个），等待用户选择。

### 阶段 3：规划

`[Mode: Plan]` - Gemini 主导规划

**必须调用 Gemini**（使用 `resume <GEMINI_SESSION>` 复用会话）：
- ROLE_FILE：`~/.claude/.ccg/prompts/gemini/architect.md`
- 需求：用户选择的方案
- 上下文：阶段 2 的分析结果
- OUTPUT：组件结构、UI 流程、样式方案

Claude 综合规划，用户批准后保存到 `.claude/plan/task-name.md`。

### 阶段 4：实现

`[Mode: Execute]` - 代码开发

- 严格遵循已批准的计划
- 遵循现有项目设计系统和代码标准
- 确保响应性和可访问性

### 阶段 5：优化

`[Mode: Optimize]` - Gemini 主导审查

**必须调用 Gemini**（遵循上述调用规范）：
- ROLE_FILE：`~/.claude/.ccg/prompts/gemini/reviewer.md`
- 需求：审查以下前端代码变更
- 上下文：git diff 或代码内容
- OUTPUT：可访问性、响应性、性能、设计一致性问题列表

整合审查反馈，用户确认后执行优化。

### 阶段 6：质量审查

`[Mode: Review]` - 最终评估

- 对照计划检查完成度
- 验证响应性和可访问性
- 报告问题和建议

---

## 关键规则

1. **Gemini 前端意见值得信赖**
2. **Codex 前端意见仅供参考**
3. 外部模型**零文件系统写入权限**
4. Claude 处理所有代码写入和文件操作
