# RewardOption

## 概念说明

RewardOption 是一次奖励选择界面里的一个可选项。它保存展示文本、稀有度、来源、效果列表和选择后要应用的内容。Roguelike 常见"三选一升级"，UI 需要显示它，RewardSystem 需要执行它，RunDirector 需要知道玩家选了哪个。

## 设计目的

作为 RewardDefinition（静态配置）到 RewardSelectionUI（展示层）和 RewardSystem.apply_selected（执行层）之间的运行时载体，携带展示信息和效果列表，使 UI 只需读取 RewardOption 就能渲染并提交选择。

## 文件

`res://addons/mkit/modules/rewards/reward_option.gd`

## 接口

```gdscript
class_name RewardOption
extends RefCounted

var reward_id: String = ""
var display_name: String = ""
var description: String = ""
var icon: Texture2D = null
var rarity: String = "common"
var source: String = ""
var effects: Array[GameEffect] = []
var payload: Dictionary = {}
```

## 函数使用场景

RewardOption 是纯数据对象，无公开方法。由 RewardSystem._build_option() 从 RewardDefinition 构建，传给 RewardSelectionUI 展示，再通过 RewardSystem.apply_selected() 执行。

- **`reward_id`**：玩家选择后记录到 RunState.reward_history，Analytics 也可据此统计奖励选择数据。
- **`display_name` / `description` / `icon` / `rarity`**：RewardSelectionUI 据此渲染奖励卡片，包括按 rarity 设置背景色或边框样式。
- **`effects`**：RewardSystem.apply_selected() 调用 EffectExecutor.execute_many(option.effects, context) 执行。

## 使用示例

```gdscript
var option := RewardOption.new()
option.reward_id = "reward.attack_plus_20"
option.display_name = "Power Up"
option.description = "+20% attack power"
option.rarity = "common"

# 由 RewardSystem 自动从 RewardDefinition 复制 effects
# option.effects = reward_definition.effects.duplicate()
```
