---
name: evolve
description: 分析本能并建议或生成演化结构
command: true
---

# Evolve 命令

## 实现

使用插件根路径运行本能 CLI：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" evolve [--generate]
```

或者如果未设置 `CLAUDE_PLUGIN_ROOT`（手动安装）：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py evolve [--generate]
```

分析本能并将相关的本能聚合为更高层级的结构：
- **命令（Commands）**：当本能描述用户调用的操作时
- **技能（Skills）**：当本能描述自动触发的行为时
- **智能体（Agents）**：当本能描述复杂的多步骤过程时

## 用法

```
/evolve                    # 分析所有本能并建议演化
/evolve --generate         # 同时在 evolved/{skills,commands,agents} 下生成文件
```

## 演化规则

### → 命令（用户调用）
当本能描述用户会显式请求的操作时：
- 多个关于"当用户要求..."的本能
- 带有"当创建新的 X"之类触发器的本能
- 遵循可重复序列的本能

示例：
- `new-table-step1`: "当添加数据库表时，创建迁移"
- `new-table-step2`: "当添加数据库表时，更新架构"
- `new-table-step3`: "当添加数据库表时，重新生成类型"

→ 创建：**new-table** 命令

### → 技能（自动触发）
当本能描述应该自动发生的行为时：
- 模式匹配触发器
- 错误处理响应
- 代码风格强制

示例：
- `prefer-functional`: "编写函数时，优先使用函数式风格"
- `use-immutable`: "修改状态时，使用不可变模式"
- `avoid-classes`: "设计模块时，避免基于类的设计"

→ 创建：`functional-patterns` 技能

### → 智能体（需要深度/隔离）
当本能描述受益于隔离的复杂多步骤过程时：
- 调试工作流
- 重构序列
- 研究任务

示例：
- `debug-step1`: "调试时，首先检查日志"
- `debug-step2`: "调试时，隔离失败的组件"
- `debug-step3`: "调试时，创建最小复现"
- `debug-step4`: "调试时，用测试验证修复"

→ 创建：**debugger** 智能体

## 操作步骤

1. 检测当前项目上下文
2. 读取项目和全局本能（项目在 ID 冲突时优先）
3. 按触发器/领域模式对本能分组
4. 识别：
   - 技能候选（具有 2+ 本能的触发器集群）
   - 命令候选（高置信度工作流本能）
   - 智能体候选（更大、高置信度的集群）
5. 在适用时显示晋升候选（项目 → 全局）
6. 如果传入了 `--generate`，写入文件至：
   - 项目范围: `~/.claude/homunculus/projects/<project-id>/evolved/`
   - 全局回退: `~/.claude/homunculus/evolved/`

## 输出格式

```
============================================================
  EVOLVE 分析 - 12 个本能
  项目: my-app (a1b2c3d4e5f6)
  项目范围: 8 | 全局: 4
============================================================

高置信度本能 (>=80%): 5

## 技能候选
1. 集群: "添加测试"
   本能: 3
   平均置信度: 82%
   领域: testing
   范围: project

## 命令候选 (2)
  /adding-tests
    来自: test-first-workflow [project]
    置信度: 84%

## 智能体候选 (1)
  adding-tests-agent
    覆盖 3 个本能
    平均置信度: 82%
```

## 标志

- `--generate`: 除分析输出外，还生成演化文件

## 生成的文件格式

### 命令
```markdown
---
name: new-table
description: 创建新的数据库表，包含迁移、架构更新和类型生成
command: /new-table
evolved_from:
  - new-table-migration
  - update-schema
  - regenerate-types
---

# New Table 命令

[基于聚合本能生成的内容]

## 步骤
1. ...
2. ...
```

### 技能
```markdown
---
name: functional-patterns
description: 强制函数式编程模式
evolved_from:
  - prefer-functional
  - use-immutable
  - avoid-classes
---

# Functional Patterns 技能

[基于聚合本能生成的内容]
```

### 智能体
```markdown
---
name: debugger
description: 系统化调试智能体
model: sonnet
evolved_from:
  - debug-check-logs
  - debug-isolate
  - debug-reproduce
---

# Debugger 智能体

[基于聚合本能生成的内容]
```
