---
name: video-editing
description: 用于剪切、结构和增强真实素材的 AI 辅助视频编辑工作流。涵盖从原始捕获到 FFmpeg、Remotion、ElevenLabs、fal.ai 和 Descript 或 CapCut 中的最终打磨的完整管道。当用户想要编辑视频、剪切素材、创建 vlog 或构建视频内容时使用。
---

# 视频编辑

真实素材的 AI 辅助编辑。不是从提示生成。快速编辑现有视频。

## 何时激活

- 用户想要编辑、剪切或结构化视频素材
- 将长录制转化为短形式内容
- 从原始捕获构建 vlog、教程或演示视频
- 向现有视频添加叠加层、字幕、音乐或画外音
- 为不同平台（YouTube、TikTok、Instagram）重新构架视频
- 用户说"编辑视频"、"剪切此素材"、"制作 vlog"或"视频工作流"

## 核心论点

当您停止要求 AI 创建整个视频并开始使用它来压缩、结构和增强真实素材时，AI 视频编辑很有用。价值不是生成。价值是压缩。

## 管道

```
Screen Studio / 原始素材
  → Claude / Codex
  → FFmpeg
  → Remotion
  → ElevenLabs / fal.ai
  → Descript 或 CapCut
```

每一层都有特定工作。不要跳过层。不要尝试让一个工具做所有事情。

## 第 1 层：捕获（Screen Studio / 原始素材）

收集源材料：
- **Screen Studio**：用于应用演示、编码会话、浏览器工作流的精美屏幕录制
- **原始摄像机素材**：vlog 素材、采访、事件录制
- **通过 VideoDB 的桌面捕获**：具有实时上下文的会话录制（查看 `videodb` 技能）

输出：准备好组织的原始文件。

## 第 2 层：组织（Claude / Codex）

使用 Claude Code 或 Codex：
- **转录和标记**：生成转录、识别主题和主题
- **规划结构**：决定保留什么、剪切什么、什么顺序有效
- **识别死区**：查找暂停、离题、重复拍摄
- **生成编辑决策列表**：剪切的timestamp、要保留的片段
- **搭建 FFmpeg 和 Remotion 代码**：生成命令和合成

```
示例提示：
"这是一个 4 小时录制的转录。识别 24 分钟 vlog 的 8 个最强片段。
给我每个片段的 FFmpeg 剪切命令。"
```

此层关于结构，而非最终创意品味。

## 第 3 层：确定性剪切（FFmpeg）

FFmpeg 处理无聊但关键的工作：分割、修剪、连接和预处理。

### 按 timestamp 提取片段

```bash
ffmpeg -i raw.mp4 -ss 00:12:30 -to 00:15:45 -c copy segment_01.mp4
```

### 从编辑决策列表批量剪切

```bash
#!/bin/bash
# cuts.txt: start,end,label
while IFS=, read -r start end label; do
  ffmpeg -i raw.mp4 -ss "$start" -to "$end" -c copy "segments/${label}.mp4"
done < cuts.txt
```

### 连接片段

```bash
# 创建文件列表
for f in segments/*.mp4; do echo "file '$f'"; done > concat.txt
ffmpeg -f concat -safe 0 -i concat.txt -c copy assembled.mp4
```

### 创建代理以更快编辑

```bash
ffmpeg -i raw.mp4 -vf "scale=960:-2" -c:v libx264 -preset ultrafast -crf 28 proxy.mp4
```

### 提取音频以转录

```bash
ffmpeg -i raw.mp4 -vn -acodec pcm_s16le -ar 16000 audio.wav
```

### 标准化音频电平

```bash
ffmpeg -i segment.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:v copy normalized.mp4
```

## 第 4 层：可编程合成（Remotion）

Remotion 将编辑问题转化为可组合代码。将其用于传统编辑器使事情变得痛苦的地方：

### 何时使用 Remotion

- 叠加层：文本、图像、品牌、下三分
- 数据可视化：图表、统计、动画数字
- 动态图形：转场、解释动画
- 可组合场景：跨视频的可重用模板
- 产品演示：注释截图、UI 高亮

### 基本 Remotion 合成

```tsx
import { AbsoluteFill, Sequence, Video, useCurrentFrame } from "remotion";

export const VlogComposition: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill>
      {/* 主素材 */}
      <Sequence from={0} durationInFrames={300}>
        <Video src="/segments/intro.mp4" />
      </Sequence>

      {/* 标题叠加层 */}
      <Sequence from={30} durationInFrames={90}>
        <AbsoluteFill style={{
          justifyContent: "center",
          alignItems: "center",
        }}>
          <h1 style={{
            fontSize: 72,
            color: "white",
            textShadow: "2px 2px 8px rgba(0,0,0,0.8)",
          }}>
            AI 编辑栈
          </h1>
        </AbsoluteFill>
      </Sequence>

      {/* 下一片段 */}
      <Sequence from={300} durationInFrames={450}>
        <Video src="/segments/demo.mp4" />
      </Sequence>
    </AbsoluteFill>
  );
};
```

### 渲染输出

```bash
npx remotion render src/index.ts VlogComposition output.mp4
```

