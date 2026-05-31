# Angular Aria

Angular Aria（`@angular/aria`）是一组无头、无障碍的指令集合，实现了常见的 WAI-ARIA 模式。这些指令处理键盘交互、ARIA 属性、焦点管理和屏幕阅读器支持。

**作为 AI 智能体，你的角色是提供 HTML 结构和 CSS 样式**，而指令负责处理复杂的无障碍逻辑。

## 无头组件样式

由于 Angular Aria 组件是无头的，它们不附带默认样式。你**必须**使用 CSS 根据指令自动应用的 ARIA 属性或结构类来为不同状态添加样式。

CSS 中常见的 ARIA 属性目标：

- `[aria-expanded="true"]` / `[aria-expanded="false"]`
- `[aria-selected="true"]`
- `[aria-disabled="true"]`
- `[aria-current="page"]`（用于导航）

---

**重要**：使用此包之前，必须通过包管理器安装。请确认它已在项目中安装。如有必要，使用 `npm install @angular/aria` 安装。

## 1. 手风琴（Accordion）

将相关内容组织到可展开/折叠的部分中。

**用途**：手风琴是一种布局组件，用于将内容组织成逻辑分组，用户可以一次展开一个分组以减少内容密集页面的滚动。适用于常见问题、长表单或信息的渐进式展示，但不适用于主导航或用户需要同时查看多个内容部分的场景。

**导入**：`import { AccordionContent, AccordionGroup, AccordionPanel, AccordionTrigger } from '@angular/aria/accordion';`

**指令**：`ngAccordionGroup`、`ngAccordionTrigger`、`ngAccordionPanel`、`ngAccordionContent`（用于懒加载）。

```ts
@Component({
  selector: 'app-cmp',
  imports: [AccordionContent, AccordionGroup, AccordionPanel, AccordionTrigger],
  template: `...`,
  styles: [],
})
export class App {
  protected readonly title = signal('angular-app');
}
```

```html
<div ngAccordionGroup [multiExpandable]="false">
  <div class="accordion-item">
    <button ngAccordionTrigger panelId="panel-1" class="accordion-header">
      Section 1
      <span class="icon">▼</span>
    </button>
    <div ngAccordionPanel panelId="panel-1" class="accordion-panel">
      <ng-template ngAccordionContent>
        <p>Lazy loaded content here.</p>
      </ng-template>
    </div>
  </div>
</div>
```

**样式策略**：
在触发器上定位 `[aria-expanded]` 属性以旋转图标，并为面板可见性添加样式。

```css
.accordion-header[aria-expanded='true'] .icon {
  transform: rotate(180deg);
}

/* 面板指令处理 DOM 移除，但你可以为过渡添加样式 */
.accordion-panel {
  padding: 1rem;
  border-top: 1px solid #ccc;
}
```

---

## 2. 列表框（Listbox）

用于显示选项列表的基础指令。用于可见的选择列表（而非下拉菜单）。

**用途**：可见的可选择列表（单选或多选）。

**导入**：`import {Listbox, Option} from '@angular/aria/listbox';`

**指令**：`ngListbox`、`ngOption`。

```ts
@Component({
  selector: 'app-cmp',
  imports: [Listbox, Option],
  template: `...`,
  styles: [],
})
export class App {
  protected readonly title = signal('angular-app');
}
```

```html
<!-- 水平或垂直方向 -->
<ul ngListbox [(values)]="selectedItems" orientation="horizontal" [multi]="true">
  <li ngOption value="apple" class="option">Apple</li>
  <li ngOption value="banana" class="option">Banana</li>
</ul>
```

**样式策略**：
定位 `[aria-selected="true"]` 表示选中状态，`:focus-visible` 或 `[data-active]` 表示焦点项（Angular Aria 使用浮动 tabindex 或 activedescendant）。

```css
.option {
  padding: 8px;
  cursor: pointer;
}
.option[aria-selected='true'] {
  background: #e0f7fa;
  font-weight: bold;
}
/* 焦点状态由 aria 管理 */
.option:focus-visible {
  outline: 2px solid blue;
}
```

---

## 3. 组合框（Combobox）、选择（Select）和多选（Multiselect）

这些模式将 `ngCombobox` 与包含 `ngListbox` 的弹出窗口结合使用。

- **组合框**：文本输入 + 弹出窗口（用于自动完成）。
- **选择**：只读组合框 + 单选列表框。
- **多选**：只读组合框 + 多选列表框。

