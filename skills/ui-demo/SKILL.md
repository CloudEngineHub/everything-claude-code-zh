---
name: ui-demo
description: 使用 Playwright 录制精美的 UI 演示视频。当用户要求为 Web 应用创建演示、演示视频、屏幕录制或教程视频时使用。生成带可见光标、自然节奏和专业感的 WebM 视频。
origin: ECC
---

# UI 演示视频录制器

使用 Playwright 的视频录制功能录制精美的 Web 应用演示视频，带注入的光标覆盖、自然节奏和叙事流程。

## 何时使用

- 用户要求"演示视频"、"屏幕录制"、"演示"或"教程"
- 用户想要以视觉方式展示功能或工作流
- 用户需要用于文档、入职培训或利益相关者演示的视频

## 三阶段流程

每个演示都经过三个阶段：**发现 -> 排练 -> 录制**。绝不跳过直接录制。

---

## 阶段 1：发现

在编写任何脚本之前，探索目标页面以了解实际存在的内容。

### 为什么

你无法编写你未曾看到的脚本。字段可能是 `<input>` 而非 `<textarea>`，下拉菜单可能是自定义组件而非 `<select>`，评论框可能支持 `@mentions` 或 `#tags`。假设会静默破坏录制。

### 如何操作

导航到流程中的每个页面并转储其交互元素：

```javascript
// 在编写演示脚本之前，对流程中的每个页面运行此代码
const fields = await page.evaluate(() => {
  const els = [];
  document.querySelectorAll('input, select, textarea, button, [contenteditable]').forEach(el => {
    if (el.offsetParent !== null) {
      els.push({
        tag: el.tagName,
        type: el.type || '',
        name: el.name || '',
        placeholder: el.placeholder || '',
        text: el.textContent?.trim().substring(0, 40) || '',
        contentEditable: el.contentEditable === 'true',
        role: el.getAttribute('role') || '',
      });
    }
  });
  return els;
});
console.log(JSON.stringify(fields, null, 2));
```

### 要查找什么

- **表单字段**：它们是 `<select>`、`<input>`、自定义下拉菜单还是组合框？
- **选择选项**：转储选项值和文本。占位符通常有 `value="0"` 或 `value=""` 看起来非空。使用 `Array.from(el.options).map(o => ({ value: o.value, text: o.text }))`。跳过文本包含"Select"或值为 `"0"` 的选项。
- **富文本**：评论框是否支持 `@mentions`、`#tags`、Markdown 或表情符号？检查占位符文本。
- **必填字段**：哪些字段阻止表单提交？检查 `required`、标签中的 `*`，并尝试空提交查看验证错误。
- **动态内容**：字段是否在其他字段填写后出现？
- **按钮标签**：确切的文本如 `"Submit"`、`"Submit Request"` 或 `"Send"`。
- **表格列标题**：对于表格驱动的模态框，将每个 `input[type="number"]` 映射到其列标题而非假设所有数字输入含义相同。

### 输出

每个页面的字段映射，用于在脚本中编写正确的选择器。示例：

```text
/purchase-requests/new:
  - Budget Code: <select> (页面上第一个 select, 4 个选项)
  - Desired Delivery: <input type="date">
  - Context: <textarea> (不是 input)
  - BOM 表格: span.cursor-pointer -> input 的行内可编辑单元格模式
  - Submit: <button> text="Submit"

/purchase-requests/N (详情):
  - Comment: <input placeholder="Type a message..."> 支持 @user 和 #PR 标签
  - Send: <button> text="Send" (输入有内容前禁用)
```

---

## 阶段 2：排练

不录制运行所有步骤。验证每个选择器都能解析。

### 为什么

静默的选择器失败是演示录制失败的主要原因。排练在浪费录制之前捕获它们。

### 如何操作

使用 `ensureVisible`，一个会记录并大声失败的包装器：

```javascript
async function ensureVisible(page, locator, label) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    const msg = `排练失败：未找到 "${label}" - 选择器：${typeof locator === 'string' ? locator : '(locator 对象)'}`;
    console.error(msg);
    const found = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('button, input, select, textarea, a'))
        .filter(el => el.offsetParent !== null)
        .map(el => `${el.tagName}[${el.type || ''}] "${el.textContent?.trim().substring(0, 30)}"`)
        .join('\n  ');
    });
    console.error('  可见元素：\n  ' + found);
    return false;
  }
  console.log(`排练通过："${label}"`);
  return true;
}
```

### 排练脚本结构

```javascript
const steps = [
  { label: '登录邮箱字段', selector: '#email' },
  { label: '登录提交按钮', selector: 'button[type="submit"]' },
  { label: '新建请求按钮', selector: 'button:has-text("New Request")' },
  { label: 'Budget Code 选择框', selector: 'select' },
  { label: '交付日期', selector: 'input[type="date"]:visible' },
  { label: '描述字段', selector: 'textarea:visible' },
  { label: '添加项目按钮', selector: 'button:has-text("Add Item")' },
  { label: '提交按钮', selector: 'button:has-text("Submit")' },
];

let allOk = true;
for (const step of steps) {
  if (!await ensureVisible(page, step.selector, step.label)) {
    allOk = false;
  }
}
if (!allOk) {
  console.error('排练失败 - 在录制前修复选择器');
  process.exit(1);
}
console.log('排练通过 - 所有选择器已验证');
```

