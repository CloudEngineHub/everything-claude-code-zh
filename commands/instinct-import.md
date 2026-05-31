---
name: instinct-import
description: 从文件或 URL 导入本能到项目/全局作用域
command: true
---

# 本能导入命令

## 实现

使用插件根路径运行本能 CLI：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" import <file-or-url> [--dry-run] [--force] [--min-confidence 0.7] [--scope project|global]
```

如果未设置 `CLAUDE_PLUGIN_ROOT`（手动安装）：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py import <file-or-url>
```

从本地文件路径或 HTTP(S) URL 导入本能。

## 用法

```
/instinct-import team-instincts.yaml
/instinct-import https://github.com/org/repo/instincts.yaml
/instinct-import team-instincts.yaml --dry-run
/instinct-import team-instincts.yaml --scope global --force
```

## 操作步骤

1. 获取本能文件（本地路径或 URL）
2. 解析并验证格式
3. 检查与现有本能的重复
4. 合并或添加新本能
5. 保存到继承本能目录：
   - 项目作用域：`~/.claude/homunculus/projects/<project-id>/instincts/inherited/`
   - 全局作用域：`~/.claude/homunculus/instincts/inherited/`

## 导入过程

```
 正在从以下文件导入本能：team-instincts.yaml
================================================

找到 12 条待导入本能。

分析冲突...

## 新本能 (8)
这些将被添加：
  ✓ use-zod-validation (置信度：0.7)
  ✓ prefer-named-exports (置信度：0.65)
  ✓ test-async-functions (置信度：0.8)
  ...

## 重复本能 (3)
已有相似本能：
  WARNING: prefer-functional-style
     本地：0.8 置信度，12 次观察
     导入：0.7 置信度
     → 保留本地（更高置信度）

  WARNING: test-first-workflow
     本地：0.75 置信度
     导入：0.9 置信度
     → 更新为导入（更高置信度）

导入 8 条新的，更新 1 条？
```

## 合并行为

当导入的本能 ID 已存在时：
- 更高置信度的导入成为更新候选
- 等于或更低置信度的导入被跳过
- 除非使用 `--force`，否则需用户确认

## 来源追踪

导入的本能标记为：
```yaml
source: inherited
scope: project
imported_from: "team-instincts.yaml"
project_id: "a1b2c3d4e5f6"
project_name: "my-project"
```

## 标志

- `--dry-run`：预览而不导入
- `--force`：跳过确认提示
- `--min-confidence <n>`：仅导入高于阈值的本能
- `--scope <project|global>`：选择目标作用域（默认：`project`）

## 输出

导入后：
```
PASS: 导入完成！

添加：8 条本能
更新：1 条本能
跳过：3 条本能（已存在等/更高置信度）

新本能保存到：~/.claude/homunculus/instincts/inherited/

运行 /instinct-status 查看所有本能。
```
