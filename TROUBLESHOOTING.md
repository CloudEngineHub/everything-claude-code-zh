# 故障排除指南

Everything Claude Code (ECC) 插件的常见问题与解决方案。

## 目录

- [内存与上下文问题](#内存与上下文问题)
- [智能体 Harness 故障](#智能体-harness-故障)
- [钩子与工作流错误](#钩子与工作流错误)
- [安装与配置](#安装与配置)
- [性能问题](#性能问题)
- [常见错误信息](#常见错误信息)
- [获取帮助](#获取帮助)

---

## 内存与上下文问题

### 上下文窗口溢出

**症状：** "Context too long" 错误或响应不完整

**原因：**
- 大文件上传超出 token 限制
- 对话历史累积过多
- 单次会话中多个大型工具输出

**解决方案：**
```bash
# 1. 清除对话历史并重新开始
# 使用 Claude Code: "New Chat" 或 Cmd/Ctrl+Shift+N

# 2. 在分析前减小文件大小
head -n 100 large-file.log > sample.log

# 3. 对大型输出使用流式处理
head -n 50 large-file.txt

# 4. 将任务拆分为更小的块
# 不要用: "分析所有50个文件"
# 而是用: "分析 src/components/ 目录中的文件"
```

### 内存持久化失败

**症状：** 智能体不记得之前的上下文或观察记录

**原因：**
- 持续学习钩子被禁用
- 观察记录文件损坏
- 项目检测失败

**解决方案：**
```bash
# 检查观察记录是否正在被记录
ls ~/.claude/homunculus/projects/*/observations.jsonl

# 查找当前项目的哈希 ID
python3 - <<'PY'
import json, os
registry_path = os.path.expanduser("~/.claude/homunculus/projects.json")
with open(registry_path) as f:
    registry = json.load(f)
for project_id, meta in registry.items():
    if meta.get("root") == os.getcwd():
        print(project_id)
        break
else:
    raise SystemExit("Project hash not found in ~/.claude/homunculus/projects.json")
PY

# 查看该项目最近的观察记录
tail -20 ~/.claude/homunculus/projects/<project-hash>/observations.jsonl

# 在重新创建损坏的观察记录文件之前先备份
mv ~/.claude/homunculus/projects/<project-hash>/observations.jsonl \
  ~/.claude/homunculus/projects/<project-hash>/observations.jsonl.bak.$(date +%Y%m%d-%H%M%S)

# 验证钩子已启用
grep -r "observe" ~/.claude/settings.json
```

---

## 智能体 Harness 故障

### 智能体未找到

**症状：** "Agent not loaded" 或 "Unknown agent" 错误

**原因：**
- 插件未正确安装
- 智能体路径配置错误
- 市场安装与手动安装不匹配

**解决方案：**
```bash
# 检查插件安装
ls ~/.claude/plugins/cache/

# 验证智能体存在（市场安装）
ls ~/.claude/plugins/cache/*/agents/

# 手动安装时，智能体应该在:
ls ~/.claude/agents/  # 仅自定义智能体

# 重新加载插件
# Claude Code → 设置 → 扩展 → 重新加载
```

### 工作流执行挂起

**症状：** 智能体启动但永不完成

**原因：**
- 智能体逻辑中的无限循环
- 被用户输入阻塞
- 等待 API 的网络超时

**解决方案：**
```bash
# 1. 检查卡住的进程
ps aux | grep claude

# 2. 启用调试模式
export CLAUDE_DEBUG=1

# 3. 设置更短的超时时间
export CLAUDE_TIMEOUT=30

# 4. 检查网络连接
curl -I https://api.anthropic.com
```

### 工具使用错误

**症状：** "Tool execution failed" 或权限被拒绝

**原因：**
- 缺少依赖项（npm、python 等）
- 文件权限不足
- 路径未找到

**解决方案：**
```bash
# 验证所需工具已安装
which node python3 npm git

# 修复钩子脚本的权限
chmod +x ~/.claude/plugins/cache/*/hooks/*.sh
chmod +x ~/.claude/plugins/cache/*/skills/*/hooks/*.sh

# 检查 PATH 包含必要的二进制文件
echo $PATH
```

---

## 钩子与工作流错误

### 钩子未触发

**症状：** 前置/后置钩子未执行

**原因：**
- 钩子未在 settings.json 中注册
- 钩子语法无效
- 钩子脚本不可执行

**解决方案：**
```bash
# 检查钩子是否已注册
grep -A 10 '"hooks"' ~/.claude/settings.json

# 验证钩子文件存在且可执行
ls -la ~/.claude/plugins/cache/*/hooks/

# 手动测试钩子
bash ~/.claude/plugins/cache/*/hooks/pre-bash.sh <<< '{"command":"echo test"}'

# 重新注册钩子（如果使用插件）
# 在 Claude Code 设置中禁用并重新启用插件
```

### Python/Node 版本不匹配

**症状：** "python3 not found" 或 "node: command not found"

**原因：**
- 缺少 Python/Node 安装
- PATH 未配置
- Python 版本错误（Windows）

**解决方案：**
```bash
# 安装 Python 3（如果缺失）
# macOS: brew install python3
# Ubuntu: sudo apt install python3
# Windows: 从 python.org 下载

# 安装 Node.js（如果缺失）
# macOS: brew install node
# Ubuntu: sudo apt install nodejs npm
# Windows: 从 nodejs.org 下载

# 验证安装
python3 --version
node --version
npm --version

# Windows: 确保 python（而非 python3）可用
python --version
```

### 开发服务器拦截器误报

**症状：** 钩子拦截了包含 "dev" 的合法命令

**原因：**
- Heredoc 内容触发了模式匹配
- 非 dev 命令的参数中包含 "dev"

**解决方案：**
```bash
# 此问题已在 v1.8.0+ 中修复 (PR #371)
# 升级插件到最新版本

# 临时解决方案：将开发服务器包装在 tmux 中
tmux new-session -d -s dev "npm run dev"
tmux attach -t dev

# 如需要可临时禁用钩子
# 编辑 ~/.claude/settings.json 并移除 pre-bash 钩子
```

---

## 安装与配置

### 插件未加载

**症状：** 安装后插件功能不可用

**原因：**
- 市场缓存未更新
- Claude Code 版本不兼容
- 插件文件损坏
- 本地 Claude 设置被清除或重置

**解决方案：**
```bash
# 首先检查 ECC 对本机的了解
ecc list-installed
ecc doctor
ecc repair

# 仅当 doctor/repair 无法恢复缺失文件时才重新安装

# 在修改前检查插件缓存
ls -la ~/.claude/plugins/cache/

# 备份插件缓存而不是直接删除
mv ~/.claude/plugins/cache ~/.claude/plugins/cache.backup.$(date +%Y%m%d-%H%M%S)
mkdir -p ~/.claude/plugins/cache

# 从市场重新安装
# Claude Code → 扩展 → Everything Claude Code → 卸载
# 然后从市场重新安装

# 如果问题出在市场/账户访问上，请单独使用 ECC Tools 的账单/账户恢复功能；不要用重新安装代替账户恢复

# 检查 Claude Code 版本
claude --version
# 需要 Claude Code 2.0+

# 手动安装（如果市场安装失败）
git clone https://github.com/affaan-m/everything-claude-code.git
cp -r everything-claude-code ~/.claude/plugins/ecc
```

### 包管理器检测失败

**症状：** 使用了错误的包管理器（使用了 npm 而非 pnpm）

**原因：**
- 没有锁文件
- CLAUDE_PACKAGE_MANAGER 未设置
- 多个锁文件导致检测混乱

**解决方案：**
```bash
# 全局设置首选包管理器
export CLAUDE_PACKAGE_MANAGER=pnpm
# 添加到 ~/.bashrc 或 ~/.zshrc

# 或按项目设置
echo '{"packageManager": "pnpm"}' > .claude/package-manager.json

# 或使用 package.json 字段
npm pkg set packageManager="pnpm@8.15.0"

# 警告：删除锁文件可能会改变已安装的依赖版本。
# 请先提交或备份锁文件，然后运行全新安装并重新运行 CI。
# 仅在有意切换包管理器时执行此操作。
rm package-lock.json  # 如果使用 pnpm/yarn/bun
```

---

## 性能问题

### 响应时间缓慢

**症状：** 智能体需要 30 秒以上才能响应

**原因：**
- 观察记录文件过大
- 活跃钩子过多
- API 网络延迟

**解决方案：**
```bash
# 归档大型观察记录而不是删除
archive_dir="$HOME/.claude/homunculus/archive/$(date +%Y%m%d)"
mkdir -p "$archive_dir"
find ~/.claude/homunculus/projects -name "observations.jsonl" -size +10M -exec sh -c '
  for file do
    base=$(basename "$(dirname "$file")")
    gzip -c "$file" > "'"$archive_dir"'/${base}-observations.jsonl.gz"
    : > "$file"
  done
' sh {} +

# 临时禁用未使用的钩子
# 编辑 ~/.claude/settings.json

# 保持活跃的观察记录文件较小
# 大型归档应存放在 ~/.claude/homunculus/archive/
```

### CPU 使用率过高

**症状：** Claude Code 消耗 100% CPU

**原因：**
- 观察记录无限循环
- 对大型目录的文件监视
- 钩子中的内存泄漏

**解决方案：**
```bash
# 检查失控进程
top -o cpu | grep claude

# 临时禁用持续学习
touch ~/.claude/homunculus/disabled

# 重启 Claude Code
# Cmd/Ctrl+Q 然后重新打开

# 检查观察记录文件大小
du -sh ~/.claude/homunculus/*/
```

---

## 常见错误信息

### "EACCES: permission denied"

```bash
# 修复钩子权限
find ~/.claude/plugins -name "*.sh" -exec chmod +x {} \;

# 修复观察记录目录权限
chmod -R u+rwX,go+rX ~/.claude/homunculus
```

### "MODULE_NOT_FOUND"

```bash
# 安装插件依赖
cd ~/.claude/plugins/cache/ecc
npm install

# 或手动安装
cd ~/.claude/plugins/ecc
npm install
```

### "spawn UNKNOWN"

```bash
# Windows 专用：确保脚本使用正确的行尾符
# 将 CRLF 转换为 LF
find ~/.claude/plugins -name "*.sh" -exec dos2unix {} \;

# 或安装 dos2unix
# macOS: brew install dos2unix
# Ubuntu: sudo apt install dos2unix
```

---

## 获取帮助

如果您仍然遇到问题：

1. **查看 GitHub Issues**: [github.com/affaan-m/everything-claude-code/issues](https://github.com/affaan-m/everything-claude-code/issues)
2. **启用调试日志**:
   ```bash
   export CLAUDE_DEBUG=1
   export CLAUDE_LOG_LEVEL=debug
   ```
3. **收集诊断信息**:
   ```bash
   claude --version
   node --version
   python3 --version
   echo $CLAUDE_PACKAGE_MANAGER
   ls -la ~/.claude/plugins/cache/
   ```
4. **提交 Issue**: 包含调试日志、错误信息和诊断信息

---

## 相关文档

- [README.md](./README.md) - 安装和功能
- [CONTRIBUTING.md](./CONTRIBUTING.md) - 开发指南
- [docs/](./docs/) - 详细文档
- [examples/](./examples/) - 使用示例
