---
name: agent-eval
description: 在自定义任务上对编码智能体（Claude Code、Aider、Codex 等）进行头对头比较，包含通过率、成本、时间和一致性指标
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# 智能体评估技能

一个轻量级 CLI 工具，用于在可重现任务上对编码智能体进行头对头比较。每个"哪个编码智能体最好？"的比较都基于氛围 — 此工具将其系统化。

## 何时激活

- 在您自己的代码库上比较编码智能体（Claude Code、Aider、Codex 等）
- 在采用新工具或模型之前测量智能体性能
- 当智能体更新其模型或工具时运行回归检查
- 为团队生成数据支持的智能体选择决策

## 安装

> **注意：** 在审查源代码后从其存储库安装 agent-eval。

## 核心概念

### YAML 任务定义

声明式定义任务。每个任务指定做什么、触摸哪些文件以及如何判断成功：

```yaml
name: add-retry-logic
description: 为 HTTP 客户端添加指数退避重试
repo: ./my-project
files:
  - src/http_client.py
prompt: |
  为所有 HTTP 请求添加指数退避的重试逻辑。
  最多 3 次重试。初始延迟 1 秒，最大延迟 30 秒。
judge:
  - type: pytest
    command: pytest tests/test_http_client.py -v
  - type: grep
    pattern: "exponential_backoff|retry"
    files: src/http_client.py
commit: "abc1234"  # 固定到特定提交以确保可重现性
```

### Git 工作树隔离

每个智能体运行都有自己的 git 工作树 — 不需要 Docker。这提供了可重现性隔离，因此智能体不会相互干扰或损坏基础存储库。

### 收集的指标

| 指标 | 衡量内容 |
|--------|-----------------|
| 通过率 | 智能体是否产生通过判断器的代码？ |
| 成本 | 每项任务的 API 开销（如果可用） |
| 时间 | 完成的墙钟秒数 |
| 一致性 | 重复运行的通过率（例如，3/3 = 100%） |

## 工作流程

### 1. 定义任务

创建一个 `tasks/` 目录，每个任务一个 YAML 文件：

```bash
mkdir tasks
# 编写任务定义（见上面的模板）
```

### 2. 运行智能体

针对您的任务执行智能体：

```bash
agent-eval run --task tasks/add-retry-logic.yaml --agent claude-code --agent aider --runs 3
```

每次运行：
1. 从指定提交创建新的 git 工作树
2. 将提示传递给智能体
3. 运行判断器标准
4. 记录通过/失败、成本和时间

### 3. 比较结果

生成比较报告：

```bash
agent-eval report --format table
```

```
Task: add-retry-logic (各运行 3 次)
┌──────────────┬───────────┬────────┬────────┬─────────────┐
│ Agent        │ Pass Rate │ Cost   │ Time   │ Consistency │
├──────────────┼───────────┼────────┼────────┼─────────────┤
│ claude-code  │ 3/3       │ $0.12  │ 45s    │ 100%        │
│ aider        │ 2/3       │ $0.08  │ 38s    │  67%        │
└──────────────┴───────────┴────────┴────────┴─────────────┘
```

## 判断器类型

### 基于代码（确定性）

```yaml
judge:
  - type: pytest
    command: pytest tests/ -v
  - type: command
    command: npm run build
```

### 基于模式

```yaml
judge:
  - type: grep
    pattern: "class.*Retry"
    files: src/**/*.py
```

### 基于模型（LLM 作为判断器）

```yaml
judge:
  - type: llm
    prompt: |
      此实现是否正确处理指数退避？
      检查：最大重试次数、递增延迟、抖动。
```

## 最佳实践

- **从 3-5 个任务开始**，代表您真实的工作负载，而非玩具示例
- **每个智能体至少运行 3 次试验**以捕获方差 — 智能体是非确定性的
- **在任务 YAML 中固定提交**，以便结果在数天/数周内可重现
- **每个任务至少包含一个确定性判断器**（测试、构建）— LLM 判断器增加噪声
- **与通过率一起跟踪成本** — 95% 的智能体但成本 10 倍可能不是正确的选择
- **对任务定义进行版本控制** — 它们是测试夹具，将其视为代码

## 链接

- 存储库：[github.com/joaquinhuigomez/agent-eval](https://github.com/joaquinhuigomez/agent-eval)