### 排练失败时

1. 阅读可见元素转储。
2. 找到正确的选择器。
3. 更新脚本。
4. 重新运行排练。
5. 只有当每个选择器通过后才继续。

---

## 阶段 3：录制

只有在发现和排练都通过后才创建录制。

### 录制原则

#### 1. 叙事流程

将视频计划为故事。遵循用户指定的顺序，或使用此默认顺序：

- **入场**：登录或导航到起点
- **背景**：平移周围环境让观众定位自己
- **行动**：执行主要工作流步骤
- **变化**：展示次要功能如设置、主题或本地化
- **结果**：展示结果、确认或新状态

#### 2. 节奏

- 登录后：`4s`
- 导航后：`3s`
- 点击按钮后：`2s`
- 主要步骤之间：`1.5-2s`
- 最终操作后：`3s`
- 打字延迟：每字符 `25-40ms`

#### 3. 光标覆盖

注入跟随鼠标移动的 SVG 箭头光标：

```javascript
async function injectCursor(page) {
  await page.evaluate(() => {
    if (document.getElementById('demo-cursor')) return;
    const cursor = document.createElement('div');
    cursor.id = 'demo-cursor';
    cursor.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M5 3L19 12L12 13L9 20L5 3Z" fill="white" stroke="black" stroke-width="1.5" stroke-linejoin="round"/>
    </svg>`;
    cursor.style.cssText = `
      position: fixed; z-index: 999999; pointer-events: none;
      width: 24px; height: 24px;
      transition: left 0.1s, top 0.1s;
      filter: drop-shadow(1px 1px 2px rgba(0,0,0,0.3));
    `;
    cursor.style.left = '0px';
    cursor.style.top = '0px';
    document.body.appendChild(cursor);
    document.addEventListener('mousemove', (e) => {
      cursor.style.left = e.clientX + 'px';
      cursor.style.top = e.clientY + 'px';
    });
  });
}
```

在每次页面导航后调用 `injectCursor(page)`，因为覆盖层在导航时会被销毁。

#### 4. 鼠标移动

绝不传送光标。在点击之前移动到目标：

```javascript
async function moveAndClick(page, locator, label, opts = {}) {
  const { postClickDelay = 800, ...clickOpts } = opts;
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`警告：moveAndClick 跳过 - "${label}" 不可见`);
    return false;
  }
  try {
    await el.scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    const box = await el.boundingBox();
    if (box) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 10 });
      await page.waitForTimeout(400);
    }
    await el.click(clickOpts);
  } catch (e) {
    console.error(`警告：moveAndClick 在 "${label}" 上失败：${e.message}`);
    return false;
  }
  await page.waitForTimeout(postClickDelay);
  return true;
}
```

每次调用都应包含描述性的 `label` 用于调试。

#### 5. 打字

可见地打字，而非即时填充：

```javascript
async function typeSlowly(page, locator, text, label, charDelay = 35) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`警告：typeSlowly 跳过 - "${label}" 不可见`);
    return false;
  }
  await moveAndClick(page, el, label);
  await el.fill('');
  await el.pressSequentially(text, { delay: charDelay });
  await page.waitForTimeout(500);
  return true;
}
```

#### 6. 滚动

使用平滑滚动而非跳跃：

```javascript
await page.evaluate(() => window.scrollTo({ top: 400, behavior: 'smooth' }));
await page.waitForTimeout(1500);
```

#### 7. 仪表板平移

展示仪表板或概览页面时，在关键元素上移动光标：

```javascript
async function panElements(page, selector, maxCount = 6) {
  const elements = await page.locator(selector).all();
  for (let i = 0; i < Math.min(elements.length, maxCount); i++) {
    try {
      const box = await elements[i].boundingBox();
      if (box && box.y < 700) {
        await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 8 });
        await page.waitForTimeout(600);
      }
    } catch (e) {
      console.warn(`警告：panElements 跳过元素 ${i}（选择器："${selector}"）：${e.message}`);
    }
  }
}
```

#### 8. 字幕

在视口底部注入字幕条：

```javascript
async function injectSubtitleBar(page) {
  await page.evaluate(() => {
    if (document.getElementById('demo-subtitle')) return;
    const bar = document.createElement('div');
    bar.id = 'demo-subtitle';
    bar.style.cssText = `
      position: fixed; bottom: 0; left: 0; right: 0; z-index: 999998;
      text-align: center; padding: 12px 24px;
      background: rgba(0, 0, 0, 0.75);
      color: white; font-family: -apple-system, "Segoe UI", sans-serif;
      font-size: 16px; font-weight: 500; letter-spacing: 0.3px;
      transition: opacity 0.3s;
      pointer-events: none;
    `;
    bar.textContent = '';
    bar.style.opacity = '0';
    document.body.appendChild(bar);
  });
}

