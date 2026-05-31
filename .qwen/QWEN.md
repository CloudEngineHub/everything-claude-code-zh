# Qwen CLI 配置

此目录包含 ECC 的 Qwen CLI 安装模板。

## 运行时位置

运行时，此仓库中的源 `.qwen/` 目录被复制到用户的主级 `~/.qwen/` 安装根目录：

```bash
./install.sh --target qwen --profile minimal
```

托管安装还会写入 `~/.qwen/ecc-install-state.json`，以便未来的 ECC 更新和卸载可以区分 ECC 拥有的文件与用户拥有的 Qwen 配置。

## 已安装表面

Qwen 目标安装与其他 harness 适配器使用的相同托管清单模块：

- `rules/`
- `agents/`
- `commands/`
- `skills/`
- `mcp-configs/`

钩子运行时文件故意不为 Qwen 选择，直到 Qwen 钩子/事件合同经过验证。
