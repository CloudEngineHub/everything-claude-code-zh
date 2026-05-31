---
description: 代码审查 — 本地未提交的更改或 GitHub PR（传入 PR 编号/URL 进入 PR 模式）
argument-hint: "[pr-number | pr-url | 留空则进行本地审查]"
---

# 代码审查 (Code Review)

> PR 审查模式改编自 Wirasm 的 PRPs-agentic-eng。PRP 工作流系列的一部分。

**输入**: $ARGUMENTS

---

## 模式选择

如果 `$ARGUMENTS` 包含 PR 编号、PR URL 或 `--pr`：
→ 跳转到下面的 **PR 审查模式**。

否则：
→ 使用 **本地审查模式**。

---

## 本地审查模式

对未提交的更改进行全面的安全和质量审查。

### 阶段 1 — 收集

```bash
git diff --name-only HEAD
```

如果没有更改的文件，停止："Nothing to review."

### 阶段 2 — 审查

完整读取每个更改的文件。检查：

**安全问题 (CRITICAL):**
- 硬编码的凭据、API 密钥、令牌
- SQL 注入漏洞
- XSS 漏洞
- 缺失输入验证
- 不安全的依赖项
- 路径遍历风险

**代码质量 (HIGH):**
- 函数超过 50 行
- 文件超过 800 行
- 嵌套深度超过 4 层
- 缺失错误处理
- console.log 语句
- TODO/FIXME 注释
- 公共 API 缺失 JSDoc

**最佳实践 (MEDIUM):**
- 变异模式（建议使用 immutable 代替）
- 代码/注释中的 Emoji 使用
- 新代码缺失测试
- 可访问性问题 (a11y)

### 阶段 3 — 报告

生成包含以下内容的报告：
- 严重程度：CRITICAL, HIGH, MEDIUM, LOW
- 文件位置和行号
- 问题描述
- 建议的修复

如果发现 CRITICAL 或 HIGH 问题，阻止提交。
永远不要批准包含安全漏洞的代码。

---

## PR 审查模式

全面的 GitHub PR 审查 — 获取差异、读取完整文件、运行验证、发布审查。

### 阶段 1 — 获取

解析输入以确定 PR：

| 输入 | 操作 |
|---|---|
| 编号（如 `42`） | 作为 PR 编号使用 |
| URL（`github.com/.../pull/42`） | 提取 PR 编号 |
| 分支名称 | 通过 `gh pr list --head <branch>` 查找 PR |

```bash
gh pr view <NUMBER> --json number,title,body,author,baseRefName,headRefName,changedFiles,additions,deletions
gh pr diff <NUMBER>
```

如果未找到 PR，停止并显示错误。存储 PR 元数据用于后续阶段。

### 阶段 2 — 上下文

构建审查上下文：

1. **项目规则** — 读取 `CLAUDE.md`、`.claude/docs/` 和任何贡献指南
2. **规划产物** — 检查 `.claude/prds/`、`.claude/plans/`、`.claude/reviews/` 和旧版 `.claude/PRPs/{prds,plans,reports,reviews}/` 中与此 PR 相关的上下文
3. **PR 意图** — 解析 PR 描述中的目标、关联的 issue、测试计划
4. **更改的文件** — 列出所有修改的文件并按类型分类（源码、测试、配置、文档）

### 阶段 3 — 审查

**完整**读取每个更改的文件（不仅仅是差异片段 — 你需要周围的上下文）。

对于 PR 审查，获取 PR head 修订版本的完整文件内容：
```bash
gh pr diff <NUMBER> --name-only | while IFS= read -r file; do
  gh api "repos/{owner}/{repo}/contents/$file?ref=<head-branch>" --jq '.content' | base64 -d
done
```

跨 7 个类别应用审查检查清单：

| 类别 | 检查内容 |
|---|---|
| **正确性** | 逻辑错误、差一错误、null 处理、边缘情况、竞态条件 |
| **类型安全** | 类型不匹配、不安全的类型转换、`any` 使用、缺失的泛型 |
| **模式合规性** | 是否符合项目约定（命名、文件结构、错误处理、导入） |
| **安全性** | 注入、认证漏洞、秘密暴露、SSRF、路径遍历、XSS |
| **性能** | N+1 查询、缺失索引、无界循环、内存泄漏、大负载 |
| **完整性** | 缺失测试、缺失错误处理、不完整的迁移、缺失文档 |
| **可维护性** | 死代码、魔法数字、深层嵌套、不清晰的命名、缺失类型 |

为每个发现分配严重程度：

