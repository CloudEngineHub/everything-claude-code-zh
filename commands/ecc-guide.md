---
description: 从实时仓库内容中导航 ECC 当前的智能体、技能、命令、钩子、安装配置文件和文档。
---

# /ecc-guide

将此命令用作 Everything Claude Code 的对话式导航。它应帮助用户发现适合其任务的 ECC 功能，而不会倾倒整个 README 或过时的目录计数。

## 用法

```text
/ecc-guide
/ecc-guide setup
/ecc-guide skills
/ecc-guide commands
/ecc-guide hooks
/ecc-guide install
/ecc-guide find: <查询>
/ecc-guide <功能或文件名>
```

## 运行规则

1. 在回答之前，当检出可用时先读取当前仓库文件。
2. 优先使用当前文件系统/目录数据，而非硬编码计数。
3. 保持第一个回答简短，然后提供具体的深入路径。
4. 将用户链接到规范文件，而不是复制长段落。
5. 不要发明不存在的命令、技能、智能体或安装配置文件。

## 检查内容

使用以下文件作为规范导航：

- `README.md` 用于安装路径、重置/卸载指导和高层定位
- `AGENTS.md` 用于贡献者和项目结构指导
- `agent.yaml` 用于导出的智能体和命令功能
- `commands/` 用于维护的斜杠命令入口
- `skills/*/SKILL.md` 用于可复用的技能工作流
- `agents/*.md` 用于委托的智能体角色
- `hooks/README.md` 和 `hooks/hooks.json` 用于钩子行为
- `manifests/install-*.json` 用于选择性安装模块、组件和配置文件
- `scripts/ci/catalog.js --json` 用于在 ECC 内运行时的实时目录计数

## 响应模式

### 无参数

给出紧凑菜单：

- 设置和安装
- 选择技能
- 命令兼容性入口
- 智能体和委托
- 钩子和安全
- 安装故障排除
- 查找特定功能

然后询问他们接下来想做什么。

### 主题查找

对于 `skills`、`commands`、`hooks`、`install` 或 `agents` 等主题：

1. 用 3-6 个要点总结当前功能。
2. 指向规范的目录/文件。
3. 建议一两个可以验证状态的命令。
4. 除非用户要求，否则避免穷举列表。

### 搜索模式

对于 `find: <查询>`：

1. 使用 `rg` 搜索相关文件。
2. 按功能分组结果：技能、命令、智能体、规则、文档、钩子。
3. 最先返回最强匹配及其文件路径。
4. 为每个匹配建议下一步操作。

### 功能查找

对于特定的功能名称：

1. 先检查确切路径，例如 `skills/<name>/SKILL.md`、`commands/<name>.md` 和 `agents/<name>.md`。
2. 如果精确查找失败，使用 `rg` 搜索。
3. 解释该功能的作用、何时使用以及哪个文件是规范的。
4. 仅在相邻功能能减少混淆时才提及。

## 相关命令

- `/project-init` 用于目标项目的堆栈感知 ECC 引导
- `/harness-audit` 用于确定性仓库就绪评分
- `/skill-health` 用于技能质量检查
- `/skill-create` 用于从本地 git 历史提取新技能
- `/security-scan` 用于 Claude/OpenCode 配置安全审查
