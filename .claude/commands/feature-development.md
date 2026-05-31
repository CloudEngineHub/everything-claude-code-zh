---
name: feature-development
description: everything-claude-code 中 feature-development 的工作流命令脚手架。
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /feature-development

在 `everything-claude-code` 中处理 **feature-development** 时使用此工作流。

## 目标

标准功能实现工作流

## 常见文件

- `manifests/*`
- `schemas/*`
- `**/*.test.*`
- `**/api/**`

## 建议序列

1. 在编辑之前了解当前状态和故障模式。
2. 进行满足工作流目标的最小连贯更改。
3. 对接触的文件运行最相关的验证。
4. 总结更改内容和仍需审查的内容。

## 典型提交信号

- 添加功能实现
- 为功能添加测试
- 更新文档

## 注意事项

- 将此视为脚手架，而非硬编码脚本。
- 如果工作流发生实质性更改，请更新命令。
