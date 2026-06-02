# RewardOption

## 概念说明

RewardOption 是一次奖励选择界面里的一个可选项。它保存展示文本、稀有度、来源、效果列表和选择后要应用的内容。Roguelike 常见"三选一升级"，UI 需要显示它，RewardSystem 需要执行它，RunDirector 需要知道玩家选了哪个。

## 设计目的

作为 RewardDefinition（静态配置）到 RewardSelectionUI（展示层）和 RewardSystem.apply_selected（执行层）之间的运行时载体，携带展示信息和效果列表，使 UI 只需读取 RewardOption 就能渲染并提交选择。

## 文件

`res://addons/mkit/modules/loot/reward_option.gd`

## 字段说明

- **reward_id**：稳定 ID 字段。例：RewardOption 通过 reward_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **display_name**：代码字段。显示名称。
- **description**：代码字段。描述文本。
- **icon**：代码字段。图标资源。
- **rarity**：稀有度。例：common、rare、legendary，用于掉落权重和 UI 颜色。
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **effects**：玩法结果列表。例：DealDamageEffect 后接 ApplyStatusEffect(status.burn)。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。

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
