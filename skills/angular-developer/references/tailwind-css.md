# 在 Angular 中使用 Tailwind CSS

Tailwind CSS 是一个实用优先的 CSS 框架，与 Angular 无缝集成。

**关键智能体指南：始终关注 Tailwind CSS v4 实践。不要回退到旧的 Tailwind v3 模式（如创建 `tailwind.config.js` 并使用 `@tailwind` 指令），因为这会破坏应用构建。现代 Angular 项目使用 Tailwind v4。**

## 自动设置（推荐）

将 Tailwind CSS 添加到 Angular 项目的最简单方式是通过 Angular CLI：

```shell
ng add tailwindcss
```

这会自动：

1. 安装 `tailwindcss` 和对等依赖。
2. 配置项目使用 Tailwind CSS。
3. 在全局样式中添加正确的导入。

## 手动设置（Tailwind v4）

如果手动设置，请使用以下 Tailwind v4 模式：

### 1. 安装依赖

安装 Tailwind CSS 和 PostCSS：

```shell
npm install tailwindcss @tailwindcss/postcss postcss
```

### 2. 配置 PostCSS

在项目根目录创建 `.postcssrc.json` 文件：

```json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
```

_（不要创建 `tailwind.config.js` 文件！v4 中的配置通过 CSS 变量处理。）_

### 3. 导入 Tailwind CSS

在全局样式文件（如 `src/styles.css`）中，添加标准的 v4 导入：

```css
@import 'tailwindcss';
```

_（如果使用 SCSS，请使用 `@use 'tailwindcss';`。）_

### 4. 使用实用类

现在你可以在组件模板中直接使用 Tailwind 类：

```html
<h1 class="text-3xl font-bold underline">Hello world!</h1>
```

## AI 智能体总结

- **不要使用 `@tailwind base; @tailwind components; @tailwind utilities;`**。使用 `@import 'tailwindcss';`。
- **不要创建 `tailwind.config.js`**。配置直接通过 CSS 中的主题变量或 PostCSS 配置管理。
- 严格遵循 v4 语法和工作流。
