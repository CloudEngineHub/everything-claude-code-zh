---
description: 检测项目技术栈并使用仓库的安装清单和栈映射生成试运行的 ECC 引入计划。
---

# /project-init

为当前项目创建安全、可审查的 ECC 引入计划。此命令应以试运行模式启动，仅在用户明确批准后才写入文件。

## 用法

```text
/project-init
/project-init --dry-run
/project-init --target claude
/project-init --target cursor
/project-init --skills continuous-learning-v2,security-review
/project-init --config ecc-install.json
```

## 安全规则

1. 默认试运行。在用户批准具体计划之前，不要修改 `CLAUDE.md`、设置文件、规则、技能或安装状态。
2. 保留现有项目指导。如果 `CLAUDE.md`、`.claude/settings.local.json`、`.cursor/`、`.codex/`、`.gemini/`、`.opencode/`、`.codebuddy/`、`.joycode/` 或 `.qwen/` 已存在，检查它并提出合并/追加计划而非覆盖。
3. 使用 ECC 的安装器和清单工具。不要手动复制文件或克隆任意远程仓库作为安装快捷方式。
4. 保持权限狭窄。任何生成的设置应匹配检测到的构建/测试/lint 工具，避免广泛的 shell 访问。
5. 在应用任何变更之前报告确切会变更什么。

## 检测输入

读取当前项目根目录，从以下内容检测技术栈信号：

- 包管理器文件：`package.json`、`package-lock.json`、`pnpm-lock.yaml`、`yarn.lock`、`bun.lockb`
- 语言清单：`pyproject.toml`、`requirements.txt`、`go.mod`、`Cargo.toml`、`pom.xml`、`build.gradle`、`build.gradle.kts`
- 框架文件：`next.config.*`、`vite.config.*`、`tailwind.config.*`、`Dockerfile`、`docker-compose.yml`
- ECC 配置：`ecc-install.json`
- 可选栈映射：ECC 仓库中的 `config/project-stack-mappings.json`

当 ECC 检出可用时，使用 `config/project-stack-mappings.json` 作为栈到规则/技能的参考。如果文件不可用，回退到已安装的 ECC 清单和用户明确选择。

## 规划流程

1. 识别目标工具。默认为 `claude`，除非用户要求 `cursor`、`codex`、`gemini`、`opencode`、`codebuddy`、`joycode` 或 `qwen`。
2. 从项目文件检测技术栈并展示每个匹配的证据。
3. 解析最小有用的 ECC 计划：
   - 项目有 `ecc-install.json`：`node scripts/install-plan.js --config ecc-install.json --json`
   - 用户指定了配置文件：`node scripts/install-plan.js --profile <profile> --target <target> --json`
   - 用户指定了技能：`node scripts/install-plan.js --skills <skill-ids> --target <target> --json`
   - 仅检测到语言栈：使用这些语言名称进行传统的语言安装试运行
4. 在写入前运行试运行应用命令：

```bash
node scripts/install-apply.js --target <target> --dry-run --json <language-or-profile-args>
```

5. 总结检测到的技术栈、选择的模块/组件/技能、目标路径、跳过的不支持模块以及将要变更的文件。
6. 在应用非试运行命令之前请求批准。

## 输出约定

返回：

1. 检测到的技术栈证据
2. 拟议的目标工具
3. 使用的确切试运行命令
4. 批准后要运行的确切应用命令
5. 将要创建或变更的文件/目录
6. 关于现有文件、宽泛权限、缺失脚本或不支持目标的警告

## CLAUDE.md 指导

如果用户想要 `CLAUDE.md` 启动文件，与安装器计划分开生成，保持最小：

- 构建命令（如检测到）
- 测试命令（如检测到）
- lint/typecheck 命令（如检测到）
- 开发服务器命令（如检测到）
- 来自现有包脚本或清单的仓库特定注释

绝不替换现有 `CLAUDE.md`，除非展示 diff 并获得批准。

## 相关

- `config/project-stack-mappings.json` 用于栈到界面提示
- `scripts/install-plan.js` 用于确定性计划解析
- `scripts/install-apply.js` 用于试运行和应用操作
- `/ecc-guide` 用于安装前的交互式功能发现
