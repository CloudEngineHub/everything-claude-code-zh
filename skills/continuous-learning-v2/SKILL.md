---
name: continuous-learning-v2
description: 基于 Instinct 的学习系统，通过 hooks 观察会话，创建具有置信度评分的原子 instincts，并将其演进为 skills/commands/agents。v2.1 添加了项目范围的 instincts 以防止跨项目污染。
origin: ECC
version: 2.1.0
---

# Continuous Learning v2.1 - 基于 Instinct 的架构

一个先进的学习系统，通过原子 "instincts"（具有置信度评分的小型学习行为），将你的 Claude Code 会话转化为可重用知识。

**v2.1** 添加了**项目范围的 instincts** — React 模式留在你的 React 项目中，Python 约定留在你的 Python 项目中，通用模式（如"始终验证输入"）全局共享。

## 何时激活

- 设置从 Claude Code 会话自动学习
- 通过 hooks 配置基于 instinct 的行为提取
- 调整学习行为的置信度阈值
- 审查、导出或导入 instinct 库
- 将 instincts 演进为完整的 skills、commands 或 agents
- 管理项目范围与全局 instincts
- 将 instincts 从项目范围提升到全局范围

## v2.1 新特性

| 特性 | v2.0 | v2.1 |
|---------|------|------|
| 存储 | 全局（`~/.claude/homunculus/`） | 项目范围（`${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/projects/<hash>/`） |
| 范围 | 所有 instincts 到处应用 | 项目范围 + 全局 |
| 检测 | 无 | git remote URL / 仓库路径 |
| 提升 | N/A | 在 2+ 个项目中出现时从项目提升到全局 |
| 命令 | 4（status/evolve/export/import） | 6（+promote/projects） |
| 跨项目 | 污染风险 | 默认隔离 |

## v2 新特性（相比 v1）

| 特性 | v1 | v2 |
|---------|----|----|
| 观察 | Stop hook（会话结束） | PreToolUse/PostToolUse（100% 可靠） |
| 分析 | 主上下文 | 后台 agent（Haiku） |
| 粒度 | 完整 skills | 原子 "instincts" |
| 置信度 | 无 | 0.3-0.9 加权 |
| 演进 | 直接到 skill | Instincts -> 聚类 -> skill/command/agent |
| 共享 | 无 | 导出/导入 instincts |

## Instinct 模型

Instinct 是一个小的学习行为：

```yaml
---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
scope: project
project_id: "a1b2c3d4e5f6"
project_name: "my-react-app"
---

# Prefer Functional Style

## Action
Use functional patterns over classes when appropriate.

## Evidence
- Observed 5 instances of functional pattern preference
- User corrected class-based approach to functional on 2025-01-15
```

**属性：**
- **原子性** -- 一个触发器，一个动作
- **置信度加权** -- 0.3 = 试探性，0.9 = 几乎确定
- **领域标记** -- code-style、testing、git、debugging、workflow 等
- **证据支持** -- 跟踪创建了它的观察结果
- **范围感知** -- `project`（默认）或 `global`

## 工作原理

```
Session Activity (在 git 仓库中)
      |
      | Hooks 捕获 prompts + 工具使用（100% 可靠）
      | + 检测项目上下文（git remote / 仓库路径）
      v
+---------------------------------------------+
|  projects/<project-hash>/observations.jsonl  |
|   (prompts, tool calls, outcomes, project)   |
+---------------------------------------------+
      |
      | Observer agent 读取（后台，Haiku）
      v
+---------------------------------------------+
|          模式检测                   |
|   * 用户纠正 -> instinct             |
|   * 错误解决 -> instinct            |
|   * 重复工作流 -> instinct           |
|   * 范围决定：项目还是全局？       |
+---------------------------------------------+
      |
      | 创建/更新
      v
+---------------------------------------------+
|  projects/<project-hash>/instincts/personal/ |
|   * prefer-functional.yaml (0.7) [project]   |
|   * use-react-hooks.yaml (0.9) [project]     |
+---------------------------------------------+
|  instincts/personal/  (全局)               |
|   * always-validate-input.yaml (0.85) [global]|
|   * grep-before-edit.yaml (0.6) [global]     |
+---------------------------------------------+
      |
      | /evolve 聚类 + /promote
      v
+---------------------------------------------+
|  projects/<hash>/evolved/ (项目范围)   |
|  evolved/ (全局)                           |
|   * commands/new-feature.md                  |
|   * skills/testing-workflow.md               |
|   * agents/refactor-specialist.md            |
+---------------------------------------------+
```

