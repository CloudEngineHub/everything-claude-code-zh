---
name: fal-ai-media
description: 通过 fal.ai MCP 的统一媒体生成——图像、视频和音频。涵盖文本转图像（Nano Banana）、文本/图像转视频（Seedance、Kling、Veo 3）、文本转语音（CSM-1B）和视频转音频（ThinkSound）。当用户想要用 AI 生成图像、视频或音频时使用。
origin: ECC
---

# fal.ai 媒体生成

> **易漂移技能。** fal.ai 模型 ID、定价、输入参数和 MCP 工具名称
> 变化很快。在承诺特定模型、参数、输出格式或成本之前，
> 请搜索或获取当前模型元数据。

通过 MCP 使用 fal.ai 模型生成图像、视频和音频。

## 何时激活

- 用户想要从文本提示生成图像
- 从文本或图像创建视频
- 生成语音、音乐或音效
- 任何媒体生成任务
- 用户说"生成图像"、"创建视频"、"文本转语音"、"制作缩略图"或类似内容

## MCP 要求

必须配置 fal.ai MCP 服务器。添加到 `~/.claude.json`：

```json
"fal-ai": {
  "command": "npx",
  "args": ["-y", "fal-ai-mcp-server"],
  "env": { "FAL_KEY": "YOUR_FAL_KEY_HERE" }
}
```

