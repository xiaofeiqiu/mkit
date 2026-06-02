# ProgressionState

## 概念说明

ProgressionState 是玩家长期进度的纯数据状态。它保存货币、升级等级和已解锁内容，并提供序列化/反序列化。ProgressionSystem 需要一个可保存、可测试的状态对象，不能把长期状态散落在 UI 或 SaveManager 里。

## 设计目的

把玩家跨 Run 的长期进度数据（货币、升级等级、已解锁内容）集中到一个纯数据对象，使 ProgressionSystem 可以通过简洁接口读写进度，SaveManager 通过 Saveable 接口持久化，测试也可以直接创建实例验证逻辑。

## 文件

`res://addons/mkit/modules/progression/progression_state.gd`

## 字段说明

- **currencies**：长期货币表。例：meta_currency=320。
- **upgrade_levels**：升级等级表。例：upgrade.attack_plus_20=2。
- **unlocked_content_ids**：已解锁内容。例：ability.fireball_basic 已进入奖励池。

## 接口

```gdscript
class_name ProgressionState
extends RefCounted
var currencies: Dictionary = {}
var upgrade_levels: Dictionary = {}
var unlocked_content_ids: Array[String] = []
func get_currency(currency_id: String) -> int
func add_currency(currency_id: String, amount: int) -> void
func spend_currency(currency_id: String, amount: int) -> bool
func get_upgrade_level(upgrade_id: String) -> int
func set_upgrade_level(upgrade_id: String, level: int) -> void
func unlock_content(content_id: String) -> void
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`get_currency(currency_id)`**：读取指定货币余额，供大厅 UI 显示 meta_currency 数量和 ProgressionSystem.can_unlock() 检查。
- **`add_currency(currency_id, amount)`**：增加货币余额，确保不低于 0。run 结束结算时调用。
- **`spend_currency(currency_id, amount)`**：花费货币，余额不足时返回 false 且不扣除。ProgressionSystem.unlock_or_level_up() 调用。
- **`get_upgrade_level(upgrade_id)`**：读取指定升级的当前等级（0 表示未购买），供 UI 显示已购买等级和判断是否满级。
- **`set_upgrade_level(upgrade_id, level)`**：更新升级等级，ProgressionSystem 购买成功后调用。
- **`unlock_content(content_id)`**：将内容 ID 加入已解锁列表（去重），供奖励池过滤使用。
- **`to_save_data()` / `from_save_data(data)`**：序列化和反序列化，供 ProgressionSystem（Saveable）的对应方法调用。

## 使用示例

```gdscript
var state := ProgressionState.new()
state.add_currency("meta_currency", 40)
state.set_upgrade_level("upgrade.attack_plus_20", 1)
state.unlock_content("ability.fireball_basic")

print(state.get_currency("meta_currency")) # 40
print(state.get_upgrade_level("upgrade.attack_plus_20")) # 1
```