## 项目检测

系统自动检测你的当前项目：

1. **`CLAUDE_PROJECT_DIR` 环境变量**（最高优先级）
2. **`git remote get-url origin`** -- 哈希以创建可移植的项目 ID（不同机器上的同一仓库获得相同的 ID）
3. **`git rev-parse --show-toplevel`** -- 使用仓库路径的备选方案（特定于机器）
4. **全局回退** -- 如果未检测到项目，instincts 进入全局范围

每个项目获得一个 12 字符的哈希 ID（如 `a1b2c3d4e5f6`）。注册文件位于 `${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/projects.json`，将 ID 映射到人类可读的名称。

### 数据目录

Continuous-learning-v2 将观察者数据存储在 `~/.claude` 之外，这样 Claude Code 的敏感路径守卫不会阻止后台 instinct 写入：

1. `CLV2_HOMUNCULUS_DIR` 设置为绝对路径时
2. `$XDG_DATA_HOME/ecc-homunculus`
3. `$HOME/.local/share/ecc-homunculus`

在 `~/.claude/homunculus` 有数据的现有用户可以一次性迁移：

```bash
bash skills/continuous-learning-v2/scripts/migrate-homunculus.sh
```

## 快速开始

### 1. 启用观察 Hooks

**如果作为插件安装**（推荐）：

不需要额外的 `settings.json` hook 块。Claude Code v2.1+ 自动加载插件 `hooks/hooks.json`，`observe.sh` 已在其中注册。

如果你之前将 `observe.sh` 复制到了 `~/.claude/settings.json` 中，请移除那个重复的 `PreToolUse` / `PostToolUse` 块。重复插件 hook 会导致双重执行和 `${CLAUDE_PLUGIN_ROOT}` 解析错误，因为该变量仅在插件管理的 `hooks/hooks.json` 条目中可用。

**如果手动安装**到 `~/.claude/skills`，添加到你的 `~/.claude/settings.json`：

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh"
      }]
    }]
  }
}
```

### 2. 初始化目录结构

系统在首次使用时自动创建目录，但你也可以手动创建：

```bash
# 全局目录
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/ecc-homunculus"/{instincts/{personal,inherited},evolved/{agents,skills,commands},projects}

