---
name: uncloud
description: 在管理 Uncloud 集群时使用 — 部署服务、配置 Caddy 入口、为非集群设备添加静态代理路由、发布端口、扩展、检查日志或使用 `uc` CLI 管理机器和卷。
origin: ECC
---

# Uncloud 集群管理

`uc` CLI 参考 — 使用 Docker 容器、WireGuard 网格网络和 Caddy 反向代理的去中心化自托管平台。

## 何时激活

在以下情况下使用此技能：
- 使用 `uc machine` 引导或加入机器
- 使用 `uc deploy` 从 Compose 文件部署服务
- 通过 Uncloud 发布 HTTP、HTTPS、TCP 或 UDP 端口
- 使用 `x-caddy`、`x-ports` 或 `--caddyfile` 配置 Caddy 入口
- 通过集群代理路由外部 LAN 设备
- 检查日志、服务状态、卷、DNS 或机器放置

## 工作原理

Uncloud 在通过 WireGuard 网格连接的对等机器上运行 Docker 服务。每台机器都是平等的集群成员；服务在覆盖网络上通信，Caddy 全局运行以终止公共 HTTP/HTTPS 流量。Compose 文件可以使用 Uncloud扩展进行入口、放置和生成的 Caddy 配置，而 `uc` CLI 处理镜像分发、调度、扩展、日志和集群状态。

## 示例

```bash
uc machine init user@host --name machine-1
uc service run --name web -p app.example.com:8080/https nginx:latest
uc deploy
```

## 核心概念

- **无中心控制平面** — 所有机器都是通过 WireGuard 连接的平等对等节点
- **Caddy** 作为全局服务运行在每台机器上；自动从 Let's Encrypt 获取 TLS
- **覆盖网络** — 服务默认通过 `10.210.0.0/16` 通信；网格内提供 DNS
- **Caddyfile 自动生成** — 永远不要直接编辑；使用 `x-caddy` / `--caddyfile` 替代

---

## CLI 快速参考

### 机器

| 命令 | 用途 |
|---------|---------|
| `uc machine init user@host` | 引导第一台机器 / 新集群 |
| `uc machine add user@host` | 将机器加入现有集群 |
| `uc machine ls` | 列出机器 |
| `uc machine update NAME --public-ip IP` | 更新入口的公共 IP |
| `uc machine rm NAME` | 移除机器 |

关键 `init` 标志：`--name`、`--network 10.210.0.0/16`、`--no-caddy`、`--no-dns`、`--public-ip auto|IP|none`

### 服务

| 命令 | 用途 |
|---------|---------|
| `uc service ls` / `uc ls` | 列出服务 |
| `uc service run IMAGE` | 运行单个容器服务 |
| `uc deploy` | 从 `compose.yaml` 部署 |
| `uc deploy --no-build` | 部署已推送的镜像而不重新构建 |
| `uc deploy --recreate` | 强制重建服务 |
| `uc scale SERVICE N` | 设置副本数量 |
| `uc service logs SERVICE` | 查看日志 |
| `uc service exec SERVICE` | 进入容器 Shell |
| `uc service inspect SERVICE` | 详细信息 |
| `uc service rm SERVICE` | 移除服务（保留命名卷） |
| `uc ps` | 集群中所有容器 |

### 镜像

```bash
uc image push myapp:latest                    # 推送本地镜像到所有机器
uc image push myapp:latest -m machine1,machine2  # 推送到特定机器
uc images                                     # 列出集群中的镜像
```

### 卷

```bash
uc volume ls                  # 所有卷
uc volume ls -m machine1      # 特定机器上
uc volume create NAME -m MACHINE
uc volume rm NAME
```

### Caddy

```bash
uc caddy config    # 显示当前生成的 Caddyfile（只读）
uc caddy deploy    # 跨集群部署/升级 Caddy
```

### DNS 和上下文

```bash
uc dns show        # 显示保留的 *.uncld.dev 域名
uc dns reserve     # 保留新域名
uc ctx ls          # 列出集群上下文
uc ctx use prod    # 切换上下文
```

---

## 端口发布

### HTTP/HTTPS（通过 Caddy 反向代理）

```
-p [hostname:]container_port[/protocol]
```

| 示例 | 含义 |
|---------|---------|
| `-p 8080/https` | HTTPS，自动 `service-name.cluster-domain` 主机名 |
| `-p app.example.com:8080/https` | HTTPS，自定义主机名 |
| `-p 8080/http` | 仅 HTTP，无 TLS |

### TCP/UDP（主机绑定，绕过 Caddy）

```
-p [host_ip:]host_port:container_port[/protocol]@host
```

| 示例 | 含义 |
|---------|---------|
| `-p 5432:5432@host` | TCP 5432 在所有接口 |
| `-p 127.0.0.1:5432:5432@host` | TCP 5432 仅回环 |
| `-p 53:5353/udp@host` | UDP |

---

## Compose 文件扩展

Uncloud 在 Docker Compose 之上添加了这些扩展：

