# InventoryController

**层：** Module  
**文件：** `addons/mkit/modules/inventory/inventory_controller.gd`  
**继承：** `extends SaveableComponent`

## 职责

背包控制器，挂在 `Controllers/InventoryController`。增删查物品、处理堆叠与容量、发 `inventory_changed` 与 `EventService.emit_inventory_changed`（任务系统靠它统计"获得物品"）。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `capacity` | `int`（@export）| `30` | 格子数 |
| `model` | `InventoryModel` | 新建 | 数据模型 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `can_add_item(item) -> bool` | `bool` | 是否放得下 |
| `add_item(item: ItemInstance) -> bool` | `bool` | 加入（自动堆叠/分格）|
| `remove_item_by_instance_id(instance_id, quantity := 1) -> bool` | `bool` | 按实例 id 移除 |
| `find_item(instance_id) -> ItemInstance` | — | 按实例 id 查 |
| `find_item_by_definition(definition_id) -> ItemInstance` | — | 按定义 id 查 |

## 信号

`inventory_changed` · `item_added(item)` · `item_removed(item)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var inv := player.get_node("Controllers/InventoryController") as InventoryController
inv.add_item(ItemInstance.create("item.potion", 1))
```

### 典型场景（Level 2）

```gdscript
# 加物品并处理"放不下"
func give_item(player: Node, item_id: String, qty: int) -> bool:
    var inv := player.get_node_or_null("Controllers/InventoryController") as InventoryController
    if inv == null:
        return false
    var item := ItemInstance.create(item_id, qty)
    if not inv.can_add_item(item):
        print("背包已满")            # 失败路径
        return false
    inv.item_added.connect(func(i: ItemInstance): print("获得 %s ×%d" % [i.definition_id, i.quantity]), CONNECT_ONE_SHOT)
    return inv.add_item(item)
```

> 存档：是 `SaveableComponent`，`to_save_data` 存所有格子，需由 `Saveable` 代理收集（见 [cookbook/11](../../cookbook/11_progression_and_save.md)）。

## 相关

- → [ItemInstance](ItemInstance.md) · [ItemDefinition](ItemDefinition.md) · [GrantItemEffect](GrantItemEffect.md) · [EquipmentController](EquipmentController.md)
- → [cookbook/14_shop.md](../../cookbook/14_shop.md)
