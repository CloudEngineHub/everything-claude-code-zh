---
description: 对智能体、钩子、MCP、权限和密钥表面运行 AgentShield。
agent: everything-claude-code:security-reviewer
subtask: true
---

# 安全扫描命令

对当前项目或目标路径运行 AgentShield，然后将发现转化为优先级修复计划。

## 用法

`/security-scan [路径] [--format text|json|markdown|html] [--min-severity low|medium|high|critical] [--fix]`

- `路径`（可选）：默认为当前项目。使用 `.claude/` 路径、仓库根目录或已检入的模板目录。
- `--format`：输出格式。使用 `json` 用于 CI，`markdown` 用于交接，`html` 用于独立审查报告。
- `--min-severity`：过滤低优先级发现。
- `--fix`：仅应用明确标记为安全且可自动修复的 AgentShield 修复。

## 确定性引擎

优先使用打包的扫描器：

```bash
npx ecc-agentshield scan --path "${TARGET_PATH:-.}" --format text
```

对于本地 AgentShield 开发，从 AgentShield 检出运行：

```bash
npm run scan -- --path "${TARGET_PATH:-.}" --format text
```

不要编造发现。使用 AgentShield 输出作为事实来源，将扫描器事实与后续判断分开。

## 审查清单

1. 首先识别活动运行时发现：
   - 硬编码密钥
   - 宽泛权限
   - 可执行钩子
   - 具有 shell、文件系统、远程传输或未固定 `npx` 的 MCP 服务器
   - 处理不受信任内容但缺少防御的智能体提示
2. 分离较低置信度的清单：
   - 文档示例
   - 模板示例
   - 插件清单
   - 项目本地可选设置
3. 对于每个 critical 或 high 发现，返回：
   - 文件路径
   - 严重程度
   - 运行时置信度
   - 为什么重要
   - 确切的修复方案
   - 是否可安全自动修复
4. 如果请求 `--fix`，在应用修复前陈述计划的编辑。
5. 修复后重新运行扫描并报告修复前/后分数。

## 输出约定

返回：

1. 安全等级和分数。
2. 按严重程度和运行时置信度统计的数量。
3. Critical/high 发现及其确切路径。
4. 分开分组的较低置信度发现。
5. 修复顺序。
6. 运行的命令以及扫描是本地的、CI 的还是 npx 驱动的。

## CI 模式

在 GitHub Actions 中使用 AgentShield 进行强制门控：

```yaml
- uses: affaan-m/agentshield@v1
  with:
    path: "."
    min-severity: "medium"
    fail-on-findings: true
```

## 链接

- 技能：`skills/security-scan/SKILL.md`
- 智能体：`agents/security-reviewer.md`
- 扫描器：<https://github.com/affaan-m/agentshield>

## 参数

$ARGUMENTS:
- 可选目标路径
- 可选 AgentShield 标志