async function showSubtitle(page, text) {
  await page.evaluate((t) => {
    const bar = document.getElementById('demo-subtitle');
    if (!bar) return;
    if (t) {
      bar.textContent = t;
      bar.style.opacity = '1';
    } else {
      bar.style.opacity = '0';
    }
  }, text);
  if (text) await page.waitForTimeout(800);
}
```

在每次导航后与 `injectCursor(page)` 一起调用 `injectSubtitleBar(page)`。

使用模式：

```javascript
await showSubtitle(page, '步骤 1 - 登录');
await showSubtitle(page, '步骤 2 - 仪表板概览');
await showSubtitle(page, '');
```

指南：

- 字幕文本保持简短，理想情况下不超过 60 个字符。
- 使用 `步骤 N - 操作` 格式保持一致。
- 在 UI 可以自己表达的长时间停顿中清除字幕。

## 脚本模板

```javascript
'use strict';
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = process.env.QA_BASE_URL || 'http://localhost:3000';
const VIDEO_DIR = path.join(__dirname, 'screenshots');
const OUTPUT_NAME = 'demo-FEATURE.webm';
const REHEARSAL = process.argv.includes('--rehearse');

// 在此处粘贴 injectCursor、injectSubtitleBar、showSubtitle、moveAndClick、
// typeSlowly、ensureVisible 和 panElements。

(async () => {
  const browser = await chromium.launch({ headless: true });

  if (REHEARSAL) {
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    // 导航流程并对每个选择器运行 ensureVisible。
    await browser.close();
    return;
  }

  const context = await browser.newContext({
    recordVideo: { dir: VIDEO_DIR, size: { width: 1280, height: 720 } },
    viewport: { width: 1280, height: 720 }
  });
  const page = await context.newPage();

  try {
    await injectCursor(page);
    await injectSubtitleBar(page);

    await showSubtitle(page, '步骤 1 - 登录');
    // 登录操作

    await page.goto(`${BASE_URL}/dashboard`);
    await injectCursor(page);
    await injectSubtitleBar(page);
    await showSubtitle(page, '步骤 2 - 仪表板概览');
    // 平移仪表板

    await showSubtitle(page, '步骤 3 - 主要工作流');
    // 操作序列

    await showSubtitle(page, '步骤 4 - 结果');
    // 最终展示
    await showSubtitle(page, '');
  } catch (err) {
    console.error('演示错误：', err.message);
  } finally {
    await context.close();
    const video = page.video();
    if (video) {
      const src = await video.path();
      const dest = path.join(VIDEO_DIR, OUTPUT_NAME);
      try {
        fs.copyFileSync(src, dest);
        console.log('视频已保存：', dest);
      } catch (e) {
        console.error('错误：复制视频失败：', e.message);
        console.error('  源：', src);
        console.error('  目标：', dest);
      }
    }
    await browser.close();
  }
})();
```

用法：

```bash
# 阶段 2：排练
node demo-script.cjs --rehearse

# 阶段 3：录制
node demo-script.cjs
```

## 录制前检查清单

- [ ] 发现阶段已完成
- [ ] 排练通过所有选择器 OK
- [ ] 无头模式已启用
- [ ] 分辨率设为 `1280x720`
- [ ] 每次导航后重新注入光标和字幕覆盖
- [ ] 在主要过渡处使用了 `showSubtitle(page, '步骤 N - ...')`
- [ ] 所有点击使用了带描述性标签的 `moveAndClick`
- [ ] 可见输入使用了 `typeSlowly`
- [ ] 没有静默的 catch；辅助函数记录警告
- [ ] 内容展示使用了平滑滚动
- [ ] 关键停顿对人类观看者可见
- [ ] 流程匹配请求的叙事顺序
- [ ] 脚本反映阶段 1 中发现的实际 UI

## 常见陷阱

1. 导航后光标消失 - 重新注入。
2. 视频太快 - 添加停顿。
3. 光标是一个点而非箭头 - 使用 SVG 覆盖。
4. 光标传送 - 点击前先移动。
5. 选择下拉框看起来不对 - 展示移动，然后选择选项。
6. 模态框感觉突兀 - 确认前添加阅读停顿。
7. 视频文件路径是随机的 - 复制到稳定的输出名称。
8. 选择器失败被吞没 - 绝不使用静默 catch 块。
9. 字段类型被假设 - 先发现它们。
10. 功能被假设 - 在编写脚本前检查实际 UI。
11. 占位符选择值看起来真实 - 注意 `"0"` 和 `"Select..."`。
12. 弹出窗口创建单独的视频 - 显式捕获弹出页面，需要时稍后合并。