# 项目目录在 hook 首次在 git 仓库中运行时自动创建
```

### 3. 使用 Instinct 命令

```bash
/instinct-status     # 显示已学习的 instincts（项目 + 全局）
/evolve              # 将相关的 instincts 聚类为 skills/commands
/instinct-export     # 导出 instincts 到文件
/instinct-import     # 从其他人导入 instincts
/promote             # 将项目 instincts 提升到全局范围
/projects            # 列出所有已知项目及其 instinct 计数
```

## 命令

| 命令 | 描述 |
|---------|-------------|
| `/instinct-status` | 显示所有 instincts（项目范围 + 全局）及置信度 |
| `/evolve` | 将相关 instincts 聚类为 skills/commands，建议提升 |
| `/instinct-export` | 导出 instincts（可按范围/领域过滤） |
| `/instinct-import <file>` | 导入 instincts 并带范围控制 |
| `/promote [id]` | 将项目 instincts 提升到全局范围 |
| `/projects` | 列出所有已知项目及其 instinct 计数 |

## 配置

编辑 `config.json` 控制后台观察者：

```json
{
  "version": "2.1",
  "observer": {
    "enabled": false,
    "run_interval_minutes": 5,
    "min_observations_to_analyze": 20
  }
}
```

| 键 | 默认值 | 描述 |
|-----|---------|-------------|
| `observer.enabled` | `false` | 启用后台观察者 agent |
| `observer.run_interval_minutes` | `5` | 观察者分析观察结果的频率 |
| `observer.min_observations_to_analyze` | `20` | 分析运行前的最小观察结果数 |

其他行为（观察捕获、instinct 阈值、项目范围、提升标准）通过 `instinct-cli.py` 和 `observe.sh` 中的代码默认值配置。

## 文件结构

```
${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/
+-- identity.json           # 你的资料，技术水平
+-- projects.json           # 注册表：项目哈希 -> 名称/路径/远程
+-- observations.jsonl      # 全局观察结果（回退）
+-- instincts/
|   +-- personal/           # 全局自动学习的 instincts
|   +-- inherited/          # 全局导入的 instincts
+-- evolved/
|   +-- agents/             # 全局生成的 agents
|   +-- skills/             # 全局生成的 skills
|   +-- commands/           # 全局生成的 commands
+-- projects/
    +-- a1b2c3d4e5f6/       # 项目哈希（来自 git remote URL）
    |   +-- project.json    # 每项目元数据镜像（id/name/root/remote）
    |   +-- observations.jsonl
    |   +-- observations.archive/
    |   +-- instincts/
    |   |   +-- personal/   # 项目特定的自动学习
    |   |   +-- inherited/  # 项目特定的导入
    |   +-- evolved/
    |       +-- skills/
    |       +-- commands/
    |       +-- agents/
    +-- f6e5d4c3b2a1/       # 另一个项目
        +-- ...
```

## 范围决策指南

| 模式类型 | 范围 | 示例 |
|-------------|-------|---------|
| 语言/框架约定 | **project** | "使用 React hooks"、"遵循 Django REST 模式" |
| 文件结构偏好 | **project** | "测试在 `__tests__`/"、"组件在 src/components/" |
| 代码风格 | **project** | "使用函数式风格"、"优先使用 dataclasses" |
| 错误处理策略 | **project** | "使用 Result 类型处理错误" |
| 安全实践 | **global** | "验证用户输入"、"清理 SQL" |
| 通用最佳实践 | **global** | "先写测试"、"始终处理错误" |
| 工具工作流偏好 | **global** | "编辑前先 Grep"、"写入前先读取" |
| Git 实践 | **global** | "Conventional commits"、"小型聚焦提交" |

## Instinct 提升（项目 -> 全局）

当相同的 instinct 以高置信度出现在多个项目中时，它是提升到全局范围的候选者。

**自动提升标准：**
- 相同 instinct ID 在 2+ 个项目中
- 平均置信度 >= 0.8

**如何提升：**

```bash
# 提升特定 instinct
python3 instinct-cli.py promote prefer-explicit-errors

# 自动提升所有符合条件的 instincts
python3 instinct-cli.py promote

# 预览而不做更改
python3 instinct-cli.py promote --dry-run
```

`/evolve` 命令也会建议提升候选者。

## 置信度评分

置信度随时间演变：

| 分数 | 含义 | 行为 |
|-------|---------|----------|
| 0.3 | 试探性 | 建议但不强制 |
| 0.5 | 中等 | 相关时应用 |
| 0.7 | 强 | 自动批准应用 |
| 0.9 | 几乎确定 | 核心行为 |

**置信度增加** 当：
- 模式被重复观察到
- 用户不纠正建议的行为
- 来自其他源的类似 instincts 一致

**置信度降低** 当：
- 用户明确纠正该行为
- 模式长时间未被观察到
- 出现矛盾的证据

## 为什么用 Hooks 而非 Skills 进行观察？

> "v1 依靠 skills 进行观察。Skills 是概率性的 — 基于 Claude 的判断，它们大约 50-80% 的时间触发。"

Hooks **100% 的时间**确定性地触发。这意味着：
- 每个工具调用都被观察到
- 不会错过任何模式
- 学习是全面的

## 向后兼容性

v2.1 与 v2.0 和 v1 完全兼容：
- 现有全局 instincts 可以通过 `scripts/migrate-homunculus.sh` 从 `~/.claude/homunculus/instincts/` 迁移
- 现有的 `~/.claude/skills/learned/` skills 来自 v1 仍然工作
- Stop hook 仍然运行（但现在也馈送到 v2）
- 渐进式迁移：并行运行两者

## 隐私

- 观察结果**本地**保留在你的机器上
- 项目范围的 instincts 按项目隔离
- 只有 **instincts**（模式）可以被导出 — 不导出原始观察结果
- 不共享实际代码或对话内容
- 你控制导出和提升的内容

## 相关

- [ECC-Tools GitHub App](https://github.com/apps/ecc-tools) - 从仓库历史生成 instincts
- Homunculus - 启发了 v2 instinct 架构的社区项目（原子观察、置信度评分、instinct 演进管道）
- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - 持续学习章节

---

*基于 Instinct 的学习：一个项目一个项目地教 Claude 你的模式。*
