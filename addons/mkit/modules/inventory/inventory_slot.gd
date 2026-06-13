class_name InventorySlot
extends RefCounted
## 说明：`InventorySlot` 是 背包与装备系统 的槽位对象，负责保存容器中的单个条目状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在背包与装备系统中复用这段契约或状态时使用它。
## 示例：`var instance := InventorySlot.new()`

## 槽位在背包中的位置；-1 表示尚未放入模型。
var index: int = -1
## 槽位内的物品实例；为 null 表示空槽。
var item: ItemInstance = null


## 检查当前对象是否满足 `empty` 状态；调用方可据此选择后续流程。
func is_empty() -> bool:
	return item == null


## 清空本对象持有的运行时表和缓存；通常在测试或重新 bootstrap 前调用。
func clear() -> void:
	item = null
