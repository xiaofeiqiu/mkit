# ShopUI

**层：** Module  
**文件：** `addons/mkit/modules/ui/shop_ui.gd`  
**继承：** `extends Control`

## 职责

最小商店 UI。绑定 `ShopService` 和买家节点后，把当前商店 entries 渲染为按钮，按钮触发 `ShopService.buy()`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `controller` | `ShopService` | `null` | 已绑定商店服务 |
| `buyer` | `Node` | `null` | 购买者，需有 `Controllers/InventoryController` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `bind(shop_controller: ShopService, shop_buyer: Node = null) -> void` | — | 连接商店信号并渲染 |
| `close() -> void` | — | 调 `close_shop()` 并释放 UI |

## 使用模式

### 最小示例（Level 1）

```gdscript
var shop: ShopService = ServiceRegistry.get_service("shop") as ShopService
$ShopUI.bind(shop, player)
```

### 典型场景（Level 2）

```gdscript
func open_shop_ui(shop_id: String, player: Node) -> void:
    var shop: ShopService = ServiceRegistry.get_service("shop") as ShopService
    if shop == null or not shop.open_shop(shop_id):
        return
    $ShopUI.visible = true
    $ShopUI.bind(shop, player)
```

## 相关

- → [ShopService](ShopService.md) · [ShopDefinition](ShopDefinition.md) · [InventoryController](InventoryController.md)
- → [cookbook/14_shop.md](../../cookbook/14_shop.md)

