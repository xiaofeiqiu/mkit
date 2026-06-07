# ShopService

**层：** Module  
**文件：** `addons/mkit/modules/shop/shop_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"shop"`

## 职责

买卖结算。`open_shop` 设当前店，`buy`/`sell` 用 `SpendCurrencyEffect`/`AddCurrencyEffect` 结算 **`ProgressionService` 货币** 并增删 `InventoryController` 物品；买入失败自动退款。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `open_shop(shop_id) -> bool` | `bool` | 打开商店 |
| `close_shop() -> void` | — | 关闭 |
| `get_buy_price(item_id) -> int` | `int` | 买价 |
| `get_sell_price(item_id) -> int` | `int` | 卖价 |
| `can_buy(item_id, quantity, buyer) -> bool` | `bool` | 能否购买 |
| `buy(item_id, quantity, buyer) -> bool` | `bool` | 购买 |
| `sell(item_instance_id, quantity, seller) -> bool` | `bool` | 出售（按**实例 id**）|

## 信号

`shop_opened(id)` · `item_purchased(item_id, quantity, total_cost)` · `item_sold(item_id, quantity, total_gain)` · `transaction_failed(item_id, reason)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var shop := ServiceRegistry.get_service("shop") as ShopService
shop.open_shop("shop.village")
shop.buy("item.potion", 1, player)
```

### 典型场景（Level 2）

```gdscript
# 购买，覆盖钱不够 / 缺货 / 背包满
func try_buy(player: Node, item_id: String) -> void:
    var shop := ServiceRegistry.get_service("shop") as ShopService
    shop.transaction_failed.connect(func(id: String, reason: String):
        print("买不了 %s：%s" % [id, reason])      # Insufficient currency / Out of stock / Inventory…
    )
    if shop.can_buy(item_id, 1, player):
        shop.buy(item_id, 1, player)               # 成功路径：扣 gold、入包、发 item_purchased
```

> 货币在 `ProgressionService`（不是实体 `ResourcePoolComponent`）；买家须有 `Controllers/InventoryController`。

## 相关

- → [ShopDefinition](ShopDefinition.md) · [ShopEntry](ShopEntry.md) · [InventoryController](InventoryController.md) · [ref/modules/ProgressionService.md](ProgressionService.md)
- → [pipeline.md — Shop Purchase](../../pipeline.md#16-shop-purchase) · [cookbook/14_shop.md](../../cookbook/14_shop.md)
