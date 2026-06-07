# ShopEntry

**层：** Module  
**文件：** `addons/mkit/modules/shop/shop_entry.gd`  
**继承：** `extends Resource`

## 职责

商店里的一个商品条目：物品、可选定价、库存、上架条件。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `item_id` | `String` | `""` | 物品 id |
| `price_override` | `int` | `-1` | `>=0` 固定此价；`-1` 用 `value × buy_price_multiplier` |
| `stock` | `int` | `-1` | `-1` 无限；`>=0` 有限库存 |
| `conditions` | `Array[Condition]` | `[]` | 上架/可购买条件 |

## 相关

- → [ShopDefinition](ShopDefinition.md) · [ShopService](ShopService.md)
