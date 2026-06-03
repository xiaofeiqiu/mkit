# ShopEntry

## 概念说明

ShopEntry 是商店中一件商品的静态 Resource 配置。它把一个 item_id 接入某个 ShopDefinition，并可单独覆盖价格、限制库存、附加上架条件。

## 设计目的

让单件商品的定价与可购买性与 ItemDefinition 解耦：基础价来自 ItemDefinition.value，而某件商品的特价、限购或解锁条件作为 entry 数据表达，不污染物品定义本身。

## 文件

`res://addons/mkit/modules/shop/shop_entry.gd`

## 字段说明

- **item_id**：商品对应的物品定义 ID。ShopController 用它在 ContentRegistry 查找 ItemDefinition 并创建 ItemInstance。
- **price_override**：买价覆盖。>= 0 时作为最终买价直接使用（不再乘 buy_price_multiplier）；为 -1（默认）时按 ItemDefinition.value × buy_price_multiplier 计算。
- **stock**：库存数量。-1（默认）表示无限库存；>= 0 时每次买入递减，减到 0 后该 entry 不可再买。
- **conditions**：上架/可购买条件列表。ShopController 通过 ConditionEvaluator 校验；未全部满足时该 entry 被锁定，买入被拒绝。

## 接口

```gdscript
class_name ShopEntry
extends Resource
@export var item_id: String = ""
@export var price_override: int = -1
@export var stock: int = -1
@export var conditions: Array[Condition] = []
```

## 函数使用场景

ShopEntry 是纯数据 Resource，无公开方法。字段由 Inspector 配置后随 ShopDefinition 注册到 ContentRegistry，运行时由 ShopController 读取。

- **普通商品**：只填 `item_id`，价格按 ItemDefinition.value × buy_price_multiplier，库存无限。
- **特价商品**：设 `price_override` 为固定买价，绕过倍率。
- **限购商品**：设 `stock` 为正数，买完即下架。
- **条件解锁**：在 `conditions` 中挂条件（例如需要某进度或某任务完成），未满足时锁定。

## 使用示例

```gdscript
var entry := ShopEntry.new()
entry.item_id = "item.sword_iron"
entry.price_override = 120
entry.stock = 1
```
