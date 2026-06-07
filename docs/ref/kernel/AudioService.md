# AudioService

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/audio_service.gd`  
**继承：** `extends Saveable`  
**服务 ID：** `"audio"`

## 职责

音效与背景音乐播放，含音乐淡入淡出与音量总线持久化。是 `Saveable`（`save_id="audio"`），总线音量会进存档。`FeedbackSystem`、`WorldService`（区域 BGM）调用它。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `sfx_map` | `Dictionary`（@export）| `{}` | `sfx_id → AudioStream` |
| `music_map` | `Dictionary`（@export）| `{}` | `music_id → AudioStream` |
| `sfx_bus` / `music_bus` | `String`（@export）| `"SFX"` / `"Music"` | 总线名 |
| `current_music_id` | `String` | `""` | 当前 BGM |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `play_sfx(audio_id: String, volume_db := 0.0) -> void` | — | 播一次性音效 |
| `play_music(music_id: String, fade_seconds := 0.0) -> void` | — | 播 BGM，可交叉淡入 |
| `stop_music() -> void` | — | 停 BGM |
| `set_bus_volume(bus, db) -> bool` | `bool` | 设总线音量（会被存档）|
| `get_bus_volume(bus) -> float` | `float` | 读总线音量 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var audio := ServiceRegistry.get_port(ServiceRegistry.SERVICE_AUDIO) as AudioService
audio.play_sfx("hit")
audio.play_music("dungeon_theme", 1.5)   # 1.5s 淡入
```

## 相关

- → [ref/modules/FeedbackSystem.md](../modules/FeedbackSystem.md) · [ref/modules/WorldService.md](../modules/WorldService.md)
- → [Saveable](Saveable.md)（音量持久化）
