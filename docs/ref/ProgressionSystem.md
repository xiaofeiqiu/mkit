# ProgressionSystem

## 概念说明

ProgressionSystem 是长期进度和升级购买的控制器。它管理 ProgressionState，校验升级前置和货币，应用解锁与效果，并实现 Saveable。SaveManager 不应该知道 meta currency 或升级规则；RewardSystem 也不应该直接修改永久进度。

## 设计目的

作为玩家长期进度的唯一协调者，把货币管理、升级购买校验（前置、货币、等级上限）、内容解锁和效果应用集中到一个节点，并通过继承 Saveable 自然接入 SaveManager 的存档体系。

## 文件

`res://addons/mkit/modules/progression/progression_system.gd`

## 字段说明

- **state**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **content**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name ProgressionSystem
extends Saveable
signal currency_changed(currency_id: String, amount: int)
signal upgrade_level_changed(upgrade_id: String, level: int)
signal content_unlocked(content_id: String)
var state := ProgressionState.new()
var content: ContentRegistry = null
func add_currency(currency_id: String, amount: int) -> void
func spend_currency(currency_id: String, amount: int) -> bool
func get_currency(currency_id: String) -> int
func can_unlock(upgrade_id: String) -> bool
func unlock_or_level_up(upgrade_id: String, context: GameplayContext = null) -> bool
func get_definition(upgrade_id: String) -> UpgradeDefinition
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`add_currency(currency_id, amount)`**：增加长期货币余额，发出 `currency_changed` 信号。run 结束结算时调用，例如 `progression.add_currency("meta_currency", 120)`。
- **`spend_currency(currency_id, amount)`**：通用扣款入口。校验空 id 和非正数后委托 `ProgressionState.spend_currency()`，余额不足返回 `false`，成功后发出 `currency_changed`。与 `unlock_or_level_up()` 的区别：前者是通用扣款，后者是完整的升级购买事务（含前置校验、等级提升、效果执行）。Shop、IAP 结算等场景应调用此方法而非直接修改 `ProgressionState`。
- **`can_unlock(upgrade_id)`**：检查升级的所有前提（前置升级已完成、未满级、货币足够），返回是否可购买。大厅 UI 据此决定按钮是否可点。
- **`unlock_or_level_up(upgrade_id, context)`**：执行完整购买流程：再次验证条件、扣除货币、提升等级、解锁内容（`unlock_content_ids`）、通过 EffectExecutor 执行 `effects`，并发出对应信号。
- **`get_definition(upgrade_id)`**：从 ContentRegistry 读取 UpgradeDefinition，内部 can_unlock 和 unlock_or_level_up 调用。
- **`to_save_data()` / `from_save_data(data)`**：实现 Saveable 接口，委托给 ProgressionState 序列化/反序列化，SaveManager 遍历场景树时自动调用。

## 使用示例

```gdscript
var progression := ServiceRegistry.get_service("progression") as ProgressionSystem

# run 结束后发放货币
progression.add_currency("meta_currency", 120)

# 大厅购买升级
if progression.can_unlock("upgrade.attack_plus_20"):
    progression.unlock_or_level_up("upgrade.attack_plus_20")
else:
    print("Cannot unlock: ", "upgrade.attack_plus_20")
```
