---
name: click-path-audit
description: "追踪每个面向用户的按钮/触点，通过其完整的状态变更序列来发现这样的缺陷：函数单独工作正常但相互抵消、产生错误的最终状态，或使 UI 处于不一致状态。使用场景：系统性调试未发现缺陷但用户报告按钮不工作，或在涉及共享状态存储的重大重构之后。"
origin: community
---

# /click-path-audit — 行为流审计

发现静态代码阅读容易遗漏的缺陷：状态交互副作用、顺序调用之间的竞态条件，以及相互静默撤销的处理函数。

## 解决的问题

传统调试检查的是：
- 函数是否存在？（缺少连接）
- 是否崩溃？（运行时错误）
- 返回类型是否正确？（数据流）

但它不检查：
- **最终 UI 状态是否与按钮标签的承诺一致？**
- **函数 B 是否静默撤销了函数 A 刚做的事情？**
- **共享状态（Zustand/Redux/context）是否有抵消预期操作的副作用？**

真实案例：一个"新邮件"按钮调用了 `setComposeMode(true)` 然后 `selectThread(null)`。两个函数单独都正常工作。但 `selectThread` 有一个副作用会重置 `composeMode: false`。按钮什么也没做。系统性调试找到了 54 个缺陷 — 这个被遗漏了。

---

## 工作原理

对目标区域中的每个交互触点：

```
1. 识别处理函数（onClick, onSubmit, onChange 等）
2. 按顺序追踪处理函数中的每个函数调用
3. 对每个函数调用：
   a. 它读取了什么状态？
   b. 它写入了什么状态？
   c. 它对共享状态有副作用吗？
   d. 它是否作为副作用重置/清除了某些状态？
4. 检查：后面的调用是否撤销了前面调用的状态变更？
5. 检查：最终状态是否符合用户从按钮标签期望的结果？
6. 检查：是否存在竞态条件（异步调用以错误顺序解决）？
```

---

## 执行步骤

### 步骤 1：映射状态存储

在审计任何触点之前，构建每个状态存储操作的副作用映射：

```
对范围内的每个 Zustand 存储 / React context：
  对每个 action/setter：
    - 它设置了哪些字段？
    - 它是否作为副作用重置了其他字段？
    - 文档：actionName → {sets: [...], resets: [...]}
```

这是关键参考。"新邮件"缺陷在不了解 `selectThread` 重置 `composeMode` 的情况下是不可见的。

**输出格式：**
```
存储：emailStore
  setComposeMode(bool) → sets: {composeMode}
  selectThread(thread|null) → sets: {selectedThread, selectedThreadId, messages, drafts, selectedDraft, summary} RESETS: {composeMode: false, composeData: null, redraftOpen: false}
  setDraftGenerating(bool) → sets: {draftGenerating}
  ...

危险重置（清除了不属于自己状态的操作）：
  selectThread → 重置 composeMode（由 setComposeMode 拥有）
  reset → 重置所有内容
```

### 步骤 2：审计每个触点

对目标区域中的每个按钮/开关/表单提交：

```
触点：[组件:行号] 中的 [按钮标签]
  处理函数：onClick → {
    调用 1: functionA() → sets {X: true}
    调用 2: functionB() → sets {Y: null} RESETS {X: false}  ← 冲突
  }
  预期：用户看到 [按钮标签承诺的内容描述]
  实际：X 为 false 因为 functionB 重置了它
  结论：缺陷 — [描述]
```

**检查以下每种缺陷模式：**

#### 模式 1：顺序撤销
```
handler() {
  setState_A(true)     // 设置 X = true
  setState_B(null)     // 副作用：重置 X = false
}
// 结果：X 为 false。第一次调用毫无意义。
```

#### 模式 2：异步竞态
```
handler() {
  fetchA().then(() => setState({ loading: false }))
  fetchB().then(() => setState({ loading: true }))
}
// 结果：最终 loading 状态取决于哪个先解决
```

#### 模式 3：过期闭包
```
const [count, setCount] = useState(0)
const handler = useCallback(() => {
  setCount(count + 1)  // 捕获了过期的 count
  setCount(count + 1)  // 同样的过期 count — 只增加了 1 而非 2
}, [count])
```

