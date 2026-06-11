class_name HurtboxComponent
extends Area2D
## 说明：`HurtboxComponent` 是 战斗系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := HurtboxComponent.new()`

## 编辑器配置：`owner_path` 表示资源或节点路径，由 `HurtboxComponent` 的公开 API 读取或维护。
@export var owner_path: NodePath = NodePath("../..")
## 编辑器配置：`can_receive_damage` 表示 `HurtboxComponent` 的字段值，由 `HurtboxComponent` 的公开 API 读取或维护。
@export var can_receive_damage: bool = true
## 编辑器配置：`damage_multiplier` 表示 `HurtboxComponent` 的字段值，由 `HurtboxComponent` 的公开 API 读取或维护。
@export var damage_multiplier: float = 1.0
## 编辑器配置：`damage_tags` 表示标签集合，由 `HurtboxComponent` 的公开 API 读取或维护。
@export var damage_tags: Array[String] = []


## 返回 `owner_entity` 对应的数据或对象，并保持 `HurtboxComponent` 的领域契约一致。
func get_owner_entity() -> Node:
	return get_node_or_null(owner_path)
