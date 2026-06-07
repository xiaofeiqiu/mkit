# ZoneDefinition

**层：** Module  
**文件：** `addons/mkit/modules/world/zone_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

一个区域的静态定义（`.tres`）：场景路径、BGM、默认出生点。`WorldService.go_to_zone` 按它切换。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `zone_id` | `String` | `""` | 唯一 id |
| `display_name` | `String` | `""` | 显示名 |
| `scene_path` | `String` | `""` | 区域场景 |
| `bgm_id` | `String` | `""` | 进入时播放的音乐 id（`AudioService.music_map`）|
| `default_spawn_id` | `String` | `"default"` | 默认出生点 |
| `tags` | `Array[String]` | `[]` | 标签 |

## 相关

- → [WorldService](WorldService.md) · [SpawnPoint](SpawnPoint.md)
