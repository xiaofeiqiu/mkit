class_name Wallet
extends RefCounted
## 说明：`Wallet` 是 成长系统 的货币钱包，负责保存多货币余额并处理增加、消费和存档。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在成长系统中复用这段契约或状态时使用它。
## 示例：`var instance := Wallet.new()`

## 钱包余额表；key 为 currency id，value 为当前数量。
var balances: Dictionary = {}


## 返回 `balance` 对应的数据或对象，并保持 `Wallet` 的领域契约一致。
func get_balance(currency_id: String) -> int:
	return int(balances.get(currency_id, 0))


## 设置 `balance` 对应的数据或对象，并保持 `Wallet` 的领域契约一致。
func set_balance(currency_id: String, amount: int) -> void:
	balances[currency_id] = max(0, amount)


## 向当前集合或状态中增加数据，并保持 `Wallet` 的领域契约一致。
func add(currency_id: String, amount: int) -> void:
	if currency_id.strip_edges() == "":
		return
	set_balance(currency_id, get_balance(currency_id) + amount)


## 检查当前上下文是否允许 `spend`，并保持 `Wallet` 的领域契约一致。
func can_spend(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	return get_balance(currency_id) >= amount


## 扣除指定资源或货币，并保持 `Wallet` 的领域契约一致。
func spend(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_spend(currency_id, amount):
		return false
	set_balance(currency_id, get_balance(currency_id) - amount)
	return true


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `Wallet` 的领域契约一致。
func to_save_data() -> Dictionary:
	return balances.duplicate(true)


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `Wallet` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	balances = data.duplicate(true)