### `x-ports` — 发布带域名的端口

```yaml
services:
  app:
    image: app:latest
    x-ports:
      - example.com:8000/https
      - www.example.com:8000/https
      - api.example.com:9000/https
```

### `x-caddy` — 服务自定义 Caddy 配置

```yaml
services:
  app:
    image: app:latest
    x-caddy: |
      example.com {
        redir https://www.example.com{uri} permanent
      }
      www.example.com {
        reverse_proxy {{upstreams 8000}} {
          import common_proxy
        }
        basic_auth /admin/* {
          admin $2a$14$...
        }
      }
```

`x-caddy` 内可用的模板函数：
- `{{upstreams [service] [port]}}` — 健康容器 IP
- `{{.Name}}` — 服务名称
- `{{.Upstreams}}` — 所有服务 → IP 的映射

### `x-machines` — 放置约束

```yaml
services:
  db:
    image: postgres:18
    x-machines: db-machine          # 单台机器名称
  app:
    image: app:latest
    x-machines:
      - machine-1
      - machine-2
```

### 完整多服务示例

```yaml
services:
  api:
    build: ./api
    x-ports:
      - api.example.com:3000/https
    environment:
      DATABASE_URL: postgres://db:5432/mydb

  web:
    build: ./web
    x-ports:
      - example.com:8000/https
      - www.example.com:8000/https
    environment:
      API_URL: http://api:3000

  db:
    image: postgres:18
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
    x-machines: db-machine

volumes:
  db-data:
```

---

## 路由到外部（非集群）设备

要通过 Caddy 暴露外部设备（如 BMC、NAS、路由器 UI）而不运行真实容器：

**1. 创建 Caddyfile 片段**（如 `~/device.caddyfile`）：

```caddyfile
https://device.example.com {
    reverse_proxy https://192.168.1.x {
        transport http {
            tls_insecure_skip_verify   # 自签名 BMC 证书需要
        }
    }
    log
}
```

对于明文上游：`reverse_proxy http://192.168.1.x:port`

**2. 注册为带 no-op 容器的命名服务：**

```bash
uc service run \
  --name device-bmc \
  --caddyfile ~/device.caddyfile \
  registry.k8s.io/pause:3.9
```

`pause` 是一个最小的 no-op 容器 — 它什么都不做，但给 Uncloud 一个服务条目来附加 Caddyfile。

**3. 验证：**

```bash
uc caddy config   # device.example.com 块应该出现
```

> `--caddyfile` 不能与非 `@host` 发布端口组合使用。

**DNS 提示：** 通配符记录（`*.yourdomain.com → 集群公共 IP`）意味着任何新子域立即生效 — 无需为每个服务更改 DNS。

---

## 服务 DNS（内部）

集群内的服务通过名称互相解析：

| DNS 名称 | 解析为 |
|----------|------------|
| `service-name` | 任何健康容器 |
| `service-name.internal` | 相同 |
| `rr.service-name.internal` | 轮询 |
| `nearest.service-name.internal` | 优先本机 |

---

## 扩展和全局服务

```bash
uc scale web 5    # 5 个副本（跨机器分布）
uc scale web 1    # 缩减
```

```yaml
services:
  caddy:
    deploy:
      mode: global   # 每台机器一个容器
```

---

## 镜像标签模板（在 compose.yaml 中）

```yaml
image: myapp:{{gitdate "20060102"}}.{{gitsha 7}}
image: myapp:{{gitsha 7}}.${GITHUB_RUN_ID:-local}
```

| 函数 | 输出 |
|----------|------|
| `{{gitsha N}}` | 提交 SHA 的前 N 个字符 |
| `{{gitdate "format"}}` | Git 提交日期（Go 格式） |
| `{{date "format"}}` | 当前日期 |

---

## 常见工作流

**从源码部署：**
```bash
uc deploy                          # 构建 + 推送 + 部署
uc build --push && uc deploy --no-build   # 分步操作
```

**检查服务：**
```bash
uc inspect web
uc logs -f web
uc logs --since 1h web
uc exec web                        # 打开 shell
uc exec web /bin/sh -c "env"       # 运行特定命令
```

**零停机部署** 自动发生；Uncloud 在终止旧容器之前等待健康检查。

**强制重建：**
```bash
uc deploy --recreate
```

---

## 常见错误

| 错误 | 修复 |
|---------|-----|
| 直接编辑 Caddyfile | 使用 compose 中的 `x-caddy` 或 `uc service run` 上的 `--caddyfile` |
| 代理带自签名证书的 HTTPS 上游 | 添加 `transport http { tls_insecure_skip_verify }` |
| `uc caddy config` 不显示用户定义块 | Caddy admin socket 不可达 — 检查 `uc inspect caddy` 和 `uc logs caddy` |
| 容器无法访问外部 LAN IP | 验证 Caddy 容器主机可以路由到目标网络 |
| `uc service rm` 后卷丢失 | 命名卷持久存在；只有匿名卷会被自动移除 |
