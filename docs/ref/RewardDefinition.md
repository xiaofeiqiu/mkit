# RewardDefinition

## 概念说明

RewardDefinition 是一个可能出现的奖励的静态定义。它定义奖励 ID、显示信息、稀有度、权重、出现条件和效果列表。+20% attack、+1 projectile、解锁火球、永久 HP +5 都可以用同一套奖励模型表达。

## 设计目的

把奖励的静态配置集中到 Resource 文件，使 RewardSystem 可以通过权重、条件筛选生成奖励选项，不同场景（房间奖励、宝箱选择、商店）都能共用同一批奖励定义。

## 文件

`res://addons/mkit/modules/loot/reward_definition.gd`

## 字段说明

- **reward_id**：稳定 ID 字段。例：RewardDefinition 通过 reward_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **display_name**：代码字段。显示名称。
- **description**：代码字段。描述文本。
- **icon**：代码字段。图标资源。
- **rarity**：稀有度。例：common、rare、legendary，用于掉落权重和 UI 颜色。
- **weight**：权重。例：普通药水 weight=10，稀有武器 weight=1。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。
- **effects**：玩法结果列表。例：DealDamageEffect 后接 ApplyStatusEffect(status.burn)。

## 接口

```gdscript
class_name RewardDefinition
extends Resource
@export var reward_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export var weight: float = 1.0
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []
func get_resource_id() -> String
```

## 函数使用场景

RewardDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后注册到 ContentRegistry，RewardSystem 按 ID 查找和选取。

- **`weight`**：RewardSystem 按权重比例从候选池中随机选取奖励；稀有奖励设置低权重，普通奖励设置高权重。
- **`conditions`**：RewardSystem.generate_options() 通过 ConditionEvaluator 过滤，不满足条件的定义不会出现在选项中（如只有 boss 房才出现特殊奖励）。
- **`effects`**：玩家选择该奖励后，RewardSystem.apply_selected() 通过 EffectExecutor 按顺序执行这些效果。

## 使用示例

```gdscript
var reward := RewardDefinition.new()
reward.reward_id = "reward.attack_plus_20"
reward.display_name = "Power Up"
reward.description = "+20% attack power for this run."
reward.rarity = "common"
reward.weight = 10.0

var mod_effect := ApplyStatModifierEffect.new()
mod_effect.stat_id = "attack_power"
mod_effect.operation = StatModifierDefinition.Operation.PERCENT_ADD
mod_effect.value = 0.20
mod_effect.duration = -1.0

reward.effects = [mod_effect]
```
