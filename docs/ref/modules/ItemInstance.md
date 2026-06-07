# ItemInstance

**层：** Module  
**文件：** `addons/mkit/modules/inventory/item_instance.gd`  
**继承：** `extends RefCounted`

## 职责

物品的**运行时实例**：背包里实际存在的一摞物品，带唯一 `instance_id`、数量、随机词条、耐久、强化等级。可序列化。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `instance_id` | `String` | `""` | 实例唯一 id |
| `definition_id` | `String` | `""` | 对应 `ItemDefinition.item_id` |
| `quantity` | `int` | `1` | 数量 |
| `rolled_affixes` | `Array[StatModifier]` | `[]` | 随机词条 |
| `durability` | `float` | `1.0` | 耐久 |
| `upgrade_level` | `int` | `0` | 强化等级 |
| `metadata` | `Dictionary` | `{}` | 自定义数据 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static create(def_id, qty := 1) -> ItemInstance` | `ItemInstance` | 构造一摞 |
| `to_save_data()` / `static from_save_data(data)` | — | 序列化 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var item := ItemInstance.create("item.potion", 3)
inventory.add_item(item)
```

## 相关

- → [ItemDefinition](ItemDefinition.md) · [InventoryController](InventoryController.md)
