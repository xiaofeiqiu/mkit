class_name Wallet
extends RefCounted
## 说明：`Wallet` 是 成长系统 的货币钱包，负责保存多货币余额并处理增加、消费和存档。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在成长系统中复用这段契约或状态时使用它。
## 示例：`var instance := Wallet.new()`

## 钱包余额表；key 为 currency id，value 为当前数量。
var balances: Dictionary = {}


## 读取当前对象中的 `balance`；未找到时返回 null、空集合或该 API 的默认值。
func get_balance(currency_id: String) -> int:
	return int(balances.get(currency_id, 0))


## 更新当前对象中的 `balance`；输入值按该对象规则校验或夹取。
func set_balance(currency_id: String, amount: int) -> void:
	balances[currency_id] = max(0, amount)


## 向当前集合或状态加入传入数据；重复项按该对象规则合并或覆盖。
func add(currency_id: String, amount: int) -> void:
	if currency_id.strip_edges() == "":
		return
	set_balance(currency_id, get_balance(currency_id) + amount)


## 用 GameplayContext 和当前运行时状态判断是否允许 `spend`；失败原因由对应查询 API 提供。
func can_spend(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	return get_balance(currency_id) >= amount


## 尝试扣除指定资源或货币；成功会更新余额，失败保持原状态。
func spend(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_spend(currency_id, amount):
		return false
	set_balance(currency_id, get_balance(currency_id) - amount)
	return true


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	return balances.duplicate(true)


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
func from_save_data(data: Dictionary) -> void:
	balances = data.duplicate(true)
