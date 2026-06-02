# HurtboxComponent

## 概念说明

HurtboxComponent 是实体"可以被打中"的受击区域（Area2D）。它表示角色身体、弱点、护盾范围等可被 HitboxComponent 命中的区域，并提供 `damage_multiplier` 和 `damage_tags` 让不同区域具有不同的受击属性。一个敌人可以有身体和头部弱点两个 Hurtbox，也可以短暂无敌；这些受击规则不应该写进伤害公式里。

## 设计目的

把"哪里能被打中、被打中时附加什么修改"分离到独立的 Area2D 组件，使无敌帧（临时关闭 `can_receive_damage`）、弱点判定（`damage_multiplier`）和命中标签（`damage_tags`）可以灵活配置，而不影响伤害公式本身。

## 文件

`res://addons/mkit/modules/combat/hurtbox_component.gd`

## 接口

```gdscript
class_name HurtboxComponent
extends Area2D

@export var owner_path: NodePath = NodePath("../..")
@export var can_receive_damage: bool = true
@export var damage_multiplier: float = 1.0
@export var damage_tags: Array[String] = []

func get_owner_entity() -> Node:
    return get_node_or_null(owner_path)
```

## 函数使用场景

- **`get_owner_entity()`**：HitboxComponent 检测到碰撞后调用此方法，获取 Hurtbox 所属的实体节点（通常是 CharacterBody2D），再从实体上查找 HealthComponent 应用伤害。
- **`can_receive_damage`**：Dash 无敌帧期间设为 false，HitboxComponent 会跳过该 Hurtbox 的命中检测。
- **`damage_multiplier`**：HitboxComponent 将 `base_damage * hurtbox.damage_multiplier` 作为请求的 base_amount，实现弱点或护盾的倍率。
- **`damage_tags`**：追加到 DamageRequest.tags，CombatResolver 或后续效果可据此判断命中区域类型（如 `weak_point`、`shield`）。

## 使用示例

### Enemy 场景结构

```text
Enemy.tscn
  CharacterBody2D
    EntityIdentity
    Components
      HealthComponent
      StatsComponent
      HurtboxComponent (body)
      HurtboxComponent (head_weak_point)
```

### Inspector 配置弱点 Hurtbox

```text
HurtboxComponent (head_weak_point):
  owner_path = "../.."
  can_receive_damage = true
  damage_multiplier = 1.5
  damage_tags = ["weak_point"]
```

### 无敌帧设置

```gdscript
# Dash 开始时
$Components/HurtboxComponent.can_receive_damage = false
# Dash 结束时
$Components/HurtboxComponent.can_receive_damage = true
```
