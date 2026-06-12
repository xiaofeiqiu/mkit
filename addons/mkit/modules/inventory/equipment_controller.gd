class_name EquipmentController
extends SaveableComponent
## 说明：`EquipmentController` 是 背包与装备系统 的实体控制器，负责协调实体组件、服务和运行时状态。
## 上游：通常由 EntityRoot、CommandReceiver、StateMachine、玩家输入或 AI 创建或调用。
## 下游：会连接组件、ActionService、EffectService、ContentService 和 EventService，不直接依赖具体游戏内容。
## 使用：当项目实体需要把输入、状态机和组件能力组合成可调用行为时使用它。
## 示例：`var instance := EquipmentController.new()`

## 当 `EquipmentController` 发生 `equipment changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal equipment_changed(slot_id: String, item: ItemInstance)
## 该装备控制器允许使用的槽位 id 列表。
@export var allowed_slots: Array[String] = ["weapon", "helmet", "armor", "ring", "amulet"]
## 已装备物品表；key 为槽位 id，value 为 ItemInstance。
var equipped: Dictionary = {}


## 检查当前上下文是否允许 `equip`，并保持 `EquipmentController` 的领域契约一致。
func can_equip(item: ItemInstance, slot_id: String) -> bool:
	if item == null:
		return false
	if not allowed_slots.has(slot_id):
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	return definition.equipment_slot == slot_id


## 执行 `equip` 对应的公开操作，并保持 `EquipmentController` 的领域契约一致。
func equip(item: ItemInstance, slot_id: String) -> bool:
	if not can_equip(item, slot_id):
		return false
	if equipped.has(slot_id):
		unequip(slot_id)
	equipped[slot_id] = item
	_apply_item_modifiers(item)
	equipment_changed.emit(slot_id, item)
	return true


## 执行 `unequip` 对应的公开操作，并保持 `EquipmentController` 的领域契约一致。
func unequip(slot_id: String) -> ItemInstance:
	if not equipped.has(slot_id):
		return null
	var item := equipped[slot_id] as ItemInstance
	_remove_item_modifiers(item)
	equipped.erase(slot_id)
	equipment_changed.emit(slot_id, null)
	return item


## 返回 `equipped` 对应的数据或对象，并保持 `EquipmentController` 的领域契约一致。
func get_equipped(slot_id: String) -> ItemInstance:
	return equipped.get(slot_id, null)


## 返回 `item_definition` 对应的数据或对象，并保持 `EquipmentController` 的领域契约一致。
func get_item_definition(item_id: String) -> ItemDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(item_id) as ItemDefinition


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `EquipmentController` 的领域契约一致。
func to_save_data() -> Dictionary:
	var slots: Dictionary = {}
	for slot_id in equipped.keys():
		var item := equipped[slot_id] as ItemInstance
		if item != null:
			slots[str(slot_id)] = item.to_save_data()
	return {"slots": slots}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `EquipmentController` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	for item in equipped.values():
		if item is ItemInstance:
			_remove_item_modifiers(item)
	equipped.clear()
	var slots: Dictionary = data.get("slots", {})
	for slot_id in slots.keys():
		var key := str(slot_id)
		if not allowed_slots.has(key):
			continue
		var raw: Variant = slots[slot_id]
		if raw is Dictionary:
			var item := ItemInstance.from_save_data(raw)
			equipped[key] = item
			_apply_item_modifiers(item)
			equipment_changed.emit(key, item)


func _apply_item_modifiers(item: ItemInstance) -> void:
	var stats := EntityContract.get_component(owner, "StatsComponent") as StatsComponent
	if stats == null:
		return
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return
	for mod_def in definition.stat_modifiers:
		stats.add_modifier(StatModifier.from_definition(mod_def, item.instance_id))
	for rolled in item.rolled_affixes:
		rolled.source_id = item.instance_id
		stats.add_modifier(rolled)


func _remove_item_modifiers(item: ItemInstance) -> void:
	var stats := EntityContract.get_component(owner, "StatsComponent") as StatsComponent
	if stats != null:
		stats.remove_modifiers_from_source(item.instance_id)
