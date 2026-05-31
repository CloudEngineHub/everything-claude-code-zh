---
name: network-config-validation
description: 路由器和交换机配置的部署前检查，包括危险命令、重复地址、子网重叠、过期引用、管理平面风险和 IOS 风格的安全卫生。
origin: community
---

# 网络配置验证

在更改窗口之前或自动化运行接触生产设备之前使用此技能审查网络配置。

## 何时使用

- 在部署之前审查 Cisco IOS 或 IOS-XE 风格的代码段。
- 审计来自脚本或模板的生成配置。
- 查找危险命令、重复 IP 地址或子网重叠。
- 检查 ACL、路由映射、前缀列表或行策略是否被引用但未定义。
- 为网络自动化构建轻量级试运行前脚本。

## 工作原理

将配置验证视为分层证据，而不是完整的解析器。正则表达式检查对于试运行前警告很有用，但最终批准仍需要网络工程师审查意图、平台语法和回滚步骤。

按以下顺序验证：

1. 破坏性命令。
2. 凭据和管理平面暴露。
3. 重复地址和重叠子网。
4. 对 ACL、路由映射、前缀列表和接口的过期引用。
5. 操作卫生，如 NTP、时间戳、远程日志记录和横幅。

## 危险命令检测

```python
import re

DANGEROUS_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\breload\b", re.I), "reload 导致停机"),
    (re.compile(r"\berase\s+(startup|nvram|flash)", re.I), "擦除持久存储"),
    (re.compile(r"\bformat\b", re.I), "格式化设备文件系统"),
    (re.compile(r"\bno\s+router\s+(bgp|ospf|eigrp)\b", re.I), "删除路由进程"),
    (re.compile(r"\bno\s+interface\s+\S+", re.I), "删除接口配置"),
    (re.compile(r"\baaa\s+new-model\b", re.I), "更改身份验证行为"),
    (re.compile(r"\bcrypto\s+key\s+(zeroize|generate)\b", re.I), "更改设备 SSH 密钥"),
]

def find_dangerous_commands(lines: list[str]) -> list[dict[str, str | int]]:
    findings = []
    for line_number, line in enumerate(lines, start=1):
        stripped = line.strip()
        for pattern, reason in DANGEROUS_PATTERNS:
            if pattern.search(stripped):
                findings.append({
                    "line": line_number,
                    "command": stripped,
                    "reason": reason,
                })
    return findings
```

## 重复 IP 和子网重叠

```python
import ipaddress
import re
from collections import Counter

IP_ADDRESS_RE = re.compile(
    r"^\s*ip address\s+"
    r"(?P<ip>\d{1,3}(?:\.\d{1,3}){3})\s+"
    r"(?P<mask>\d{1,3}(?:\.\d{1,3}){3})\b",
    re.I | re.M,
)

def extract_interfaces(config: str) -> list[dict[str, str]]:
    results = []
    current = None
    for line in config.splitlines():
        if line.startswith("interface "):
            current = line.split(maxsplit=1)[1]
            continue
        match = IP_ADDRESS_RE.match(line)
        if current and match:
            ip = match.group("ip")
            mask = match.group("mask")
            network = ipaddress.ip_interface(f"{ip}/{mask}").network
            results.append({"interface": current, "ip": ip, "network": str(network)})
    return results

def find_duplicate_ips(config: str) -> list[str]:
    ips = [entry["ip"] for entry in extract_interfaces(config)]
    counts = Counter(ips)
    return sorted(ip for ip, count in counts.items() if count > 1)

def find_subnet_overlaps(config: str) -> list[tuple[str, str]]:
    networks = [ipaddress.ip_network(entry["network"]) for entry in extract_interfaces(config)]
    overlaps = []
    for index, left in enumerate(networks):
        for right in networks[index + 1:]:
            if left.overlaps(right):
                overlaps.append((str(left), str(right)))
    return overlaps
```

## 管理平面检查

按节解析 VTY 块，以便访问类检查不会溢出到不相关的行。

```python
import re

def iter_blocks(config: str, starts_with: str) -> list[str]:
    blocks = []
    current: list[str] = []
    for line in config.splitlines():
        if line.startswith(starts_with):
            if current:
                blocks.append("\n".join(current))
            current = [line]
            continue
        if current:
            if line and not line.startswith(" "):
                blocks.append("\n".join(current))
                current = []
            else:
                current.append(line)
    if current:
        blocks.append("\n".join(current))
    return blocks

def check_vty_blocks(config: str) -> list[str]:
    issues = []
    for block in iter_blocks(config, "line vty"):
        if re.search(r"transport\s+input\s+.*telnet", block, re.I):
            issues.append("VTY 允许 Telnet；要求仅 SSH。")
        if not re.search(r"\baccess-class\s+\S+\s+in\b", block, re.I):
            issues.append("VTY 块没有入站访问类源限制。")
        if not re.search(r"\bexec-timeout\s+\d+\s+\d+\b", block, re.I):
            issues.append("VTY 块没有显式 exec-timeout。")
    return issues
```

## 安全卫生检查

```python
SECURITY_PATTERNS = [
    (re.compile(r"\bsnmp-server community\s+(public|private)\b", re.I),
     "配置了默认 SNMP community"),
    (re.compile(r"\bsnmp-server community\s+\S+", re.I),
     "配置了 SNMPv2 community 字符串；优先使用 SNMPv3 authPriv"),
    (re.compile(r"\bip ssh version 1\b", re.I),
     "启用了 SSH 版本 1"),
    (re.compile(r"\benable password\b", re.I),
     "存在 enable password；使用 enable secret"),
    (re.compile(r"\busername\s+\S+\s+password\b", re.I),
     "本地用户名使用密码而不是 secret"),
]

BEST_PRACTICE_PATTERNS = [
    (re.compile(r"\bntp server\b", re.I), "NTP 服务器"),
    (re.compile(r"\bservice timestamps\b", re.I), "日志时间戳"),
    (re.compile(r"\blogging\s+\S+", re.I), "日志目的地或缓冲区"),
    (re.compile(r"\bsnmp-server group\s+\S+\s+v3\s+priv\b", re.I), "SNMPv3 authPriv 组"),
    (re.compile(r"\bbanner\s+(login|motd)\b", re.I), "登录横幅"),
]

def check_security(config: str) -> list[str]:
    return [message for pattern, message in SECURITY_PATTERNS if pattern.search(config)]

def check_missing_hygiene(config: str) -> list[str]:
    return [
        f"缺少 {description}"
        for pattern, description in BEST_PRACTICE_PATTERNS
        if not pattern.search(config)
    ]
```

## 示例

### 更改窗口试运行前

1. 对要粘贴的确切代码段运行危险命令检查。
2. 对完整的候选配置运行重复 IP 和子网重叠检查。
3. 确认每个引用的 ACL、路由映射和前缀列表都存在。
4. 在任何管理平面更改之前确认回滚命令和带外访问。

### 自动化试运行前

在 Netmiko、NAPALM、Ansible 或供应商 API 自动化推送生成的配置之前使用验证作为阻塞门。对危险命令和凭据失败关闭。警告超出更改范围的最佳实践差距。

## 反模式

- 将正则表达式验证视为设备解析器。
- 在没有试运行差异的情况下应用生成的配置。
- 建议将 SNMPv2 community 字符串作为监控要求。
- 使用正则表达式检查 VTY 块，意外跨越不相关的节。
- 通过禁用 ACL 而不是读取计数器/日志来测试防火墙行为。

## 另请参阅

- Agent: `network-config-reviewer`
- Agent: `network-troubleshooter`
- Skill: `network-interface-health`
