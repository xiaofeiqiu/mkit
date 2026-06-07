# RoomLoader

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/room_loader.gd`  
**继承：** `extends RefCounted`

## 职责

加载房间场景。通过 `ContentService` 查 `RoomDefinition`，实例化其 `scene_path`，清空容器旧房间，并返回场景内 `RoomController`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `last_error` | `String` | `""` | 最近一次失败原因 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `load_room(room_definition_id: String, container: Node) -> RoomController` | `RoomController` | 成功返回 controller；失败返回 `null` 并写 `last_error` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var loader := RoomLoader.new()
var controller: RoomController = loader.load_room("room.combat_a", room_root)
```

### 典型场景（Level 2）

```gdscript
func load_or_fail(room_id: String, container: Node) -> RoomController:
    var loader := RoomLoader.new()
    var controller: RoomController = loader.load_room(room_id, container)
    if controller == null:
        push_warning(loader.last_error)
        return null
    controller.enter_room()
    return controller
```

## 相关

- → [RoomDefinition](RoomDefinition.md) · [RoomController](RoomController.md) · [RunDirector](RunDirector.md)

