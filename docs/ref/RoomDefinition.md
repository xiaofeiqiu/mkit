# RoomDefinition

## 概念说明

RoomDefinition 是一个房间类型的静态定义。它定义房间场景路径、房间类型、难度、尺寸、敌人生成规则和奖励池。地牢生成器应该选择 `room.dungeon_small_01` 这种稳定定义，而不是直接散落加载场景路径。

## 设计目的

把房间的全部静态属性集中到一个 Resource 文件，使 DungeonGenerator、RoomController 和存档系统都通过稳定 ID 引用房间，不直接依赖场景路径或硬编码的敌人生成逻辑。

## 文件

`res://addons/mkit/modules/room/room_definition.gd`

## 接口

```gdscript
class_name RoomDefinition
extends Resource

@export var room_id: String = ""
@export var scene_path: String = ""
@export var room_type: String = "combat" # combat, shop, treasure, boss, event
@export var difficulty_rating: int = 1
@export var size: Vector2i = Vector2i(1, 1)
@export var tags: Array[String] = []
@export var enemy_spawn_ids: Array[String] = []
@export var reward_pool_ids: Array[String] = []
```

## 函数使用场景

RoomDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后注册到 ContentRegistry。

- **`scene_path`**：RunDirector._load_room() 通过此路径加载 PackedScene 并实例化房间场景。
- **`enemy_spawn_ids`**：RoomController.spawn_enemies() 对每个 ID 调用 EntitySpawner.spawn_entity()。
- **`reward_pool_ids`**：RoomController.generate_reward() 将此列表传给 RewardSystem.generate_options()，生成清房间奖励。
- **`room_type`**：DungeonGenerator 据此决定布局结构（combat、boss、treasure 等具有不同 UI 和行为）。

## 使用示例

```gdscript
var room := RoomDefinition.new()
room.room_id = "room.dungeon_small_01"
room.scene_path = "res://game/rooms/dungeon_small_01.tscn"
room.room_type = "combat"
room.difficulty_rating = 1
room.enemy_spawn_ids = [
    "enemy.goblin_basic",
    "enemy.goblin_basic",
    "enemy.slime_basic"
]
room.reward_pool_ids = [
    "reward.attack_plus_20",
    "reward.max_hp_plus_10",
    "reward.potion_bundle"
]
```
