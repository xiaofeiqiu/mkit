# SpawnPoint

**层：** Module  
**文件：** `addons/mkit/modules/world/spawn_point.gd`  
**继承：** `extends Marker2D`

## 职责

区域内的命名出生点。`WorldService` 切区域后按 `spawn_id` 找到它，把玩家放到此处。`_ready` 时自动加入 `"spawn_point"` group。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `spawn_id` | `String` | `"default"` | 出生点 id（与 `go_to_zone` 的 spawn_id 匹配）|

## 常量

`GROUP = "spawn_point"`

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在区域场景里放 SpawnPoint，spawn_id="from_village"
# Portal/ZoneDefinition 的 target_spawn_id 指向它
```

## 相关

- → [WorldService](WorldService.md) · [ZoneDefinition](ZoneDefinition.md) · [Portal](Portal.md)
- → [cookbook/15_world_zone_transition.md](../../cookbook/15_world_zone_transition.md)
