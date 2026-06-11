class_name SaveableComponent
extends Node
## 说明：`SaveableComponent` 是 存档系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := SaveableComponent.new()`



## 返回 `save_key` 对应的数据或对象，并保持 `SaveableComponent` 的领域契约一致。
func get_save_key() -> String:
	return name


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `SaveableComponent` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `SaveableComponent` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	pass
