---
name: accessibility
description: 使用 WCAG 2.2 AA 级标准设计、实施和审计包容性数字产品。使用此技能为 Web 和原生平台（iOS/Android）生成语义化 ARIA 和辅助功能属性。
origin: ECC
---

# 无障碍功能（WCAG 2.2）

此技能确保数字界面对所有用户都可感知、可操作、可理解和稳健（POUR），包括使用屏幕阅读器、开关控制或键盘导航的用户。它专注于 WCAG 2.2 成功标准的技术实施。

## 何时使用

- 为 Web、iOS 或 Android 定义 UI 组件规格。
- 审计现有代码的无障碍障碍或合规性差距。
- 实施新的 WCAG 2.2 标准，如目标尺寸（最小）和焦点外观。
- 将高级设计需求映射到技术属性（ARIA 角色、特征、提示）。

## 核心概念

- **POUR 原则**：WCAG 的基础（可感知、可操作、可理解、稳健）。
- **语义映射**：使用原生元素而非通用容器以提供内置无障碍功能。
- **无障碍树**：辅助技术实际"读取"的 UI 表示。
- **焦点管理**：控制键盘/屏幕阅读器光标的顺序和可见性。
- **标签和提示**：通过 `aria-label`、`accessibilityLabel` 和 `contentDescription` 提供上下文。

## 工作原理

### 步骤 1：识别组件角色

确定功能用途（例如，这是按钮、链接还是选项卡？）。在使用自定义角色之前，先使用最语义化的原生元素。

### 步骤 2：定义可感知属性

- 确保文本对比度达到 **4.5:1**（正常）或 **3:1**（大文本/UI）。
- 为非文本内容（图像、图标）添加文本替代。
- 实施响应式重排（高达 400% 缩放而不损失功能）。

### 步骤 3：实施可操作控件

- 确保最小 **24x24 CSS 像素**的目标尺寸（WCAG 2.2 SC 2.5.8）。
- 验证所有交互元素都可通过键盘访问并具有可见的焦点指示器（SC 2.4.11）。
- 为拖拽操作提供单指针替代方案。

### 步骤 4：确保可理解逻辑

- 使用一致的导航模式。
- 提供描述性错误消息和更正建议（SC 3.3.3）。
- 实施"冗余输入"（SC 3.3.7）以防止两次请求相同数据。

### 步骤 5：验证稳健兼容性

- 使用正确的 `Name, Role, Value` 模式。
- 为动态状态更新实施 `aria-live` 或实时区域。

## 无障碍架构图

```mermaid
flowchart TD
  UI["UI 组件"] --> Platform{平台?}
  Platform -->|Web| ARIA["WAI-ARIA + HTML5"]
  Platform -->|iOS| SwiftUI["辅助功能特征 + 标签"]
  Platform -->|Android| Compose["语义 + 内容描述"]

  ARIA --> AT["辅助技术（屏幕阅读器、开关）"]
  SwiftUI --> AT
  Compose --> AT
```

## 跨平台映射

| 功能            | Web (HTML/ARIA)          | iOS (SwiftUI)                        | Android (Compose)                                           |
| :----------------- | :----------------------- | :----------------------------------- | :---------------------------------------------------------- |
| **主要标签**  | `aria-label` / `<label>` | `.accessibilityLabel()`              | `contentDescription`                                        |
| **次要提示** | `aria-describedby`       | `.accessibilityHint()`               | `Modifier.semantics { stateDescription = ... }`             |
| **操作角色**    | `role="button"`          | `.accessibilityAddTraits(.isButton)` | `Modifier.semantics { role = Role.Button }`                 |
| **实时更新**   | `aria-live="polite"`     | `.accessibilityLiveRegion(.polite)`  | `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` |

## 示例

### Web：可访问搜索

```html
<form role="search">
  <label for="search-input" class="sr-only">搜索产品</label>
  <input type="search" id="search-input" placeholder="搜索..." />
  <button type="submit" aria-label="提交搜索">
    <svg aria-hidden="true">...</svg>
  </button>
</form>
```

### iOS：可访问操作按钮

```swift
Button(action: deleteItem) {
    Image(systemName: "trash")
}
.accessibilityLabel("删除项目")
.accessibilityHint("从列表中永久删除此项目")
.accessibilityAddTraits(.isButton)
```

### Android：可访问切换开关

```kotlin
Switch(
    checked = isEnabled,
    onCheckedChange = { onToggle() },
    modifier = Modifier.semantics {
        contentDescription = "启用通知"
    }
)
```

## 避免的反模式

- **Div 按钮**：使用 `<div>` 或 `<span>` 处理点击事件而不添加角色和键盘支持。
- **仅颜色含义**：仅通过颜色变化指示错误或状态（例如，将边框变为红色）。
- **未包含的模态焦点**：模态框不捕获焦点，允许键盘用户在模态框打开时导航背景内容。焦点必须被包含并且可通过 `Escape` 键或明确的关闭按钮退出（WCAG SC 2.1.2）。
- **冗余 Alt 文本**：在 alt 文本中使用"图像..."或"图片..."（屏幕阅读器已宣布"图像"角色）。

## 最佳实践清单

- [ ] 交互元素满足 **24x24px**（Web）或 **44x44pt**（原生）的目标尺寸。
- [ ] 焦点指示器清晰可见且高对比度。
- [ ] 模态框在打开时**包含焦点**，并在关闭时干净地释放焦点（`Escape` 键或关闭按钮）。
- [ ] 下拉菜单和菜单在关闭时将焦点恢复到触发元素。
- [ ] 表单提供基于文本的错误建议。
- [ ] 所有仅图标按钮都有描述性文本标签。
- [ ] 内容在文本缩放时正确重排。

## 参考资料

- [WCAG 2.2 指南](https://www.w3.org/TR/WCAG22/)
- [WAI-ARIA 创作实践](https://www.w3.org/TR/wai-aria-practices/)
- [iOS 辅助功能编程指南](https://developer.apple.com/documentation/accessibility)
- [iOS 人机界面指南 - 辅助功能](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Android 辅助功能开发者指南](https://developer.android.com/guide/topics/ui/accessibility)

## 相关技能

- `frontend-patterns`
- `design-system`
- `liquid-glass-design`
- `swiftui-patterns`
