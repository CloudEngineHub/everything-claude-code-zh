---
name: homelab-pihole-dns
description: Pi-hole 安装、阻止列表管理、DNS-over-HTTPS 设置、DHCP 集成、本地 DNS 记录以及在家庭网络上排除 DNS 解析故障。
origin: 社区
---

# 家庭实验室 Pi-hole DNS

Pi-hole 是一个运行在 Raspberry Pi 或任何 Linux 主机上的网络级 DNS 广告拦截器。您网络上的每台设备都会自动获得广告和恶意软件域阻止——无需浏览器扩展。

## 何时使用

- 在 Raspberry Pi 或 Linux 主机上安装 Pi-hole
- 将 Pi-hole 配置为家庭网络的 DNS 服务器
- 添加或管理阻止列表
- 设置 DNS-over-HTTPS (DoH) 上游解析器
- 创建本地 DNS 记录（例如 `nas.home.lan`、`pi.home.lan`）
- 排除在安装 Pi-hole后失去互联网访问的设备故障
- 与 DHCP 一起或代替 DHCP 运行 Pi-hole

## Pi-hole 工作原理

```
正常流程（无 Pi-hole）：
  设备 → 请求 ads.tracker.com → ISP DNS → 真实 IP → 加载广告

使用 Pi-hole：
  设备 → 请求 ads.tracker.com → Pi-hole DNS → 被阻止（返回 0.0.0.0） → 无广告
```

所有 DNS 查询首先通过 Pi-hole。
Pi-hole 根据阻止列表进行检查。
被阻止的域返回空响应——广告/跟踪器永远不会加载。
允许的域被转发到您的上游解析器（Cloudflare、Google 等）。

## 安装

### Docker（推荐）

Docker 是安装 Pi-hole 的最简单方法，并使更新和备份变得简单。

```yaml
# docker-compose.yml
services:
  pihole:
    image: pihole/pihole:<pinned-release-tag>
    container_name: pihole
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"          # Web 管理
    environment:
      TZ: "America/New_York"
      WEBPASSWORD: "${PIHOLE_WEBPASSWORD}"   # 通过 .env 文件或密钥设置
      PIHOLE_DNS_: "1.1.1.1;1.0.0.1"
      DNSMASQ_LISTENING: "all"
    volumes:
      - "./etc-pihole:/etc/pihole"
      - "./etc-dnsmasq.d:/etc/dnsmasq.d"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN              # 仅当 Pi-hole 将提供 DHCP 时需要
```

在部署之前，将 `<pinned-release-tag>` 替换为当前 Pi-hole 发布标签。
避免对长期 DNS 基础设施使用 `latest`，以便升级是经过审查和故意的。

在 `docker-compose.yml` 旁边的 `.env` 文件中设置 `PIHOLE_WEBPASSWORD`，将其 chmod 为 `600`，并保持在 git 之外——不要将密码直接放在 compose 文件中。

在 `http://<pi-ip>/admin` 访问 Web 管理

### 裸机安装（Raspberry Pi OS / Debian / Ubuntu）

Pi-hole 在安装前需要静态 IP。

```bash
# 步骤 1：分配静态 IP（在 Pi OS 上编辑 /etc/dhcpcd.conf）
sudo nano /etc/dhcpcd.conf
# 在底部添加：
interface eth0
static ip_address=192.168.3.2/24
static routers=192.168.3.1
static domain_name_servers=192.168.3.1

# 步骤 2：下载并在运行之前检查安装程序。
# 优先使用 Pi-hole 为您的操作系统/版本记录的包或安装程序路径。
curl -sSL https://install.pi-hole.net -o pi-hole-install.sh
less pi-hole-install.sh   # 在继续之前审查

# 步骤 3：运行
bash pi-hole-install.sh

# 按照交互式安装程序进行：
#   1. 选择网络接口（eth0 用于有线 — 推荐）
#   2. 选择上游 DNS（Cloudflare 或保留默认 — 稍后可以更改）
#   3. 确认静态 IP
#   4. 安装 Web 管理界面（推荐）
#   5. 记录最后显示的管理员密码
```

## 将网络指向 Pi-hole

```
# 方法 1：在路由器 DHCP 设置中更改 DNS（推荐）
  路由器管理 UI → DHCP 设置 → DNS 服务器
  主 DNS：192.168.3.2  (Pi-hole IP)
  辅助 DNS：留空以进行严格阻止，或使用第二个 Pi-hole。
                 公共后备（如 1.1.1.1）在推出期间提高可用性，
                 但可以绕过阻止，因为客户端可能会查询它。

  所有设备在下次 DHCP 续期时自动获得 Pi-hole 作为 DNS。
  强制续期：重新连接 Wi-Fi 或在 Linux 上运行 'sudo dhclient -r && sudo dhclient'

# 方法 2：每设备 DNS（在网络范围推出前测试有用）
  Windows：控制面板 → 网络适配器 → IPv4 属性 → 手动设置 DNS
  macOS：系统设置 → 网络 → 详细信息 → DNS → 手动设置
  Linux：/etc/resolv.conf 或 NetworkManager

# 方法 3：Pi-hole 作为 DHCP 服务器（替换路由器 DHCP）
  Pi-hole 管理 → 设置 → DHCP → 启用
  首先禁用路由器上的 DHCP — 同一网络上的两个 DHCP 服务器会导致冲突
  优点：主机名解析自动工作（设备注册其名称）
```

