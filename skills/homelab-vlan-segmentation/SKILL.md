---
name: homelab-vlan-segmentation
description: 使用 UniFi、pfSense/OPNsense 和 MikroTik 将家庭网络分段为 VLAN，用于 IoT、访客、可信和服务器流量——包括交换机中继配置、防火墙规则和无线 SSID 映射。
origin: 社区
---

# 家庭实验室 VLAN 分段

如何将家庭网络分割为隔离的 VLAN，使 IoT 设备、访客和主 PC 无法相互通信。这是家庭网络最有效的安全升级。

此处显示的所有防火墙规则在分段之间添加隔离——它们不会移除现有保护。在维护窗口中应用更改，并在继续之前验证每个步骤后的分段间连接性。

## 何时使用

- 首次在家庭网络上设置 VLAN
- 将 IoT 设备（智能灯泡、摄像头、电视）与可信设备隔离
- 创建无法到达家庭设备的访客 Wi-Fi 网络
- 向不熟悉 VLAN 概念的人解释其工作原理
- 配置中继端口、接入端口和 SSID 到 VLAN 映射
- 排除 pfSense/OPNsense/UniFi 上的 VLAN 间路由或防火墙规则问题

## 工作原理

```
无 VLAN — 扁平网络：
  所有设备位于 192.168.1.0/24
  智能电视（潜在恶意软件）→ 可以到达您的 NAS、PC、所有设备

使用 VLAN：
  VLAN 10 — 可信    192.168.10.0/24  (PC、手机、笔记本电脑)
  VLAN 20 — IoT        192.168.20.0/24  (智能电视、灯泡、摄像头)
  VLAN 30 — 服务器    192.168.30.0/24  (NAS、Pi、虚拟机)
  VLAN 40 — 访客      192.168.40.0/24  (访客 Wi-Fi)
  VLAN 99 — 管理  192.168.99.0/24  (交换机/AP Web UI)

  智能电视 → 被阻止到达 192.168.10.0/24 和 192.168.30.0/24
  访客 → 仅互联网，无法看到任何家庭设备
```

## VLAN 设计模板

```
VLAN  名称        子网              网关         用途
10    trusted     192.168.10.0/24     192.168.10.1    PC、手机、笔记本电脑
20    iot         192.168.20.0/24     192.168.20.1    智能家居设备
30    servers     192.168.30.0/24     192.168.30.1    NAS、Pi、自托管
40    guest       192.168.40.0/24     192.168.40.1    访客 Wi-Fi
99    management  192.168.99.0/24     192.168.99.1    网络设备 Web UI
```

## 示例

**带有 UniFi AP 和托管交换机的典型家庭实验室：**

```
场景：3卧室住宅，UniFi Dream Machine + UniFi 8端口交换机 + 2个 AP

VLAN 10 — 可信    192.168.10.0/24   MacBook、iPhone、iPad
VLAN 20 — IoT        192.168.20.0/24   Nest 温控器、Philips Hue、Ring 门铃、智能电视
VLAN 30 — 服务器    192.168.30.0/24   Synology NAS (192.168.30.10)、Pi-hole (192.168.30.2)
VLAN 40 — 访客      192.168.40.0/24   访客 Wi-Fi — 仅互联网

SSID → VLAN 映射：
  "Home"      → VLAN 10 (WPA2、强密码、仅可信设备)
  "IoT"       → VLAN 20 (WPA2、单独密码、打印在路由器上用于设置)
  "Guest"     → VLAN 40 (WPA2、简单密码、可自由分享)

交换机端口行为：
  端口 1  → 路由器中继（标记 VLAN 10,20,30,40,99）
  端口 2  → AP 中继（标记 VLAN 10,20,40；AP 处理每个 SSID 标记）
  端口 3  → 接入 VLAN 30 (NAS — 未标记，无需 VLAN 感知)
  端口 4  → 接入 VLAN 30 (Pi-hole — 未标记)
  端口 5–8 → 接入 VLAN 10 (有线工作站)

应用的防火墙规则（所有规则添加隔离，不移除现有保护）：
  IoT → 可信：阻止
  IoT → 服务器：阻止 192.168.30.2:53 例外 (允许 Pi-hole DNS)
  IoT → 互联网：允许
  访客 → 本地网络：阻止
  访客 → 互联网：允许
  可信 → 所有地方：允许
```

