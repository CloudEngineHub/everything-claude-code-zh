---
name: cisco-ios-patterns
description: Cisco IOS 和 IOS-XE 审查模式，涵盖 show 命令、配置层级、通配符掩码、ACL 放置、接口规范和安全的变更窗口验证。
origin: community
---

# Cisco IOS 模式

在审查 Cisco IOS 或 IOS-XE 代码片段、构建变更窗口检查清单，或解释如何在不恶化事件的情况下从路由器或交换机收集证据时，使用此技能。

## 何时使用

- 在计划变更前审查 IOS 或 IOS-XE 配置。
- 选择只读的 `show` 命令进行故障排除。
- 检查 ACL 通配符掩码和接口方向。
- 解释全局、接口、路由进程和线路配置模式。
- 验证变更已进入 running config 并已有意保存。

## 操作规则

将 IOS 示例视为模式，而非可直接粘贴的生产变更。在真实设备上进行更改之前，确认平台、接口名称、当前配置、回滚路径和带外访问。

建议遵循此工作流：

1. 使用只读命令捕获当前状态。
2. 审查确切的候选配置。
3. 确认管理访问不会被锁定。
4. 在维护窗口中应用最小变更。
5. 重新读取状态，与基线对比，仅在验证后保存。

## 模式参考

```text
Router> enable
Router# show running-config
Router# configure terminal
Router(config)# interface GigabitEthernet0/1
Router(config-if)# description UPLINK-TO-CORE
Router(config-if)# no shutdown
Router(config-if)# exit
Router(config)# end
Router# show running-config interface GigabitEthernet0/1
```

`running-config` 是活动内存。`startup-config` 是重启后保留的配置。
不要仅仅因为命令被接受就保存更改；先验证行为，然后在变更获批后使用 `copy running-config startup-config`。

## 只读收集

```text
show version
show inventory
show processes cpu sorted
show memory statistics
show logging
show running-config | section line vty
show running-config | section interface
show running-config | section router bgp
show ip interface brief
show interfaces
show interfaces status
show vlan brief
show mac address-table
show spanning-tree
show ip route
show ip protocols
show ip access-lists
show route-map
show ip prefix-list
```

收集你需要的特定部分，而不是将完整配置转储到工单中，因为配置可能包含密钥、客户名称或私有拓扑信息。

## 通配符掩码

IOS ACL 和许多路由语句使用通配符掩码，而非子网掩码。

```text
子网掩码            通配符掩码
255.255.255.255   0.0.0.0
255.255.255.252   0.0.0.3
255.255.255.0     0.0.0.255
255.255.0.0       0.0.255.255
```

部署前审查通配符掩码。被子网掩码意外当作通配符使用可能会匹配远超预期范围的流量。

```text
ip access-list extended WEB-IN
  10 permit tcp 192.0.2.0 0.0.0.255 any eq 443
  999 deny ip any any log
```

每个 ACL 末尾都有一个隐式拒绝。当运营目标包括观察未命中流量时，添加显式的带日志的拒绝规则，并确认日志量在安全范围内。

## ACL 放置审查

在将 ACL 应用到接口之前，回答以下问题：

- 正在过滤哪个方向的流量，`in` 还是 `out`？
- 管理流量是否来自已知的跳板机或管理子网？
- 是否有显式允许所需的路由、DNS、NTP、监控或应用流量？
- 是否可以从安全的测试源获取命中计数？
- 是否有回滚命令和活动的控制台或带外路径？

不要通过移除防火墙或 ACL 保护来测试可达性。先读取计数器、日志和路由状态。

## 接口规范

```text
interface GigabitEthernet0/1
 description UPLINK-TO-CORE
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
 switchport trunk native vlan 999
 no shutdown
```

使用清晰的描述、显式的交换端口模式和有文档记录的本征 VLAN。
在路由接口上，在假设链路状态等于转发正常之前，确认掩码、对端地址和路由进程。

## 变更窗口验证

使用与实际变更匹配的前后检查。

```text
show running-config | section interface GigabitEthernet0/1
show interfaces GigabitEthernet0/1
show logging | include GigabitEthernet0/1|changed state|line protocol
show ip route <prefix>
show ip access-lists <name>
```

对于路由变更，还要在变更前后捕获邻居状态和路由表。对于 ACL 变更，从计划的测试源对比命中计数，而不是依赖通用 ping。

## 反模式

- 在没有设备特定差异对比的情况下应用生成的配置。
- 在变更后检查通过之前保存配置。
- 在 IOS 期望通配符掩码的地方使用子网掩码。
- 将 ACL 应用到错误的接口方向。
- 通过禁用 ACL、路由策略或认证来排除故障。
- 将完整配置粘贴到公共工具中而不清理密钥和拓扑信息。

## 另请参阅

- 智能体：`network-config-reviewer`
- 智能体：`network-troubleshooter`
- 技能：`network-config-validation`
- 技能：`network-interface-health`
