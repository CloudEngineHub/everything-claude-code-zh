---
name: angular-developer
description: 生成 Angular 代码并提供架构指导。在创建项目、组件或服务，或在反应性（signals、linkedSignal、resource）、表单、依赖注入、路由、SSR、无障碍功能 (ARIA)、动画、样式（组件样式、Tailwind CSS）、测试或 CLI 工具的最佳实践时触发。
origin: ECC
---

# Angular 开发者指南

## 何时激活

- 在任何 Angular 项目或代码库中工作
- 创建或搭建新的 Angular 项目、应用程序或库
- 生成组件、服务、指令、管道、守卫或解析器
- 使用 Angular Signals、`linkedSignal` 或 `resource` 实施反应性
- 使用 Angular 表单（signal forms、reactive forms 或 template-driven）
- 设置依赖注入、路由、懒加载或路由守卫
- 添加无障碍功能 (ARIA)、动画或组件样式
- 编写或调试特定于 Angular 的测试（单元、组件 harness、E2E）
- 配置 Angular CLI 工具或 Angular MCP 服务器

1. 在提供指导之前始终分析项目的 Angular 版本，因为最佳实践和可用功能在版本之间可能差异很大。如果使用 Angular CLI 创建新项目，除非用户提示，否则不要指定版本。

2. 生成代码时，遵循 Angular 的样式指南和可维护性及性能最佳实践。使用 Angular CLI 搭建组件、服务、指令、管道和路由以确保一致性。

3. 完成代码生成后，运行 `ng build` 以确保没有构建错误。如果有错误，分析错误消息并在继续之前修复它们。不要跳过此步骤，这对于确保生成的代码正确且功能正常至关重要。

## 创建新项目

如果用户未提供指南，创建新 Angular 项目时使用以下默认值：

1. 使用最新的稳定 Angular 版本，除非用户另有说明。
2. 仅当目标 Angular 版本支持时，才为新项目首选 Signal Forms。[了解更多](references/signal-forms.md)。

**`ng new` 的执行规则：**
当要求创建新 Angular 项目时，必须通过遵循以下严格步骤来确定正确的执行命令：

**步骤 1：检查显式用户版本。**

- **如果**用户请求特定版本（例如，Angular 15），绕过本地安装并严格使用 `npx`。
- **命令：** `npx @angular/cli@<requested_version> new <project-name>`

**步骤 2：检查现有的 Angular 安装。**

- **如果**未请求特定版本，在终端中运行 `ng version` 以检查系统上是否已安装 Angular CLI。
- **如果**命令成功并返回已安装的版本，直接使用本地/全局安装。
- **命令：** `ng new <project-name>`

**步骤 3：回退到最新版本。**

- **如果**未请求特定版本 **且** `ng version` 命令失败（表示不存在 Angular 安装），您必须使用 `npx` 获取最新版本。
- **命令：** `npx @angular/cli@latest new <project-name>`

## 组件

使用 Angular 组件时，根据任务查阅以下参考：

- **基础知识**：解剖、元数据、核心概念和模板控制流 (@if、@for、@switch)。阅读 [components.md](references/components.md)
- **输入**：基于信号的输入、转换和模型输入。阅读 [inputs.md](references/inputs.md)
- **输出**：基于信号的输出和自定义事件最佳实践。阅读 [outputs.md](references/outputs.md)
- **宿主元素**：宿主绑定和属性注入。阅读 [host-elements.md](references/host-elements.md)

如果您需要上述参考中未找到的更深入文档，请阅读 `https://angular.dev/guide/components` 处的文档。

## 反应性和数据管理

管理状态和数据反应性时，使用 Angular Signals 并查阅以下参考：

- **Signals 概述**：核心信号概念（`signal`、`computed`）、反应性上下文和 `untracked`。阅读 [signals-overview.md](references/signals-overview.md)
- **依赖状态 (`linkedSignal`)**：创建链接到源信号的可写状态。阅读 [linked-signal.md](references/linked-signal.md)
- **异步反应性 (`resource`)**：直接将异步数据获取到信号状态中。阅读 [resource.md](references/resource.md)
- **副作用 (`effect`)**：日志记录、第三方 DOM 操作（`afterRenderEffect`）以及何时不使用效果。阅读 [effects.md](references/effects.md)

## 表单

在大多数情况下，对于新应用，**首选 signal forms**。做出表单决策时，分析项目并考虑以下指南：

- 如果应用版本支持 Signal Forms 且这是新表单，**首选 signal forms**。
- 对于旧应用或现有表单，匹配应用当前的表单策略。

- **Signal Forms**：使用信号进行表单状态管理。阅读 [signal-forms.md](references/signal-forms.md)
- **模板驱动表单**：用于简单表单。阅读 [template-driven-forms.md](references/template-driven-forms.md)
- **响应式表单**：用于复杂表单。阅读 [reactive-forms.md](references/reactive-forms.md)

## 依赖注入

在 Angular 中实施依赖注入时，遵循以下指南：

