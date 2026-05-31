---
name: database-migration
description: everything-claude-code 中 database-migration 的工作流命令脚手架。
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /database-migration

在 `everything-claude-code` 中处理 **database-migration** 时使用此工作流。

## 目标

带有迁移文件的数据库 schema 更改

## 常见文件

- `**/schema.*`
- `migrations/*`

## 建议序列

1. 在编辑之前了解当前状态和故障模式。
2. 进行满足工作流目标的最小连贯更改。
3. 对接触的文件运行最相关的验证。
4. 总结更改内容和仍需审查的内容。

## 典型提交信号

- 创建迁移文件
- 更新 schema 定义
- 生成/更新类型

## 注意事项

- 将此视为脚手架，而非硬编码脚本。
- 如果工作流发生实质性更改，请更新命令。
