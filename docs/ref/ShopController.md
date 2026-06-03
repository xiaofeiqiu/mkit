# ShopController

## 概念说明

ShopController 是商店域的运行时 Node，注册为 ServiceRegistry 的 `shop` service。它负责打开/关闭商店、计算买卖价格、校验交易可行性，并通过 ProgressionSystem 扣加货币、通过买家的 InventoryController 增删物品，最后发出交易信号与 EventRouter 事件。

## 设计目的

把交易层薄薄地架在已有的 inventory 与 progression 之上：ShopController 不持有货币也不持有背包，只编排"扣币 + 入包"或"出包 + 加币"的原子流程，并保证任一步失败时回滚（例如入包失败退还货币），让商店成为可复用的通用机制。

## 文件

`res://addons/mkit/modules/shop/shop_controller.gd`

## 字段说明

- **shop_opened**：成功 open_shop 时发出，携带 shop_id。
- **item_purchased**：买入成功时发出，携带 item_id、数量与实付总价。
- **item_sold**：卖出成功时发出，携带 item_id、数量与所得总价。
- **transaction_failed**：任一交易被拒绝时发出，携带 item_id 与失败原因文本。
- **current_shop**：当前打开的 ShopDefinition；未开店时为 null。
- **content**：ContentRegistry 引用。为空时会尝试从 ServiceRegistry 的 `content` service 懒加载。

## 接口

```gdscript
class_name ShopController
extends Node
signal shop_opened(shop_id: String)
signal item_purchased(item_id: String, quantity: int, total_cost: int)
signal item_sold(item_id: String, quantity: int, total_gain: int)
signal transaction_failed(item_id: String, reason: String)
var current_shop: ShopDefinition = null
var content: ContentRegistry = null
func open_shop(shop_id: String) -> bool
func close_shop() -> void
func get_buy_price(item_id: String) -> int
func get_sell_price(item_id: String) -> int
func can_buy(item_id: String, quantity: int, buyer: Node) -> bool
func buy(item_id: String, quantity: int, buyer: Node) -> bool
func sell(item_instance_id: String, quantity: int, seller: Node) -> bool
func get_definition(shop_id: String) -> ShopDefinition
```

## 函数使用场景

- **`open_shop(shop_id)`**：玩家与商人互动或 UI 打开店铺时调用，从 ContentRegistry 取 ShopDefinition 设为 current_shop 并发 shop_opened；定义缺失时返回 false。
- **`close_shop()`**：关闭店铺界面时清空 current_shop。
- **`get_buy_price(item_id)`**：UI 显示价格或买入前计算单价；entry.price_override >= 0 时直接返回该值，否则按 ItemDefinition.value × buy_price_multiplier；无店或无 entry 返回 -1。
- **`get_sell_price(item_id)`**：计算单件卖价（ItemDefinition.value × sell_price_multiplier）；无店或物品未知返回 -1。
- **`can_buy(item_id, quantity, buyer)`**：UI 在启用购买按钮前预检；内部统一走拦截原因判定（无店/数量非法/不售/未知物品/条件未满足/缺货/背包满/货币不足），无拦截原因时返回 true。
- **`buy(item_id, quantity, buyer)`**：执行买入——先扣买家货币，再向其 InventoryController 入包；入包失败会退还货币并发 transaction_failed；成功后递减 entry 库存、发 item_purchased 和 EventRouter.emit_item_purchased。
- **`sell(item_instance_id, quantity, seller)`**：执行卖出——按实例 ID 在背包定位物品，校验 allow_sell/数量/归属后移除并给卖家加货币，发 item_sold 和 EventRouter.emit_item_sold；任一校验失败发 transaction_failed。
- **`get_definition(shop_id)`**：从 ContentRegistry 读取 ShopDefinition；shop_id 为空或内容缺失时返回 null。

## 使用示例

```gdscript
var shop := ServiceRegistry.get_service("shop") as ShopController
shop.open_shop("shop.village_general")
if shop.can_buy("item.potion_small", 1, player):
    shop.buy("item.potion_small", 1, player)
```
