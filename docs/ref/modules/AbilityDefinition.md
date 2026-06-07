# AbilityDefinition

**层：** Module  
**文件：** `addons/mkit/modules/combat/abilities/ability_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

技能的静态配置（`.tres`）：冷却、充能、消耗、施法时间、射程、条件与 effect 链。由 `AbilityController` 按 `ability_id` 从 `ContentService` 拉取。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `ability_id` | `String` | `""` | 唯一 id（`get_content_id` 返回它）|
| `display_name` | `String` | `""` | 显示名 |
| `description` | `String` | `""` | 描述（multiline）|
| `icon` | `Texture2D` | — | 图标 |
| `cooldown` | `float` | `1.0` | 冷却秒数 |
| `charges` | `int` | `1` | 充能层数 |
| `cost_type` | `String` | `"none"` | 消耗的资源池 id（对应 `ResourcePoolComponent`）|
| `cost_amount` | `float` | `0.0` | 消耗量 |
| `cast_time` | `float` | `0.0` | `>0` 走 `CastAction`，`0` 为瞬发 |
| `range` | `float` | `0.0` | 射程（配合条件使用）|
| `tags` | `Array[String]` | `[]` | 标签 |
| `conditions` | `Array[Condition]` | `[]` | 施放门槛 |
| `effects` | `Array[GameEffect]` | `[]` | 施放产生的效果链 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 一般在 Inspector 配 .tres；代码读取：
var content := ServiceRegistry.get_service("content") as ContentService
var def := content.get_resource("fireball") as AbilityDefinition
print("%s 冷却 %.1fs" % [def.display_name, def.cooldown])
```

## 相关

- → [AbilityController](AbilityController.md)（注册/施放）· [AbilityInstance](AbilityInstance.md)（运行时）· [CastAction](CastAction.md)
- → [cookbook/05_ability.md](../../cookbook/05_ability.md) · [pipeline.md — Ability Cast](../../pipeline.md#5-ability-cast)
