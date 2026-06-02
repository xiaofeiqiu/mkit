# EntityRoot

## 概念说明

EntityRoot 是玩法实体场景的组合根节点。它把 `EntityIdentity`、`StateMachine`、`CommandReceiver`、Components、Controllers 和表现层串起来，并提供组件和控制器的快速查找入口。组合式实体设计比深继承更适合 RPG：玩家、敌人、召唤物、陷阱可以共享组件但拥有不同组合。

## 设计目的

提供一个统一的实体根节点基类，让外部系统（AI、战斗、UI）通过标准化的 `get_component()` 和 `get_controller()` 接口访问实体能力，而不是直接依赖深层节点路径或特定脚本类型。

## 文件

`res://addons/mkit/modules/entity/entity_root.gd`

## 接口

```gdscript
class_name EntityRoot
extends CharacterBody2D

@onready var identity: EntityIdentity = $EntityIdentity
@onready var state_machine: StateMachine = $StateMachine
@onready var command_receiver: CommandReceiver = $CommandReceiver

func get_entity_id() -> String:
    if identity == null:
        return name
    return identity.entity_id

func get_component(component_name: String) -> Node:
    return get_node_or_null("Components/%s" % component_name)

func get_controller(controller_name: String) -> Node:
    return get_node_or_null("Controllers/%s" % controller_name)
```

## 函数使用场景

- **`get_entity_id()`**：获取实体的运行时唯一 ID。用于伤害事件的来源/目标归属、仇恨系统追踪、日志记录等场景。
- **`get_component(component_name)`**：按名称查找 Components 子节点。外部系统（如战斗系统）通过 `get_component("HealthComponent")` 取到 HealthComponent，不需要知道具体场景路径。
- **`get_controller(controller_name)`**：按名称查找 Controllers 子节点。例如奖励系统通过 `get_controller("InventoryController")` 添加物品，AI 通过 `get_controller("AbilityController")` 施放技能。

## 使用示例

```gdscript
func print_player_info(player: EntityRoot) -> void:
    print(player.get_entity_id())

    var health := player.get_component("HealthComponent") as HealthComponent
    print("HP: ", health.current_hp)

    var abilities := player.get_controller("AbilityController") as AbilityController
    print("Has fireball: ", abilities.has_ability("ability.fireball_basic"))
```
