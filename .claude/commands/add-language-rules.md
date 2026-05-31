---
name: add-language-rules
description: everything-claude-code 中 add-language-rules 的工作流命令脚手架。
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-language-rules

在 `everything-claude-code` 中处理 **add-language-rules** 时使用此工作流。

## 目标

向规则系统添加新的编程语言，包括编码风格、钩子、模式、安全和测试指南。

## 常见文件

- `rules/*/coding-style.md`
- `rules/*/hooks.md`
- `rules/*/patterns.md`
- `rules/*/security.md`
- `rules/*/testing.md`

## 建议序列

1. 在编辑之前了解当前状态和故障模式。
2. 进行满足工作流目标的最小连贯更改。
3. 对接触的文件运行最相关的验证。
4. 总结更改内容和仍需审查的内容。

## 典型提交信号

- 在 rules/{language}/ 下创建新目录
- 添加具有特定语言内容的 coding-style.md、hooks.md、patterns.md、security.md 和 testing.md 文件
- 可选地引用或链接到相关技能

## 注意事项

- 将此视为脚手架，而非硬编码脚本。
- 如果工作流发生实质性更改，请更新命令。
