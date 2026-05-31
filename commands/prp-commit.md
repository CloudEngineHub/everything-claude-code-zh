---
description: "智能提交，支持自然语言文件定位 — 用通俗语言描述要提交什么"
argument-hint: "[目标描述]（留空 = 所有变更）"
---

# 智能提交

> 改编自 Wirasm 的 PRPs-agentic-eng。PRP 工作流系列的一部分。

**输入**：$ARGUMENTS

---

## 阶段 1 — 评估

```bash
git status --short
```

如果输出为空 → 停止："没有内容可提交。"

向用户展示变更摘要（添加、修改、删除、未跟踪）。

---

## 阶段 2 — 解释与暂存

解释 `$ARGUMENTS` 以确定暂存什么：

| 输入 | 解释 | Git 命令 |
|---|---|---|
| *（空白/空）* | 暂存所有内容 | `git add -A` |
| `staged` | 使用已暂存的内容 | *（不执行 git add）* |
| `*.ts` 或 `*.py` 等 | 暂存匹配的 glob | `git add '*.ts'` |
| `except tests` | 暂存所有，然后取消暂存测试 | `git add -A && git reset -- '**/*.test.*' '**/*.spec.*' '**/test_*' 2>/dev/null \|\| true` |
| `only new files` | 仅暂存未跟踪文件 | `git ls-files --others --exclude-standard \| grep . && git ls-files --others --exclude-standard \| xargs git add` |
| `the auth changes` | 从 status/diff 中解释 — 查找 auth 相关文件 | `git add <匹配的文件>` |
| 具体文件名 | 暂存那些文件 | `git add <文件>` |

对于自然语言输入（如 "the auth changes"），交叉引用 `git status` 输出和 `git diff` 来识别相关文件。向用户展示你正在暂存哪些文件以及为什么。

```bash
git add <确定的文件>
```

暂存后，验证：
```bash
git diff --cached --stat
```

如果没有暂存内容，停止："没有匹配你描述的文件。"

---

## 阶段 3 — 提交

用祈使语气编写单行提交消息：

```
{类型}: {描述}
```

类型：
- `feat` — 新功能或能力
- `fix` — Bug 修复
- `refactor` — 代码重构（无行为变更）
- `docs` — 文档变更
- `test` — 添加或更新测试
- `chore` — 构建、配置、依赖
- `perf` — 性能改进
- `ci` — CI/CD 变更

规则：
- 祈使语气（"add feature" 而非 "added feature"）
- 类型前缀后小写
- 末尾无句号
- 72 字符以内
- 描述变更了**什么**，而非**如何**变更

```bash
git commit -m "{类型}: {描述}"
```

---

## 阶段 4 — 输出

向用户报告：

```
已提交：{hash_short}
消息：   {类型}: {描述}
文件：     {count} 个文件已变更

下一步：
  - git push           → 推送到远程
  - /prp-pr            → 创建拉取请求
  - /code-review       → 推送前审查
```

---

## 示例

| 你说 | 发生什么 |
|---|---|
| `/prp-commit` | 暂存所有，自动生成消息 |
| `/prp-commit staged` | 仅提交已暂存的内容 |
| `/prp-commit *.ts` | 暂存所有 TypeScript 文件，提交 |
| `/prp-commit except tests` | 暂存除测试文件外的所有内容 |
| `/prp-commit the database migration` | 从状态中找到 DB 迁移文件，暂存它们 |
| `/prp-commit only new files` | 仅暂存未跟踪文件 |
