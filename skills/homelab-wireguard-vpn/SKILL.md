---
name: homelab-wireguard-vpn
description: WireGuard VPN 服务器设置、对等配置、密钥生成、分隧道与全隧道路由，以及从手机和笔记本电脑客户端远程访问家庭网络。
origin: 社区
---

# 家庭实验室 WireGuard VPN

WireGuard 是一种快速、现代的 VPN 协议。它是远程访问家庭网络的正确选择——比 OpenVPN 更简单，比大多数替代方案更快。

所有配置示例显示常见设置。在将其应用到您的系统之前，请查看每个命令——尤其是 iptables 转发规则和密钥文件权限——并在维护窗口中进行更改。

## 何时使用

- 在 Raspberry Pi、Linux 主机、pfSense 或路由器上设置 WireGuard 服务器
- 生成 WireGuard 密钥对并写入对等配置文件
- 从手机或笔记本电脑配置远程访问到家庭网络
- 解释分隧道（仅路由家庭流量）与全隧道（路由所有流量）
- 排除无法启动的 WireGuard 连接
- 为多个客户端自动对等配置生成

## WireGuard 工作原理

```
您的手机 (WireGuard 客户端)
    │
    │  加密 UDP 隧道（端口 51820）
    │
您的家庭路由器 (WireGuard 服务器 — 需要公共 IP 或 DDNS)
    │
您的家庭网络 (192.168.1.0/24, NAS, Pi 等)
```

每个设备都有一个密钥对（公钥 + 私钥）。
服务器知道每个客户端的公钥。
客户端知道服务器的公钥 + 端点 (IP:端口)。
流量端到端加密，无中央服务器或证书颁发机构。

## 服务器设置 (Linux)

```bash
# 安装 WireGuard
sudo apt update && sudo apt install wireguard -y

# 生成服务器密钥对 — 从一开始就创建具有私有权限的文件
sudo mkdir -p /etc/wireguard
sudo sh -c 'umask 077; wg genkey > /etc/wireguard/server_private.key'
sudo sh -c 'wg pubkey < /etc/wireguard/server_private.key > /etc/wireguard/server_public.key'

# 写入服务器配置 — 替换实际私钥值
# 不要将私钥存储在版本控制中或共享它们
sudo tee /etc/wireguard/wg0.conf << 'EOF'
[Interface]
Address = 10.8.0.1/24              # VPN 子网 — 服务器获得 .1
ListenPort = 51820
PrivateKey = <paste_server_private_key_here>

# 范围转发规则：允许 VPN 流量进出，而非全面的 FORWARD ACCEPT
PostUp   = iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
PostUp   = iptables -A FORWARD -i eth0 -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostUp   = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -o eth0 -j ACCEPT
PostDown = iptables -D FORWARD -i eth0 -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# 手机 — 替换为实际手机公钥
PublicKey = <phone_public_key>
AllowedIPs = 10.8.0.2/32

[Peer]
# 笔记本电脑 — 替换为实际笔记本电脑公钥
PublicKey = <laptop_public_key>
AllowedIPs = 10.8.0.3/32
EOF
sudo chmod 600 /etc/wireguard/wg0.conf

# 将 eth0 替换为您的实际出站接口名称
# 检查：ip route show default

# 启用 IP 转发（通过服务器路由流量所需）
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl --system

# 启动 WireGuard 并在启动时启用
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

## 客户端配置

```bash
# 为每个客户端设备生成唯一的密钥对
# 在客户端上运行，或在服务器上运行并安全传输私钥 —— 永不以明文方式
umask 077
wg genkey | tee phone_private.key | wg pubkey > phone_public.key

# 客户端配置文件 (phone_wg0.conf):
[Interface]
PrivateKey = <phone_private_key>
Address = 10.8.0.2/32
DNS = 192.168.1.2                  # 可选：通过隧道使用 Pi-hole 进行 DNS

