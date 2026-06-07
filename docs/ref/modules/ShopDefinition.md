# ShopDefinition

**层：** Module  
**文件：** `addons/mkit/modules/shop/shop_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

商店的静态定义（`.tres`）：货币、商品条目、买卖价倍率、是否收购。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `shop_id` | `String` | `""` | 唯一 id |
| `display_name` | `String` | `""` | 店名 |
| `currency_id` | `String` | `"gold"` | 货币（`ProgressionService` 货币）|
| `entries` | `Array[ShopEntry]` | `[]` | 商品 |
| `buy_price_multiplier` | `float` | `1.0` | 买价 = `value × 它` |
| `sell_price_multiplier` | `float` | `0.5` | 卖价 = `value × 它` |
| `allow_sell` | `bool` | `true` | 是否收购玩家物品 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_entry(item_id) -> ShopEntry` | — | 按物品查条目 |

## 相关

- → [ShopEntry](ShopEntry.md) · [ShopService](ShopService.md)
- → [cookbook/14_shop.md](../../cookbook/14_shop.md)
