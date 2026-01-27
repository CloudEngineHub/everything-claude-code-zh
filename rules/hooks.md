# Hooks System (Hook 系统)

## Hook 类型

- **PreToolUse**: 在工具执行之前 (验证，参数修改)
- **PostToolUse**: 在工具执行之后 (自动格式化，检查)
- **Stop**: 当会话结束时 (最终验证)

## 当前 Hooks (在 ~/.claude/settings.json 中)

### PreToolUse
- **tmux reminder**: 为长时间运行的命令 (npm, pnpm, yarn, cargo, etc.) 建议使用 tmux
- **git push review**: 推送前打开 Zed 进行审查
- **doc blocker**: 阻止创建不必要的 .md/.txt 文件

### PostToolUse
- **PR creation**: 记录 PR URL 和 GitHub Actions 状态
- **Prettier**: 编辑后自动格式化 JS/TS 文件
- **TypeScript check**: 编辑 .ts/.tsx 文件后运行 tsc
- **console.log warning**: 警告有关已编辑文件中的 console.log

### Stop
- **console.log audit**: 在会话结束前检查所有修改的文件是否有 console.log

## 自动接受权限 (Auto-Accept Permissions)

谨慎使用：
- 为受信任、定义明确的计划启用
- 对探索性工作禁用
- 永远不要使用 dangerously-skip-permissions 标志
- 改为在 `~/.claude.json` 中配置 `allowedTools`

## TodoWrite 最佳实践

使用 TodoWrite 工具来：
- 跟踪多步任务的进度
- 验证对指令的理解
- 启用实时指导
- 显示细粒度的实施步骤

Todo 列表揭示：
- 乱序的步骤
- 缺失的项目
- 额外不必要的项目
- 错误的粒度
- 误解的需求
