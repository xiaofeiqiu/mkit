class_name HurtboxComponent
extends Area2D
## 说明：`HurtboxComponent` 是 战斗系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := HurtboxComponent.new()`

## Hurtbox 向上查找拥有者的 NodePath；默认指向实体根节点。
@export var owner_path: NodePath = NodePath("../..")
## 是否允许该 Hurtbox 接收伤害；关闭后忽略传入命中。
@export var can_receive_damage: bool = true
## 受到伤害时应用的倍率；1 为原始伤害，0 表示免疫。
@export var damage_multiplier: float = 1.0
## Hurtbox 为传入伤害补充的标签；可用于部位、护甲或弱点规则。
@export var damage_tags: Array[String] = []


## 读取当前对象中的 `owner_entity`；未找到时返回 null、空集合或该 API 的默认值。
func get_owner_entity() -> Node:
	return get_node_or_null(owner_path)
