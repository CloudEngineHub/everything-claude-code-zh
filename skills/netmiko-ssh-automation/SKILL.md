---
name: netmiko-ssh-automation
description: 安全的 Python Netmiko 模式，用于只读收集、有界批量 SSH、TextFSM 解析、受保护的配置更改、超时和网络自动化错误处理。
origin: community
---

# Netmiko SSH 自动化

在编写或审查使用 Netmiko 连接网络设备的 Python 自动化时使用此技能。保持默认路径为只读；配置更改需要单独的更改窗口、同行审查和回滚计划。

## 何时使用

- 跨路由器、交换机或防火墙收集 `show` 命令输出。
- 构建用于接口、路由或配置证据的小型审计脚本。
- 为网络 SSH 脚本添加超时和异常处理。
- 在存在模板时使用 TextFSM 解析命令输出。
- 在自动化接触生产设备之前进行审查。

## 安全默认值

- 从只读 `send_command()` 收集开始。
- 保持清单小而明确；不要扫描整个地址范围。
- 使用环境变量、保险库或 `getpass`；永远不要硬编码凭据。
- 设置连接和读取超时。
- 限制并发，以免旧设备过载。
- 在 `send_config_set()` 之前需要显式操作员标志。
- 在更改已验证和批准之前不要调用 `save_config()`。

## 只读连接模式

```python
import os
from getpass import getpass
from netmiko import ConnectHandler
from netmiko.exceptions import (
    NetmikoAuthenticationException,
    NetmikoTimeoutException,
    ReadTimeout,
)

device = {
    "device_type": "cisco_ios",
    "host": "192.0.2.10",
    "username": os.environ.get("NETMIKO_USERNAME") or input("用户名: "),
    "password": os.environ.get("NETMIKO_PASSWORD") or getpass("密码: "),
    "secret": os.environ.get("NETMIKO_ENABLE_SECRET"),
    "conn_timeout": 10,
    "auth_timeout": 20,
    "banner_timeout": 15,
    "read_timeout_override": 30,
}

try:
    with ConnectHandler(**device) as conn:
        if device.get("secret") and not conn.check_enable_mode():
            conn.enable()
        output = conn.send_command("show ip interface brief", read_timeout=30)
        print(output)
except NetmikoAuthenticationException:
    print("身份验证失败")
except NetmikoTimeoutException:
    print("SSH 连接超时")
except ReadTimeout:
    print("命令读取超时")
```

在示例中使用文档范围中的占位符地址。将真实清单保留在忽略的本地文件或机密管理系统中。

## 批量收集

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

def collect_show(device: dict[str, Any], command: str) -> dict[str, Any]:
    host = device["host"]
    try:
        with ConnectHandler(**device) as conn:
            output = conn.send_command(command, read_timeout=45)
        return {"host": host, "ok": True, "output": output}
    except (NetmikoAuthenticationException, NetmikoTimeoutException, ReadTimeout) as exc:
        return {"host": host, "ok": False, "error": type(exc).__name__}

results = []
with ThreadPoolExecutor(max_workers=8) as pool:
    futures = [pool.submit(collect_show, device, "show version") for device in devices]
    for future in as_completed(futures):
        results.append(future.result())
```

保持 `max_workers` 较低，除非已知设备资源和 AAA 系统能处理更高的连接量。

## 结构化解析

Netmiko 可以请求 TextFSM、TTP 或 Genie 解析支持的命令输出。将解析器输出视为优化，而不是唯一的证据路径。

```python
with ConnectHandler(**device) as conn:
    parsed = conn.send_command(
        "show ip interface brief",
        use_textfsm=True,
        raise_parsing_error=False,
        read_timeout=30,
    )

if isinstance(parsed, str):
    print("没有解析器模板匹配；存储原始输出以供审查")
else:
    for row in parsed:
        print(row)
```

如果解析驱动阻塞决策，请将原始命令输出与解析结果一起保留，以便操作员可以检查不匹配。

## 受保护的配置模式

```python
import os

commands = [
    "interface GigabitEthernet0/1",
    "description CHANGE-1234 UPLINK-TO-CORE",
]

apply_changes = os.environ.get("APPLY_NETWORK_CHANGES") == "1"

if not apply_changes:
    print("仅试运行。候选命令：")
    print("\n".join(commands))
else:
    with ConnectHandler(**device) as conn:
        conn.enable()
        before = conn.send_command("show running-config interface GigabitEthernet0/1")
        output = conn.send_config_set(commands)
        after = conn.send_command("show running-config interface GigabitEthernet0/1")
        print(before)
        print(output)
        print(after)
        print("在保存启动配置之前验证行为。")
```

保存配置是一个单独的批准步骤。在生产中，包括回滚片段并在更改记录中捕获前后证据。

## 审查清单

- 脚本是否识别了明确的清单来源？
- 凭据是否从源、日志和异常消息中缺席？
- 是否设置了 `conn_timeout`、`auth_timeout` 和命令 `read_timeout`？
- 失败是否按设备报告，而不停止整个批次？
- 脚本是否避免广泛扫描和无界并发？
- 配置更改是否在试运行或显式操作员标志之后？
- `save_config()` 是否与初始推送分离并与验证相关联？

## 反模式

- 在源中硬编码密码、启用密码或私钥。
- 将配置命令作为默认代码路径发送。
- 对 CIDR 范围而不是经过审查的清单运行自动化。
- 将完整的运行配置记录到共享系统而不进行清理。
- 将解析器成功视为设备状态正确的证明。

## 另请参阅

- Skill: `cisco-ios-patterns`
- Skill: `network-config-validation`
- Skill: `network-interface-health`
