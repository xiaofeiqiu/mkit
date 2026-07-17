class_name RoomDefinition
extends ContentDefinition
## 说明：`RoomDefinition` 是 房间与一局流程系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `RoomDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册房间定义时使用的稳定 id；RunDirector 和 RoomController 按它加载房间。
@export var room_id: String = ""
## 要加载或实例化的场景路径；应填写 res:// 开头的 .tscn 资源。
@export var scene_path: String = ""
## 房间类型字符串；例如 combat、shop、event，由游戏内容约定。
@export var room_type: String = "combat"
## 房间难度等级；生成器和奖励系统可用它缩放内容。
@export var difficulty_rating: int = 1
## 房间在逻辑网格中的尺寸；用于布局、地图或生成约束。
@export var size: Vector2i = Vector2i(1, 1)
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
## 房间可生成敌人的 EntityDefinition id 列表。
@export var enemy_spawn_ids: Array[String] = []
## 房间可使用的奖励池或 LootTableDefinition id 列表。
@export var reward_pool_ids: Array[String] = []


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return room_id
