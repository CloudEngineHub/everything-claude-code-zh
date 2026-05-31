---
name: frontend-a11y
description: >
  React 和 Next.js 的无障碍模式——语义化 HTML、ARIA 属性、
  表单标签、键盘导航、焦点管理和屏幕阅读器支持。
  在构建任何交互式 UI 组件或表单时使用。
origin: community
---

# 前端无障碍模式

React 和 Next.js 的实用无障碍模式。涵盖代码审查中最常被标记的问题：缺失的表单标签、不正确的 ARIA 使用、非语义的交互元素和损坏的键盘导航。

## 何时激活

- 构建或审查表单组件（`<input>`、`<select>`、`<textarea>`）
- 创建交互式元素（模态框、下拉菜单、工具提示、选项卡）
- 在 `<div>` 或 `<span>` 上使用 `onClick`
- 为任何元素添加 `aria-*` 属性
- 实现键盘导航或焦点管理
- 收到来自代码审查工具（CodeRabbit、ESLint a11y）的无障碍反馈
- 构建必须支持屏幕阅读器的组件

## 表单无障碍

缺失的 `htmlFor` / `id` 配对和断开的错误消息是代码审查中最常被标记的问题。

### 标签连接

```tsx
// 错误：label 与 input 没有关联——屏幕阅读器无法将它们联系起来
<label>邮箱</label>
<input type="email" />

// 正确：htmlFor 匹配 input id
<label htmlFor="email">邮箱</label>
<input id="email" type="email" />
```

### 必填字段

```tsx
// 错误：仅视觉的星号对屏幕阅读器没有任何意义
<label htmlFor="email">邮箱 *</label>
<input id="email" type="email" />

// 正确：required 启用原生浏览器验证；aria-required 向屏幕阅读器发出信号
<label htmlFor="email">
  邮箱 <span aria-hidden="true">*</span>
</label>
<input id="email" type="email" required aria-required="true" />
```

### 错误消息

```tsx
// 错误：错误文本在视觉上存在但未链接到输入框
<input id="email" type="email" />
<span className="error">邮箱地址无效</span>

// 正确：aria-describedby 将输入框连接到其错误消息
// aria-invalid 向屏幕阅读器发出无效状态信号
<input
  id="email"
  type="email"
  aria-describedby="email-error"
  aria-invalid={!!error}
/>
{error && (
  <span id="email-error" role="alert">
    {error}
  </span>
)}
```

### 完整的无障碍表单

```tsx
interface LoginFormProps {
  onSubmit: (email: string, password: string) => void;
}

export function LoginForm({ onSubmit }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newErrors: typeof errors = {};
    if (!email) newErrors.email = '邮箱是必填的';
    if (!password) newErrors.password = '密码是必填的';
    if (Object.keys(newErrors).length) {
      setErrors(newErrors);
      return;
    }
    onSubmit(email, password);
  };

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">
          邮箱 <span aria-hidden="true">*</span>
        </label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={e => setEmail(e.target.value)}
          aria-required="true"
          aria-describedby={errors.email ? 'email-error' : undefined}
          aria-invalid={!!errors.email}
          autoComplete="email"
        />
        {errors.email && (
          <span id="email-error" role="alert">
            {errors.email}
          </span>
        )}
      </div>

      <div>
        <label htmlFor="password">
          密码 <span aria-hidden="true">*</span>
        </label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={e => setPassword(e.target.value)}
          aria-required="true"
          aria-describedby={errors.password ? 'password-error' : undefined}
          aria-invalid={!!errors.password}
          autoComplete="current-password"
        />
        {errors.password && (
          <span id="password-error" role="alert">
            {errors.password}
          </span>
        )}
      </div>

      <button type="submit">登录</button>
    </form>
  );
}
```

## 语义化 HTML

使用与意图匹配的元素。屏幕阅读器和键盘用户依赖原生语义。

```tsx
// 错误：div 没有角色、没有键盘支持、没有可访问名称
<div onClick={handleClick}>提交</div>

// 正确：button 可聚焦，在 Enter/Space 上激活，宣布为"按钮"
<button type="button" onClick={handleClick}>提交</button>
```

```tsx
// 错误：非语义导航
<div onClick={() => navigate('/home')}>首页</div>

// 正确：锚点支持右键、中键和键盘导航
<a href="/home">首页</a>
```

```tsx
// 错误：标题层级跳过（h1 到 h4）
<h1>仪表板</h1>
<h4>最近活动</h4>

// 正确：顺序的标题层级
<h1>仪表板</h1>
<h2>最近活动</h2>
```

## ARIA 属性

仅当原生 HTML 语义不足时使用 ARIA。错误的 ARIA 比没有 ARIA 更糟糕。

### aria-label vs aria-labelledby

```tsx
// aria-label：内联字符串标签——当没有可见的标签文本时使用
<button aria-label="关闭模态框">
  <XIcon />
</button>

// aria-labelledby：引用另一个元素的文本——当存在可见标签时使用
<section aria-labelledby="section-title">
  <h2 id="section-title">最近订单</h2>
  {/* 内容 */}
</section>
```

### aria-describedby

```tsx
// 提供标签之外的补充描述
<button
  aria-describedby="delete-warning"
  onClick={handleDelete}
>
  删除账户
</button>
<p id="delete-warning">此操作无法撤销。</p>
```

### aria-live 用于动态内容

```tsx
// 使用 aria-live 宣布在不重新加载页面的情况下更新的内容
// polite：等待用户完成当前操作后再宣布
// assertive：立即打断——仅用于紧急错误

export function StatusMessage({ message, isError }: { message: string; isError?: boolean }) {
  return (
    <div role="status" aria-live={isError ? 'assertive' : 'polite'} aria-atomic="true">
      {message}
    </div>
  );
}
```

