---
name: llm-trading-agent-security
description: 具有钱包或交易权限的自主交易智能体的安全模式。涵盖提示注入、支出限制、发送前模拟、熔断器、MEV 保护和密钥处理。
origin: ECC direct-port adaptation
version: "1.0.0"
---

# LLM 交易智能体安全

自主交易智能体比普通 LLM 应用面临更严峻的威胁模型：一次注入或错误工具调用可能直接导致资产损失。

## 何时使用

- 构建签名和发送交易的 AI 智能体
- 审计交易机器人或链上执行助手
- 为智能体设计钱包密钥管理
- 向 LLM 授予下单、兑换或资金库操作的访问权限

## 工作原理

分层防御。单一检查不够。将提示词卫生、支出策略、模拟、执行限制和钱包隔离视为独立控制层。

## 示例

### 将提示注入视为金融攻击

```python
import re

INJECTION_PATTERNS = [
    r'ignore (previous|all) instructions',
    r'new (task|directive|instruction)',
    r'system prompt',
    r'send .{0,50} to 0x[0-9a-fA-F]{40}',
    r'transfer .{0,50} to',
    r'approve .{0,50} for',
]

def sanitize_onchain_data(text: str) -> str:
    for pattern in INJECTION_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            raise ValueError(f"Potential prompt injection: {text[:100]}")
    return text
```

不要盲目将代币名称、交易对标签、Webhook 或社交动态注入可执行的提示词中。

### 硬性支出限制

```python
from decimal import Decimal

MAX_SINGLE_TX_USD = Decimal("500")
MAX_DAILY_SPEND_USD = Decimal("2000")

class SpendLimitError(Exception):
    pass

class SpendLimitGuard:
    def check_and_record(self, usd_amount: Decimal) -> None:
        if usd_amount > MAX_SINGLE_TX_USD:
            raise SpendLimitError(f"Single tx ${usd_amount} exceeds max ${MAX_SINGLE_TX_USD}")

        daily = self._get_24h_spend()
        if daily + usd_amount > MAX_DAILY_SPEND_USD:
            raise SpendLimitError(f"Daily limit: ${daily} + ${usd_amount} > ${MAX_DAILY_SPEND_USD}")

        self._record_spend(usd_amount)
```

### 发送前模拟

```python
class SlippageError(Exception):
    pass

async def safe_execute(self, tx: dict, expected_min_out: int | None = None) -> str:
    sim_result = await self.w3.eth.call(tx)

    if expected_min_out is None:
        raise ValueError("min_amount_out is required before send")

    actual_out = decode_uint256(sim_result)
    if actual_out < expected_min_out:
        raise SlippageError(f"Simulation: {actual_out} < {expected_min_out}")

    signed = self.account.sign_transaction(tx)
    return await self.w3.eth.send_raw_transaction(signed.raw_transaction)
```

### 熔断器

```python
class TradingCircuitBreaker:
    MAX_CONSECUTIVE_LOSSES = 3
    MAX_HOURLY_LOSS_PCT = 0.05

    def check(self, portfolio_value: float) -> None:
        if self.consecutive_losses >= self.MAX_CONSECUTIVE_LOSSES:
            self.halt("Too many consecutive losses")

        if self.hour_start_value <= 0:
            self.halt("Invalid hour_start_value")
            return

        hourly_pnl = (portfolio_value - self.hour_start_value) / self.hour_start_value
        if hourly_pnl < -self.MAX_HOURLY_LOSS_PCT:
            self.halt(f"Hourly PnL {hourly_pnl:.1%} below threshold")
```

### 钱包隔离

```python
import os
from eth_account import Account

private_key = os.environ.get("TRADING_WALLET_PRIVATE_KEY")
if not private_key:
    raise EnvironmentError("TRADING_WALLET_PRIVATE_KEY not set")

account = Account.from_key(private_key)
```

使用仅包含所需会话资金的专用热钱包。绝不要让智能体直接访问主力资金库钱包。

### MEV 和截止时间保护

```python
import time

PRIVATE_RPC = "https://rpc.flashbots.net"
MAX_SLIPPAGE_BPS = {"stable": 10, "volatile": 50}
deadline = int(time.time()) + 60
```

## 部署前检查清单

- 外部数据在进入 LLM 上下文之前已清理
- 支出限制独立于模型输出执行
- 交易在发送前经过模拟
- `min_amount_out` 是强制性的
- 熔断器在回撤或无效状态时停止
- 密钥来自环境变量或密钥管理器，绝不来自代码或日志
- 在适当情况下使用私有内存池或受保护路由
- 滑点和截止时间按策略设置
- 所有智能体决策都有审计日志，不仅是成功的发送
