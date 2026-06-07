# HurtboxComponent

**层：** Module  
**文件：** `addons/mkit/modules/combat/hurtbox_component.gd`  
**继承：** `extends Area2D`

## 职责

受击判定盒。被 `HitboxComponent` 命中时提供"伤害归属到哪个实体"以及伤害倍率/标签。挂在可被攻击的实体上。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `owner_path` | `NodePath` | `"../.."` | 指向实体根（伤害归属）|
| `can_receive_damage` | `bool` | `true` | 是否可受击（无敌帧可置 false）|
| `damage_multiplier` | `float` | `1.0` | 受击倍率（弱点 >1）|
| `damage_tags` | `Array[String]` | `[]` | 附加到伤害的标签 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_owner_entity() -> Node` | `Node` | 返回 `owner_path` 指向的实体 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在实体下挂 HurtboxComponent + CollisionShape2D
# owner_path 默认 "../.." 指向 EntityRoot；弱点部位设 damage_multiplier = 2.0
```

## 相关

- → [HitboxComponent](HitboxComponent.md) · [cookbook/04_attack_action.md](../../cookbook/04_attack_action.md)
