# UpgradeDefinition

## 概念说明

UpgradeDefinition 是永久或局内升级的静态定义。它定义升级 ID、最大等级、货币消耗、前置条件、解锁内容和应用效果。Roguelite 的 meta progression 需要长期可存档的升级，但奖励和角色属性仍应走 Effect/Stats 系统。

## 设计目的

把升级的所有静态配置（花费、等级上限、前置、效果、解锁内容）集中到一个 Resource 文件，使 ProgressionSystem 能按稳定 ID 查找并处理购买/升级逻辑，UI 只需读取定义即可渲染升级树。

## 文件

`res://addons/mkit/modules/progression/upgrade_definition.gd`

## 接口

```gdscript
class_name UpgradeDefinition
extends Resource

@export var upgrade_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_level: int = 1
@export var currency_id: String = "meta_currency"
@export var cost_by_level: Array[int] = [100]
@export var prerequisite_upgrade_ids: Array[String] = []
@export var unlock_content_ids: Array[String] = []
@export var effects: Array[GameEffect] = []
@export var tags: Array[String] = []
@export var is_meta_upgrade: bool = true

func get_cost_for_level(next_level: int) -> int: ...
```

## 函数使用场景

- **`get_cost_for_level(next_level)`**：返回升到指定等级所需的货币数量。ProgressionSystem.can_unlock() 和 UI 调用此方法显示购买消耗。若 next_level 超过 cost_by_level 数组范围，则使用最后一个值。

## 使用示例

```gdscript
var upgrade := UpgradeDefinition.new()
upgrade.upgrade_id = "upgrade.attack_plus_20"
upgrade.display_name = "Power Up"
upgrade.description = "+20% attack for this run at start."
upgrade.max_level = 3
upgrade.currency_id = "meta_currency"
upgrade.cost_by_level = [100, 200, 300]
upgrade.unlock_content_ids = ["reward.attack_plus_20"]
upgrade.is_meta_upgrade = true

# 查询各等级消耗
print(upgrade.get_cost_for_level(1)) # 100
print(upgrade.get_cost_for_level(2)) # 200
```
