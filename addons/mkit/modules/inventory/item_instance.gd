class_name ItemInstance
extends RefCounted
## 说明：`ItemInstance` 是 背包与装备系统 的运行时实例，负责保存由定义资源派生出的可变状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在背包与装备系统中复用这段契约或状态时使用它。
## 示例：`var instance := ItemInstance.new()`

## 运行时实例 id；用于区分同一内容定义产生的多个实例。
var instance_id: String = ""
## 该物品实例来源的 ItemDefinition id。
var definition_id: String = ""
## 物品或奖励数量；应为正数，堆叠物品会按该值合并。
var quantity: int = 1
## 运行时随机出的词缀修饰列表；不会回写到 ItemDefinition。
var rolled_affixes: Array[StatModifier] = []
## 物品耐久比例或数值；默认 1.0 表示满耐久。
var durability: float = 1.0
## 物品强化等级；0 表示未强化。
var upgrade_level: int = 0
## 物品实例扩展数据；key 由具体游戏或系统约定。
var metadata: Dictionary = {}


## 创建并返回新的运行时对象；返回值、signal 或事件会表达实际执行结果。
static func create(def_id: String, qty: int = 1) -> ItemInstance:
	var item := ItemInstance.new()
	item.instance_id = "item_%d" % Time.get_ticks_usec()
	item.definition_id = def_id
	item.quantity = qty
	return item


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	var affixes: Array = []
	for modifier in rolled_affixes:
		if modifier != null:
			affixes.append(modifier.to_save_data())
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"quantity": quantity,
		"durability": durability,
		"upgrade_level": upgrade_level,
		"metadata": metadata,
		"rolled_affixes": affixes
	}


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
static func from_save_data(data: Dictionary) -> ItemInstance:
	var item := ItemInstance.new()
	item.instance_id = str(data.get("instance_id", ""))
	item.definition_id = str(data.get("definition_id", ""))
	item.quantity = int(data.get("quantity", 1))
	item.durability = float(data.get("durability", 1.0))
	item.upgrade_level = int(data.get("upgrade_level", 0))
	item.metadata = data.get("metadata", {})
	item.rolled_affixes = []
	for raw in data.get("rolled_affixes", []):
		if raw is Dictionary:
			item.rolled_affixes.append(StatModifier.from_save_data(raw))
	return item
