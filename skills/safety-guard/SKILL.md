---
name: safety-guard
description: 在生产系统上工作或自主运行智能体时，使用此技能防止破坏性操作。
origin: ECC
---

# 安全防护 — 防止破坏性操作

## 何时使用

- 在生产系统上工作时
- 智能体自主运行时（全自动模式）
- 需要将编辑限制在特定目录时
- 执行敏感操作时（迁移、部署、数据变更）

## 工作原理

三种保护模式：

### 模式 1：谨慎模式

在执行破坏性命令前拦截并发出警告：

```
监控的模式：
- rm -rf（尤其是 /、~ 或项目根目录）
- git push --force
- git reset --hard
- git checkout .（丢弃所有更改）
- DROP TABLE / DROP DATABASE
- docker system prune
- kubectl delete
- chmod 777
- sudo rm
- npm publish（意外发布）
- 任何带有 --no-verify 的命令
```

检测到时：显示命令的作用，要求确认，建议更安全的替代方案。

### 模式 2：冻结模式

将文件编辑锁定到特定目录树：

```
/safety-guard freeze src/components/
```

在 `src/components/` 之外的任何 Write/Edit 都会被阻止并给出解释。当你希望智能体专注于一个区域而不触碰无关代码时非常有用。

### 模式 3：防护模式（谨慎 + 冻结组合）

两种保护同时激活。自主智能体的最高安全级别。

```
/safety-guard guard --dir src/api/ --allow-read-all
```

智能体可以读取任何内容，但只能写入 `src/api/`。破坏性命令在任何地方都会被阻止。

### 解锁

```
/safety-guard off
```

## 实现

使用 PreToolUse 钩子拦截 Bash、Write、Edit 和 MultiEdit 工具调用。在允许执行之前，根据活动规则检查命令/路径。

## 集成

- 默认为 `codex -a never` 会话启用
- 与 ECC 2.0 中的可观测性风险评分配对使用
- 将所有被阻止的操作记录到 `~/.claude/safety-guard.log`
