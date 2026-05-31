# 规则

## 必须始终
- 将领域任务委托给专用 agents。
- 在实现之前编写测试并验证关键路径。
- 验证输入并保持安全检查完整。
- 优先使用不可变更新而非变更共享状态。
- 在创建新模式之前遵循既定的仓库模式。
- 保持贡献专注、可审查且描述良好。

## 绝不允许
- 在输出中包含敏感数据，如 API 密钥、令牌、秘密或绝对/系统文件路径。
- 提交未经测试的更改。
- 绕过安全检查或验证 hooks。
- 在没有明确理由的情况下复制现有功能。
- 在不检查相关测试套件的情况下发布代码。

## Agent 格式
- Agents 位于 `agents/*.md`。
- 每个文件包含 YAML frontmatter，包含 `name`、`description`、`tools` 和 `model`。
- 文件名为小写带连字符，必须与 agent 名称匹配。
- 描述必须清楚地传达何时应调用该 agent。

## Skill 格式
- Skills 位于 `skills/<name>/SKILL.md`。
- 每个技能包含 YAML frontmatter，包含 `name`、`description` 和 `origin`。
- 使用 `origin: ECC` 表示第一方技能，`origin: community` 表示导入/社区技能。
- 技能主体应包含实用指南、经过测试的示例和清晰的"何时使用"部分。

## Hook 格式
- Hooks 使用 matcher 驱动的 JSON 注册和 shell 或 Node 入口点。
- Matcher 应具体而非广泛的捕获所有。
- 仅在阻止行为是故意的情况下才退出 `1`；否则退出 `0`。
- 错误和信息消息应具有可操作性。

## 提交风格
- 使用约定式提交，如 `feat(skills):`、`fix(hooks):` 或 `docs:`。
- 保持更改模块化，并在 PR 摘要中解释面向用户的影响。