### aria-expanded 和 aria-controls

```tsx
export function Accordion({ title, children }: { title: string; children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(false);
  const contentId = useId();

  return (
    <div>
      <button aria-expanded={isOpen} aria-controls={contentId} onClick={() => setIsOpen(prev => !prev)}>
        {title}
      </button>
      <div id={contentId} hidden={!isOpen}>
        {children}
      </div>
    </div>
  );
}
```

## 键盘导航

每个交互元素必须仅通过键盘就可到达和操作。

### 自定义下拉菜单

```tsx
export function Dropdown({ options, onSelect }: { options: string[]; onSelect: (value: string) => void }) {
  const [isOpen, setIsOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const listId = useId();

  if (!options.length) return null;

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setActiveIndex(i => Math.min(i + 1, options.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setActiveIndex(i => Math.max(i - 1, 0));
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        if (isOpen) onSelect(options[activeIndex]);
        setIsOpen(prev => !prev);
        break;
      case 'Escape':
        setIsOpen(false);
        break;
    }
  };

  return (
    <div
      role="combobox"
      aria-expanded={isOpen}
      aria-haspopup="listbox"
      aria-controls={listId}
      tabIndex={0}
      onKeyDown={handleKeyDown}
      onClick={() => setIsOpen(prev => !prev)}
    >
      <span>{options[activeIndex]}</span>
      {isOpen && (
        <ul id={listId} role="listbox">
          {options.map((option, index) => (
            <li
              key={option}
              role="option"
              aria-selected={index === activeIndex}
              onClick={() => {
                onSelect(option);
                setIsOpen(false);
              }}
            >
              {option}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

## 焦点管理

当 UI 状态改变时焦点必须逻辑移动——特别是模态框和路由转换。

### 模态框焦点恢复

> 此示例涵盖初始焦点和恢复。对于完整的焦点陷阱（Tab/Shift+Tab 在模态框内循环），使用像 [`focus-trap-react`](https://github.com/focus-trap/focus-trap-react) 这样的库，它处理动态内容和嵌套 portal 等边缘情况。

```tsx
export function Modal({ isOpen, onClose, title, children }: { isOpen: boolean; onClose: () => void; title: string; children: React.ReactNode }) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      // 保存当前聚焦的元素并将焦点移入模态框
      previousFocusRef.current = document.activeElement as HTMLElement;
      modalRef.current?.focus();
    } else {
      // 将焦点恢复到打开模态框的元素
      previousFocusRef.current?.focus();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div ref={modalRef} role="dialog" aria-modal="true" aria-labelledby="modal-title" tabIndex={-1} onKeyDown={e => e.key === 'Escape' && onClose()}>
      <h2 id="modal-title">{title}</h2>
      {children}
      <button onClick={onClose}>关闭</button>
    </div>
  );
}
```

## 图像和图标

```tsx
// 错误：装饰性图标被宣布为未标记的图像
<img src="/icon.svg" />

// 正确：装饰性图像对屏幕阅读器隐藏
<img src="/decoration.png" alt="" aria-hidden="true" />

// 正确：有意义的图像带描述性 alt 文本
<img src="/chart.png" alt="月收入从一月到三月增长了 23%" />

// 正确：带可访问标签的图标按钮
<button aria-label="删除项目">
  <TrashIcon aria-hidden="true" />
</button>
```

## 减少动画

尊重在其操作系统设置中请求减少动画的用户。

```tsx
export function useReducedMotion(): boolean {
  const [prefersReduced, setPrefersReduced] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReduced(mq.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReduced(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return prefersReduced;
}

// 用法
export function AnimatedCard({ children }: { children: React.ReactNode }) {
  const reduceMotion = useReducedMotion();

  return (
    <div
      style={{
        transition: reduceMotion ? 'none' : 'transform 300ms ease'
      }}
    >
      {children}
    </div>
  );
}
```

## 反模式

```tsx
// 错误：在非交互元素上使用 onClick 但没有键盘支持
<div onClick={handleClick}>点击我</div>

// 错误：在没有 role 的 div 上使用 aria-label
<div aria-label="导航">...</div>

// 错误：placeholder 用作 label 的替代
<input placeholder="输入您的邮箱" />

// 错误：正 tabIndex 创建不可预测的 tab 顺序
<button tabIndex={3}>提交</button>

// 错误：可聚焦元素上的 aria-hidden——键盘用户被困住
<button aria-hidden="true">打开</button>

// 错误：div 上的 role="button" 没有键盘处理器
<div role="button" onClick={handleClick}>提交</div>
// 缺少：tabIndex={0}，Enter/Space 的 onKeyDown
```

## 检查清单

在提交任何交互式组件进行审查之前：

- [ ] 每个 `<input>`、`<select>` 和 `<textarea>` 通过 `htmlFor`/`id` 连接到 `<label>`
- [ ] 错误消息通过 `aria-describedby` 链接并标记为 `role="alert"`
- [ ] 没有 `onClick` 在 `<div>` 或 `<span>` 上而没有 `role`、`tabIndex` 和 `onKeyDown`
- [ ] 纯图标按钮有 `aria-label`
- [ ] 装饰性图像使用 `alt=""` 和 `aria-hidden="true"`
- [ ] 模态框在关闭时恢复焦点（对于 Tab/Shift+Tab 循环的完整焦点陷阱，使用 `focus-trap-react` 等库）
- [ ] 动态内容更新使用 `aria-live`
- [ ] 动画尊重 `prefers-reduced-motion`

## 相关技能

- `frontend-patterns` — 通用 React 组件和状态模式
- `design-system` — 设计令牌和组件一致性
- `motion-ui` — 带无障碍考虑的动画模式
