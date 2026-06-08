# AudioDefinition

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/audio_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

音频内容定义（`.tres`）：把稳定的音频 id 绑定到一个 `AudioStream`，并声明它是 SFX 还是 BGM。加入 `ResourceDatabase.resources` 后，`GameBootstrap` 会在内容加载后自动注册到全局 `AudioService`。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `audio_id` | `String` | `""` | 全局唯一音频 id，也是 `get_content_id()` 返回值 |
| `stream` | `AudioStream` | `null` | 实际音频资源 |
| `kind` | `AudioKind` | `SFX` | `SFX` 注册到 `AudioService.sfx_map`；`MUSIC` 注册到 `music_map` |
| `loop` | `bool` | `false` | 为 `true` 且 stream 是 `AudioStreamWAV` 时，注册时设置完整长度循环 |

## 使用模式

```gdscript
var definition := AudioDefinition.new()
definition.audio_id = "bgm.forest"
definition.stream = load("res://game/audio/forest_loop.wav") as AudioStream
definition.kind = AudioDefinition.AudioKind.MUSIC
definition.loop = true
```

实际项目中推荐在编辑器里创建 `.tres` 或作为 `ResourceDatabase` 子资源维护，而不是在场景脚本里手动 load。

## 相关

- → [AudioService](AudioService.md) — 注册和播放音频
- → [GameBootstrap](GameBootstrap.md) — 启动时注册 `AudioDefinition`
- → [ResourceDatabase](ResourceDatabase.md) — 打包音频定义
