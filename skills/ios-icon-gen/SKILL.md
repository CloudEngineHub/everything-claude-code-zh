---
name: ios-icon-gen
description: 从 SF Symbols（5000+ 个 Apple 原生）或 Iconify API（来自 200+ 集合的 275k+ 开源图标）为 Xcode 资源目录生成 iOS 应用图标 PNG imagesets。在生成图标、创建图标资产、向资源目录添加图标或搜索 iOS 项目图标时使用。
origin: 社区
---

# iOS 图标生成器

从两个来源为 Xcode 资源目录生成 PNG 图标 imageset。

## 何时激活

- 为 iOS/macOS Xcode 项目生成图标资产
- 跨开源集合搜索图标
- 为资源目录创建 PNG imageset（1x、2x、3x）
- 将占位符图标替换为生产质量资产
- 匹配 Xcode 项目中的现有图标样式

## 核心原则

### 1. 两个来源，一种输出格式
两个来源产生相同的 Xcode 兼容 imageset。根据需要选择：

| 来源 | 图标 | 需要 | 最适合 |
|--------|-------|----------|----------|
| **Iconify API** | 来自 200+ 集合的 275,000+ | 互联网 | 广泛选择、特定风格、开源图标 |
| **SF Symbols** | 5,000+ 个 Apple 符号 | 仅 macOS | Apple 原生风格、离线使用 |

### 2. 始终匹配现有风格
在生成之前，检查项目现有图标的大小、颜色和粗细一致性。

### 3. 输出结构
两种方法都产生完整的 Xcode imageset：

```
<output-dir>/<asset-name>.imageset/
  Contents.json
  <asset-name>.png        # 1x（默认 68px）
  <asset-name>@2x.png     # 2x（默认 136px）
  <asset-name>@3x.png     # 3x（默认 204px）
```

## 示例

### 步骤 1：评估需求

确定图标需求：图标代表什么、首选风格、目标颜色和大小。

如果项目已有图标，请检查现有风格：
```bash
# 检查现有图标的尺寸
sips -g pixelWidth -g pixelHeight path/to/existing@2x.png
```

### 步骤 2：搜索图标

**Iconify API（推荐用于广泛选择）：**
```bash
# 搜索所有集合
$SKILL_DIR/scripts/iconify_gen.sh search "receipt"

# 在特定集合中搜索
$SKILL_DIR/scripts/iconify_gen.sh search "business card" --prefix mdi

# 列出可用集合
$SKILL_DIR/scripts/iconify_gen.sh collections
```

**SF Symbols（用于 Apple 原生风格）：**
浏览 SF Symbols 应用或参考常见名称：

| 用例 | 符号名称 |
|----------|-------------|
| 文档 | `doc.text`、`doc.fill` |
| 收据 | `doc.text.below.ecg`、`receipt` |
| 人员 | `person.crop.rectangle`、`person.text.rectangle` |
| 相机 | `camera`、`camera.fill` |
| 扫描 | `doc.viewfinder`、`qrcode.viewfinder` |
| 设置 | `gearshape`、`slider.horizontal.3` |

### 步骤 3：预览（可选）

```bash
# Iconify 预览
$SKILL_DIR/scripts/iconify_gen.sh preview mdi:receipt-text-outline
```

### 步骤 4：生成

**Iconify API:**
```bash
# 基本生成
$SKILL_DIR/scripts/iconify_gen.sh mdi:receipt-text-outline editTool_expenseReport

# 自定义颜色和输出位置
$SKILL_DIR/scripts/iconify_gen.sh mdi:receipt-text-outline myIcon --color 007AFF --output ./Assets.xcassets/icons
```

选项：`--size <pt>`（默认：68）、`--color <hex>`（默认：8E8E93）、`--output <dir>`（默认：/tmp/icons）

**SF Symbols:**
```bash
# 基本生成
swift $SKILL_DIR/scripts/generate_icons.swift doc.text.below.ecg editTool_expenseReport

# 自定义颜色、粗细和输出
swift $SKILL_DIR/scripts/generate_icons.swift person.crop.rectangle myIcon --color 007AFF --weight regular --output ./Assets.xcassets/icons
```

选项：`--size <pt>`（默认：68）、`--color <hex>`（默认：8E8E93）、`--weight <name>`（默认：thin）、`--output <dir>`（默认：/tmp/icons）

### 步骤 5：验证和集成

1. 阅读生成的 @2x PNG 以进行视觉验证
2. 如果未直接输出到资产目录，则复制到其中：
   ```bash
   cp -r /tmp/icons/<name>.imageset path/to/Assets.xcassets/<group>/
   ```
3. 构建项目以验证 Xcode 获取新资产

## 流行的 Iconify 集合

| 前缀 | 名称 | 数量 | 风格 |
|--------|------|-------|-------|
| `mdi` | Material Design Icons | 7400+ | 填充 + 轮廓变体 |
| `ph` | Phosphor | 9000+ | 每个图标 6 个粗细 |
| `solar` | Solar | 7400+ | 粗体、线性、轮廓 |
| `tabler` | Tabler Icons | 6000+ | 一致的笔画宽度 |
| `lucide` | Lucide | 1700+ | 干净、极简 |
| `ri` | Remix Icon | 3100+ | 填充 + 线条变体 |
| `carbon` | Carbon | 2400+ | IBM 设计语言 |
| `heroicons` | HeroIcons | 1200+ | Tailwind CSS 伴侣 |

浏览所有：<https://icon-sets.iconify.design/>

## 脚本参考

| 脚本 | 来源 | 路径 |
|--------|--------|------|
| `iconify_gen.sh` | Iconify API（275k+ 图标） | `$SKILL_DIR/scripts/iconify_gen.sh` |
| `generate_icons.swift` | SF Symbols（5k+ 图标） | `$SKILL_DIR/scripts/generate_icons.swift` |

## 最佳实践

- **生成前搜索** -- 浏览可用图标以找到最佳匹配
- **匹配现有项目风格** -- 在生成新图标之前检查现有图标的尺寸、颜色和粗细
- **使用 Iconify 获得多样性** -- 200+ 集合意味着您可以找到所需的确切风格
- **使用 SF Symbols 保持 Apple 一致性** -- 它们与系统 UI 完美匹配
- **直接生成到资产目录** -- 使用 `--output ./Assets.xcassets/icons` 跳过手动复制
- **视觉验证** -- 始终在提交之前预览 @2x PNG

## 反模式

- 不检查现有项目图标风格即生成图标
- 项目具有已定义调色板时使用默认颜色
- 生成错误尺寸（首先检查现有图标）
- 不进行视觉验证即提交生成的图标
