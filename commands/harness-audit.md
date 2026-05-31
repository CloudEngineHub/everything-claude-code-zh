---
description: 运行确定性仓库 harness 审计并返回优先级评分卡。
---

# Harness 审计命令

运行确定性仓库 harness 审计并返回优先级评分卡。

## 用法

`/harness-audit [scope] [--format text|json] [--root path]`

- `scope` （可选）: `repo` （默认）、`hooks`、`skills`、`commands`、`agents`
- `--format`: 输出样式（默认 `text`，`json` 用于自动化）
- `--root`: 审计指定路径而非当前工作目录

## 确定性引擎

始终运行：

```bash
node scripts/harness-audit.js <scope> --format <text|json> [--root <path>]
```

此脚本是评分和检查的真实来源。不要发明额外的维度或临时加分项。

评分标准版本: `2026-05-19`。

脚本计算最多 12 个固定类别（每个归一化为 `0-10`）。前七个始终适用；GitHub 集成始终适用；部署目标类别仅在检测到匹配标记时适用。

1. 工具覆盖
2. 上下文效率
3. 质量门
4. 记忆持久化
5. 评估覆盖
6. 安全护栏
7. 成本效率
8. GitHub 集成
9. Vercel 集成 *（当 `vercel.json` 或 `.vercel/` 存在时）*
10. Netlify 集成 *（当 `netlify.toml` 或 `.netlify/` 存在时）*
11. Cloudflare 集成 *（当 `wrangler.toml` 或 `wrangler.jsonc` 存在时）*
12. Fly 集成 *（当 `fly.toml` 存在时）*

分数来源于显式文件/规则检查，对同一提交可复现。
脚本默认审计当前工作目录，并自动检测目标是 ECC 仓库本身还是使用 ECC 的消费者项目。

## 输出契约

返回：

1. `overall_score` 满分 `max_score`。`max_score` 取决于哪些类别适用于目标；永远不要假设固定总分。
2. `applicable_categories[]` 和 `category_count` 描述哪些类别参与了评分。
3. 类别分数和具体发现。
4. 带有确切文件路径的失败检查。
5. 确定性输出的前 3 项行动（`top_actions`）。
6. 建议下一步应用的 ECC 技能。

## 清单

- 直接使用脚本输出；不要手动重新评分。
- 如果请求 `--format json`，原样返回脚本 JSON。
- 如果请求文本，总结失败检查和首要行动。
- 包含 `checks[]` 和 `top_actions[]` 中的确切文件路径。

## 示例结果

```text
Harness 审计 (repo, repo): 71/80
- 工具覆盖: 10/10 (10/10 分)
- 上下文效率: 9/10 (9/10 分)
- 质量门: 10/10 (10/10 分)
- GitHub 集成: 2/10 (2/10 分)

前 3 项行动:
1) [GitHub 集成] 在 .github/workflows/ 下添加至少一个工作流。(.github/workflows/)
2) [安全护栏] 在 hooks/hooks.json 中添加提示/工具预检安全守卫。(hooks/hooks.json)
3) [评估覆盖] 提高 scripts/hooks/lib 的自动化测试覆盖率。(tests/)
```

## 参数

$ARGUMENTS:
- `repo|hooks|skills|commands|agents` （可选范围）
- `--format text|json` （可选输出格式）
