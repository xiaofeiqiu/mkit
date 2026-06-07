# GrantItemEffect

**层：** Module  
**文件：** `addons/mkit/modules/inventory/grant_item_effect.gd`  
**继承：** `extends GameEffect`

## 职责

效果：往接收者背包加物品。用作奖励、任务回报、对话给予。接收者须有 `Controllers/InventoryController`。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `item_id` | `String` | `""` | 物品 id |
| `quantity` | `int` | `1` | 数量 |
| `give_to_source` | `bool` | `true` | 真→给 source，否则 target |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 失败：`Missing item_id` / `Missing receiver` / `Receiver has no InventoryController` / `Inventory cannot accept item` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var grant := GrantItemEffect.new()
grant.item_id = "item.potion"
grant.quantity = 2
grant.give_to_source = true   # 给接收奖励/对话的玩家
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [InventoryController](InventoryController.md)
- → [cookbook/08_loot_and_rewards.md](../../cookbook/08_loot_and_rewards.md)
