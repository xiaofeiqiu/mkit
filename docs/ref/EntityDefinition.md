# EntityDefinition

## 概念说明

EntityDefinition 是可生成实体的静态配置资源，例如玩家默认形态、goblin、slime、陷阱或召唤物。它定义实体内容 ID、场景路径、默认阵营、标签、基础属性、初始技能和掉落表。RoomController、Spawner、存档恢复和调试工具都需要通过稳定 ID 找到实体场景，不能把 definition_id 到 scene_path 的映射写散。

## 设计目的

把实体的静态配置集中到一个 Resource 文件，让房间生成、存档恢复、内容校验都只引用稳定的 `entity_definition_id`，而不是散落的场景路径或硬编码的节点初始化逻辑。

## 文件

`res://addons/mkit/modules/entity/entity_definition.gd`

## 字段说明

- **entity_definition_id**：实体定义 ID。例：enemy.goblin_basic 用于房间生成、存档恢复和 ContentRegistry 查询。
- **display_name**：代码字段。显示名称。
- **scene_path**：实体场景路径。例：enemy.goblin_basic 指向 `res://game/enemies/goblin_basic.tscn`。
- **default_faction**：默认阵营。例：敌人定义默认 faction=enemy，生成后 EntityIdentity 会继承它。
- **tags**：标签集合。例：enemy、boss、summon、trap，用于条件、AI 和伤害过滤。
- **base_stats**：基础属性表。例：goblin 的 max_hp=30、attack_power=8、move_speed=110。
- **starting_ability_ids**：初始技能 ID。例：boss 生成后自动注册 ability.boss_rage。
- **loot_table_id**：死亡掉落表 ID。例：enemy.goblin_basic 死亡后使用 loot.goblin_common。

## 接口

```gdscript
class_name EntityDefinition
extends Resource
@export var entity_definition_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var default_faction: String = "neutral"
@export var tags: Array[String] = []
@export var base_stats: Dictionary = {}
@export var starting_ability_ids: Array[String] = []
@export var loot_table_id: String = ""
```

## 函数使用场景

EntityDefinition 是纯数据 Resource，无公开方法；所有字段通过 Inspector 或代码赋值，由 EntitySpawner 读取后应用到生成的实体上。

- **`entity_definition_id`**：在 ContentRegistry 中唯一标识该定义，RoomDefinition.enemy_spawn_ids 和存档都引用此 ID。
- **`scene_path`**：EntitySpawner 加载并实例化此路径的 PackedScene。
- **`base_stats`**：EntitySpawner 生成后写入实体 StatsComponent 的初始属性值。
- **`starting_ability_ids`**：EntitySpawner 生成后调用 AbilityController.register_ability 注册的初始技能列表。
- **`loot_table_id`**：敌人死亡时 LootSystem 使用的掉落表 ID。

## 使用示例

```gdscript
var goblin := EntityDefinition.new()
goblin.entity_definition_id = "enemy.goblin_basic"
goblin.display_name = "Goblin"
goblin.scene_path = "res://game/enemies/goblin_basic.tscn"
goblin.default_faction = "enemy"
goblin.tags = ["enemy", "living", "melee"]
goblin.base_stats = {
    "max_hp": 30.0,
    "attack_power": 8.0,
    "move_speed": 110.0
}
goblin.loot_table_id = "loot.goblin_common"
```
