class_name InventoryController
extends SaveableComponent
## 说明：`InventoryController` 是 背包与装备系统 的实体控制器，负责协调实体组件、服务和运行时状态。
## 上游：通常由 EntityRoot、CommandReceiver、StateMachine、玩家输入或 AI 创建或调用。
## 下游：会连接组件、ActionService、EffectService、ContentService 和 EventService，不直接依赖具体游戏内容。
## 使用：当项目实体需要把输入、状态机和组件能力组合成可调用行为时使用它。
## 示例：`var instance := InventoryController.new()`

## 当 `InventoryController` 发生 `inventory changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal inventory_changed
## 当 `InventoryController` 发生 `item added` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal item_added(item: ItemInstance)
## 当 `InventoryController` 发生 `item removed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal item_removed(item: ItemInstance)
## 背包容量，单位为槽位数量；0 或负数表示不能存放物品。
@export var capacity: int = 30
## InventoryController 持有的运行时背包模型。
var model := InventoryModel.new()


func _ready() -> void:
	capacity = max(1, capacity)
	model.setup(capacity)
	model.owner_id = _get_owner_id()


## 用 GameplayContext 和当前运行时状态判断是否允许 `add_item`；失败原因由对应查询 API 提供。
func can_add_item(item: ItemInstance) -> bool:
	if item == null:
		return false
	if item.quantity <= 0:
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	if definition.stackable and definition.max_stack <= 0:
		return false
	return _free_space_for(definition) >= item.quantity


## 向当前集合或状态加入传入数据；重复项按该对象规则合并或覆盖。
func add_item(item: ItemInstance) -> bool:
	if item == null:
		push_warning("InventoryController.add_item: item is null")
		return false
	if item.quantity <= 0:
		push_warning("InventoryController.add_item: item quantity must be > 0")
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	if definition.stackable and definition.max_stack <= 0:
		push_error(
			(
				"InventoryController.add_item: stackable item has invalid max_stack <= 0: %s"
				% item.definition_id
			)
		)
		return false
	var stack_size := definition.max_stack if definition.stackable else 1
	if stack_size <= 0:
		push_error(
			"InventoryController.add_item: invalid stack size for item %s" % item.definition_id
		)
		return false
	if _free_space_for(definition) < item.quantity:
		return false
	var remaining := item.quantity
	var original_quantity := item.quantity
	if definition.stackable:
		for slot in model.slots:
			if slot.item != null and slot.item.definition_id == item.definition_id:
				var space := definition.max_stack - slot.item.quantity
				if space <= 0:
					continue
				var moved := min(space, remaining)
				slot.item.quantity += moved
				remaining -= moved
				if remaining <= 0:
					item_added.emit(item)
					_emit_inventory_changed(item, original_quantity, "added")
					return true
	var placed_original := false
	while remaining > 0:
		var empty := model.find_first_empty_slot()
		if empty == null:
			break
		var amount := min(remaining, stack_size)
		var stack: ItemInstance
		if not placed_original:
			item.quantity = amount
			stack = item
			placed_original = true
		else:
			stack = ItemInstance.create(item.definition_id, amount)
		empty.item = stack
		remaining -= amount
	item_added.emit(item)
	_emit_inventory_changed(item, original_quantity, "added")
	return true


func _free_space_for(definition: ItemDefinition) -> int:
	var stack_size := definition.max_stack if definition.stackable else 1
	if stack_size <= 0:
		return 0
	var total := 0
	for slot in model.slots:
		if slot.item == null:
			total += stack_size
		elif definition.stackable and slot.item.definition_id == definition.item_id:
			total += max(0, stack_size - slot.item.quantity)
	return total


## 从当前集合或状态移除传入数据；目标不存在时安全返回。
func remove_item_by_instance_id(instance_id: String, quantity: int = 1) -> bool:
	if instance_id.strip_edges() == "":
		return false
	if quantity <= 0:
		push_warning("InventoryController.remove_item_by_instance_id: quantity must be > 0")
		return false
	for slot in model.slots:
		if slot.item != null and slot.item.instance_id == instance_id:
			var removed_quantity: int = min(quantity, slot.item.quantity)
			var changed_item := slot.item
			slot.item.quantity -= quantity
			if slot.item.quantity <= 0:
				var removed := slot.item
				slot.clear()
				item_removed.emit(removed)
			_emit_inventory_changed(changed_item, removed_quantity, "removed")
			return true
	return false


## 执行 `find_item` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func find_item(instance_id: String) -> ItemInstance:
	for slot in model.slots:
		if slot.item != null and slot.item.instance_id == instance_id:
			return slot.item
	return null


## 执行 `find_item_by_definition` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func find_item_by_definition(definition_id: String) -> ItemInstance:
	for slot in model.slots:
		if slot.item != null and slot.item.definition_id == definition_id:
			return slot.item
	return null


## 读取当前对象中的 `item_definition`；未找到时返回 null、空集合或该 API 的默认值。
func get_item_definition(item_id: String) -> ItemDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(item_id) as ItemDefinition


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	var items: Array = []
	for slot in model.slots:
		items.append(slot.item.to_save_data() if slot.item != null else null)
	return {"capacity": capacity, "items": items}


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
func from_save_data(data: Dictionary) -> void:
	capacity = int(data.get("capacity", capacity))
	capacity = max(1, capacity)
	model.setup(capacity)
	var items: Array = data.get("items", [])
	for i in range(min(items.size(), model.slots.size())):
		if items[i] != null:
			model.slots[i].item = ItemInstance.from_save_data(items[i])
	_emit_inventory_changed(null, 0, "loaded")


func _emit_inventory_changed(
	item: ItemInstance = null, quantity: int = 0, change_type: String = ""
) -> void:
	inventory_changed.emit()
	var events: EventService = null
	events = Mkit.events()
	if events != null:
		events.emit_domain_event(
			InventoryEvents.inventory_changed(
				_get_owner_id(), item.definition_id if item != null else "", quantity, change_type
			)
		)


func _get_owner_id() -> String:
	var owner_node := owner if owner != null else get_parent()
	if owner_node == null:
		return name
	var identity := EntityContract.get_identity(owner_node)
	return identity.entity_id if identity != null else str(owner_node.name)
