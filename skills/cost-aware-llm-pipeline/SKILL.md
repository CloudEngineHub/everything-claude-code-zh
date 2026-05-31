---
name: cost-aware-llm-pipeline
description: LLM API 使用的成本优化模式 — 按任务复杂度路由模型、预算跟踪、重试逻辑和提示词缓存。
origin: ECC
---

# 成本感知 LLM 管道

控制 LLM API 成本同时保持质量的模式。将模型路由、预算跟踪、重试逻辑和提示词缓存组合成可组合的管道。

## 何时激活

- 构建调用 LLM API（Claude、GPT 等）的应用程序
- 处理复杂度不一的批量项目
- 需要在 API 支出的预算内运行
- 在不牺牲复杂任务质量的前提下优化成本

## 核心概念

### 1. 按任务复杂度路由模型

自动为简单任务选择更便宜的模型，将昂贵的模型保留给复杂任务。

```python
MODEL_SONNET = "claude-sonnet-4-6"
MODEL_HAIKU = "claude-haiku-4-5-20251001"

_SONNET_TEXT_THRESHOLD = 10_000  # 字符
_SONNET_ITEM_THRESHOLD = 30     # 项目数

def select_model(
    text_length: int,
    item_count: int,
    force_model: str | None = None,
) -> str:
    """根据任务复杂度选择模型。"""
    if force_model is not None:
        return force_model
    if text_length >= _SONNET_TEXT_THRESHOLD or item_count >= _SONNET_ITEM_THRESHOLD:
        return MODEL_SONNET  # 复杂任务
    return MODEL_HAIKU  # 简单任务（便宜 3-4 倍）
```

### 2. 不可变成本跟踪

使用冻结数据类跟踪累计支出。每次 API 调用返回一个新的跟踪器 — 永远不修改状态。

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class CostRecord:
    model: str
    input_tokens: int
    output_tokens: int
    cost_usd: float

@dataclass(frozen=True, slots=True)
class CostTracker:
    budget_limit: float = 1.00
    records: tuple[CostRecord, ...] = ()

    def add(self, record: CostRecord) -> "CostTracker":
        """返回添加了记录的新跟踪器（永远不修改 self）。"""
        return CostTracker(
            budget_limit=self.budget_limit,
            records=(*self.records, record),
        )

    @property
    def total_cost(self) -> float:
        return sum(r.cost_usd for r in self.records)

    @property
    def over_budget(self) -> bool:
        return self.total_cost > self.budget_limit
```

### 3. 窄范围重试逻辑

仅在瞬时错误上重试。在认证或错误请求错误上快速失败。

```python
from anthropic import (
    APIConnectionError,
    InternalServerError,
    RateLimitError,
)

_RETRYABLE_ERRORS = (APIConnectionError, RateLimitError, InternalServerError)
_MAX_RETRIES = 3

def call_with_retry(func, *, max_retries: int = _MAX_RETRIES):
    """仅在瞬时错误上重试，其他错误快速失败。"""
    for attempt in range(max_retries):
        try:
            return func()
        except _RETRYABLE_ERRORS:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # 指数退避
    # AuthenticationError、BadRequestError 等 → 立即抛出
```

### 4. 提示词缓存

缓存长系统提示词以避免每次请求都重新发送。

```python
messages = [
    {
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": system_prompt,
                "cache_control": {"type": "ephemeral"},  # 缓存此项
            },
            {
                "type": "text",
                "text": user_input,  # 可变部分
            },
        ],
    }
]
```

## 组合

在单个管道函数中组合所有四种技术：

```python
def process(text: str, config: Config, tracker: CostTracker) -> tuple[Result, CostTracker]:
    # 1. 路由模型
    model = select_model(len(text), estimated_items, config.force_model)

    # 2. 检查预算
    if tracker.over_budget:
        raise BudgetExceededError(tracker.total_cost, tracker.budget_limit)

    # 3. 带重试 + 缓存的调用
    response = call_with_retry(lambda: client.messages.create(
        model=model,
        messages=build_cached_messages(system_prompt, text),
    ))

    # 4. 跟踪成本（不可变）
    record = CostRecord(model=model, input_tokens=..., output_tokens=..., cost_usd=...)
    tracker = tracker.add(record)

    return parse_result(response), tracker
```

## 定价参考（2025-2026）

| 模型 | 输入（$/1M token） | 输出（$/1M token） | 相对成本 |
|-------|---------------------|----------------------|---------------|
| Haiku 4.5 | $0.80 | $4.00 | 1x |
| Sonnet 4.6 | $3.00 | $15.00 | ~4x |
| Opus 4.5 | $15.00 | $75.00 | ~19x |

## 最佳实践

- **从最便宜的模型开始**，仅在复杂度阈值被达到时路由到昂贵模型
- **在处理批量之前设置显式预算限制** — 尽早失败而非超支
- **记录模型选择决策**，以便你可以根据真实数据调整阈值
- **对超过 1024 token 的系统提示词使用提示词缓存** — 同时节省成本和延迟
- **绝不重试认证或验证错误** — 仅重试瞬时故障（网络、速率限制、服务器错误）

## 需要避免的反模式

- 不考虑复杂度地为所有请求使用最昂贵的模型
- 在所有错误上重试（在永久性故障上浪费预算）
- 修改成本跟踪状态（使调试和审计困难）
- 在代码库中硬编码模型名称（使用常量或配置）
- 对重复的系统提示词忽略提示词缓存

## 何时使用

- 任何调用 Claude、OpenAI 或类似 LLM API 的应用程序
- 成本快速累积的批量处理管道
- 需要智能路由的多模型架构
- 需要预算防护的生产系统