## 阻止列表管理

```
# Pi-hole 管理 → Adlists → 添加新广告列表

# 推荐的阻止列表：
  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
  # 默认 — 200k+ 域

  https://blocklistproject.github.io/Lists/malware.txt
  # 恶意软件域

  https://blocklistproject.github.io/Lists/tracking.txt
  # 跟踪/遥测

# 添加列表后：
  工具 → 更新 Gravity（下载并编译所有阻止列表）

# 如果不应阻止某个站点（误报）：
  Pi-hole 管理 → 白名单 → 添加域
  示例：api.my-legitimate-service.com

# 实时检查被阻止的内容：
  仪表板 → 查询日志（实时 DNS 查询流，带有阻止/允许状态）
```

## DNS-over-HTTPS 上游

DNS-over-HTTPS 加密您的 DNS 查询，以便您的 ISP 无法看到您解析的站点。

```bash
# 安装 cloudflared（Cloudflare 的 DoH 代理）。
# 优先使用 Cloudflare 的包存储库以进行自动签名包验证。
# 如果直接下载二进制文件，请固定发布版本并验证其校验和。
CLOUDFLARED_VERSION="<pinned-version>"
curl -LO "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-arm64"
# 在安装之前从 Cloudflare 的发行说明中验证校验和/签名。
sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# 创建 cloudflared 配置
sudo mkdir -p /etc/cloudflared
sudo tee /etc/cloudflared/config.yml << EOF
proxy-dns: true
proxy-dns-port: 5053
proxy-dns-upstream:
  - https://1.1.1.1/dns-query
  - https://1.0.0.1/dns-query
EOF

# 创建 systemd 服务
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# 现在将 Pi-hole 指向本地 DoH 代理：
#   Pi-hole 管理 → 设置 → DNS → 自定义上游 DNS
#   设置为：127.0.0.1#5053
#   取消选中所有其他上游解析器
```

## 本地 DNS 记录

使您的服务可通过名称访问（例如 `nas.home.lan`、`grafana.home.lan`）。

> **域名说明：** `.home.lan` 在家庭实验室中广泛使用并实际工作。
> IETF 保留的本地使用后缀是 `.home.arpa`（RFC 8375）——使用它以
> 遵循标准。避免 `.local` 用于 Pi-hole DNS 记录，因为它与
> mDNS/Bonjour 冲突。

```
# Pi-hole 管理 → 本地 DNS → DNS 记录

  域              IP
  nas.home.lan        192.168.30.10
  pi.home.lan         192.168.30.2
  grafana.home.lan    192.168.30.3
  proxmox.home.lan    192.168.30.4

# 从您网络上的任何设备：
  ping nas.home.lan        → 192.168.30.10
  http://grafana.home.lan  → 您的 Grafana 仪表板

# 对于子域，添加 CNAME：
  Pi-hole 管理 → 本地 DNS → CNAME 记录
  域：portainer.home.lan → 目标：pi.home.lan
```

## 故障排除

```bash
# Pi-hole 阻止不应阻止的内容
pihole -q example.com          # 检查域是否被阻止以及哪个列表
pihole -w example.com          # 立即白名单

# DNS 根本不解析
pihole status                  # 检查 pihole-FTL 是否正在运行
dig @192.168.3.2 google.com   # 直接针对 Pi-hole 测试 DNS

# 重启 Pi-hole DNS
pihole restartdns

# 检查特定设备的查询日志
pihole -t                      # 所有查询的实时尾部
# 或在 Web 管理查询日志中按客户端过滤

# Pi-hole gravity 更新（刷新阻止列表）
pihole -g
```

## 反模式

```
# 错误：依赖一个 Pi-hole 而没有恢复路径
# 如果 Pi-hole 崩溃或 Pi 失去电源，DNS 可能停止工作
# 正确：在设置期间保留记录的路由器后备以进行回滚
# 更好：运行两个 Pi-hole 实例以实现冗余；为严格阻止避免公共后备 DNS

# 错误：在没有静态 IP 的情况下安装 Pi-hole
# 如果 Pi 获得新的 DHCP IP，所有设备都会失去 DNS
# 正确：首先设置静态 IP，然后安装 Pi-hole

# 错误：在首先禁用路由器的 DHCP 的情况下启用 Pi-hole DHCP
# 同一网络上的两个 DHCP 服务器分发冲突的 IP
# 正确：禁用路由器 DHCP，然后启用 Pi-hole DHCP

# 错误：从不更新 gravity（阻止列表）
# 新的广告和恶意软件域累积 —— 陈旧的列表会错过它们
# 正确：安排每周 gravity 更新：pihole -g（或在设置 → API 中启用）
```

## 最佳实践

- 在安装 Pi-hole 之前为 Pi 分配静态 IP 或 DHCP 保留
- 将 Pi-hole 作为主 DNS；为了冗余，如果需要严格阻止，添加第二个 Pi-hole 而非公共解析器
- 使用 cloudflared 启用 DoH（DNS-over-HTTPS）进行加密的上游查询
- 将 `home.lan` 设置为您的本地域并为所有服务创建 DNS 记录
- 偶尔查看查询日志 —— 被阻止的查询显示设备正在做什么

## 相关技能

- homelab-network-setup
- homelab-vlan-segmentation
- homelab-wireguard-vpn
