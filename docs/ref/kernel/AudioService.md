# AudioService

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/audio_service.gd`  
**继承：** `extends Saveable`  
**服务 ID：** `"audio"`

## 职责

音效与背景音乐播放，含音乐淡入淡出与音量总线持久化。是 `Saveable`（`save_id="audio"`），总线音量会进存档。`GameBootstrap` 会把 `ResourceDatabase` 中的 `AudioDefinition` 自动注册进它；`FeedbackSystem`、`WorldService`（区域 BGM）调用它播放。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `sfx_map` | `Dictionary`（@export）| `{}` | `sfx_id → AudioStream`；推荐由 `AudioDefinition(kind=SFX)` 自动填充 |
| `music_map` | `Dictionary`（@export）| `{}` | `music_id → AudioStream`；推荐由 `AudioDefinition(kind=MUSIC)` 自动填充 |
| `sfx_bus` / `music_bus` | `String`（@export）| `"SFX"` / `"Music"` | 总线名 |
| `current_music_id` | `String` | `""` | 当前 BGM |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `register_audio_definition(definition: AudioDefinition) -> bool` | `bool` | 注册单个音频定义；无效 id 或空 stream 返回 `false` |
| `register_audio_definitions(definitions: Array) -> int` | `int` | 批量注册音频定义，返回成功数量 |
| `play_sfx(audio_id: String, volume_db := 0.0) -> void` | — | 播一次性音效 |
| `play_music(music_id: String, fade_seconds := 0.0) -> void` | — | 播 BGM，可交叉淡入 |
| `stop_music() -> void` | — | 停 BGM |
| `set_bus_volume(bus, db) -> bool` | `bool` | 设总线音量（会被存档）|
| `get_bus_volume(bus) -> float` | `float` | 读总线音量 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var audio := Mkit.audio()
audio.play_sfx("hit")
audio.play_music("dungeon_theme", 1.5)   # 1.5s 淡入
```

推荐把 `"hit"`、`"dungeon_theme"` 这些 id 做成 `AudioDefinition` 并加入 `ResourceDatabase`；`GameBootstrap` 启动时会自动注册。只有运行时 DLC、调试工具或测试夹具才需要直接改 `sfx_map` / `music_map`。

## 相关

- → [AudioDefinition](AudioDefinition.md)（内容定义）
- → [ref/modules/WorldService.md](../modules/WorldService.md)；游戏侧反馈系统（如 demo 的 FeedbackSystem）通常在此之上做统一入口
- → [Saveable](Saveable.md)（音量持久化）· [cookbook/15_world_zone_transition.md](../../cookbook/15_world_zone_transition.md)（区域 BGM）
