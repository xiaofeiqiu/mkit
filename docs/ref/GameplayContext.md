# GameplayContext

## 概念说明

GameplayContext 是一次玩法解析所需信息的上下文对象。负责携带 source、target、position、direction、ability_id、item_id、room_id、run_id、tags、amount 和 payload 等执行数据。它把散落的 Dictionary key 收拢起来，减少拼错 key 或漏传数据导致的 bug。

## 设计目的

作为 Condition、Action、Effect 之间传递数据的标准容器，避免各系统之间传裸 Dictionary。从命令创建 Context 后，后续所有处理器都读同一个对象，保证数据来源一致。

## 文件

`res://addons/mkit/kernel/context/gameplay_context.gd`

## 字段说明

- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **instigator**：真正发起者。例：召唤物造成伤害时 source 可以是召唤物，instigator 是玩家，用来归属击杀奖励。
- **ability_id**：技能定义 ID。例：ability.fireball_basic 让 AbilityController 找到火球定义并读取冷却、消耗和效果。
- **item_id**：物品定义 ID。例：item.potion_small 用于从 ContentRegistry 找到药水定义。
- **status_id**：状态定义 ID。例：status.burn 用于创建燃烧状态实例。
- **room_id**：房间定义或运行时房间 ID。例：room.dungeon_small_01 用于清房间、奖励和存档恢复。
- **run_id**：一局 run 的 ID。例：Analytics 可以把所有 room_cleared 和 reward_selected 归到同一局。
- **position**：世界位置。例：SpawnSceneEffect 用 position 决定投射物或掉落物生成在哪里。
- **direction**：方向。例：玩家按右方向释放火球，direction=Vector2.RIGHT。
- **amount**：通用数值。例：HealEffect 可以把 amount 当治疗量，RewardEffect 可以把 amount 当金币数量。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。

## 接口

```gdscript
class_name GameplayContext
extends RefCounted
var source: Node = null
var target: Node = null
var instigator: Node = null
var ability_id: String = ""
var item_id: String = ""
var status_id: String = ""
var room_id: String = ""
var run_id: String = ""
var position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var amount: float = 0.0
var tags: Array[String] = []
var payload: Dictionary = {}
static func from_command( command: GameCommand, source_node: Node = null, target_node: Node = null ) -> GameplayContext
func with_source(node: Node) -> GameplayContext
func with_target(node: Node) -> GameplayContext
func with_payload_value(key: String, value) -> GameplayContext
func get_payload_value(key: String, default_value = null)
func has_tag(tag: String) -> bool
```

## 函数使用场景

- **from_command()**：从命令快速构造上下文。例：CastAbilityCommand 到达玩家后，用命令 payload 中的 ability_id、direction、position 创建 GameplayContext，传给 AbilityController。
- **with_source()**：链式设置来源节点。例：构造上下文时指定施法者为玩家。
- **with_target()**：链式设置目标节点。例：指定效果作用的敌人节点。
- **with_payload_value()**：链式设置 payload 扩展字段。例：附加房间 ID 或额外参数。
- **get_payload_value()**：安全读取 payload 字段。例：Effect 从 payload 读取 spawn_parent 节点引用。
- **has_tag()**：检查上下文标签。例：条件判断当前上下文是否带有 fire 或 boss 标签。

## 使用示例

### 从 Command 创建 Context

```gdscript
func handle_cast_command(command: GameCommand) -> void:
    var context := GameplayContext.from_command(command, owner, null)
    context.ability_id = command.get_string("ability_id")
    context.source = owner
    context.target = _find_target_in_front()

    var ability_controller := owner.get_node("Controllers/AbilityController") as AbilityController
    ability_controller.cast(context.ability_id, context)
```

### 手动创建 Context

```gdscript
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy
ctx.position = enemy.global_position
ctx.direction = (enemy.global_position - player.global_position).normalized()
ctx.payload["room_id"] = "room_001"
```
