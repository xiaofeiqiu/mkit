class_name SpawnPoint
extends Marker2D
## 说明：`SpawnPoint` 是 世界与场景系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在世界与场景系统中复用这段契约或状态时使用它。
## 示例：`var instance := SpawnPoint.new()`

## 公开常量 `GROUP`，作为 `SpawnPoint` 对外暴露的类型、事件或命令标识。
const GROUP: String = "spawn_point"
## 编辑器配置：`spawn_id` 表示稳定 id，由 `SpawnPoint` 的公开 API 读取或维护。
@export var spawn_id: String = "default"


func _ready() -> void:
	add_to_group(GROUP)
