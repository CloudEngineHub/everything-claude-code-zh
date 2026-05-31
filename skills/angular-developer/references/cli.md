# Angular CLI 智能体指南

Angular CLI（`ng`）是管理 Angular 工作区的主要工具。在修改项目结构或添加 Angular 特定依赖时，始终优先使用 CLI 命令，而不是手动创建文件或使用通用 `npm` 命令。

## 1. 管理依赖

**对于 Angular 库，始终使用 `ng add`** 而不是 `npm install`。`ng add` 会安装包并运行初始化原理图（例如配置 `angular.json`、更新根提供者）。

```bash
ng add @angular/material
ng add tailwindcss
ng add @angular/fire
```

更新应用及其依赖（会自动运行代码迁移）：

```bash
ng update @angular/core@<latest or specific version> @angular/cli<latest or specific version>
```

## 2. 生成代码（`ng generate` 或 `ng g`）

始终使用 CLI 生成代码，以确保遵循 Angular 标准并自动更新必要的配置文件。

| 目标          | 命令                    | 说明                                                                                               |
| :------------ | :---------------------- | :------------------------------------------------------------------------------------------------- |
| 组件          | `ng g c path/to/name`  | 生成组件。如需要可使用 `--inline-style`（`-s`）或 `--inline-template`（`-t`）。                     |
| 服务          | `ng g s path/to/name`  | 生成 `@Injectable({providedIn: 'root'})` 服务。                                                    |
| 指令          | `ng g d path/to/name`  | 生成指令。                                                                                         |
| 管道          | `ng g p path/to/name`  | 生成管道。                                                                                         |
| 守卫          | `ng g g path/to/name`  | 生成函数式路由守卫。                                                                               |
| 环境配置      | `ng g environments`     | 搭建 `src/environments/` 并更新 `angular.json` 中的文件替换配置。                                    |

_注意：没有生成单个路由定义的命令。请先生成组件，然后手动将其添加到 `app.routes.ts` 中的 `Routes` 数组。_

## 3. 开发服务器和代理

启动带有热模块替换（HMR）的本地开发服务器：

```bash
ng serve
```

### 后端 API 代理

在开发期间代理 API 请求（例如将 `/api` 重定向到本地 Node 服务器）：

1. 创建 `src/proxy.conf.json`：
   ```json
   {
     "/api/**": {"target": "http://localhost:3000", "secure": false}
   }
   ```
2. 在 `angular.json` 的 `serve` 目标中更新：
   ```json
   "serve": {
     "builder": "@angular/build:dev-server",
     "options": { "proxyConfig": "src/proxy.conf.json" }
   }
   ```

## 4. 构建应用

将应用编译到输出目录（默认：`dist/<project-name>/browser`）。现代 Angular 使用 `@angular/build:application` 构建器（基于 esbuild）。

```bash
ng build
```

- `ng build` 默认使用生产配置，启用预编译（AOT）、压缩和摇树优化。
- 使用 `--configuration` 指定 `angular.json` 中定义的配置：`ng build --configuration=staging`。

## 5. 测试

- **单元测试**：运行 `ng test` 通过配置的测试运行器（如 Karma 或 Vitest）执行单元测试。
- **端到端测试（E2E）**：运行 `ng e2e`。如果未配置 E2E 框架，CLI 会提示安装一个（Cypress、Playwright、Puppeteer 等）。

## 6. 部署

部署应用时，必须先添加部署构建器，然后运行部署命令：

```bash
# 以 Firebase 为例
ng add @angular/fire
ng deploy
```
