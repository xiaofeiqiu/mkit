# RoomDefinition

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/room_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

房间静态配置。`RunDirector` / `RoomLoader` 用 `room_id` 找到场景路径，`RoomController` 用 enemy / reward 列表生成内容。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `room_id` | `String`（@export）| `""` | 内容 ID |
| `scene_path` | `String`（@export）| `""` | 房间场景路径，需包含子节点 `RoomController` |
| `room_type` | `String`（@export）| `"combat"` | 房间类型 |
| `difficulty_rating` | `int`（@export）| `1` | 难度标记 |
| `size` | `Vector2i`（@export）| `Vector2i(1, 1)` | 网格尺寸标记 |
| `tags` | `Array[String]`（@export）| `[]` | 分类标签 |
| `enemy_spawn_ids` | `Array[String]`（@export）| `[]` | 要 spawn 的 `EntityDefinition` ID |
| `reward_pool_ids` | `Array[String]`（@export）| `[]` | 奖励池 ID |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_content_id() -> String` | `String` | 返回 `room_id` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var room: RoomDefinition = content.get_resource("room.combat_a") as RoomDefinition
print(room.scene_path)
```

### 典型场景（Level 2）

```gdscript
func validate_room(room_id: String) -> bool:
    var content: ContentService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
    var room: RoomDefinition = content.get_resource(room_id) as RoomDefinition
    if room == null or room.scene_path == "":
        return false
    return ResourceLoader.exists(room.scene_path, "PackedScene")
```

## 相关

- → [RoomController](RoomController.md) · [RoomLoader](RoomLoader.md) · [RunDirector](RunDirector.md)
- → [cookbook/07_room.md](../../cookbook/07_room.md) · [pipeline.md — Room / Run](../../pipeline.md#18-room--run)

