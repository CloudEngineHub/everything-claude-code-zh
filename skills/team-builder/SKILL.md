---
name: team-builder
description: 交互式智能体选择器，用于组合和分派并行团队
origin: community
---

# 团队构建器

按需浏览和组合智能体团队的交互式菜单。支持扁平或域子目录的智能体集合。

## 何时使用

- 你有多个智能体角色（Markdown 文件）并想选择使用哪些来完成任务
- 你想从不同领域组合临时团队（例如 安全 + SEO + 架构）
- 你想在决定之前浏览可用的智能体

## 前提条件

智能体文件必须是包含角色提示（身份、规则、工作流、交付物）的 Markdown 文件。第一个 `# 标题` 用作智能体名称，第一段用作描述。

支持扁平 和子目录两种布局：

**子目录布局** — 域从文件夹名称推断：

```
agents/
├── engineering/
│   ├── security-engineer.md
│   └── software-architect.md
├── marketing/
│   └── seo-specialist.md
└── sales/
    └── discovery-coach.md
```

**扁平布局** — 域从共享的文件名前缀推断。当 2 个以上文件共享前缀时，该前缀算作一个域。具有唯一前缀的文件归入"通用"。注意：算法在第一个 `-` 处分割，因此多词域（如 `product-management`）应使用子目录布局：

```
agents/
├── engineering-security-engineer.md
├── engineering-software-architect.md
├── marketing-seo-specialist.md
├── marketing-content-strategist.md
├── sales-discovery-coach.md
└── sales-outbound-strategist.md
```

## 配置

智能体通过两种方法发现，按智能体名称合并并去重：

1. **`claude agents` 命令**（主要）— 运行 `claude agents` 获取 CLI 已知的所有智能体，包括用户智能体、插件智能体（如 `everything-claude-code:architect`）和内置智能体。这自动覆盖 ECC 市场安装，无需任何路径配置。
2. **文件 glob**（备用，用于读取智能体内容）— 从以下位置读取智能体 Markdown 文件：
   - `./agents/**/*.md` + `./agents/*.md` — 项目本地智能体
   - `~/.claude/agents/**/*.md` + `~/.claude/agents/*.md` — 全局用户智能体

当名称冲突时，较早的来源优先：用户智能体 > 插件智能体 > 内置智能体。如果用户指定了自定义路径，可以使用自定义路径。

## 工作原理

### 步骤 1：发现可用智能体

运行 `claude agents` 获取完整智能体列表。解析每行：
- **插件智能体**以 `plugin-name:` 为前缀（如 `everything-claude-code:security-reviewer`）。使用 `:` 后的部分作为智能体名称，插件名称作为域。
- **用户智能体**没有前缀。从 `~/.claude/agents/` 或 `./agents/` 读取对应的 Markdown 文件以提取名称和描述。
- **内置智能体**（如 `Explore`、`Plan`）跳过，除非用户明确要求包含。

对于从 Markdown 文件加载的用户智能体：
- **子目录布局：** 从父文件夹名称提取域
- **扁平布局：** 收集所有文件名前缀（第一个 `-` 之前的文本）。只有出现在 2 个或更多文件名中的前缀才算作域（如 `engineering-security-engineer.md` 和 `engineering-software-architect.md` 都以 `engineering` 开头 → Engineering 域）。具有唯一前缀的文件（如 `code-reviewer.md`、`tdd-guide.md`）归入"通用"
- 从第一个 `# 标题` 提取智能体名称。如果没有找到标题，从文件名派生名称（去掉 `.md`，将连字符替换为空格，首字母大写）
- 从标题后的第一段提取一行摘要

如果在运行 `claude agents` 和探测文件位置后没有找到智能体，告知用户："未找到智能体。运行 `claude agents` 验证你的设置。"然后停止。

### 步骤 2：呈现域菜单

```
可用的智能体领域：
1. Engineering — Software Architect, Security Engineer
2. Marketing — SEO Specialist
3. Sales — Discovery Coach, Outbound Strategist

选择领域或命名特定智能体（例如 "1,3" 或 "security + seo"）：
```

- 跳过零智能体的域（空目录）
- 显示每个域的智能体数量

### 步骤 3：处理选择

接受灵活的输入：
- 数字："1,3" 选择 Engineering 和 Sales 的所有智能体
- 名称："security + seo" 模糊匹配已发现的智能体
- "all from engineering" 选择该域中的每个智能体

如果选择了超过 5 个智能体，按字母顺序列出并要求用户缩小范围："你选择了 N 个智能体（最多 5 个）。选择要保留的，或说 'first 5' 使用按字母顺序的前五个。"

确认选择：
```
已选择：Security Engineer + SEO Specialist
他们应该做什么？（描述任务）：
```

### 步骤 4：并行启动智能体

1. 读取每个所选智能体的 Markdown 文件
2. 如果尚未提供，提示输入任务描述
3. 使用 Agent 工具并行启动所有智能体：
   - `subagent_type: "general-purpose"`
   - `prompt: "{智能体文件内容}\n\n任务：{任务描述}"`
   - 每个智能体独立运行 — 不需要智能体间通信
4. 如果智能体失败（错误、超时或空输出），内联注明失败（如 "Security Engineer: 失败 — [原因]"）并继续使用成功智能体的结果

### 步骤 5：综合结果

收集所有输出并呈现统一报告：
- 按智能体分组的结果
- 综合部分突出：
  - 智能体之间的共识
  - 建议之间的冲突或张力
  - 推荐的下一步

如果只选择了 1 个智能体，跳过综合直接呈现输出。

## 规则

- **仅动态发现。** 绝不硬编码智能体列表。目录中的新文件自动出现在菜单中。
- **每个团队最多 5 个智能体。** 超过 5 个会产生递减收益和过多的 token 使用。在选择时强制执行。
- **并行分派。** 所有智能体同时运行 — 使用 Agent 工具的并行调用模式。
- **并行 Agent 调用，而非 TeamCreate。** 此技能使用并行 Agent 工具调用进行独立工作。TeamCreate（用于多智能体对话的 Claude Code 工具）仅在智能体需要互相辩论或回应时才需要。

## 示例

```
用户：team builder

Claude：
可用的智能体领域：
1. Engineering (2) — Software Architect, Security Engineer
2. Marketing (1) — SEO Specialist
3. Sales (4) — Discovery Coach, Outbound Strategist, Proposal Strategist, Sales Engineer
4. Support (1) — Executive Summary

选择领域或命名特定智能体：

用户：security + seo

Claude：
已选择：Security Engineer + SEO Specialist
他们应该做什么？

用户：在上线前审查我的 Next.js 电商网站

[两个智能体并行启动，各自将其专长应用于代码库]

Claude：
## Security Engineer 发现
- [发现...]

## SEO Specialist 发现
- [发现...]

## 综合
两个智能体一致认为：[...]
张力：Security 推荐 CSP 阻止内联样式，SEO 需要内联 Schema 标记。解决方案：[...]
下一步：[...]
```
