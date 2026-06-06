# ItemInstance

## 概念说明

ItemInstance 是背包里一件具体物品或一组堆叠物品。它记录 instance_id、definition_id、数量、耐久、随机词缀、强化等级和运行时元数据。两把铁剑都来自 item.sword_iron，但一把 +12% 暴击、一把耐久 30%，所以必须有不同实例。

## 设计目的

区分静态物品定义（ItemDefinition）和运行时物品实例（ItemInstance），使同一物品定义可以生成具有独立属性（词缀、耐久、强化等级）的实例，并支持完整的存档/读档序列化。

## 文件

`res://addons/mkit/modules/inventory/item_instance.gd`

## 字段说明

- **instance_id**：运行时物品/对象实例 ID。例：两把 Iron Sword 都来自 item.sword_iron，但一把有暴击词缀、一把有耐久损耗，所以必须有不同 instance_id。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **quantity**：数量。例：药水 stack 数量是 3，金币掉落数量是 20。
- **rolled_affixes**：随机词缀。例：同一把 item.sword_iron 可以随机出 +12% crit chance。
- **durability**：耐久。例：武器每次攻击降低耐久，归零后需要修理或失效。
- **upgrade_level**：强化等级。例：+3 铁剑比普通铁剑有更高攻击 modifier。
- **metadata**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name ItemInstance
extends RefCounted
var instance_id: String = ""
var definition_id: String = ""
var quantity: int = 1
var rolled_affixes: Array[StatModifier] = []
var durability: float = 1.0
var upgrade_level: int = 0
var metadata: Dictionary = {}
static func create(def_id: String, qty: int = 1) -> ItemInstance
func to_save_data() -> Dictionary
static func from_save_data(data: Dictionary) -> ItemInstance
```

## 函数使用场景

- **`create(definition_id, quantity)`**：工厂方法，生成一个新的 ItemInstance，自动生成唯一 instance_id（基于微秒时间戳）。LootSystem 生成掉落、GrantItemEffect 创建物品时调用。
- **`to_save_data()`**：将实例序列化为 Dictionary，包含 instance_id、definition_id、quantity、durability、upgrade_level、metadata 和 rolled_affixes，供 InventoryController 与 EquipmentController 调用。
- **`from_save_data(data)`**：静态反序列化方法，从存档 Dictionary 恢复 ItemInstance 和 rolled_affixes，供 InventoryController.from_save_data() 与 EquipmentController.from_save_data() 调用。

## 使用示例

```gdscript
# 创建物品实例
var sword_instance := ItemInstance.create("item.sword_iron", 1)
sword_instance.durability = 0.85
sword_instance.metadata["found_in_room"] = "room_003"

# 存档 / 读档
var data := sword_instance.to_save_data()
var restored := ItemInstance.from_save_data(data)
print(restored.definition_id) # "item.sword_iron"
```
