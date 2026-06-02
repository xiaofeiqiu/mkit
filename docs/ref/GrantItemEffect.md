# GrantItemEffect

## 概念说明

GrantItemEffect 是把物品实例加入目标背包的内置 Effect。它创建 ItemInstance，查找 InventoryController，执行 can_add/add_item，并返回结构化结果。奖励、宝箱、任务、掉落拾取和消耗品转换都可能给予物品；统一 Effect 可以避免 UI 或交互对象直接改背包。

## 设计目的

提供一个可配置化的物品给予 Effect，使所有向玩家背包添加物品的场景（奖励、宝箱、任务完成）都走同一条路径，保证 InventoryController 的校验（容量、堆叠）和事件（inventory_changed）一致执行。

## 文件

`res://addons/mkit/kernel/effects/builtin/grant_item_effect.gd`

## 接口

```gdscript
class_name GrantItemEffect
extends GameEffect

@export var item_id: String = ""
@export var quantity: int = 1
@export var give_to_source: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult: ...
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法。根据 `give_to_source` 决定接收者（source 或 target），查找其 InventoryController，创建 ItemInstance.create(item_id, quantity)，调用 can_add_item 和 add_item，返回含 item_id、quantity 和 instance_id 的 EffectResult.ok，或在缺少接收者/背包满时返回 EffectResult.fail。

## 使用示例

```gdscript
var grant := GrantItemEffect.new()
grant.effect_id = "effect.reward_potions"
grant.item_id = "item.potion_small"
grant.quantity = 3
grant.give_to_source = true

var ctx := GameplayContext.new()
ctx.source = player
grant.apply(ctx)
```