- **基础知识**：依赖注入概述、服务和 `inject()` 函数。阅读 [di-fundamentals.md](references/di-fundamentals.md)
- **创建和使用服务**：创建服务、`providedIn: 'root'` 选项以及注入到组件或其他服务中。阅读 [creating-services.md](references/creating-services.md)
- **定义依赖提供者**：自动与手动提供、`InjectionToken`、`useClass`、`useValue`、`useFactory` 和范围。阅读 [defining-providers.md](references/defining-providers.md)
- **注入上下文**：允许 `inject()` 的位置、`runInInjectionContext` 和 `assertInInjectionContext`。阅读 [injection-context.md](references/injection-context.md)
- **分层注入器**：`EnvironmentInjector` 与 `ElementInjector`、解析规则、修饰符（`optional`、`skipSelf`）以及 `providers` 与 `viewProviders`。阅读 [hierarchical-injectors.md](references/hierarchical-injectors.md)

## Angular Aria

为以下任何模式构建可访问的自定义组件时：Accordion、Listbox、Combobox、Menu、Tabs、Toolbar、Tree、Grid，请查阅以下参考：

- **Angular Aria 组件**：构建无头、可访问的组件（Accordion、Listbox、Combobox、Menu、Tabs、Toolbar、Tree、Grid）和样式化 ARIA 属性。阅读 [angular-aria.md](references/angular-aria.md)

## 路由

在 Angular 中实施导航时，查阅以下参考：

- **定义路由**：URL 路径、静态与动态段、通配符和重定向。阅读 [define-routes.md](references/define-routes.md)
- **路由加载策略**：急切与懒加载、上下文感知加载。阅读 [loading-strategies.md](references/loading-strategies.md)
- **使用出口显示路由**：使用 `<router-outlet>`、嵌套出口和命名出口。阅读 [show-routes-with-outlets.md](references/show-routes-with-outlets.md)
- **导航到路由**：使用 `RouterLink` 的声明式导航和使用 `Router` 的编程式导航。阅读 [navigate-to-routes.md](references/navigate-to-routes.md)
- **使用守卫控制路由访问**：实施 `CanActivate`、`CanMatch` 和其他守卫以确安全性。阅读 [route-guards.md](references/route-guards.md)
- **数据解析器**：使用 `ResolveFn` 在路由激活之前预取数据。阅读 [data-resolvers.md](references/data-resolvers.md)
- **路由生命周期和事件**：导航事件的时间顺序和调试。阅读 [router-lifecycle.md](references/router-lifecycle.md)
- **渲染策略**：CSR、SSG（预渲染）和带水合的 SSR。阅读 [rendering-strategies.md](references/rendering-strategies.md)
- **路由过渡动画**：启用和自定义 View Transitions API。阅读 [route-animations.md](references/route-animations.md)

如果您需要更深入的文档或更多上下文，请访问 [官方 Angular 路由指南](https://angular.dev/guide/routing)。

## 样式和动画

在 Angular 中实施样式和动画时，查阅以下参考：

- **在 Angular 中使用 Tailwind CSS**：将 Tailwind CSS 集成到 Angular 项目中。阅读 [tailwind-css.md](references/tailwind-css.md)
- **Angular 动画**：使用原生 CSS（推荐）或旧版 DSL 实现动态效果。阅读 [angular-animations.md](references/angular-animations.md)
- **样式化组件**：组件样式和封装的最佳实践。阅读 [component-styling.md](references/component-styling.md)

## 测试

编写或更新测试时，根据任务查阅以下参考：

- **基础知识**：单元测试、异步模式和 `TestBed` 的最佳实践。阅读 [testing-fundamentals.md](references/testing-fundamentals.md)
- **组件 Harness**：稳健组件交互的标准模式。阅读 [component-harnesses.md](references/component-harnesses.md)
- **路由测试**：使用 `RouterTestingHarness` 进行可靠的导航测试。阅读 [router-testing.md](references/router-testing.md)
- **端到端 (E2E) 测试**：使用 Cypress 或 Playwright 的 E2E 测试最佳实践。阅读 [e2e-testing.md](references/e2e-testing.md)

## 工具

使用 Angular 工具时，查阅以下参考：

- **Angular CLI**：创建应用程序、生成代码（组件、路由、服务）、服务和构建。阅读 [cli.md](references/cli.md)
- **Angular MCP 服务器**：可用工具、配置和实验性功能。阅读 [mcp.md](references/mcp.md)

## 反模式

- 使用 `null` 或 `undefined` 作为初始 signal form 字段值 — 改为使用 `''`、`0` 或 `[]`
- 不先调用字段即访问表单字段状态标志：`form.field.valid()` — 使用 `form.field().valid()`
- 当目标 Angular 版本支持 Signal Forms 时，使用旧表单 API 开始新表单
- 在 `[formField]` 输入上设置 `min`、`max`、`value`、`disabled` 或 `readonly` HTML 属性 — 将这些定义为架构规则
- 在注入上下文之外调用 `inject()` — 需要时使用 `runInInjectionContext`
- 对应该使用 `computed()` 的派生状态使用 `effect()`
- 在嵌套的 `@for` 循环中引用 `$parent.$index` — Angular 不支持 `$parent`；改用 `let outerIdx = $index`

## 相关技能

- `tdd-workflow` — 适用于 Angular 组件和服务的测试驱动开发工作流
- `security-review` — Web 应用程序的安全检查清单，包括特定于 Angular 的关注点
- `frontend-patterns` — React/Next.js 方法的通用前端模式上下文
