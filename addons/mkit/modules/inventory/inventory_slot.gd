class_name InventorySlot
extends RefCounted
## 说明：`InventorySlot` 是 背包与装备系统 的槽位对象，负责保存容器中的单个条目状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在背包与装备系统中复用这段契约或状态时使用它。
## 示例：`var instance := InventorySlot.new()`

## 运行时状态：`index` 表示 `InventorySlot` 的字段值，由 `InventorySlot` 的公开 API 读取或维护。
var index: int = -1
## 运行时状态：`item` 表示 `InventorySlot` 的字段值，由 `InventorySlot` 的公开 API 读取或维护。
var item: ItemInstance = null


## 判断 `empty` 当前是否成立，并保持 `InventorySlot` 的领域契约一致。
func is_empty() -> bool:
	return item == null


## 清理当前保存的运行时状态或缓存，并保持 `InventorySlot` 的领域契约一致。
func clear() -> void:
	item = null
