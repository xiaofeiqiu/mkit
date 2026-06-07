# RewardOption

**层：** Module  
**文件：** `addons/mkit/modules/loot/reward_option.gd`  
**继承：** `extends RefCounted`

## 职责

由 `RewardDefinition` 生成的**运行时奖励选项**（UI 展示 + 选中执行的 effects）。`RunDirector.choosing_reward` 传出的就是它的数组。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `reward_id` | `String` | `""` | 来源 id |
| `display_name` | `String` | `""` | 显示名 |
| `description` | `String` | `""` | 描述 |
| `icon` | `Texture2D` | `null` | 图标 |
| `rarity` | `String` | `"common"` | 稀有度 |
| `source` | `String` | `""` | 来源标记 |
| `effects` | `Array[GameEffect]` | `[]` | 选中执行的效果 |
| `payload` | `Dictionary` | `{}` | 附加数据 |

## 相关

- → [RewardDefinition](RewardDefinition.md) · [RewardSystem](RewardSystem.md) · [RewardSelectionUI](RewardSelectionUI.md)