查看 [Remotion 文档](https://www.remotion.dev/docs) 了解详细模式和 API 参考。

## 第 5 层：生成资产（ElevenLabs / fal.ai）

仅生成您需要的内容。不要生成整个视频。

### 使用 ElevenLabs 的画外音

```python
import os
import requests

resp = requests.post(
    f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
    headers={
        "xi-api-key": os.environ["ELEVENLABS_API_KEY"],
        "Content-Type": "application/json"
    },
    json={
        "text": "您的旁白文本在这里",
        "model_id": "eleven_turbo_v2_5",
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
    }
)
with open("voiceover.mp3", "wb") as f:
    f.write(resp.content)
```

### 使用 fal.ai 的音乐和 SFX

使用 `fal-ai-media` 技能：
- 背景音乐生成
- 音效（ThinkSound 模型用于视频到音频）
- 转场声音

### 使用 fal.ai 的生成视觉

用于插入镜头、缩略图或不存在的 b-roll：
```
generate(model_name: "fal-ai/nano-banana-pro", input: {
  "prompt": "科技 vlog 的专业缩略图，深色背景，屏幕上有代码",
  "image_size": "landscape_16_9"
})
```

### VideoDB 生成音频

如果配置了 VideoDB：
```python
voiceover = coll.generate_voice(text="旁白在这里", voice="alloy")
music = coll.generate_music(prompt="编码 vlog 的 lo-fi 背景", duration=120)
sfx = coll.generate_sound_effect(prompt="微妙的 whoosh 转场")
```

## 第 6 层：最终打磨（Descript / CapCut）

最后一层是人类。为以下内容使用传统编辑器：
- **节奏**：调整感觉太快或太慢的剪切
- **字幕**：自动生成，然后手动清理
- **调色**：基本校正和情绪
- **最终音频混合**：平衡语音、音乐和 SFX 电平
- **导出**：平台特定格式和质量设置

这是品味存在的地方。AI 清除重复工作。您做出最终调用。

## 社交媒体重新构架

不同平台需要不同的纵横比：

| 平台 | 纵横比 | 分辨率 |
|----------|-------------|------------|
| YouTube | 16:9 | 1920x1080 |
| TikTok / Reels | 9:16 | 1080x1920 |
| Instagram Feed | 1:1 | 1080x1080 |
| X / Twitter | 16:9 或 1:1 | 1280x720 或 720x720 |

### 使用 FFmpeg 重新构架

```bash
# 16:9 到 9:16（中心裁剪）
ffmpeg -i input.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" vertical.mp4

# 16:9 到 1:1（中心裁剪）
ffmpeg -i input.mp4 -vf "crop=ih:ih,scale=1080:1080" square.mp4
```

### 使用 VideoDB 重新构架

```python
# 智能重新构架（AI 引导的主体跟踪）
reframed = video.reframe(start=0, end=60, target="vertical", mode=ReframeMode.smart)
```

## 场景检测和自动剪切

### FFmpeg 场景检测

```bash
# 检测场景变化（阈值 0.3 = 中等敏感度）
ffmpeg -i input.mp4 -vf "select='gt(scene,0.3)',showinfo" -vsync vfr -f null - 2>&1 | grep showinfo
```

### 自动剪切的静默检测

```bash
# 查找静默片段（用于切断死空气）
ffmpeg -i input.mp4 -af silencedetect=noise=-30dB:d=2 -f null - 2>&1 | grep silence
```

### 高光提取

使用 Claude 分析转录 + 场景 timestamps：
```
"给定带有 timestamps 的此转录和这些场景变化点，
识别用于社交媒体的最吸引 5 个 30 秒片段。"
```

## 每个工具最擅长什么

| 工具 | 优势 | 劣势 |
|------|----------|----------|
| Claude / Codex | 组织、规划、代码生成 | 不是创意品味层 |
| FFmpeg | 确定性剪切、批处理、格式转换 | 无视觉编辑 UI |
| Remotion | 可编程叠加层、可组合场景、可重用模板 | 非开发者的学习曲线 |
| Screen Studio | 立即获得精美屏幕录制 | 仅屏幕捕获 |
| ElevenLabs | 语音、旁白、音乐、SFX | 不是工作流的中心 |
| Descript / CapCut | 最终节奏、字幕、打磨 | 手动，不可自动化 |

## 关键原则

1. **编辑，不生成。** 此工作流用于剪切真实素材，而不是从提示创建。
2. **结构先于风格。** 在第 2 层弄对故事，然后再接触任何视觉。
3. **FFmpeg 是骨干。** 无聊但关键。长素材变得可管理的地方。
4. **Remotion 用于可重复性。** 如果您要做不止一次，请将其设为 Remotion 组件。
5. **选择性生成。** 仅对不存在的资产使用 AI 生成，而非所有内容。
6. **品味是最后一层。** AI 清除重复工作。您做出最终创意调用。

## 相关技能

- `fal-ai-media` — AI 图像、视频和音频生成
- `videodb` — 服务端视频处理、索引和流式传输
- `content-engine` — 平台原生内容分发
