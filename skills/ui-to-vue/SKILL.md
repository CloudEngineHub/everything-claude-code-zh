---
name: ui-to-vue
description: 当用户有 UI 截图或设计导出需要批量转换为 Vue 3 组件时使用，特别是使用 Vant、Element Plus 或 Ant Design Vue 时。
origin: community
---

# UI 转 Vue

将 UI 设计截图批量转换为 Vue 3 Composition API 组件代码。

## 何时使用

- 用户提供设计截图或设计导出图像的目录。
- 目标应用是 Vue 3。
- 用户想要页面组件、共享组件和路由接线的初稿。
- 用户指定 Vant、Element Plus 或 Ant Design Vue 作为组件库。

## 何时不使用

- 用户只有一张截图且想要定制组件。
- 目标项目不是 Vue。
- 设计需要详细的交互逻辑、数据流或无障碍审查。
- 截图包含不能发送到外部模型 API 的私有客户数据。

## 输入

使用按模块和页面状态分组的截图输入目录：

```text
screenshots/
|-- HomePage/
|   |-- List/
|   |   |-- HomePage-List-Default@3x.png
|   |   `-- cut-images/
|   |-- cut-images/
|   `-- HomePage-Default@3x.png
`-- cut-images/
```

支持的切图目录名称包括 `assets`、`icons`、`sprites`、`cut`、`images` 和 `cut-images`。

## 转换模型

- 页面分组：当相关截图代表列表、详情、表单、加载或空状态时，将它们合并为一个页面组件。
- UI 库映射：在可行时将原生视觉元素映射到 Vant、Element Plus 或 Ant Design Vue 组件。
- 切图优先级：优先使用页面级资产，然后是模块级资产，最后是全局共享资产。
- 组件提取：当重复的 UI 区域出现超过一次时，将其提取为共享组件。

## CLI 用法

使用 `npx` 运行转换器，使文档中的命令无需依赖全局二进制文件即可工作：

```bash
export DASHSCOPE_API_KEY=your_key
npx ui-to-vue-converter@1.0.2 --input ./screenshots --ui vant --output ./src
```

对于桌面 UI 库：

```bash
npx ui-to-vue-converter@1.0.2 --input ./designs --ui element-plus --output ./src
npx ui-to-vue-converter@1.0.2 --input ./designs --ui antd-vue --output ./src
```

如果包全局安装，可以直接使用 `ui-to-vue` 二进制文件：

```bash
npm install -g ui-to-vue-converter@1.0.2
ui-to-vue --input ./screenshots --ui vant --output ./src
```

## 选项

| 选项 | 描述 | 默认值 |
| --- | --- | --- |
| `--input` | 设计图片目录 | `./screenshots` |
| `--ui` | UI 库：`vant`、`element-plus` 或 `antd-vue` | `vant` |
| `--output` | 输出目录 | `./src` |
| `--config` | 配置文件路径 | `./.ui-to-vue.config.json` |

## API 密钥处理

转换器可以从配置文件或环境变量读取 DashScope 凭据。在仓库中优先使用环境变量：

```bash
export DASHSCOPE_API_KEY=your_key
```

如果需要本地配置文件，将其排除在版本控制之外：

```json
{
  "apiKey": "your_dashscope_key",
  "input": "./designs",
  "ui": "vant",
  "output": "./src"
}
```

```gitignore
.ui-to-vue.config.json
```

## 安全和隐私

- 将设计截图视为可能发送到外部模型 API 的源材料。
- 未经许可不要在私有客户设计上运行此流程。
- 在可重复的工作流中固定转换器版本，而非使用 `@latest`。
- 在提交之前审查生成的 Vue 代码。
- 不要提交 `.ui-to-vue.config.json`、API 密钥、生成的密钥或客户截图。

## 输出审查检查清单

- [ ] 页面组件在 `views/` 或选择的输出目录下生成。
- [ ] 重复的 UI 区域仅在复用明确时提取到 `components/`。
- [ ] 路由输出与目标项目的路由风格兼容。
- [ ] 生成的组件一致使用请求的 UI 库。
- [ ] 生成的 CSS 单位与设计基线匹配。
- [ ] 代码通过项目的格式化器、Linter、类型检查器和构建。
- [ ] 占位符文案、模拟数据和生成的资产在提交前已审查。

## 故障排除

| 问题 | 检查 |
| --- | --- |
| `401` 或认证错误 | 确认运行命令的 Shell 中设置了 `DASHSCOPE_API_KEY`。 |
| `command not found: ui-to-vue` | 使用 `npx ui-to-vue-converter@1.0.2` 形式或全局安装包。 |
| 切图被忽略 | 确认资产目录名称受支持且嵌套在匹配的页面或模块下。 |
| 组件忽略请求的 UI 库 | 用显式 `--ui` 值重新运行并检查生成的导入。 |
| 生成的布局尺寸看起来不对 | 确认截图导出宽度与目标库基线匹配。 |

## 参考文献

- npm 包：`ui-to-vue-converter`
