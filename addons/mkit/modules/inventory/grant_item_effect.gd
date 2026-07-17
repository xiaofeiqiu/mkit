class_name GrantItemEffect
extends GameEffect
## 说明：`GrantItemEffect` 是 背包与装备系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := GrantItemEffect.new()`

## 引用的 ItemDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var item_id: String = ""
## 物品或奖励数量；应为正数，堆叠物品会按该值合并。
@export var quantity: int = 1
## 是否把物品授予上下文 source；关闭时授予 target。
@export var give_to_source: bool = true


## GameEffect 子类实现此 hook 完成实际效果；apply() 会调用它并返回 EffectResult。
func _apply_impl(context: GameplayContext) -> EffectResult:
	if item_id == "":
		return EffectResult.fail(effect_id, "Missing item_id")
	var receiver := context.source if give_to_source else context.target
	if receiver == null:
		return EffectResult.fail(effect_id, "Missing receiver")
	var inventory := (
		EntityContract.get_controller(receiver, "InventoryController") as InventoryController
	)
	if inventory == null:
		return EffectResult.fail(effect_id, "Receiver has no InventoryController")
	var item := ItemInstance.create(item_id, quantity)
	if not inventory.can_add_item(item):
		return EffectResult.fail(effect_id, "Inventory cannot accept item: %s" % item_id)
	inventory.add_item(item)
	return EffectResult.ok(
		effect_id, {"item_id": item_id, "quantity": quantity, "instance_id": item.instance_id}
	)
