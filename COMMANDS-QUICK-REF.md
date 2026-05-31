# 命令快速参考

> 已全局安装 59 个斜杠命令。在任何 Claude Code 会话中输入 `/` 即可调用。

---

## 核心工作流

| 命令 | 功能 |
|---------|-------------|
| `/plan` | 重述需求、评估风险、编写分步实施计划 — **在接触代码前等待您的确认** |
| `/tdd` | 强制执行测试驱动开发：构建接口 → 编写失败的测试 → 实现 → 验证 80%+ 覆盖率 |
| `/code-review` | 对更改的文件进行全面代码质量、安全性和可维护性审查 |
| `/build-fix` | 检测并修复构建错误 — 自动委托给正确的构建解析器 agent |
| `/verify` | 运行完整验证循环：构建 → lint → 测试 → 类型检查 |
| `/quality-gate` | 根据项目标准进行质量门检查 |

---

## 测试

| 命令 | 功能 |
|---------|-------------|
| `/tdd` | 通用 TDD 工作流（任何语言） |
| `/e2e` | 生成 + 运行 Playwright 端到端测试，捕获截图/视频/追踪 |
| `/test-coverage` | 报告测试覆盖率，识别空白 |
| `/go-test` | Go 的 TDD 工作流（表驱动，使用 `go test -cover` 达到 80%+ 覆盖率） |
| `/kotlin-test` | Kotlin 的 TDD（Kotest + Kover） |
| `/rust-test` | Rust 的 TDD（cargo test，集成测试） |
| `/cpp-test` | C++ 的 TDD（GoogleTest + gcov/lcov） |

---

## 代码审查

| 命令 | 功能 |
|---------|-------------|
| `/code-review` | 通用代码审查 |
| `/python-review` | Python — PEP 8、类型提示、安全、惯用模式 |
| `/go-review` | Go — 惯用模式、并发安全、错误处理 |
| `/kotlin-review` | Kotlin — 空安全、协程安全、整洁架构 |
| `/rust-review` | Rust — 所有权、生命周期、unsafe 使用 |
| `/cpp-review` | C++ — 内存安全、现代惯用法、并发 |

---

## 构建修复

| 命令 | 功能 |
|---------|-------------|
| `/build-fix` | 自动检测语言并修复构建错误 |
| `/go-build` | 修复 Go 构建错误和 `go vet` 警告 |
| `/kotlin-build` | 修复 Kotlin/Gradle 编译器错误 |
| `/rust-build` | 修复 Rust 构建和借用检查器问题 |
| `/cpp-build` | 修复 C++ CMake 和链接器问题 |
| `/gradle-build` | 修复 Android / KMP 的 Gradle 错误 |

---

## 规划与架构

| 命令 | 功能 |
|---------|-------------|
| `/plan` | 带风险评估的实施计划 |
| `/multi-plan` | 多模型协作规划 |
| `/multi-workflow` | 多模型协作开发 |
| `/multi-backend` | 专注于后端的多模型开发 |
| `/multi-frontend` | 专注于前端的多模型开发 |
| `/multi-execute` | 多模型协作执行 |
| `/orchestrate` | tmux/worktree 多 agent 编排指南 |
| `/devfleet` | 通过 DevFleet 编排并行的 Claude Code agents |

---

## 会话管理

| 命令 | 功能 |
|---------|-------------|
| `/save-session` | 将当前会话状态保存到 `~/.claude/session-data/` |
| `/resume-session` | 从标准会话存储加载最近保存的会话，并从您离开的地方继续 |
| `/sessions` | 浏览、搜索和管理来自 `~/.claude/session-data/` 的会话历史（包含从 `~/.claude/sessions/` 的旧读） |
| `/checkpoint` | 在当前会话中标记检查点 |
| `/aside` | 回答快速的侧面问题，不丢失当前任务上下文 |
| `/context-budget` | 分析上下文窗口使用情况 — 发现 token 开销，进行优化 |

---

## 学习与改进

| 命令 | 功能 |
|---------|-------------|
| `/learn` | 从当前会话中提取可复用模式 |
| `/learn-eval` | 提取模式 + 在保存前自我评估质量 |
| `/evolve` | 分析学习的本能，建议进化的技能结构 |
| `/promote` | 将项目范围的本能提升到全局范围 |
| `/instinct-status` | 显示所有学习的本能（项目 + 全局）及置信度分数 |
| `/instinct-export` | 将本能导出到文件 |
| `/instinct-import` | 从文件或 URL 导入本能 |
| `/skill-create` | 分析本地 git 历史 → 生成可复用技能 |
| `/skill-health` | 技能组合健康仪表板，包含分析 |
| `/rules-distill` | 扫描技能，提取横切原则，提炼为规则 |

---

## 重构与清理

| 命令 | 功能 |
|---------|-------------|
| `/refactor-clean` | 删除死代码，合并重复，清理结构 |
| `/prompt-optimize` | 分析草稿提示并输出优化的 ECC 增强版本 |

---

## 文档与研究

| 命令 | 功能 |
|---------|-------------|
| `/docs` | 通过 Context7 查找当前库/API 文档 |
| `/update-docs` | 更新项目文档 |
| `/update-codemaps` | 为代码库重新生成 codemaps |

---

## 循环与自动化

| 命令 | 功能 |
|---------|-------------|
| `/loop-start` | 按间隔启动循环 agent |
| `/loop-status` | 检查运行循环的状态 |
| `/claw` | 启动 NanoClaw v2 — 持久 REPL，包含模型路由、技能热加载、分支和指标 |

---

## 项目与基础设施

| 命令 | 功能 |
|---------|-------------|
| `/projects` | 列出已知项目及其本能统计 |
| `/harness-audit` | 审计 agent 工具配置的可靠性和成本 |
| `/eval` | 运行评估工具 |
| `/model-route` | 将任务路由到正确的模型（Haiku / Sonnet / Opus） |
| `/pm2` | PM2 进程管理器初始化 |
| `/setup-pm` | 配置包管理器（npm / pnpm / yarn / bun） |

---

## 快速决策指南

```
开始新功能？                   → 先 /plan，然后 /tdd
刚写完代码？                   → /code-review
构建失败？                     → /build-fix
需要实时文档？                 → /docs <library>
会话即将结束？                 → /save-session 或 /learn-eval
第二天继续？                   → /resume-session
上下文变得沉重？              → /context-budget 然后 /checkpoint
想提取学到的东西？             → /learn-eval 然后 /evolve
运行重复任务？                 → /loop-start
```