#### 模式 4：缺失状态转换
```
// 按钮显示"保存"但处理函数只验证，从未真正保存
// 按钮显示"删除"但处理函数只设置了标志，没有调用 API
// 按钮显示"发送"但 API 端点已被移除/损坏
```

#### 模式 5：条件死路径
```
handler() {
  if (someState) {        // someState 在此处始终为 false
    doTheActualThing()    // 永远不会到达
  }
}
```

#### 模式 6：useEffect 干扰
```
// 按钮设置 stateX = true
// 一个 useEffect 监视 stateX 并将其重置为 false
// 用户看不到任何变化
```

### 步骤 3：报告

对发现的每个缺陷：

```
CLICK-PATH-NNN: [严重程度: 严重/高/中/低]
  触点：[文件:行号] 中的 [按钮标签]
  模式：[顺序撤销 / 异步竞态 / 过期闭包 / 缺失转换 / 死路径 / useEffect 干扰]
  处理函数：[函数名或内联]
  追踪：
    1. [调用] → sets {field: value}
    2. [调用] → RESETS {field: value}  ← 冲突
  预期：[用户期望什么]
  实际：[实际发生了什么]
  修复：[具体修复方案]
```

---

## 范围控制

此审计成本较高。适当限定范围：

- **全应用审计：** 在发布或重大重构后使用。按页面启动并行智能体。
- **单页面审计：** 在构建新页面或用户报告按钮不工作后使用。
- **存储聚焦审计：** 在修改 Zustand 存储后使用 — 审计所有使用被更改操作的消费者。

### 全应用推荐的智能体分工：

```
智能体 1：映射所有状态存储（步骤 1）— 这是所有其他智能体的共享上下文
智能体 2：仪表板（任务、笔记、日志、想法）
智能体 3：聊天（DanteChatColumn, JustChatPage）
智能体 4：邮件（ThreadList, DraftArea, EmailsPage）
智能体 5：项目（ProjectsPage, ProjectOverviewTab, NewProjectWizard）
智能体 6：CRM（所有子标签）
智能体 7：个人资料、设置、保险库、通知
智能体 8：管理套件（所有页面）
```

智能体 1 必须先完成。其输出是所有其他智能体的输入。

---

## 何时使用

- 在系统性调试发现"无缺陷"但用户报告 UI 不工作后
- 在修改任何 Zustand 存储操作后（检查所有调用方）
- 在任何涉及共享状态的重构后
- 发布前，对关键用户流程
- 当按钮"什么也不做"时 — 这就是解决此问题的工具

## 何时不使用

- 对于 API 级别的缺陷（错误响应格式、缺少端点）— 使用系统性调试
- 对于样式/布局问题 — 视觉检查
- 对于性能问题 — 性能分析工具

---

## 与其他技能集成

- 在 `/superpowers:systematic-debugging` 之后运行（它找到其他 54 种缺陷类型）
- 在 `/superpowers:verification-before-completion` 之前运行（它验证修复是否有效）
- 输入到 `/superpowers:test-driven-development` — 此处发现的每个缺陷都应该有一个测试

---

## 示例：启发此技能的缺陷

**ThreadList.tsx "新邮件"按钮：**
```
onClick={() => {
  useEmailStore.getState().setComposeMode(true)   // ✓ 设置 composeMode = true
  useEmailStore.getState().selectThread(null)      // ✗ 重置 composeMode = false
}}
```

存储定义：
```
selectThread: (thread) => set({
  selectedThread: thread,
  selectedThreadId: thread?.id ?? null,
  messages: [],
  drafts: [],
  selectedDraft: null,
  summary: null,
  composeMode: false,     // ← 这个静默重置杀死了按钮
  composeData: null,
  redraftOpen: false,
})
```

**系统性调试遗漏了它**，因为：
- 按钮有 onClick 处理函数（不是死代码）
- 两个函数都存在（没有缺少连接）
- 两个函数都没有崩溃（没有运行时错误）
- 数据类型正确（没有类型不匹配）

**点击路径审计捕获了它**，因为：
- 步骤 1 映射了 `selectThread` 重置 `composeMode`
- 步骤 2 追踪了处理函数：调用 1 设置 true，调用 2 重置 false
- 结论：顺序撤销 — 最终状态与按钮意图矛盾