在 [fal.ai](https://fal.ai) 获取 API 密钥。

## MCP 工具

fal.ai MCP 提供以下工具：
- `search` — 按关键词查找可用模型
- `find` — 获取模型详情和参数
- `generate` — 使用参数运行模型
- `result` — 检查异步生成状态
- `status` — 检查作业状态
- `cancel` — 取消正在运行的作业
- `estimate_cost` — 估算生成成本
- `models` — 列出热门模型
- `upload` — 上传文件作为输入

---

## 图像生成

### Nano Banana 2（快速）
适用于：快速迭代、草稿、文本转图像、图像编辑。

```
generate(
  app_id: "fal-ai/nano-banana-2",
  input_data: {
    "prompt": "日落时的未来主义城市景观，赛博朋克风格",
    "image_size": "landscape_16_9",
    "num_images": 1,
    "seed": 42
  }
)
```

### Nano Banana Pro（高保真度）
适用于：生产图像、写实主义、排版、详细提示。

```
generate(
  app_id: "fal-ai/nano-banana-pro",
  input_data: {
    "prompt": "大理石表面上无线耳机的专业产品照片，影棚灯光",
    "image_size": "square",
    "num_images": 1,
    "guidance_scale": 7.5
  }
)
```

### 通用图像参数

| 参数 | 类型 | 选项 | 说明 |
|-------|------|---------|------|
| `prompt` | string | 必填 | 描述你想要的内容 |
| `image_size` | string | `square`、`portrait_4_3`、`landscape_16_9`、`portrait_16_9`、`landscape_4_3` | 宽高比 |
| `num_images` | number | 1-4 | 生成数量 |
| `seed` | number | 任意整数 | 可复现性 |
| `guidance_scale` | number | 1-20 | 遵循提示的紧密程度（越高 = 越字面） |

### 图像编辑
使用 Nano Banana 2 配合输入图像进行内补绘制、外补绘制或风格迁移：

```
# 首先上传源图像
upload(file_path: "/path/to/image.png")

# 然后使用图像输入生成
generate(
  app_id: "fal-ai/nano-banana-2",
  input_data: {
    "prompt": "同一场景但为水彩画风格",
    "image_url": "<uploaded_url>",
    "image_size": "landscape_16_9"
  }
)
```

---

## 视频生成

### Seedance 1.0 Pro（字节跳动）
适用于：文本转视频、高质量运动的图像转视频。

```
generate(
  app_id: "fal-ai/seedance-1-0-pro",
  input_data: {
    "prompt": "无人机飞越黄昏时分的山间湖泊，电影风格",
    "duration": "5s",
    "aspect_ratio": "16:9",
    "seed": 42
  }
)
```

### Kling Video v3 Pro
适用于：带原生音频生成的文本/图像转视频。

```
generate(
  app_id: "fal-ai/kling-video/v3/pro",
  input_data: {
    "prompt": "海浪拍打岩石海岸，戏剧性的云层",
    "duration": "5s",
    "aspect_ratio": "16:9"
  }
)
```

### Veo 3（Google DeepMind）
适用于：带生成音频的视频，高视觉质量。

```
generate(
  app_id: "fal-ai/veo-3",
  input_data: {
    "prompt": "熙熙攘攘的东京夜市，霓虹灯牌，人群噪音",
    "aspect_ratio": "16:9"
  }
)
```

### 图像转视频
从现有图像开始：

```
generate(
  app_id: "fal-ai/seedance-1-0-pro",
  input_data: {
    "prompt": "镜头缓慢拉远，微风拂动树木",
    "image_url": "<uploaded_image_url>",
    "duration": "5s"
  }
)
```

### 视频参数

| 参数 | 类型 | 选项 | 说明 |
|-------|------|---------|------|
| `prompt` | string | 必填 | 描述视频 |
| `duration` | string | `"5s"`、`"10s"` | 视频时长 |
| `aspect_ratio` | string | `"16:9"`、`"9:16"`、`"1:1"` | 画面比例 |
| `seed` | number | 任意整数 | 可复现性 |
| `image_url` | string | URL | 图像转视频的源图像 |

---

## 音频生成

### CSM-1B（对话式语音）
自然的、对话式质量的文本转语音。

```
generate(
  app_id: "fal-ai/csm-1b",
  input_data: {
    "text": "你好，欢迎来到演示。让我向你展示这是如何工作的。",
    "speaker_id": 0
  }
)
```

### ThinkSound（视频转音频）
从视频内容生成匹配的音频。

```
generate(
  app_id: "fal-ai/thinksound",
  input_data: {
    "video_url": "<video_url>",
    "prompt": "鸟鸣的森林环境音"
  }
)
```

### ElevenLabs（通过 API，非 MCP）
对于专业语音合成，直接使用 ElevenLabs：

```python
import os
import requests

resp = requests.post(
    "https://api.elevenlabs.io/v1/text-to-speech/<voice_id>",
    headers={
        "xi-api-key": os.environ["ELEVENLABS_API_KEY"],
        "Content-Type": "application/json"
    },
    json={
        "text": "你的文本在这里",
        "model_id": "eleven_turbo_v2_5",
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
    }
)
with open("output.mp3", "wb") as f:
    f.write(resp.content)
```

### VideoDB 生成式音频
如果已配置 VideoDB，使用其生成式音频：

```python
# 语音生成
audio = coll.generate_voice(text="你的旁白在这里", voice="alloy")

# 音乐生成
music = coll.generate_music(prompt="欢快的电子背景音乐", duration=30)

# 音效
sfx = coll.generate_sound_effect(prompt="雷鸣后接雨声")
```

---

## 成本估算

在生成之前，检查预估成本：

```
estimate_cost(
  estimate_type: "unit_price",
  endpoints: {
    "fal-ai/nano-banana-pro": {
      "unit_quantity": 1
    }
  }
)
```

## 模型发现

查找特定任务的模型：

```
search(query: "text to video")
find(endpoint_ids: ["fal-ai/seedance-1-0-pro"])
models()
```

## 提示

- 使用 `seed` 在迭代提示时获得可复现的结果
- 从较低成本模型（Nano Banana 2）开始迭代提示，然后切换到 Pro 进行最终输出
- 对于视频，保持提示描述性但简洁——关注运动和场景
- 图像转视频比纯文本转视频产生更可控的结果
- 在运行昂贵的视频生成之前检查 `estimate_cost`

## 相关技能

- `videodb` — 视频处理、编辑和流媒体
- `video-editing` — AI 驱动的视频编辑工作流
- `content-engine` — 社交平台的内容创作
