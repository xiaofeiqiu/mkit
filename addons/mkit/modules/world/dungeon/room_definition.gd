class_name RoomDefinition
extends ContentDefinition
## 说明：`RoomDefinition` 是 房间与一局流程系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `RoomDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`room_id` 表示稳定 id，由 `RoomDefinition` 的公开 API 读取或维护。
@export var room_id: String = ""
## 编辑器配置：`scene_path` 表示资源或节点路径，由 `RoomDefinition` 的公开 API 读取或维护。
@export var scene_path: String = ""
## 编辑器配置：`room_type` 表示 `RoomDefinition` 的字段值，由 `RoomDefinition` 的公开 API 读取或维护。
@export var room_type: String = "combat"
## 编辑器配置：`difficulty_rating` 表示 `RoomDefinition` 的字段值，由 `RoomDefinition` 的公开 API 读取或维护。
@export var difficulty_rating: int = 1
## 编辑器配置：`size` 表示 `RoomDefinition` 的字段值，由 `RoomDefinition` 的公开 API 读取或维护。
@export var size: Vector2i = Vector2i(1, 1)
## 编辑器配置：`tags` 表示标签集合，由 `RoomDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
## 编辑器配置：`enemy_spawn_ids` 表示稳定 id 列表，由 `RoomDefinition` 的公开 API 读取或维护。
@export var enemy_spawn_ids: Array[String] = []
## 编辑器配置：`reward_pool_ids` 表示稳定 id 列表，由 `RoomDefinition` 的公开 API 读取或维护。
@export var reward_pool_ids: Array[String] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `RoomDefinition` 的领域契约一致。
func get_content_id() -> String:
	return room_id
