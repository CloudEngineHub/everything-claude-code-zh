---
name: skill-scout
description: 在创建新技能之前搜索现有的本地、市场、GitHub 和 Web 技能来源。当用户想要创建、构建、分叉或查找工作流技能时使用。
origin: community
---

# 技能侦察兵

在创建新技能之前使用此技能。目标是避免重复现有的社区或市场工作，同时在采纳任何外部内容之前进行审查。

来源：由 `redminwang` 从过时的社区 PR #1232 中抢救。

## 何时使用

- 用户说"创建技能"、"构建技能"、"制作技能"或"新技能"。
- 用户询问"是否有 X 的技能？"或"是否存在做 Y 的技能？"
- 用户描述了一个工作流而你即将建议创建新技能。
- 用户想要分叉或扩展现有技能。

如果用户明确表示跳过搜索或从头创建，确认后继续请求的创建工作流。

## 工作原理

### 步骤 1 - 捕获意图

提取：

- 技能应执行的任务。
- 使用它的触发条件。
- 涉及的领域、工具、框架或数据源。
- 三到五个搜索关键词加上有用的同义词。

### 步骤 2 - 搜索本地来源

先搜索已安装和市场技能名称。优先使用本地来源，因为它们已经是用户环境的一部分。

```bash
find ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | grep -iE "keyword|synonym"
find ~/.claude/plugins/marketplaces -path '*/skills/*/SKILL.md' 2>/dev/null | grep -iE "keyword|synonym"
```

然后搜索 frontmatter 描述：

```bash
grep -RilE "keyword|synonym" ~/.claude/skills ~/.claude/plugins/marketplaces 2>/dev/null
```

### 步骤 3 - 搜索远程来源

使用可用的 GitHub 和 Web 搜索工具。优先使用简洁的查询：

```bash
gh search repos "claude code skill keyword" --limit 10 --sort stars
gh search code "name: keyword" --filename SKILL.md --limit 10
```

对于 Web 搜索，最多使用三个针对性查询，如：

```text
"claude code skill" keyword
"SKILL.md" keyword
"everything-claude-code" keyword
```

### 步骤 4 - 审查外部匹配

在推荐任何外部技能进行采纳或分叉之前：

- 阅读 `SKILL.md` frontmatter 和说明。
- 查找意外的 Shell 命令、文件写入、网络调用、凭据处理或包安装。
- 检查仓库是否看起来有维护。
- 优先复制到新的本地分支并审查差异，而非编辑市场原始文件。

### 步骤 5 - 排名结果

按以下标准排名候选：

1. 技能名称中的精确关键词匹配。
2. 描述中的关键词或同义词匹配。
3. 本地安装或市场来源。
4. 有近期活动的维护中 GitHub 来源。
5. 仅 Web 提及。

将最终列表限制在 10 个结果以内。

### 步骤 6 - 呈现决策选项

给用户一个简短的表格：

| 选项 | 含义 |
| --- | --- |
| 使用现有的 | 直接调用或安装匹配的技能。 |
| 分叉或扩展 | 复制最接近的技能并修改。 |
| 全新创建 | 确认没有接近的匹配后构建新技能。 |

仅在用户选择该路径或搜索未找到接近的匹配时才创建新技能。

## 示例

### 结果表

```markdown
| # | 技能 | 来源 | 匹配原因 | 差距 |
| --- | --- | --- | --- | --- |
| 1 | article-writing | 本地 ECC | 起草文章和指南 | 不专注于发布说明 |
| 2 | content-engine | 本地 ECC | 多格式内容工作流 | 比需要的更重 |
| 3 | blog-writer | GitHub | 有近期提交的博客写作技能 | 需要安全审查 |
```

### 面向用户的摘要

```markdown
我找到了两个接近的本地匹配和一个外部候选。最接近的匹配是
`article-writing`；它涵盖起草和修订，但不包含你要求的发布说明
检查清单。我可以按原样使用、分叉为发布说明变体，或创建全新技能。
```

## 反模式

- 在搜索合理时不要直接跳到新技能创建。
- 不要在未阅读之前安装外部技能。
- 不要呈现冗长的未排名弱匹配列表。
- 不要将仅 Web 提及视为可信来源。
- 不要就地编辑已安装的市场原始文件。

## 相关技能

- `search-first` - 通用的搜索先行工作流。
- `skill-stocktake` - 审计已安装技能的健康状况、重复和差距。
- `agent-sort` - 分类和组织现有的智能体和技能。
