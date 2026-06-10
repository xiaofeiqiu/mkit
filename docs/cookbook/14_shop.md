# Recipe 14：商店购买  ·  难度 ★★☆  ·  预计 20 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

房间之间能开一家商店。玩家用货币（`ProgressionService` 里的 `gold`）买物品，钱够就扣款入包、钱不够则交易失败；开了 `allow_sell` 还能把背包里的东西按折价卖回。买卖都走 `ShopService`，UI 用内置 `ShopUI`。

## 前置

- 需完成：[Recipe 11](11_progression_and_save.md)（`ProgressionService` 货币）、背包（[Recipe 08](08_loot_and_rewards.md) 步骤 6 的 `InventoryController`）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `ItemDefinition` / `ShopDefinition` (.tres) | `ShopService` 注册、按 id 查询、算买卖价 |
| 给玩家 `Controllers/InventoryController` + 一些 `gold` | 买入：扣货币 → `add_item`；失败自动退款 |
| 开店：`ShopService.open_shop()` + 绑 `ShopUI` | `buy()` / `sell()` 校验、改库存、发 `item_purchased` / `item_sold` |

## 关键认知：商店货币来自 ProgressionService

`ShopService.buy()` 用 `SpendCurrencyEffect` / `AddCurrencyEffect` 结算，它们操作的是 **`ProgressionService` 的货币**（不是实体身上的 `ResourcePoolComponent`）。所以买东西前玩家得先有 `gold`：

```gdscript
var progression := Mkit.progression()
progression.add_currency("gold", 200)
```

## 步骤

### 步骤 1：创建 ItemDefinition

新建 Resource → `ItemDefinition`，存为 `res://data/items/potion.tres`：

| 字段 | 值 |
|------|----|
| `item_id` | `"item.potion"` |
| `display_name` | `"治疗药水"` |
| `item_type` | `"consumable"` |
| `value` | `20`（基准价，买卖价由它乘倍率得出）|
| `stackable` | `true`, `max_stack` = `99` |

加入 `ResourceDatabase.resources`。

### 步骤 2：创建 ShopDefinition

新建 Resource → `ShopDefinition`，存为 `res://data/shops/village_shop.tres`：

| 字段 | 值 |
|------|----|
| `shop_id` | `"shop.village"` |
| `display_name` | `"杂货铺"` |
| `currency_id` | `"gold"` |
| `buy_price_multiplier` | `1.0`（买价 = `value * 1.0` = 20）|
| `sell_price_multiplier` | `0.5`（卖价 = `value * 0.5` = 10）|
| `allow_sell` | `true` |
| `entries` | 见下 |

`entries` 里建 `ShopEntry`：

```
entry_potion:
  item_id        = "item.potion"
  price_override = -1     # -1 → 用 value*buy_price_multiplier 算价；>=0 则固定此价
  stock          = 5      # -1 = 无限库存
  conditions     = []
```

加入 `ResourceDatabase.resources`。

### 步骤 3：确认玩家有背包和货币

玩家 `Controllers/` 下需有 `InventoryController`（[Recipe 08](08_loot_and_rewards.md) 步骤 6）。开店前给点钱（步骤"关键认知"里的 `add_currency`）。

### 步骤 4：搭 ShopUI 并开店

新建场景 `res://game/ui/shop.tscn`，根节点用内置 `ShopUI`（`extends Control`），加一个名为 `EntryContainer` 的子节点：

```
Shop  (ShopUI)
└── EntryContainer  (VBoxContainer)   # 名字必须是 "EntryContainer"
```

在打开商店的逻辑里：

```gdscript
func open_village_shop(player: Node) -> void:
    var shop := Mkit.shop()
    if shop == null:
        return
    if not shop.open_shop("shop.village"):
        push_warning("无法打开商店：shop.village 未注册？")
        return
    var ui_scene := load("res://game/ui/shop.tscn") as PackedScene
    var ui := ui_scene.instantiate() as ShopUI
    add_child(ui)
    ui.bind(shop, player)   # buyer = 玩家实体（需带 InventoryController）
```

`ShopUI._render()` 为每个 entry 生成"名字 (价格)"按钮，点击调 `shop.buy(item_id, 1, buyer)`。

### 步骤 5：买入与卖出

买入（也可不经 UI 直接调）：

```gdscript
var shop := Mkit.shop()
if shop.can_buy("item.potion", 1, player):
    shop.buy("item.potion", 1, player)
else:
    print("买不了：钱不够 / 缺货 / 背包满")
```

`buy()` 流程：算总价 → `SpendCurrencyEffect` 扣 `gold`（失败即终止）→ `InventoryController.add_item()`（失败则**自动退款**）→ 扣库存 → 发 `item_purchased` 信号 + `ShopEvents.item_purchased` 领域事件。

卖出（按物品**实例 id**）：

```gdscript
var item := inventory.find_item_by_definition("item.potion")
if item != null:
    shop.sell(item.instance_id, 1, player)   # 进账 value * sell_price_multiplier
```

### 步骤 6：监听交易信号

```gdscript
shop.item_purchased.connect(func(item_id: String, qty: int, cost: int):
    print("买入 %s x%d，花费 %d gold" % [item_id, qty, cost])
)
shop.transaction_failed.connect(func(item_id: String, reason: String):
    print("交易失败 %s：%s" % [item_id, reason])
)
```

## 运行验证

1. 给玩家 200 gold，开店 → UI 列出"治疗药水 (20)"
2. 点击购买 → `gold` 减 20，背包多 1 个药水，库存 5 → 4
3. 钱不够时点击 → `transaction_failed: Insufficient currency`，背包/货币不变
4. 库存到 0 → `transaction_failed: Out of stock`
5. 卖出一个药水 → `gold` +10
6. `EventService.recent_events` 有 `item_purchased` / `item_sold`

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 一直 `Insufficient currency` | 玩家没有 `gold`（货币在 `ProgressionService`，不是 `ResourcePoolComponent`）| 先 `progression.add_currency("gold", N)` |
| `Buyer has no inventory` | 买家没 `Controllers/InventoryController` | 给玩家挂背包控制器 |
| 买了不进包 | 物品未注册或背包满 | `ItemDefinition` 入库；检查 `capacity` |
| `Item not sold here` | `buy` 的 item_id 不在 `entries` | 只能买 `ShopEntry` 里列出的物品 |
| ShopUI 空白 | 没 `bind()` 或缺 `EntryContainer` | `bind(shop, buyer)`；子节点名须为 `EntryContainer` |
| 卖东西没反应 | `sell` 第一参要传**实例 id** 不是 definition id | 用 `inventory.find_item_by_definition(...).instance_id` |

## 延伸阅读

- [ShopService ref](../ref/modules/ShopService.md) — open_shop / buy / sell / 价格计算
- [ShopDefinition ref](../ref/modules/ShopDefinition.md) · [ShopEntry ref](../ref/modules/ShopEntry.md)
- [InventoryController ref](../ref/modules/InventoryController.md) · [ItemDefinition ref](../ref/modules/ItemDefinition.md)
- [pipeline.md — Shop Purchase](../pipeline.md#16-shop-purchase)
