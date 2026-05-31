---
name: network-bgp-diagnostics
description: 仅诊断 BGP 故障排除模式，用于邻居状态、路由交换、前缀策略、AS 路径检查和安全证据收集。
origin: community
---

# 网络 BGP 诊断

当 BGP 会话断开、抖动、建立但缺少路由或通告意外前缀时使用此技能。默认工作流是只读证据收集；策略和重置操作属于经过审查的更改窗口。

## 何时使用

- BGP 邻居卡在 Idle、Connect、Active、OpenSent 或 OpenConfirm。
- 会话已建立但缺少预期前缀。
- 路由映射、前缀列表、最大前缀限制或 AS 路径策略可能正在过滤路由。
- 您需要 BGP 更改的前后证据。
- 您正在审查解析 BGP 摘要输出的自动化。

## 只读分流流程

1. 识别确切的邻居、地址族、VRF 和本地/远程 ASN。
2. 捕获摘要状态和上次重置原因。
3. 证明到对等体源地址的可达性。
4. 在假设传输失败之前检查路由策略引用。
5. 在平台支持的地方比较已通告、已接收和已安装的路由。

```text
show bgp summary
show bgp neighbors <peer>
show ip route <peer>
show tcp brief | include <peer>|:179
show logging | include BGP|<peer>
show running-config | section router bgp
show ip prefix-list
show route-map
```

当设备使用 VRF、IPv6、VPNv4 或 EVPN 时，使用特定于平台的地址族命令。不要假设全局 IPv4 单播。

## 状态解释

| 状态 | 首先检查 |
| --- | --- |
| 已建立且有前缀计数 | 路由交换已启动；检查策略和表选择 |
| 已建立但前缀为零 | 检查入站策略、最大前缀、已通告路由和 AFI/SAFI |
| Active | TCP 会话未完成；检查路由、源、ACL 和对等体可达性 |
| Connect | TCP 连接正在进行；检查路径和远程侦听器 |
| OpenSent/OpenConfirm | TCP 工作正常；检查 ASN、身份验证、计时器、功能和日志 |
| Idle | 邻居可能被禁用、缺少配置、被策略阻止或退避计时器 |

## 传输检查

```text
ping <peer> source <local-source>
traceroute <peer> source <local-source>
show ip route <peer>
show bgp neighbors <peer> | include BGP state|Last reset|Local host|Foreign host
```

如果对等体从环回接口源，请确认两个方向都路由到环回地址，并且邻居配置使用预期的更新源。
避免禁用 ACL 或防火墙策略作为诊断快捷方式。首先读取命中计数器、日志和路径状态。

## 路由策略检查

```text
show bgp neighbors <peer> advertised-routes
show bgp neighbors <peer> routes
show ip prefix-list <name>
show route-map <name>
show bgp <prefix>
```

某些平台需要额外配置才能使 `received-routes` 可用。不要在事件分流期间添加该配置，除非操作员批准更改。

## AS 路径和前缀审查

```text
show bgp regexp _65001_
show bgp regexp ^65001$
show bgp <prefix>
show bgp neighbors <peer> advertised-routes | include Network|Path|<prefix>
```

谨慎使用 AS 路径正则表达式。`_65001_` 将 AS 65001 匹配为标记。纯 `65001` 可以匹配更长的 ASN 或不相关的文本。

## 解析器模式

```python
import re
from typing import Any

BGP_SUMMARY_RE = re.compile(
    r"^(?P<neighbor>\d{1,3}(?:\.\d{1,3}){3})\s+"
    r"(?P<version>\d+)\s+"
    r"(?P<remote_as>\d+)\s+"
    r"(?P<msg_rcvd>\d+)\s+"
    r"(?P<msg_sent>\d+)\s+"
    r"(?P<table_version>\d+)\s+"
    r"(?P<input_queue>\d+)\s+"
    r"(?P<output_queue>\d+)\s+"
    r"(?P<uptime>\S+)\s+"
    r"(?P<state_or_prefixes>\S+)$",
    re.M,
)

def parse_bgp_summary(raw: str) -> list[dict[str, Any]]:
    rows = []
    for match in BGP_SUMMARY_RE.finditer(raw):
        state_or_prefixes = match.group("state_or_prefixes")
        if state_or_prefixes.isdigit():
            state = "Established"
            prefixes_received = int(state_or_prefixes)
        else:
            state = state_or_prefixes
            prefixes_received = None
        rows.append({
            "neighbor": match.group("neighbor"),
            "remote_as": int(match.group("remote_as")),
            "state": state,
            "prefixes_received": prefixes_received,
            "uptime": match.group("uptime"),
        })
    return rows
```

在可用时优先使用结构化解析器输出，但将原始输出与事件记录一起存储，因为 BGP 摘要格式因平台和地址族而异。

## 更改窗口专用

这些操作可能会影响路由，不应建议为自动诊断：

- 清除 BGP 会话。
- 更改邻居身份验证、计时器、更新源、路由映射或前缀列表。
- 启用额外的接收路由存储。
- 放宽防火墙、ACL 或控制平面策略。

如果批准重置，优先使用平台支持的破坏性最小的软或路由刷新选项，并准确记录为什么它是安全的。

## 反模式

- 假设 `Active` 总是意味着远程端已关闭。
- 忽略 VRF、地址族或更新源差异。
- 使用没有标记边界的广泛 AS 路径正则表达式。
- 在读取上次重置原因和日志之前对对等体进行硬重置。
- 将缺少 `received-routes` 输出视为没有路由到达的证明。

## 另请参阅

- Skill: `cisco-ios-patterns`
- Skill: `network-config-validation`
- Skill: `network-interface-health`
