# HitboxComponent

## 概念说明

HitboxComponent 是实体或投射物"能打到别人"的攻击判定区域（Area2D）。它在攻击生效帧检测进入范围的 HurtboxComponent，并把命中信息转成 DamageRequest 交给 CombatResolver 结算，最终由 HealthComponent 应用。攻击范围和伤害公式分开：剑挥到哪里由 Hitbox 负责，打多少血由 CombatResolver 负责。

## 设计目的

把"检测命中"逻辑封装到独立组件，使攻击行为（TimedAttackAction 控制开关）与伤害计算（CombatResolver）解耦。支持 faction 过滤、hit_once 规则和 on-hit 状态附加，无需在每个攻击动作中重复实现碰撞检测。

## 文件

`res://addons/mkit/modules/combat/hitbox_component.gd`

## 字段说明

- **active**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **base_damage**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **hit_once_per_activation**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **target_factions**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **hit_tags**：命中标签。例：melee、projectile、heavy_attack，可传给 CombatResolver 或状态触发逻辑。
- **on_hit_statuses**：代码字段。命中后尝试附加的状态配置列表。
- **source_entity**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **already_hit**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name HitboxComponent
extends Area2D
@export var active: bool = false
@export var base_damage: float = 1.0
@export var damage_type: String = "physical"
@export var element_type: String = "none"
@export var hit_once_per_activation: bool = true
@export var target_factions: Array[String] = ["enemy"]
@export var hit_tags: Array[String] = []
@export var on_hit_statuses: Array[Dictionary] = []
var source_entity: Node = null
var already_hit: Dictionary = {}
func set_active(value: bool) -> void
```

## 函数使用场景

- **`set_active(value)`**：开关 Hitbox 检测。`active=true` 时清空 `already_hit` 并开启 monitoring，由 TimedAttackAction 在攻击有效帧调用；`active=false` 时关闭，防止恢复帧继续造成伤害。
- **`_on_area_entered(area)`**（内部）：检测 HurtboxComponent 进入时，验证 faction、hit_once 规则和 `can_receive_damage`，然后创建 DamageRequest 并通过 CombatResolver 结算，最终调用目标 HealthComponent.apply_damage。

## 使用示例

### 攻击有效帧打开 hitbox

```gdscript
func enable_sword_hitbox() -> void:
    var hitbox := $Components/HitboxComponent as HitboxComponent
    hitbox.base_damage = 12.0
    hitbox.target_factions = ["enemy"]
    hitbox.set_active(true)
```

### 攻击结束关闭 hitbox

```gdscript
func disable_sword_hitbox() -> void:
    $Components/HitboxComponent.set_active(false)
```
