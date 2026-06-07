# LootService

**层：** Module  
**文件：** `addons/mkit/modules/loot/loot_service.gd`  
**继承：** `extends RefCounted`  
**服务 ID：** `"loot"`

## 职责

掉落与奖励生成。`roll_table` 按权重从掉落表抽物品；`generate_options`/`apply_selected` 委托 `RewardSystem` 做"三选一"奖励。`RoomController` 清空房间时用它生成奖励选项。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `roll_table(table_id, context) -> LootRollResult` | `LootRollResult` | 按表掷骰，返回掉落物 |
| `roll(table, context) -> LootRollResult` | `LootRollResult` | 直接对表对象掷骰 |
| `generate_options(pool_ids, count, context) -> Array[RewardOption]` | — | 从奖励池无放回加权抽 count 个 |
| `apply_selected(option, context) -> bool` | `bool` | 执行选中奖励的 effect 链 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var loot := ServiceRegistry.get_port(ServiceRegistry.SERVICE_LOOT) as LootService
var result := loot.roll_table("loot.beast_drop", ctx)
for item in result.item_instances:
    inventory.add_item(item)
```

### 典型场景（Level 2）

```gdscript
# 生成三选一奖励并应用玩家选择
func offer_rewards(player: Node) -> void:
    var loot := ServiceRegistry.get_port(ServiceRegistry.SERVICE_LOOT) as LootService
    var ctx := GameplayContext.new()
    ctx.source = player
    ctx.target = player
    var options := loot.generate_options(["reward.heal", "reward.atk", "reward.gold"], 3, ctx)
    if options.is_empty():
        return                                  # 池为空/未注册
    # ...展示 UI，玩家选了 options[i]
    if not loot.apply_selected(options[0], ctx):
        push_warning("奖励 effect 执行失败")     # 失败路径
```

## 相关

- → [LootTableDefinition](LootTableDefinition.md) · [LootRollResult](LootRollResult.md) · [RewardSystem](RewardSystem.md) · [RewardOption](RewardOption.md)
- → [pipeline.md — Loot Roll](../../pipeline.md#14-loot-roll) · [cookbook/08_loot_and_rewards.md](../../cookbook/08_loot_and_rewards.md)
