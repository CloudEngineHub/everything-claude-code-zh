---
name: nanoclaw-repl
description: 操作和扩展 NanoClaw v2，ECC 的零依赖会话感知 REPL，基于 claude -p 构建。
origin: ECC
---

# NanoClaw REPL

在运行或扩展 `scripts/claw.js` 时使用此技能。

## 能力

- 持久的 markdown 支持的会话
- 使用 `/model` 切换模型
- 使用 `/load` 动态加载技能
- 使用 `/branch` 进行会话分支
- 使用 `/search` 进行跨会话搜索
- 使用 `/compact` 压缩历史
- 使用 `/export` 导出到 md/json/txt
- 使用 `/metrics` 查看会话指标

## 操作指南

1. 保持会话专注于任务。
2. 在高风险更改之前创建分支。
3. 在完成主要里程碑后压缩历史。
4. 在共享或归档之前导出。

## 扩展规则

- 保持零外部运行时依赖
- 保持 markdown-as-database 兼容性
- 保持命令处理程序确定性和本地化
