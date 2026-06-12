class_name ProgressionState
extends RefCounted
## 说明：`ProgressionState` 是 成长系统 的运行时状态，负责保存可序列化或可推进的领域状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在成长系统中复用这段契约或状态时使用它。
## 示例：`var instance := ProgressionState.new()`

## 玩家或进度系统持有的钱包状态。
var wallet: Wallet = Wallet.new()
## 已购买升级等级表；key 为 upgrade id，value 为当前等级。
var upgrade_levels: Dictionary = {}
## 已经解锁的内容 id 列表；可被商店、掉落或 UI 过滤使用。
var unlocked_content_ids: Array[String] = []


## 返回 `currency` 对应的数据或对象，并保持 `ProgressionState` 的领域契约一致。
func get_currency(currency_id: String) -> int:
	return wallet.get_balance(currency_id)


## 向当前集合或状态中增加数据，并保持 `ProgressionState` 的领域契约一致。
func add_currency(currency_id: String, amount: int) -> void:
	wallet.add(currency_id, amount)


## 扣除指定资源或货币，并保持 `ProgressionState` 的领域契约一致。
func spend_currency(currency_id: String, amount: int) -> bool:
	if not wallet.can_spend(currency_id, amount):
		return false
	wallet.spend(currency_id, amount)
	return true


## 返回 `upgrade_level` 对应的数据或对象，并保持 `ProgressionState` 的领域契约一致。
func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


## 设置 `upgrade_level` 对应的数据或对象，并保持 `ProgressionState` 的领域契约一致。
func set_upgrade_level(upgrade_id: String, level: int) -> void:
	upgrade_levels[upgrade_id] = max(0, level)


## 执行 `unlock_content` 对应的公开操作，并保持 `ProgressionState` 的领域契约一致。
func unlock_content(content_id: String) -> void:
	if not unlocked_content_ids.has(content_id):
		unlocked_content_ids.append(content_id)


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `ProgressionState` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {
		"currencies": wallet.to_save_data(),
		"upgrade_levels": upgrade_levels,
		"unlocked_content_ids": unlocked_content_ids
	}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `ProgressionState` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	var raw_currencies := data.get("currencies", {})
	if raw_currencies is Dictionary:
		wallet.from_save_data(raw_currencies)
	upgrade_levels = data.get("upgrade_levels", {})
	var raw: Array = data.get("unlocked_content_ids", [])
	unlocked_content_ids.assign(raw)
