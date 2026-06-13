class_name Interactable
extends Node
## 说明：`Interactable` 是 交互系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在交互系统中复用这段契约或状态时使用它。
## 示例：`var instance := Interactable.new()`

## 交互点的稳定 id；事件、存档或测试可用它定位交互对象。
@export var interaction_id: String = ""
## 交互提示文本；UI 可直接显示给玩家。
@export var display_text: String = "Interact"
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []


## 用 GameplayContext 和当前运行时状态判断是否允许 `interact`；失败原因由对应查询 API 提供。
func can_interact(context: GameplayContext) -> bool:
	return ConditionEvaluator.evaluate_all(conditions, context)


## 执行 `interact` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func interact(context: GameplayContext) -> bool:
	if not can_interact(context):
		return false
	return _interact_impl(context)


func _interact_impl(context: GameplayContext) -> bool:
	return true
