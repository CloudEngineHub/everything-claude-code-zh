---
description: "从当前分支创建 GitHub PR — 发现模板、分析变更、推送"
argument-hint: "[base-branch]（默认：main）"
---

# 创建拉取请求

> 改编自 Wirasm 的 PRPs-agentic-eng。PRP 工作流系列的一部分。

**输入**：`$ARGUMENTS` — 可选，可能包含基础分支名称和/或标志（如 `--draft`）。

**解析 `$ARGUMENTS`**：
- 提取任何已识别的标志（`--draft`）
- 将剩余的非标志文本视为基础分支名称
- 如果未指定，默认基础分支为 `main`

---

## 阶段 1 — 验证

检查前置条件：

```bash
git branch --show-current
git status --short
git log origin/<base>..HEAD --oneline
```

| 检查 | 条件 | 失败时的操作 |
|---|---|---|
| 不在基础分支上 | 当前分支 ≠ base | 停止："先切换到功能分支。" |
| 工作目录干净 | 没有未提交的变更 | 警告："你有未提交的变更。请先提交或暂存。使用 `/prp-commit` 提交。" |
| 有领先提交 | `git log origin/<base>..HEAD` 不为空 | 停止："没有领先于 `<base>` 的提交。没有内容可创建 PR。" |
| 无现有 PR | `gh pr list --head <branch> --json number` 为空 | 停止："PR 已存在：#<number>。使用 `gh pr view <number> --web` 打开它。" |

所有检查通过后，继续。

---

## 阶段 2 — 发现

### PR 模板

按顺序搜索 PR 模板：

1. `.github/PULL_REQUEST_TEMPLATE/` 目录 — 如果存在，列出文件让用户选择（或使用 `default.md`）
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/pull_request_template.md`
4. `docs/pull_request_template.md`

如果找到，读取并使用其结构作为 PR 正文。

### 提交分析

```bash
git log origin/<base>..HEAD --format="%h %s" --reverse
```

分析提交以确定：
- **PR 标题**：使用带有类型前缀的约定式提交格式 — `feat: ...`、`fix: ...` 等
  - 如果有多个类型，使用主要的那个
  - 如果只有单个提交，原样使用其消息
- **变更摘要**：按类型/领域分组提交

### 文件分析

```bash
git diff origin/<base>..HEAD --stat
git diff origin/<base>..HEAD --name-only
```

分类已变更文件：源代码、测试、文档、配置、迁移。

### PRP 产物

检查相关的 PRP 产物：
- `.claude/PRPs/reports/` — 实现报告
- `.claude/PRPs/plans/` — 已执行的计划
- `.claude/PRPs/prds/` — 相关 PRD

如果存在，在 PR 正文中引用。

---

## 阶段 3 — 推送

```bash
git push -u origin HEAD
```

如果推送因分歧失败：
```bash
git fetch origin
git rebase origin/<base>
git push -u origin HEAD
```

如果 rebase 发生冲突，停止并通知用户。

---

## 阶段 4 — 创建

### 使用模板

如果在阶段 2 中找到了 PR 模板，使用提交和文件分析填充每个部分。保留所有模板部分 — 不适用的部分填"N/A"而不是删除。

### 不使用模板

使用此默认格式：

```markdown
## 摘要

<1-2 句话描述此 PR 做了什么以及为什么>

## 变更

<按领域分组的变更列表>

## 变更文件

<变更文件的表格或列表，标注变更类型：添加/修改/删除>

## 测试

<变更如何测试的描述，或"需要测试">

## 相关问题

<关联问题，使用 Closes/Fixes/Relates to #N，或"无">
```

### 创建 PR

```bash
gh pr create \
  --title "<PR 标题>" \
  --base <base-branch> \
  --body "<PR 正文>"
  # 如果从 $ARGUMENTS 中解析到 --draft 标志，则添加 --draft
```

---

## 阶段 5 — 验证

```bash
gh pr view --json number,url,title,state,baseRefName,headRefName,additions,deletions,changedFiles
gh pr checks --json name,status,conclusion 2>/dev/null || true
```

---

## 阶段 6 — 输出

向用户报告：

```
PR #<number>: <标题>
URL: <url>
分支: <head> → <base>
变更: +<additions> -<deletions>，跨 <changedFiles> 个文件

CI 检查: <状态摘要 或 "pending" 或 "未配置">

引用的产物:
  - <PR 正文中链接的任何 PRP 报告/计划>

下一步:
  - gh pr view <number> --web   → 在浏览器中打开
  - /code-review <number>       → 审查 PR
  - gh pr merge <number>        → 准备好后合并
```

---

## 边界情况

- **无 `gh` CLI**：停止并提示："GitHub CLI (`gh`) 是必需的。安装：<https://cli.github.com/>"
- **未认证**：停止并提示："先运行 `gh auth login`。"
- **需要强制推送**：如果远程已分歧且完成了 rebase，使用 `git push --force-with-lease`（绝不使用 `--force`）。
- **多个 PR 模板**：如果 `.github/PULL_REQUEST_TEMPLATE/` 有多个文件，列出并让用户选择。
- **大型 PR（>20 个文件）**：警告 PR 大小。如果变更在逻辑上可分离，建议拆分。