## UniFi 配置

### 在 UniFi 控制器中创建网络

```
设置 → 网络 → 创建新网络

对于每个 VLAN：
  名称：IoT
  用途：企业  (提供 DHCP + 路由)
  VLAN ID：20
  网络：192.168.20.0/24
  网关 IP：192.168.20.1
  DHCP：启用
  DHCP 范围：192.168.20.100 – 192.168.20.254
```

### 将 SSID 映射到 VLAN (UniFi)

```
设置 → WiFi → 创建新 WiFi

  名称：IoT-Network
  密码：<单独密码>
  网络：IoT  ← 在此处选择您的 VLAN
  # 连接到此 SSID 的所有设备都落在 VLAN 20 中

  名称：Guest
  密码：<访客密码>
  网络：Guest
  访客策略：启用  ← 也将访客彼此隔离
```

### UniFi 防火墙规则（流量规则）

```
设置 → 流量和安全性 → 流量规则

# 阻止 IoT 到达可信 VLAN
  操作：阻止
  类别：本地网络
  源：IoT (192.168.20.0/24)
  目标：可信 (192.168.10.0/24)

# 仅允许 IoT 到达互联网
  操作：允许
  源：IoT
  目标：互联网

# 阻止访客访问所有本地网络
  操作：阻止
  源：访客
  目标：本地网络
```

## pfSense / OPNsense 配置

### 创建 VLAN

```
接口 → 分配 → VLAN → 添加

  父接口：em1  (您的 LAN NIC)
  VLAN 标签：20
  描述：IoT

# 对每个 VLAN 重复，然后将每个 VLAN 分配给接口：
接口 → 分配 → 添加
  选择您创建的 VLAN → 点击添加
  启用接口，将 IP 设置为网关地址 (192.168.20.1/24)
```

### 每个 VLAN 的 DHCP

```
服务 → DHCP 服务器 → 选择您的 VLAN 接口

  启用 DHCP
  范围：192.168.20.100 至 192.168.20.254
  DNS 服务器：192.168.30.2  ← Pi-hole IP（如果您有）
```

### 防火墙规则（pfSense/OPNsense）

```
# 规则从上到下处理，首先匹配的获胜。

# 在 IoT 接口 (VLAN 20) 上：
  规则 1：允许 IoT → Pi-hole DNS  ← 必须在 RFC1918 阻止规则之前
    协议：UDP/TCP
    源：IoT 网络
    目标：192.168.30.2 端口 53
    操作：允许

  规则 2：阻止 IoT → RFC1918 (所有私有 IP 范围)
    协议：任何
    源：IoT 网络
    目标：RFC1918  (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12)
    操作：阻止

  规则 3：允许 IoT → 互联网
    协议：任何
    源：IoT 网络
    目标：任何
    操作：允许

# 在可信接口 (VLAN 10) 上：
  允许所有 (可信设备可以到达所有地方)
    源：可信网络
    目标：任何
    操作：允许

# 需要特定本地服务的 IoT 设备的额外例外：
  在规则 2 (RFC1918 阻止) 之前插入：
    协议：TCP
    源：IoT 网络
    目标：192.168.30.x 端口 8123  ← Home Assistant
    操作：允许
```

## MikroTik 配置

