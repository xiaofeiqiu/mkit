# RewardSystem

**层：** Module  
**文件：** `addons/mkit/modules/loot/reward_system.gd`  
**继承：** `extends RefCounted`

## 职责

从 `RewardDefinition` 池**无放回加权**抽取若干 `RewardOption`，并执行选中项的 effect 链。`LootService.generate_options`/`apply_selected` 委托给它。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `generate_options(pool_ids, count, context) -> Array[RewardOption]` | — | 过条件 → 按权重无放回抽 count 个 |
| `apply_selected(option, context) -> bool` | `bool` | 执行 effects；全成功才 true，并发 `reward_selected` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 一般通过 LootService 间接调用：
var loot := Mkit.loot()
var options := loot.generate_options(["reward.a", "reward.b"], 2, ctx)
```

## 相关

- → [RewardDefinition](RewardDefinition.md) · [RewardOption](RewardOption.md) · [LootService](LootService.md)
