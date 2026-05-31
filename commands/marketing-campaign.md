---
description: 规划和执行完整的营销活动。接受产品简介，返回定位、着陆页文案、邮件序列、社交帖子、广告变体、视频脚本和内容日历。也可审查现有文案的转化质量。
allowed_tools: ["Read", "Grep", "Glob", "WebSearch", "WebFetch", "Write"]
---

# /marketing-campaign

从产品简介到完整内容套件，规划和执行营销活动。

## 用法

```
/marketing-campaign                          # 交互式提示输入简介
/marketing-campaign [产品简介]          # 从内联简介生成完整活动
/marketing-campaign copy [类型]              # 仅生成单个交付物
/marketing-campaign review [文件或简介]   # 文案审计（转化和品牌一致性）
```

## 功能

1. **研究** — 在写任何内容之前，先分析目标受众并绘制竞争对手地图
2. **定位** — 先锁定活动角度和调性特征
3. **文案生产** — 按正确顺序生成完整内容套件（着陆页 → 邮件 → 社交 → 广告 → 视频脚本 → 日历）
4. **审查** — 通过转化和品牌一致性检查清单审核所有输出

## 模式

### 完整活动模式

提供包含以下内容的产品简介：
- 产品名称和描述
- 目标受众（具体的，非泛泛的）
- 产品解决的核心问题
- 核心利益/成果
- 调性指导
- 所需渠道
- 发布目标或时间线

智能体按顺序返回所有活动交付物，末尾附带文案审查总结。

### 单个交付物模式

```
/marketing-campaign copy landing-page
/marketing-campaign copy email-sequence
/marketing-campaign copy social-posts
/marketing-campaign copy ads
/marketing-campaign copy video-scripts
```

需要先定义定位。运行完整模式或在请求单个交付物之前提供角度。

### 文案审查模式

```
/marketing-campaign review path/to/copy.md
/marketing-campaign review "在此粘贴文案"
```

返回结构化审计，涵盖：
- 5 秒清晰度测试（首屏文案）
- CTA 质量（具体、有说服力、每篇一个）
- 品牌调性一致性
- 声明的具体性和可支持性
- 平台原生适配
- 跨渠道一致性

## 简介模板

```markdown
产品：[名称]
描述：[1-3 句话描述功能]
受众：[具体是谁]
问题：[产品解决的具体痛点]
利益：[用户获得的成果]
调性：[形容词 + 要避免什么]
渠道：[着陆页、邮件、LinkedIn、X、广告、视频]
目标：[发布、候补名单、注册、认知 — 以及时间线]
```

## 输出位置

保存活动资产时，约定为 `.claude/campaigns/{campaign-name}/`：

```
.claude/campaigns/product-launch/
├── positioning.md
├── landing-page.md
├── email-sequence.md
├── social-posts.md
├── ad-copy.md
├── video-scripts.md
└── content-calendar.md
```

写入文件前确认保存位置。

## 示例

```
/marketing-campaign 为面向英国大学学生的 AI 职业平台构建 7 天发布活动。
```

```
/marketing-campaign copy landing-page
```

```
/marketing-campaign review .claude/campaigns/the-key/landing-page.md
```

## 智能体委派

此命令调用：
- `marketing-agent` — 活动规划和文案制作
- `brand-voice` — 当调性需要在多个输出中保持一致时进行语音捕获
- `content-engine` — 平台原生的社交内容制作
- `crosspost` — 多平台分发
- `market-research` — 深度受众或竞争情报

## 相关命令

- `/plan` — 活动前的战略规划
- `/plan-prd` — 活动简报前的产品需求文档
- `/code-review` — 审查着陆页实现背后的代码

---

*Everything Claude Code 的一部分*
