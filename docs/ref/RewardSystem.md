# RewardSystem

## 概念说明

RewardSystem 是玩家可选择奖励的生成和应用系统。它负责生成三选一、商店选择、房间奖励等选项，并执行玩家选择的效果。Roguelike 的核心循环常常是清房间后选奖励，所以它必须独立于具体 UI。

## 设计目的

把奖励的"生成"（按权重和条件从候选池中选取）与"应用"（执行效果）统一到一个无状态服务类，使 RoomController、RunDirector 和 RewardSelectionUI 都通过 RewardSystem 操作奖励，而不散落各处写重复的权重选择和 EffectExecutor 调用。

## 文件

`res://addons/mkit/modules/loot/reward_system.gd`

## 接口

```gdscript
class_name RewardSystem
extends RefCounted
func generate_options( pool_ids: Array[String], count: int, context: GameplayContext ) -> Array[RewardOption]
func apply_selected(option: RewardOption, context: GameplayContext) -> bool
```

## 函数使用场景

- **`generate_options(pool_ids, count, context)`**：从 pool_ids 中查找对应的 RewardDefinition，过滤掉条件不满足的定义，然后按权重无重复地抽取 count 个，返回 RewardOption 数组。RoomController.generate_reward() 调用此方法生成三选一奖励。
- **`apply_selected(option, context)`**：玩家选择奖励后调用，通过 EffectExecutor.execute_many 执行 option.effects，成功后发出 EventRouter `reward_selected` 事件。RunDirector.select_reward() 调用此方法。
- **`_weighted_pick(candidates)`**：内部方法，用 RandomService 按权重从候选列表中随机选取一个 RewardDefinition，保证固定 seed 下结果可复现。
- **`_build_option(def)`**：内部方法，把 RewardDefinition 的静态信息复制到新建的 RewardOption，供 UI 展示使用。

## 使用示例

### 生成三选一奖励

```gdscript
var reward_system := RewardSystem.new()
var ctx := GameplayContext.new()
ctx.source = player
ctx.run_id = "run_001"

var options := reward_system.generate_options([
    "reward.attack_plus_20",
    "reward.max_hp_plus_10",
    "reward.projectile_plus_1",
    "reward.move_speed_plus_15"
], 3, ctx)
```

### 应用玩家选择

```gdscript
func on_reward_clicked(option: RewardOption) -> void:
    var ctx := GameplayContext.new()
    ctx.source = player
    ctx.run_id = current_run.run_id

    var reward_system := RewardSystem.new()
    if reward_system.apply_selected(option, ctx):
        print("Reward applied: ", option.reward_id)
```
