# ItemDefinition

## 概念说明

ItemDefinition 是一个物品类型的静态定义，例如小药水、铁剑、钥匙、金币袋。它定义物品 ID、类型、是否可堆叠、装备槽、使用效果、属性修改和标签。掉落表、商店、背包、装备和存档都应该引用 `item.potion_small` 这种稳定定义 ID。

## 设计目的

把物品的全部静态属性集中到一个 Resource 文件，使 InventoryController、EquipmentController、LootSystem 和存档系统都通过稳定 ID 引用物品，不直接依赖场景路径或运行时实例。

## 文件

`res://addons/mkit/modules/inventory/item_definition.gd`

## 接口

```gdscript
class_name ItemDefinition
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: String = "material" # weapon, armor, consumable, material, quest
@export var rarity: String = "common"
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var equipment_slot: String = ""
@export var tags: Array[String] = []
@export var use_conditions: Array[Condition] = []
@export var use_effects: Array[GameEffect] = []
@export var stat_modifiers: Array[StatModifierDefinition] = []
```

## 函数使用场景

ItemDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后注册到 ContentRegistry。

- **`item_type`**：InventoryController 和 EquipmentController 据此判断物品的处理方式（consumable 可使用，weapon/armor 可装备）。
- **`stackable` / `max_stack`**：InventoryController.add_item() 据此决定是否在已有堆叠上增加数量。
- **`equipment_slot`**：EquipmentController.can_equip() 校验物品的 equipment_slot 是否与目标槽位匹配。
- **`use_effects`**：玩家使用消耗品时，由 EffectExecutor 执行此列表。
- **`stat_modifiers`**：EquipmentController 装备物品时，通过 StatsComponent.add_modifier 施加；卸下时移除。

## 使用示例

### 铁剑

```gdscript
var sword := ItemDefinition.new()
sword.item_id = "item.sword_iron"
sword.display_name = "Iron Sword"
sword.item_type = "weapon"
sword.rarity = "common"
sword.stackable = false
sword.equipment_slot = "weapon"
sword.tags = ["weapon", "sword", "melee"]

var attack_mod := StatModifierDefinition.new()
attack_mod.modifier_id = "mod.sword_iron.attack"
attack_mod.stat_id = "attack_power"
attack_mod.operation = StatModifierDefinition.Operation.FLAT_ADD
attack_mod.value = 5.0
sword.stat_modifiers = [attack_mod]
```

### 小药水

```gdscript
var potion := ItemDefinition.new()
potion.item_id = "item.potion_small"
potion.display_name = "Small Potion"
potion.item_type = "consumable"
potion.stackable = true
potion.max_stack = 10

var heal := HealEffect.new()
heal.effect_id = "effect.potion_small_heal"
heal.amount = 25.0
potion.use_effects = [heal]
```