**用途**：组合框是一个低级基础指令，将文本输入与弹出窗口同步，作为自动完成、选择和多选模式的基础逻辑。专门用于构建自定义过滤、独特选择需求或偏离标准文档组件的专用输入到弹出窗口协调。

**导入**：

```
  import {Combobox, ComboboxInput, ComboboxPopupContainer} from '@angular/aria/combobox';
  import {Listbox, Option} from '@angular/aria/listbox';
```

**指令**：`ngCombobox`、`ngComboboxInput`、`ngComboboxPopupContainer`、`ngListbox`、`ngOption`。

```html
<!-- 示例：标准选择 -->
<div ngCombobox [readonly]="true">
  <button ngComboboxInput class="select-trigger">
    {{ selectedValue() || 'Choose an option' }}
  </button>

  <ng-template ngComboboxPopupContainer>
    <ul ngListbox [(values)]="selectedValue" class="dropdown-menu">
      <li ngOption value="option1">Option 1</li>
      <li ngOption value="option2">Option 2</li>
    </ul>
  </ng-template>
</div>
```

**样式策略**：
将弹出容器样式化为悬浮在内容之上的下拉菜单（通常与 CDK Overlay 配合使用）。

```css
.select-trigger {
  width: 200px;
  padding: 8px;
  text-align: left;
}
.dropdown-menu {
  list-style: none;
  padding: 0;
  margin: 0;
  border: 1px solid #ccc;
  background: white;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
```

---

## 4. 菜单（Menu）和菜单栏（Menubar）

用于操作、命令和上下文菜单（不用于表单选择）。

**用途**：菜单栏是一种高级导航模式，用于构建桌面风格的应用命令栏（如文件、编辑、视图），在整个界面中持续存在。最适合将复杂命令组织到具有完整水平键盘支持的逻辑顶级类别中，但不适用于简单的独立操作列表或水平空间受限的移动优先布局。

**导入**：`import {MenuBar, Menu, MenuContent, MenuItem} from '@angular/aria/menu';`

**指令**：`ngMenuBar`、`ngMenu`、`ngMenuItem`、`ngMenuTrigger`。

```html
<!-- 菜单栏示例 -->
<ul ngMenuBar class="menubar">
  <li ngMenuItem value="file">
    <button ngMenuTrigger [menu]="fileMenu">File</button>
  </li>
</ul>

<ul ngMenu #fileMenu="ngMenu" class="menu">
  <li ngMenuItem value="new">New</li>
  <li ngMenuItem value="open">Open</li>
</ul>
```

**样式策略**：
菜单栏使用 flexbox。根据触发器的状态隐藏/显示子菜单。

```css
.menubar {
  display: flex;
  gap: 10px;
  list-style: none;
  padding: 0;
}
.menu {
  background: white;
  border: 1px solid #ccc;
  padding: 5px 0;
}
.menu li {
  padding: 5px 15px;
  cursor: pointer;
}
```

---

## 5. 选项卡（Tabs）

分层内容区域，只有一个面板可见。

**用途**：选项卡组件用于将相关内容组织到独立的、可导航的部分中，允许用户在不离开页面的情况下在类别或视图之间切换。适用于设置面板、多主题文档或仪表板，但不适用于顺序工作流（步骤条）或导航涉及超过 7-8 个部分的场景。

**导入**：`import {Tab, Tabs, TabList, TabPanel, TabContent} from '@angular/aria/tabs';`

**指令**：`ngTabs`、`ngTabList`、`ngTab`、`ngTabPanel`、`ngTabContent`。

```html
<div ngTabs>
  <ul ngTabList class="tab-list">
    <li ngTab value="profile" class="tab-btn">Profile</li>
    <li ngTab value="security" class="tab-btn">Security</li>
  </ul>

  <div ngTabPanel value="profile" class="tab-panel">
    <ng-template ngTabContent>Profile Settings</ng-template>
  </div>
  <div ngTabPanel value="security" class="tab-panel">
    <ng-template ngTabContent>Security Settings</ng-template>
  </div>
</div>
```

**样式策略**：
在选项卡按钮上定位 `[aria-selected="true"]`。

```css
.tab-list {
  display: flex;
  border-bottom: 2px solid #ccc;
  list-style: none;
  padding: 0;
}
.tab-btn {
  padding: 10px 20px;
  cursor: pointer;
  border-bottom: 2px solid transparent;
}
.tab-btn[aria-selected='true'] {
  border-bottom-color: blue;
  font-weight: bold;
}
.tab-panel {
  padding: 20px;
}
```

---

## 6. 工具栏（Toolbar）