[Peer]
PublicKey = <server_public_key>
Endpoint = your-home-ip.ddns.net:51820  # 您的公共 IP 或 DDNS 主机名
AllowedIPs = 192.168.1.0/24            # 分隧道：仅家庭网络流量
# AllowedIPs = 0.0.0.0/0, ::/0        # 全隧道：所有流量通过 VPN

PersistentKeepalive = 25              # 保持 NAT 洞打开（移动客户端需要）
```

## 分隧道与全隧道

```
# 分隧道：AllowedIPs = 192.168.1.0/24
  仅前往您家庭网络的流量通过 VPN。
  互联网流量 (YouTube, Spotify) 直接传输 — 在移动设备上性能更好。
  最适合："我只是想从任何地方到达我的 NAS 和 Pi。"

# 全隧道：AllowedIPs = 0.0.0.0/0, ::/0
  所有流量通过您的家庭互联网连接。
  有用于：通过家庭 DNS/Pi-hole 广告阻止。
  缺点：家庭上传速度成为您各地的瓶颈。

# 多子网分隧道（最常见的家庭实验室用例）：
  AllowedIPs = 192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24, 10.8.0.0/24
  通过隧道路由所有 VLAN；互联网保持直接。
```

## 密钥生成和对等管理

```python
import subprocess

def generate_keypair() -> tuple[str, str]:
    """生成 WireGuard 密钥对。返回 (private_key, public_key)。"""
    private = subprocess.check_output(["wg", "genkey"]).decode().strip()
    public = subprocess.run(
        ["wg", "pubkey"], input=private.encode(), capture_output=True
    ).stdout.decode().strip()
    return private, public

def generate_preshared_key() -> str:
    return subprocess.check_output(["wg", "genpsk"]).decode().strip()

def build_client_config(
    client_private_key: str,
    client_vpn_ip: str,       # 例如 "10.8.0.3"
    server_public_key: str,
    server_endpoint: str,     # 例如 "home.example.com:51820"
    allowed_ips: str = "192.168.1.0/24",
    dns: str = "",
) -> str:
    dns_line = f"DNS = {dns}\n" if dns else ""
    return f"""[Interface]
PrivateKey = {client_private_key}
Address = {client_vpn_ip}/32
{dns_line}
[Peer]
PublicKey = {server_public_key}
Endpoint = {server_endpoint}
AllowedIPs = {allowed_ips}
PersistentKeepalive = 25
"""

def build_server_peer_block(
    client_public_key: str,
    client_vpn_ip: str,
    comment: str = "",
) -> str:
    comment_line = f"# {comment}\n" if comment else ""
    return f"""
{comment_line}[Peer]
PublicKey = {client_public_key}
AllowedIPs = {client_vpn_ip}/32
"""
```

将私钥保留在源代码管理之外。如果使用此脚本，请将密钥材料写入模式为 600 的文件，并且永远不要记录或打印它。

## pfSense / OPNsense WireGuard

```
# pfSense: VPN → WireGuard → 添加隧道
  接口密钥：生成（自动创建密钥对）
  监听端口：51820
  接口地址：10.8.0.1/24

# 添加对等（每个客户端一个）：
  公钥：<客户端公钥>
  允许的 IP：10.8.0.2/32

# 分配 WireGuard 接口：
  接口 → 分配 → 添加（选择 wg0）
  启用接口，不需要 IP（在隧道配置中设置）

# 防火墙规则：
  WAN → 允许 UDP 端口 51820 入站（以便客户端可以到达服务器）
  WireGuard 接口 → 允许流量到您希望可访问的 LAN 网络
```

## 家庭服务器的 DDNS（动态 DNS）

大多数家庭互联网连接具有动态 IP。使用 DDNS，以便您的 VPN 端点在 IP 更改后保持可达。

```bash
# 选项 1：Cloudflare DDNS — 在密钥文件中存储凭据，而非内联
# docker-compose 条目使用 env 文件：
  ddns-updater:
    image: qmcgaw/ddns-updater
    env_file: ./ddns.env   # 在此处存储 zone_id 和令牌，而非 compose
    restart: unless-stopped

