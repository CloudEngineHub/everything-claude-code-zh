---
name: evolve
description: 将相关的 instincts 聚类为 skills, commands, 或 agents
command: /evolve
implementation: python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py evolve
---

# Evolve Command (演化命令)

## 实施

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py evolve [--generate]
```

分析 instincts 并将相关的聚类为更高级的结构：
- **Commands**: 当 instincts 描述用户调用的操作时
- **Skills**: 当 instincts 描述自动触发的行为时
- **Agents**: 当 instincts 描述复杂、多步的过程时

## 用法

```
/evolve                    # 分析所有 instincts 并建议演化
/evolve --domain testing   # 仅演化 testing 域中的 instincts
/evolve --dry-run          # 显示将要创建的内容而不实际创建
/evolve --threshold 5      # 需要 5+ 相关的 instincts 才聚类
```

## 演化规则

### → Command (用户调用)
当 instincts 描述用户会显式请求的操作时：
- 关于 "当用户要求..." 的多个 instincts
- 带有像 "当创建一个新 X 时" 触发器的 instincts
- 遵循可重复序列的 instincts

示例：
- `new-table-step1`: "when adding a database table, create migration"
- `new-table-step2`: "when adding a database table, update schema"
- `new-table-step3`: "when adding a database table, regenerate types"

→ 创建: `/new-table` command

### → Skill (自动触发)
当 instincts 描述应该自动发生的行为时：
- 模式匹配触发器
- 错误处理响应
- 代码风格强制

示例：
- `prefer-functional`: "when writing functions, prefer functional style"
- `use-immutable`: "when modifying state, use immutable patterns"
- `avoid-classes`: "when designing modules, avoid class-based design"

→ 创建: `functional-patterns` skill

### → Agent (需要深度/隔离)
当 instincts 描述受益于隔离的复杂、多步过程时：
- 调试工作流
- 重构序列
- 研究任务

示例：
- `debug-step1`: "when debugging, first check logs"
- `debug-step2`: "when debugging, isolate the failing component"
- `debug-step3`: "when debugging, create minimal reproduction"
- `debug-step4`: "when debugging, verify fix with test"

→ 创建: `debugger` agent

## 做什么

1. 读取 `~/.claude/homunculus/instincts/` 中的所有 instincts
2. 通过以下方式分组 instincts:
   - 域相似性
   - 触发模式重叠
   - 动作序列关系
3. 对于每组 3+ 相关的 instincts:
   - 确定演化类型 (command/skill/agent)
   - 生成适当的文件
   - 保存到 `~/.claude/homunculus/evolved/{commands,skills,agents}/`
4. 将演化结构链接回源 instincts

## 输出格式

```
🧬 Evolve Analysis
==================

Found 3 clusters ready for evolution:

## Cluster 1: Database Migration Workflow
Instincts: new-table-migration, update-schema, regenerate-types
Type: Command
Confidence: 85% (based on 12 observations)

Would create: /new-table command
Files:
  - ~/.claude/homunculus/evolved/commands/new-table.md

## Cluster 2: Functional Code Style
Instincts: prefer-functional, use-immutable, avoid-classes, pure-functions
Type: Skill
Confidence: 78% (based on 8 observations)

Would create: functional-patterns skill
Files:
  - ~/.claude/homunculus/evolved/skills/functional-patterns.md

## Cluster 3: Debugging Process
Instincts: debug-check-logs, debug-isolate, debug-reproduce, debug-verify
Type: Agent
Confidence: 72% (based on 6 observations)

Would create: debugger agent
Files:
  - ~/.claude/homunculus/evolved/agents/debugger.md

---
Run `/evolve --execute` to create these files.
```

## 标志 (Flags)

- `--execute`: 实际创建演化结构 (默认是预览)
- `--dry-run`: 预览而不创建
- `--domain <name>`: 仅演化指定域中的 instincts
- `--threshold <n>`: 形成聚类所需的最小 instincts 数 (默认: 3)
- `--type <command|skill|agent>`: 仅创建指定类型

## 生成的文件格式

### Command
```markdown
---
name: new-table
description: Create a new database table with migration, schema update, and type generation
command: /new-table
evolved_from:
  - new-table-migration
  - update-schema
  - regenerate-types
---

# New Table Command

[Generated content based on clustered instincts]

## Steps
1. ...
2. ...
```

### Skill
```markdown
---
name: functional-patterns
description: Enforce functional programming patterns
evolved_from:
  - prefer-functional
  - use-immutable
  - avoid-classes
---

# Functional Patterns Skill

[Generated content based on clustered instincts]
```

### Agent
```markdown
---
name: debugger
description: Systematic debugging agent
model: sonnet
evolved_from:
  - debug-check-logs
  - debug-isolate
  - debug-reproduce
---

# Debugger Agent

[Generated content based on clustered instincts]
```
