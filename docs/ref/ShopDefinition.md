# ShopDefinition

## 概念说明

ShopDefinition 是商店的静态 Resource 配置。它描述商店 ID、展示名称、使用的货币、可交易的条目列表，以及买入/卖出的全局价格倍率。具体商店内容（卖什么、定多少价）由游戏项目在 `game/` 中创建资源，addon 只提供通用交易结构。

## 设计目的

让一个商店可以通过数据组合 inventory 物品与 progression 货币，而不是在系统代码中硬编码店内商品与价格。价格既可由 ItemDefinition.value 乘倍率推导，也可由 ShopEntry 覆盖。

## 文件

`res://addons/mkit/modules/shop/shop_definition.gd`

## 字段说明

- **shop_id**：商店稳定 ID。例：`shop.village_general`，供 ContentRegistry、存档和 ShopController 查找。
- **display_name**：商店显示名称。UI 可直接读取。
- **currency_id**：交易使用的货币 ID，对应 ProgressionSystem 中的货币。例：`gold`。
- **entries**：商店条目列表。每个元素是 ShopEntry，描述一件可买卖的物品及其价格/库存覆盖。
- **buy_price_multiplier**：买入价格倍率。仅作用于由 ItemDefinition.value 推导的基础价；当 ShopEntry.price_override >= 0 时不参与计算。
- **sell_price_multiplier**：卖出价格倍率。卖价始终由 ItemDefinition.value 乘此倍率得到。
- **allow_sell**：是否允许玩家向该商店出售物品。为 false 时所有 sell 调用被拒绝。

## 接口

```gdscript
class_name ShopDefinition
extends Resource
@export var shop_id: String = ""
@export var display_name: String = ""
@export var currency_id: String = "gold"
@export var entries: Array[ShopEntry] = []
@export var buy_price_multiplier: float = 1.0
@export var sell_price_multiplier: float = 0.5
@export var allow_sell: bool = true
func get_resource_id() -> String
func get_entry(item_id: String) -> ShopEntry
```

## 函数使用场景

- **`get_resource_id()`**：返回 `shop_id`，供 ContentRegistry 使用稳定 ID 索引商店定义。
- **`get_entry(item_id)`**：ShopController 计算价格、校验库存和买卖前按 item_id 查找对应 ShopEntry；找不到时返回 null。

## 使用示例

```gdscript
var potion_entry := ShopEntry.new()
potion_entry.item_id = "item.potion_small"
potion_entry.stock = 10

var shop := ShopDefinition.new()
shop.shop_id = "shop.village_general"
shop.currency_id = "gold"
shop.buy_price_multiplier = 1.0
shop.sell_price_multiplier = 0.5
shop.entries = [potion_entry]
```
