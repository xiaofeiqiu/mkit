# SpawnPoint

## 概念说明

SpawnPoint 是放置在区域场景中的落点标记 Marker2D。它带一个 spawn_id，并在 `_ready` 时加入 `spawn_point` 组，供 WorldRouter 在切换区域后按 ID 定位玩家应出现的位置。

## 设计目的

解决"出房间回到原位置"的问题：区域之间的落点不写死坐标，而是用命名的 SpawnPoint 表达。Portal 指定 target_spawn_id，WorldRouter 在目标场景里按相同 spawn_id 找到 SpawnPoint，把玩家移过去。

## 文件

`res://addons/mkit/modules/world/spawn_point.gd`

## 字段说明

- **spawn_id**：落点稳定 ID，在所属区域场景内唯一。WorldRouter 用它匹配 Portal.target_spawn_id 或 ZoneDefinition.default_spawn_id。

## 接口

```gdscript
class_name SpawnPoint
extends Marker2D
@export var spawn_id: String = "default"
func _ready() -> void
```

## 函数使用场景

- **`_ready()`**：节点进入场景树时把自身加入 `spawn_point` 组，使 WorldRouter 能通过 `get_nodes_in_group("spawn_point")` 枚举并按 spawn_id 匹配。

SpawnPoint 本身无主动行为，只作为被 WorldRouter 查询的位置标记。把它作为子节点摆进区域场景，并设置 spawn_id 即可。

## 使用示例

```gdscript
var gate := SpawnPoint.new()
gate.spawn_id = "village_gate"
gate.position = Vector2(64, 200)
village_scene.add_child(gate)
```
