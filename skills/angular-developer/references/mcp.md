# Angular CLI MCP 服务器

Angular CLI 包含一个模型上下文协议（MCP）服务器，使 AI 助手（如 Cursor、Gemini CLI、JetBrains AI 等）能够直接与 Angular CLI 交互。它提供了代码生成、代码现代化、获取示例和运行构建/测试的工具。

## 可用工具（默认）

启用 MCP 服务器后，AI 智能体可以访问以下工具：

| 名称                        | 描述                                                                                               |
| :-------------------------- | :-------------------------------------------------------------------------------------------------- |
| `ai_tutor`                  | 启动交互式 AI 驱动的 Angular 教程。                                                                 |
| `find_examples`             | 查找现代 Angular 功能的权威最佳实践代码示例。                                                       |
| `get_best_practices`        | 获取 Angular 最佳实践指南（对独立组件、类型化表单等至关重要）。                                      |
| `list_projects`             | 通过读取 `angular.json` 列出工作区中的所有应用和库。                                                |
| `onpush_zoneless_migration` | 分析代码并提供迁移到 `OnPush` 变更检测的计划（无 zone 的前提条件）。                                  |
| `search_documentation`      | 搜索 `https://angular.dev` 上的官方文档。                                                           |

## 实验性工具

某些工具必须使用 `--experimental-tool`（或 `-E`）标志显式启用。

| 名称                       | 描述                                                              |
| :------------------------- | :---------------------------------------------------------------- |
| `build`                    | 使用 `ng build` 执行一次性构建。                                   |
| `devserver.start`          | 异步启动开发服务器（`ng serve`）。立即返回。                        |
| `devserver.stop`           | 停止开发服务器。                                                    |
| `devserver.wait_for_build` | 返回运行中开发服务器最近一次构建的日志。                             |
| `e2e`                      | 执行端到端测试。                                                    |
| `modernize`                | 执行代码迁移以对齐最新最佳实践和语法。                               |
| `test`                     | 运行项目的单元测试。                                                |

## 配置

要使用 MCP 服务器，你需要配置宿主环境（IDE 或 CLI）来运行 `npx @angular/cli mcp`。

### Antigravity IDE

在项目根目录创建名为 `.antigravity/mcp.json` 的文件：

```json
{
  "mcpServers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

### Gemini CLI

在项目根目录创建 `.gemini/settings.json`：

```json
{
  "mcpServers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

### Cursor

在项目根目录创建 `.cursor/mcp.json`（或全局位置 `~/.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

### VS Code

创建 `.vscode/mcp.json`：

```json
{
  "servers": {
    "angular-cli": {
      "command": "npx",
      "args": ["-y", "@angular/cli", "mcp"]
    }
  }
}
```

## 命令选项

你可以在配置的 `args` 数组中向 MCP 服务器传递参数：

- `--read-only`：仅注册不修改项目的工具。
- `--local-only`：仅注册不需要互联网连接的工具。
- `--experimental-tool`（`-E`）：启用特定的实验性工具（如 `-E build`、`-E devserver`）。

只读模式并启用实验性工具的示例：

```json
"args": ["-y", "@angular/cli", "mcp", "--read-only", "-E", "build", "-E", "modernize"]
```
