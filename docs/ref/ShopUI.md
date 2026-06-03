# ShopUI

## 概念说明

ShopUI 是商店界面 Control。它绑定一个 ShopController 与买家节点，订阅商店信号渲染条目按钮，玩家点击即触发买入。它是商店交易这一玩法的可视层。

## 设计目的

把商店的展示逻辑（渲染条目、显示价格）与交易逻辑（扣币、入包、发事件）分离：UI 只负责呈现和提交购买请求，实际交易由 ShopController 处理。商店数据变化时，UI 通过信号被动重渲染，不直接读写货币或背包。

## 文件

`res://addons/mkit/modules/ui/shop_ui.gd`

## 字段说明

- **controller**：绑定的 ShopController 引用。UI 通过它读取 current_shop、查询价格并发起买入。
- **buyer**：买家节点，作为 buy 调用的对象（其 Controllers/InventoryController 接收物品）。

## 接口

```gdscript
class_name ShopUI
extends Control
var controller: ShopController = null
var buyer: Node = null
func bind(shop_controller: ShopController, shop_buyer: Node = null) -> void
func close() -> void
```

## 函数使用场景

- **`bind(shop_controller, shop_buyer)`**：打开商店界面时调用，保存 controller 与 buyer，连接 shop_opened / item_purchased / item_sold 信号（避免重复连接），并立即渲染一次。
- **`close()`**：关闭界面时调用 controller.close_shop() 并 queue_free 自身。
- **`_render()`**：内部方法，清空 EntryContainer 后遍历 current_shop.entries，为每个条目创建一个显示 item_id 与买价的 Button，按下时调用 controller.buy(item_id, 1, buyer)。
- **`_on_shop_changed` / `_on_item_purchased` / `_on_item_sold`**：内部信号回调，收到商店或交易变化时重新调用 `_render()`。

## 使用示例

```gdscript
var shop := ServiceRegistry.get_service("shop") as ShopController
shop.open_shop("shop.village_general")

var ui := ShopUI.new()
add_child(ui)
ui.bind(shop, player)
```
