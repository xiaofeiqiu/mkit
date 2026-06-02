# EntityIdentity

## 概念说明

EntityIdentity 是玩法实体的身份证节点。它负责保存 `entity_id`、`definition_id`、`faction`、`tags` 等识别信息。系统需要判断"这是玩家、敌人、Boss、召唤物还是投射物"，但不应该依赖节点名字或具体脚本类；EntityIdentity 提供统一的身份查询入口。

## 设计目的

把实体的身份信息（运行时 ID、静态定义 ID、阵营、标签）集中到一个组件里，让战斗系统、AI、条件判断、日志和事件都能通过统一接口查询实体身份，而无需依赖具体节点类型或场景路径。

## 文件

`res://addons/mkit/modules/entity/entity_identity.gd`

## 字段说明

- **entity_id**：运行时实体 ID。例：场景里有三个 goblin，它们都来自 enemy.goblin_basic，但运行时应分别是 goblin_001、goblin_002、goblin_003，这样伤害、死亡、AI 目标和 Debug 才能指向具体个体。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **display_name**：代码字段。显示名称。
- **faction**：阵营。例：player 的攻击只伤害 enemy faction，敌人之间不会互相误伤。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。

## 接口

```gdscript
class_name EntityIdentity
extends Node
@export var entity_id: String = ""
@export var definition_id: String = ""
@export var display_name: String = ""
@export var faction: String = "neutral"
@export var tags: Array[String] = []
func has_tag(tag: String) -> bool
func has_any_tag(input_tags: Array[String]) -> bool
func is_faction(value: String) -> bool
```

## 函数使用场景

- **`_ready()`**：节点进入场景树时，若 `entity_id` 未在 Inspector 中设置，则自动生成一个基于节点名和微秒时间戳的运行时 ID。适用于动态生成的敌人场景，确保每个实例拥有唯一身份。
- **`has_tag(tag)`**：检查实体是否具有指定标签。用于条件判断，例如战斗系统判断某个实体是否为 `"boss"`，奖励系统检查玩家是否有 `"fire_element"` 标签。
- **`has_any_tag(input_tags)`**：检查实体是否具有给定标签列表中的任意一个。用于更宽松的过滤，例如 AoE 效果检查目标是否属于 `["enemy", "boss"]` 之一。
- **`is_faction(value)`**：检查实体所属阵营是否与指定值匹配。用于战斗系统判断攻击目标是否为敌方阵营，防止友伤或被误击。

## 使用示例

### 在 Player 场景中配置身份

```gdscript
func _ready() -> void:
    var identity := $EntityIdentity as EntityIdentity
    identity.entity_id = "player_001"
    identity.definition_id = "entity.player.default"
    identity.faction = "player"
    identity.tags = ["player", "living", "controllable"]
```

### 判断目标 faction

```gdscript
func is_enemy(target: Node) -> bool:
    var identity := target.get_node_or_null("EntityIdentity") as EntityIdentity
    return identity != null and identity.faction == "enemy"
```
