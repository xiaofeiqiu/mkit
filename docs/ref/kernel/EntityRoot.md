# EntityRoot

**层：** Kernel  
**文件：** `addons/mkit/kernel/entity/entity_root.gd`  
**继承：** `extends CharacterBody2D`

## 职责

实体场景根节点的便捷基类。约定 `EntityIdentity` / `StateMachine` / `CommandReceiver` 为直接子节点，并提供 `get_component()` / `get_controller()` 定位 `Components/` 与 `Controllers/` 下的兄弟节点。跨模块代码优先通过 `EntityContract` 调用这些入口。

## 约定布局

```
EntityRoot
├── EntityIdentity
├── StateMachine
├── CommandReceiver
├── Components/    （HealthComponent / StatsComponent …）
├── Controllers/   （AbilityController / InventoryController …）
└── Presentation/  （Sprite / AnimationPlayer）
```

## 字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `identity` | `EntityIdentity` | `@onready $EntityIdentity` |
| `state_machine` | `StateMachine` | `@onready $StateMachine` |
| `command_receiver` | `CommandReceiver` | `@onready $CommandReceiver` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_entity_id() -> String` | `String` | `identity.entity_id`（无则节点名）|
| `get_component(name_or_script) -> Node` | `Node` | `Components/<name>` 或匹配脚本 |
| `get_controller(name_or_script) -> Node` | `Node` | `Controllers/<name>` 或匹配脚本 |
| `has_contract_node(container, member) -> bool` | `bool` | 检查默认契约容器内成员是否存在 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var hp := (entity as EntityRoot).get_component("HealthComponent") as HealthComponent
var hp2 := EntityContract.get_component(entity, "HealthComponent") as HealthComponent
```

### 典型场景（Level 2）

```gdscript
# 自定义实体脚本，继承 EntityRoot
class_name PlayerEntity
extends EntityRoot


func _ready() -> void:
    add_to_group("player")
    var stats := get_component("StatsComponent") as StatsComponent
    var hp := get_component("HealthComponent") as HealthComponent
    if hp != null:
        hp.died.connect(func(_e: Node): print("玩家死亡"))
    var abilities := get_controller("AbilityController") as AbilityController
    print("玩家 %s 就绪，攻击力 %.0f" % [get_entity_id(), stats.get_stat_value("attack_power")])
```

## 相关

- → [EntityIdentity](EntityIdentity.md) · [EntityDefinition](../modules/EntityDefinition.md) · [EntitySpawner](../modules/EntitySpawner.md)
- → [architecture.md — 实体节点约定](../../architecture.md) · [cookbook/02_player_entity.md](../../cookbook/02_player_entity.md)
