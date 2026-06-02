# HealthComponent

## 概念说明

HealthComponent 是实体生命值状态的拥有者。它追踪 current/max HP、应用伤害和治疗、并在 HP 归零时触发死亡流程。伤害公式、死亡流程和 UI 显示都依赖 HP，但扣血本身应该只有一个明确入口。

## 设计目的

成为所有扣血和治疗操作的唯一权威入口，确保伤害结算、死亡触发、HP 变化通知和 on-hit 状态附加都在同一处发生，避免多处散落修改 HP 导致 UI、事件和存档不同步。

## 文件

`res://addons/mkit/modules/health/health_component.gd`

## 接口

```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: float, max_value: float)
signal damaged(result: DamageResult)
signal healed(amount: float, source: Node)
signal died(owner_entity: Node)

@export var current_hp: float = 100.0
@export var destroy_on_death: bool = false

var dead: bool = false
var stats: StatsComponent = null

func _ready() -> void: ...
func get_max_hp() -> float: ...
func apply_damage(result: DamageResult) -> void: ...
func heal(amount: float, source: Node = null) -> void: ...
func die(killer: Node = null) -> void: ...
func revive(percent: float = 1.0) -> void: ...
```

## 函数使用场景

- **`get_max_hp()`**：从 StatsComponent 读取 `max_hp` 属性的当前值（含 modifier），供 UI 显示血量条和 HealthComponent 内部 clamp 使用。
- **`apply_damage(result)`**：应用 CombatResolver 产出的 DamageResult。扣除 `final_amount`，将 on-hit 状态交给 StatusEffectController 施加，发出 `damaged` 和 `damage_applied` 事件，HP 归零时调用 `die()`。是所有伤害路径（Hitbox 命中、DealDamageEffect）的最终汇聚点。
- **`heal(amount, source)`**：将 current_hp 增加 amount，但不超过 max_hp。发出 `healed` 和 `health_changed` 信号。已死亡实体不响应治疗。
- **`die(killer)`**：标记 dead=true，将 current_hp 设为 0，发出 `died` 信号和 EventRouter `entity_died` 事件。若 `destroy_on_death=true` 则调用 `queue_free`。
- **`revive(percent)`**：复活实体，将 current_hp 恢复到 max_hp 的指定比例，重置 dead=false，发出 `health_changed`。

## 使用示例

### 受到伤害

```gdscript
var damage := CombatResolver.get_default().resolve(request)
var health := enemy.get_node("Components/HealthComponent") as HealthComponent
health.apply_damage(damage)
```

### 治疗

```gdscript
var health := player.get_node("Components/HealthComponent") as HealthComponent
health.heal(25.0, player)
```

### 监听死亡

```gdscript
func _ready() -> void:
    $Components/HealthComponent.died.connect(_on_died)

func _on_died(owner_entity: Node) -> void:
    print(owner_entity.name, " died")
```