将相关控件分组（如文本格式化）。

**用途**：工具栏是一种组织组件，用于将频繁访问的相关控件分组到单个逻辑容器中。最适合通过箭头键导航和视觉结构来增强需要重复操作的工作流（如文本格式化或媒体控制）的键盘效率。

**导入**：`import {Toolbar, ToolbarWidget, ToolbarWidgetGroup} from '@angular/aria/toolbar';`

**指令**：`ngToolbar`、`ngToolbarWidget`、`ngToolbarWidgetGroup`。

```html
<div ngToolbar class="toolbar">
  <div ngToolbarWidgetGroup [multi]="true" role="group" aria-label="Formatting">
    <button ngToolbarWidget value="bold" class="tool-btn">B</button>
    <button ngToolbarWidget value="italic" class="tool-btn">I</button>
  </div>
</div>
```

**样式策略**：
在工具栏中定位 `[aria-pressed="true"]`（用于切换按钮）或 `[aria-checked="true"]`（用于单选组）。

```css
.toolbar {
  display: flex;
  gap: 5px;
  padding: 8px;
  background: #f5f5f5;
}
.tool-btn {
  padding: 5px 10px;
  border: 1px solid #ccc;
}
.tool-btn[aria-pressed='true'],
.tool-btn[aria-checked='true'] {
  background: #ddd;
}
```

---

## 7. 树（Tree）

显示层级数据（文件系统、嵌套导航）。

**用途**：树组件专为导航和显示深度嵌套的层级数据结构（如文件系统、组织架构图或复杂站点架构）而设计。专门用于用户需要展开或折叠分支的多级关系，但不适用于扁平列表、数据表格或简单选择菜单。

**导入**：`import {Tree, TreeItem, TreeItemGroup} from '@angular/aria/tree';`

**指令**：`ngTree`、`ngTreeItem`、`ngTreeGroup`。

```html
<ul ngTree class="tree">
  <li ngTreeItem value="documents">
    <span class="tree-label">Documents</span>
    <ul ngTreeGroup class="tree-group">
      <li ngTreeItem value="resume">Resume.pdf</li>
    </ul>
  </li>
</ul>
```

**样式策略**：
定位 `[aria-expanded]` 来显示/隐藏子项或旋转箭头图标。在嵌套组上使用 `padding-left` 来展示层级。

```css
.tree,
.tree-group {
  list-style: none;
  padding-left: 20px;
}
.tree-label::before {
  content: '> ';
  display: inline-block;
  transition: transform 0.2s;
}
li[aria-expanded='true'] > .tree-label::before {
  transform: rotate(90deg);
}
```

## 8. 网格（Grid）

一个二维交互式单元格集合，支持通过方向键导航。

**用途**：数据表格、日历、电子表格和交互元素的布局模式。
**指令**：`ngGrid`、`ngGridRow`、`ngGridCell`、`ngGridCellWidget`。

```html
<table ngGrid [multi]="true" [enableSelection]="true" class="grid-table">
  <tr ngGridRow>
    <th ngGridCell role="columnheader">Name</th>
    <th ngGridCell role="columnheader">Status</th>
  </tr>
  <tr ngGridRow>
    <td ngGridCell>Project A</td>
    <td ngGridCell [(selected)]="isSelected">
      <button ngGridCellWidget (activated)="onActivate()">Active</button>
    </td>
  </tr>
</table>
```

**样式策略**：
定位 `[aria-selected="true"]` 表示选中的单元格，`:focus-visible` 表示活动单元格（浮动 tabindex）或容器上的 `[aria-activedescendant]`。

```css
.grid-table {
  border-collapse: collapse;
}
[ngGridCell] {
  padding: 8px;
  border: 1px solid #ddd;
}
[ngGridCell][aria-selected='true'] {
  background: #e3f2fd;
}
/* 焦点状态由浮动 tabindex 管理 */
[ngGridCell]:focus-visible {
  outline: 2px solid #2196f3;
  outline-offset: -2px;
}
```

## 智能体通用规则

1. **当被要求实现这些特定的 Aria 模式时，不要使用原生 HTML 元素如 `<select>`**。使用 `ng*` 指令。
2. **手动处理 CSS**：记住 `Angular Aria` 不提供样式。你必须编写 CSS，定位指令自动切换的原生 ARIA 属性（`aria-expanded`、`aria-selected` 等）。
3. **懒加载**：始终在 `ng-template` 内部使用提供的结构指令（`ngAccordionContent`、`ngTabContent`）来处理重内容面板，以确保它们被懒渲染。