```
# 步骤 1：创建启用 VLAN 过滤的网桥
/interface bridge
add name=bridge vlan-filtering=yes

# 步骤 2：将物理端口添加到网桥
# 到路由器/上行链路的中继端口（所有 VLAN 标记）
/interface bridge port
add bridge=bridge interface=ether1 frame-types=admit-only-vlan-tagged

# 可信设备的接入端口（未标记 VLAN 10）
/interface bridge port
add bridge=bridge interface=ether2 pvid=10 frame-types=admit-only-untagged-and-priority-tagged

# IoT 设备的接入端口（未标记 VLAN 20）
/interface bridge port
add bridge=bridge interface=ether3 pvid=20 frame-types=admit-only-untagged-and-priority-tagged

# 步骤 3：定义哪些端口上允许哪些 VLAN
/interface bridge vlan
add bridge=bridge tagged=ether1 untagged=ether2 vlan-ids=10
add bridge=bridge tagged=ether1 untagged=ether3 vlan-ids=20

# 步骤 4：在网桥上创建 VLAN 接口（网关 IP）
/interface vlan
add interface=bridge name=vlan10 vlan-id=10
add interface=bridge name=vlan20 vlan-id=20

# 步骤 5：分配网关 IP
/ip address
add interface=vlan10 address=192.168.10.1/24
add interface=vlan20 address=192.168.20.1/24

# 步骤 6：DHCP 池和服务器
/ip pool
add name=pool-trusted ranges=192.168.10.100-192.168.10.254
add name=pool-iot ranges=192.168.20.100-192.168.20.254

/ip dhcp-server
add interface=vlan10 address-pool=pool-trusted name=dhcp-trusted
add interface=vlan20 address-pool=pool-iot name=dhcp-iot

/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1
add address=192.168.20.0/24 gateway=192.168.20.1

# 步骤 7：防火墙 — 阻止 IoT 到达可信 VLAN
/ip firewall filter
add chain=forward src-address=192.168.20.0/24 dst-address=192.168.10.0/24 \
    action=drop comment="阻止 IoT 到可信"
```

## 交换机中继与接入端口

```
# 中继端口：承载多个 VLAN（标记）— 连接交换机到交换机、交换机到路由器、交换机到 AP
# 接入端口：承载一个 VLAN（未标记）— 连接到终端设备 (PC、摄像头、NAS)

# 连接到路由器的托管交换机端口应该是中继：
  允许的 VLAN：10, 20, 30, 40, 99

# 连接到 PC 的端口应该是接入端口：
  VLAN：10 (可信)
  无标记 — PC 不知道或不在乎 VLAN

# 连接到 AP 的端口必须是中继：
  AP 使用正确的 VLAN ID 标记来自每个 SSID 的流量
  允许的 VLAN：10, 20, 40  (AP 提供的任何 SSID)
```

## 反模式

```
# 错误：创建 VLAN 而不添加防火墙规则
# 没有防火墙规则的 VLAN 不提供安全性 — VLAN 间路由默认开放
# 正确：创建 VLAN 后立即添加显式阻止规则

# 错误：将 Pi-hole 放在 IoT VLAN 中
# IoT 设备可以到达它，但可信设备无法到达（需要额外规则）
# 正确：Pi-hole 在服务器 VLAN 中，规则允许所有 VLAN 到达端口 53

# 错误：本机 VLAN 等于管理 VLAN
# 未标记流量落在您的管理 VLAN 中启用 VLAN 跳跃攻击
# 正确：使用专用的未使用 VLAN 作为本机 (例如 VLAN 999)，保持管理流量标记

# 错误：IoT SSID 和可信 SSID 使用相同的 Wi-Fi 密码
# 任何学习密码的人都可以将 IoT 设备连接到错误的分段
```

## 最佳实践

- 从 4 个 VLAN 开始：可信、IoT、服务器、访客 — 根据需要添加更多
- 将 Pi-hole 放在服务器 VLAN (192.168.30.x) 中
- 添加防火墙规则，允许所有 VLAN 到 Pi-hole IP 的 DNS（端口 53）—— 在任何 RFC1918 阻止规则之前
- 每次规则更改后测试隔离：从 IoT VLAN，尝试 ping 可信设备 — 应该失败
- 为交换机和 AP Web UI 使用管理 VLAN，并限制仅可信 VLAN 访问
- 在表格中记录您的 VLAN 设计 (VLAN ID、名称、子网、用途)

## 相关技能

- homelab-network-setup
- homelab-pihole-dns
- homelab-wireguard-vpn
