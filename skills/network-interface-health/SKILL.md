---
name: network-interface-health
description: 诊断路由器、交换机和 Linux 主机上的接口错误、丢包、CRC、双工不匹配、抖动、速度协商问题和计数器趋势。
origin: community
---

# 网络接口健康

当网络症状可能由物理链路、交换机端口、电缆、收发器、双工设置或拥塞接口引起时使用此技能。

## 何时使用

- 主机或 VLAN 有丢包、延迟峰值或间歇性可达性。
- 交换机或路由器接口显示 CRC、runts、giants、丢包、重置或抖动。
- 您需要在更换硬件之前比较链路的两端。
- 更改窗口需要前后接口计数器证据。
- 监控报告上升的 `ifInErrors`、`ifOutErrors` 或 `ifOutDiscards`。

## 工作原理

接口计数器是证据，但趋势比绝对数字更重要。捕获基线，等待测量间隔，再次捕获，然后比较增量。

```text
show interfaces <interface>
show interfaces <interface> status
show logging | include <interface>|changed state|line protocol
```

在 Linux 主机上：

```text
ip -s link show <interface>
ethtool <interface>
ethtool -S <interface>
```

## 计数器参考

| 计数器 | 含义 | 常见原因 |
| --- | --- | --- |
| CRC | 接收帧校验和失败 | 坏电缆、脏光纤、坏光模块、双工不匹配 |
| input errors | 聚合接收端错误 | 在得出结论之前检查子计数器 |
| runts | 低于最小以太网大小的帧 | 双工不匹配、冲突域、故障网卡 |
| giants | 大于预期 MTU 的帧 | MTU 不匹配或巨型帧边界 |
| input drops | 设备无法接受入站数据包 | 突发、超额订阅、CPU 路径、队列压力 |
| output drops | 出站队列丢弃数据包 | 拥塞、QoS 策略、上行链路不足 |
| resets | 接口硬件重置 | 抖动、keepalive、驱动程序、光模块、电源 |
| collisions | 以太网冲突计数器 | 半双工或协商不匹配 |

## 诊断流程

### CRC 或输入错误

1. 确认计数器正在递增，而不仅仅是历史记录。
2. 检查链路的两端。接收端错误通常指向到达该侧的信号，不一定是报告错误的端口。
3. 更换跳线或清洁/更换光纤和光模块。
4. 确认两端的速度/双工设置匹配。
5. 检查日志中是否有同一时间戳周围的抖动事件。

### 丢包

1. 将输入丢包与输出丢包分开。
2. 将接口速率与容量进行比较。
3. 检查 QoS 策略、队列计数器以及链路是否为超额订阅的上行链路。
4. 将队列调整视为次要措施。首先证明链路是否拥塞。

### 双工和速度

在双方都支持的现代以太网链路上优先使用自动协商。如果一方必须固定，请在双方明确配置并记录原因。永远不要在一方混合固定速度/双工与另一方的自动。

```text
show interfaces <interface> | include duplex|speed
```

## 安全解析器示例

将每个接口块从一个头部切片到下一个。不要使用任意字符窗口；大型接口块可能导致计数器丢失或分配给错误的端口。

```python
import re
from typing import Any

HEADER_RE = re.compile(
    r"^(?P<name>\S+) is (?P<status>(?:administratively )?down|up), "
    r"line protocol is (?P<protocol>up|down)",
    re.I | re.M,
)
ERROR_RE = re.compile(r"(?P<input>\d+) input errors, (?P<crc>\d+) CRC", re.I)
DROP_RE = re.compile(r"(?P<output>\d+) output errors", re.I)
DUPLEX_RE = re.compile(r"(?P<duplex>Full|Half|Auto)-duplex,\s+(?P<speed>[^,]+)", re.I)

def parse_show_interfaces(raw: str) -> list[dict[str, Any]]:
    headers = list(HEADER_RE.finditer(raw))
    interfaces = []
    for index, header in enumerate(headers):
        end = headers[index + 1].start() if index + 1 < len(headers) else len(raw)
        block = raw[header.start():end]
        errors = ERROR_RE.search(block)
        drops = DROP_RE.search(block)
        duplex = DUPLEX_RE.search(block)
        interfaces.append({
            "name": header.group("name"),
            "status": header.group("status"),
            "protocol": header.group("protocol"),
            "duplex": duplex.group("duplex") if duplex else "unknown",
            "speed": duplex.group("speed").strip() if duplex else "unknown",
            "input_errors": int(errors.group("input")) if errors else 0,
            "crc_errors": int(errors.group("crc")) if errors else 0,
            "output_errors": int(drops.group("output")) if drops else 0,
        })
    return interfaces
```

## 示例

### 一个交换机端口上的 CRC

1. 捕获本地端口的计数器。
2. 捕获连接的远程端口的计数器。
3. 在更改路由或防火墙规则之前更换电缆或光模块。
4. 仅在记录基线后清除计数器。
5. 在固定间隔后重新检查。

### 互联网慢但 LAN 正常

1. 检查 WAN 接口丢包/错误。
2. 检查 LAN 上行链路利用率和输出丢包。
3. 如果 WAN 链路干净但吞吐量仍然很低，请检查网关 CPU。
4. 在指责上游服务之前比较有线和无线测试。

## 反模式

- 在保存基线之前清除计数器。
- 仅查看链路的一侧。
- 在没有时间窗口的情况下假设所有历史 CRC 都是活动问题。
- 在一侧混合自动协商与另一侧的固定速度/双工。
- 在检查拥塞之前将输出丢包视为电缆问题。

## 另请参阅

- Agent: `network-troubleshooter`
- Skill: `network-config-validation`
- Skill: `homelab-network-setup`
