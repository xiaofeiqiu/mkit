# RewardDefinition

**层：** Module  
**文件：** `addons/mkit/modules/loot/reward_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

一个可选奖励的静态定义（`.tres`）：展示信息、稀有度、权重、出现条件、选中时执行的 effect 链。`RewardSystem` 从这些池里加权抽 `RewardOption`。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `reward_id` | `String` | `""` | 唯一 id |
| `display_name` | `String` | `""` | 显示名 |
| `description` | `String` | `""` | 描述（multiline）|
| `icon` | `Texture2D` | — | 图标 |
| `rarity` | `String` | `"common"` | 稀有度 |
| `weight` | `float` | `1.0` | 抽取权重 |
| `conditions` | `Array[Condition]` | `[]` | 出现条件 |
| `effects` | `Array[GameEffect]` | `[]` | 选中后执行 |

## 相关

- → [RewardOption](RewardOption.md) · [RewardSystem](RewardSystem.md) · [LootService](LootService.md)
- → [cookbook/08_loot_and_rewards.md](../../cookbook/08_loot_and_rewards.md)
