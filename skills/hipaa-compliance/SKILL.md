---
name: hipaa-compliance
description: 医疗隐私和安全工作的 HIPAA 特定入口。当任务明确围绕 HIPAA、PHI 处理、覆盖实体、BAA、泄露姿态或美国医疗合规要求构建时使用。
origin: ECC 直接移植改编
version: "1.0.0"
---

# HIPAA 合规

当任务明确与美国医疗合规相关时，将其用作 HIPAA 特定入口。此技能有意保持精简和规范：

- `healthcare-phi-compliance` 仍然是 PHI/PII 处理、数据分类、审计日志记录、加密和泄露防止的主要实现技能。
- `healthcare-reviewer` 仍然是专门的审查者，当代码、架构或产品行为需要医疗感知的第二遍检查时使用。
- `security-review` 仍然适用于一般身份验证、输入处理、密钥、API 和部署加固。

## 何时使用

- 请求明确提及 HIPAA、PHI、覆盖实体、业务伙伴或 BAA
- 构建或审查存储、处理、导出或传输 PHI 的美国医疗软件
- 评估日志记录、分析、LLM 提示、存储或支持工作流是否产生 HIPAA 暴露
- 设计面向患者或面向临床医生的系统，其中最小必要访问和可审计性很重要

## 工作原理

将 HIPAA 视为更广泛医疗隐私技能之上的叠加层：

1. 从 `healthcare-phi-compliance` 开始，获取具体实现规则。
2. 应用 HIPAA 特定决策门：
   - 此数据是 PHI 吗？
   - 此行为者是覆盖实体或业务伙伴吗？
   - 供应商或模型提供商在接触数据之前是否需要 BAA？
   - 访问是否限制在最小必要范围内？
   - 读/写/导出事件是否可审计？
3. 如果任务影响患者安全、临床工作流或受监管的生产架构，升级到 `healthcare-reviewer`。

## HIPAA 特定防护

- 永远不要将 PHI 放在日志、分析事件、崩溃报告、提示或客户端可见的错误字符串中。
- 永远不要在 URL、浏览器存储、屏幕截图或复制的示例负载中暴露 PHI。
- 需要对 PHI 读写的经过身份验证的访问、范围授权和审计跟踪。
- 将第三方 SaaS、可观察性、支持工具和 LLM 提供商视为默认阻止，直到 BAA 状态和数据边界清晰。
- 遵循最小必要访问：正确的用户应仅看到任务所需的最小 PHI 片段。
- 优先使用不透明的内部 ID，而非姓名、医疗记录号码、电话号码、地址或其他标识符。

## 示例

### 示例 1：构建为 HIPAA 的产品请求

用户请求：

> 为我们的临床医生仪表板添加 AI 生成的就诊摘要。我们服务美国诊所，需要保持 HIPAA 合规。

响应模式：

- 激活 `hipaa-compliance`
- 使用 `healthcare-phi-compliance` 审查 PHI 移动、日志记录、存储和提示边界
- 在发送任何 PHI 之前验证摘要提供商是否被 BAA 覆盖
- 如果摘要影响临床决策，升级到 `healthcare-reviewer`

### 示例 2：供应商/工具决策

用户请求：

> 我们可以将支持记录单和患者消息发送到我们的分析堆栈吗？

响应模式：

- 假设这些消息可能包含 PHI
- 阻止设计，除非分析供应商已批准用于 HIPAA 绑定工作负载且数据路径最小化
- 尽可能要求编辑或非 PHI 事件模型

## 相关技能

- `healthcare-phi-compliance`
- `healthcare-reviewer`
- `healthcare-emr-patterns`
- `healthcare-eval-harness`
- `security-review`
