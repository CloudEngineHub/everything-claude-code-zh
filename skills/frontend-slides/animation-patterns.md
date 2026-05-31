# 动画模式参考

在生成演示文稿时使用此参考。将动画与预期的感觉相匹配。

## 效果与感觉对照表

| 感觉 | 动画 | 视觉提示 |
|---------|-----------|-------------|
| **戏剧性/电影感** | 慢速淡入（1-1.5s）、大比例缩放过渡（0.9 到 1）、视差滚动 | 深色背景、聚光灯效果、全出血图片 |
| **科技感/未来感** | 霓虹发光（box-shadow）、故障/乱码文字、网格揭示 | 粒子系统（canvas）、网格图案、等宽字体、青色/品红/电蓝色 |
| **趣味性/友好感** | 弹性缓动（弹簧物理）、浮动/上下弹跳 | 圆角、粉彩/明亮色彩、手绘元素 |
| **专业性/企业感** | 精细微妙的快速动画（200-300ms）、干净的幻灯片 | 海军蓝/石板灰/炭灰色、精确间距、数据可视化 |
| **平静/极简** | 非常缓慢的微妙运动、轻柔淡入 | 大量留白、柔和色调、衬线字体、充裕内边距 |
| **编辑/杂志风** | 交错文字揭示、图文交互 | 强字体层次、引用语、突破网格的布局、衬线标题 + 无衬线正文 |

## 入场动画

```css
/* 淡入 + 上滑（最通用） */
.reveal {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.6s var(--ease-out-expo),
                transform 0.6s var(--ease-out-expo);
}
.visible .reveal {
    opacity: 1;
    transform: translateY(0);
}

/* 缩放入场 */
.reveal-scale {
    opacity: 0;
    transform: scale(0.9);
    transition: opacity 0.6s, transform 0.6s var(--ease-out-expo);
}
.visible .reveal-scale {
    opacity: 1;
    transform: scale(1);
}

/* 从左侧滑入 */
.reveal-left {
    opacity: 0;
    transform: translateX(-50px);
    transition: opacity 0.6s, transform 0.6s var(--ease-out-expo);
}
.visible .reveal-left {
    opacity: 1;
    transform: translateX(0);
}

/* 模糊入场 */
.reveal-blur {
    opacity: 0;
    filter: blur(10px);
    transition: opacity 0.8s, filter 0.8s var(--ease-out-expo);
}
.visible .reveal-blur {
    opacity: 1;
    filter: blur(0);
}
```

## 背景效果

```css
/* 渐变网格 — 分层径向渐变营造深度感 */
.gradient-bg {
    background:
        radial-gradient(ellipse at 20% 80%, rgba(120, 0, 255, 0.3) 0%, transparent 50%),
        radial-gradient(ellipse at 80% 20%, rgba(0, 255, 200, 0.2) 0%, transparent 50%),
        var(--bg-primary);
}

/* 噪点纹理 — 内联 SVG 营造颗粒感 */
.noise-bg {
    background-image: url("data:image/svg+xml,..."); /* 内联 SVG 噪点 */
}

/* 网格图案 — 细微的结构线条 */
.grid-bg {
    background-image:
        linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
    background-size: 50px 50px;
}
```

## 交互效果

```javascript
/* 悬停 3D 倾斜 — 为卡片/面板增加深度感 */
class TiltEffect {
    constructor(element) {
        this.element = element;
        this.element.style.transformStyle = 'preserve-3d';
        this.element.style.perspective = '1000px';

        this.element.addEventListener('mousemove', (e) => {
            const rect = this.element.getBoundingClientRect();
            const x = (e.clientX - rect.left) / rect.width - 0.5;
            const y = (e.clientY - rect.top) / rect.height - 0.5;
            this.element.style.transform = `rotateY(${x * 10}deg) rotateX(${-y * 10}deg)`;
        });

        this.element.addEventListener('mouseleave', () => {
            this.element.style.transform = 'rotateY(0) rotateX(0)';
        });
    }
}
```

## 故障排除

| 问题 | 解决方案 |
|---------|-----|
| 字体未加载 | 检查 Fontshare/Google Fonts URL；确保 CSS 中字体名称匹配 |
| 动画未触发 | 验证 Intersection Observer 是否运行；检查 `.visible` 类是否被添加 |
| 滚动吸附不工作 | 确保 html 上设置了 `scroll-snap-type: y mandatory`；每张幻灯片需要 `scroll-snap-align: start` |
| 移动端问题 | 在 768px 断点禁用重型效果；测试触摸事件；减少粒子数量 |
| 性能问题 | 谨慎使用 `will-change`；优先使用 `transform`/`opacity` 动画；节流滚动处理 |
