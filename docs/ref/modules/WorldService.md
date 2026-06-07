# WorldService

**层：** Module  
**文件：** `addons/mkit/modules/world/world_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"world"`

## 职责

区域（Zone）切换协调者。`go_to_zone` 通过 `SceneService` 换场景，场景就绪后把玩家放到匹配的 `SpawnPoint`，发 `zone_changed` 并播放区域 BGM。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `player_group` | `String`（@export）| `"player"` | 定位玩家的 group |
| `current_zone_id` | `String` | `""` | 当前区域 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `go_to_zone(zone_id, spawn_id := "") -> bool` | `bool` | 切到区域并落到出生点 |
| `get_current_zone() -> ZoneDefinition` | — | 当前区域定义 |
| `place_player_at_spawn(spawn_id) -> bool` | `bool` | 把玩家移到某出生点 |

## 信号

`zone_changed(from_zone_id, to_zone_id)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var world := ServiceRegistry.get_service("world") as WorldService
world.go_to_zone("zone.forest", "from_village")
```

## 相关

- → [ZoneDefinition](ZoneDefinition.md) · [SpawnPoint](SpawnPoint.md) · [Portal](Portal.md) · [ref/kernel/SceneService.md](../kernel/SceneService.md)
- → [pipeline.md — Scene / Zone Transition](../../pipeline.md#20-scene--zone-transition)