# ddns.env (chmod 600, 不提交到 git)：
#   SETTINGS_CLOUDFLARE_ZONE_ID=your_zone_id
#   SETTINGS_CLOUDFLARE_TOKEN=your_api_token

# 选项 2：DuckDNS（免费，简单）
  在 duckdns.org 注册 → 获取令牌和子域名 (myhome.duckdns.org)
  在 /etc/ddns.env (模式 600) 中存储令牌，然后使用小型 root 拥有的脚本：

  # /usr/local/bin/update-duckdns
  #!/bin/sh
  set -eu
  . /etc/ddns.env
  curl --fail --silent --show-error --max-time 10 \
    --get "https://www.duckdns.org/update" \
    --data-urlencode "domains=myhome" \
    --data-urlencode "token=${DUCKDNS_TOKEN}" \
    --data-urlencode "ip="

  # Cron 任务：
  */5 * * * * /usr/local/bin/update-duckdns >/dev/null 2>&1
```

## 故障排除

```bash
# 检查 WireGuard 状态和最后一次握手
sudo wg show

# 如果"latest handshake"从不或很旧，则隧道未连接。
# 检查：
# 1. 路由器/防火墙上的 UDP 端口 51820 是否打开？
sudo ufw status  # 或检查 pfSense/UniFi 防火墙规则

# 2. 客户端配置中的服务器公钥是否正确？
sudo wg show wg0 public-key   # 与客户端配置中的进行比较

# 3. 服务器上是否启用了 IP 转发？
cat /proc/sys/net/ipv4/ip_forward  # 应该是 1

# 4. 客户端 AllowedIPs 是否覆盖您尝试到达的 IP？
# 如果 AllowedIPs = 192.168.1.0/24 且您尝试到达 192.168.3.5，则不会路由。

# 检查 WireGuard 错误的内核日志
dmesg | grep wireguard

# 重启 WireGuard
sudo wg-quick down wg0 && sudo wg-quick up wg0
```

## 反模式

```
# 错误：将私钥存储在版本控制中或共享它们
# 私钥等同于密码 —— 永远不要提交到 git

# 错误：在移动设备上使用 AllowedIPs = 0.0.0.0/0 而不考虑影响
# 全隧道通过家庭上传路由所有移动流量 —— 通常很慢

# 错误：不在移动客户端上设置 PersistentKeepalive
# 没有它的移动客户端在 NAT 上的空闲隧道会断开

# 错误：在防火墙中打开端口 51820 但忘记在服务器上进行 IP 转发
# 隧道连接但没有流量路由 —— 调试令人困惑

# 错误：在多个客户端设备之间共享密钥对
# 每个设备必须有自己唯一的密钥对 — 共享密钥会破坏安全模型

# 错误：使用广泛的"FORWARD ACCEPT"iptables 规则
# 将转发规则范围限制为仅 wg0 接口和方向
```

## 最佳实践

- 为每个客户端设备生成唯一的密钥对 —— 永不重用密钥
- 为移动设备使用分隧道 (`AllowedIPs = <home subnets>`)
- 在所有移动客户端上设置 `PersistentKeepalive = 25`
- 如果 ISP 分配动态 IP，使用 DDNS；在 env 文件中存储凭据，而非内联
- 使用范围的 iptables 转发规则（仅在 wg0 上入站）而非全面的 FORWARD ACCEPT
- 在客户端配置中添加 Pi-hole 的 IP 作为 `DNS =` 以通过 VPN 获得广告阻止
- 定期轮换服务器密钥对并更新所有客户端配置

## 相关技能

- homelab-network-setup
- homelab-vlan-segmentation
- homelab-pihole-dns