| 严重程度 | 含义 | 操作 |
|---|---|---|
| **CRITICAL** | 安全漏洞或数据丢失风险 | 合并前必须修复 |
| **HIGH** | 可能导致问题的 Bug 或逻辑错误 | 合并前应该修复 |
| **MEDIUM** | 代码质量问题或缺失的最佳实践 | 建议修复 |
| **LOW** | 风格问题或小建议 | 可选 |

### 阶段 4 — 验证

运行可用的验证命令：

从配置文件（`package.json`、`Cargo.toml`、`go.mod`、`pyproject.toml` 等）检测项目类型，然后运行适当的命令：

**Node.js / TypeScript**（有 `package.json`）：
```bash
npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null  # 类型检查
npm run lint                                                    # Lint
npm test                                                        # 测试
npm run build                                                   # 构建
```

**Rust**（有 `Cargo.toml`）：
```bash
cargo clippy -- -D warnings  # Lint
cargo test                   # 测试
cargo build                  # 构建
```

**Go**（有 `go.mod`）：
```bash
go vet ./...    # Lint
go test ./...   # 测试
go build ./...  # 构建
```

**Python**（有 `pyproject.toml` / `setup.py`）：
```bash
pytest  # 测试
```

仅运行适用于检测到的项目类型的命令。记录每项的通过/失败状态。

### 阶段 5 — 决定

根据发现形成建议：

| 条件 | 决定 |
|---|---|
| 零个 CRITICAL/HIGH 问题，验证通过 | **APPROVE** |
| 仅有 MEDIUM/LOW 问题，验证通过 | **APPROVE** 并附带评论 |
| 任何 HIGH 问题或验证失败 | **REQUEST CHANGES** |
| 任何 CRITICAL 问题 | **BLOCK** — 合并前必须修复 |

特殊情况：
- Draft PR → 始终使用 **COMMENT**（不批准/阻止）
- 仅文档/配置更改 → 较轻的审查，关注正确性
- 明确的 `--approve` 或 `--request-changes` 标志 → 覆盖决定（但仍报告所有发现）

### 阶段 6 — 报告

在 `.claude/reviews/pr-<NUMBER>-review.md` 创建审查产物，除非仓库已经使用旧版 `.claude/PRPs/reviews/` 进行此工作流：

```markdown
# PR Review: #<NUMBER> — <TITLE>

**Reviewed**: <date>
**Author**: <author>
**Branch**: <head> → <base>
**Decision**: APPROVE | REQUEST CHANGES | BLOCK

## Summary
<1-2 句总体评估>

## Findings

### CRITICAL
<findings 或 "None">

### HIGH
<findings 或 "None">

### MEDIUM
<findings 或 "None">

### LOW
<findings 或 "None">

## Validation Results

| Check | Result |
|---|---|
| Type check | Pass / Fail / Skipped |
| Lint | Pass / Fail / Skipped |
| Tests | Pass / Fail / Skipped |
| Build | Pass / Fail / Skipped |

## Files Reviewed
<文件列表及变更类型：Added/Modified/Deleted>
```

### 阶段 7 — 发布

将审查发布到 GitHub：

```bash
# 如果 APPROVE
gh pr review <NUMBER> --approve --body "<summary of review>"

# 如果 REQUEST CHANGES
gh pr review <NUMBER> --request-changes --body "<summary with required fixes>"

# 如果仅 COMMENT（draft PR 或信息性）
gh pr review <NUMBER> --comment --body "<summary>"
```

对于特定行的内联评论，使用 GitHub 审查评论 API：
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/comments" \
  -f body="<comment>" \
  -f path="<file>" \
  -F line=<line-number> \
  -f side="RIGHT" \
  -f commit_id="$(gh pr view <NUMBER> --json headRefOid --jq .headRefOid)"
```

或者，一次性发布带有多个内联评论的审查：
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/reviews" \
  -f event="COMMENT" \
  -f body="<overall summary>" \
  --input comments.json  # [{"path": "file", "line": N, "body": "comment"}, ...]
```

### 阶段 8 — 输出

向用户报告：

```
PR #<NUMBER>: <TITLE>
Decision: <APPROVE|REQUEST_CHANGES|BLOCK>

Issues: <critical_count> critical, <high_count> high, <medium_count> medium, <low_count> low
Validation: <pass_count>/<total_count> checks passed

Artifacts:
  Review: .claude/reviews/pr-<NUMBER>-review.md
  GitHub: <PR URL>

Next steps:
  - <基于决定的上下文建议>
```

---

## 边缘情况

- **无 `gh` CLI**：回退到仅本地审查（读取差异，跳过 GitHub 发布）。警告用户。
- **分支已分叉**：建议在审查前执行 `git fetch origin && git rebase origin/<base>`。
- **大型 PR（>50 个文件）**：警告审查范围。优先关注源码更改，然后是测试，最后是配置/文档。
