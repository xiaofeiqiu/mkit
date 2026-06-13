class_name ZoneDefinition
extends ContentDefinition
## 说明：`ZoneDefinition` 是 世界与场景系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `ZoneDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册区域定义时使用的稳定 id；WorldService 切换区域时按它查找场景。
@export var zone_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 要加载或实例化的场景路径；应填写 res:// 开头的 .tscn 资源。
@export var scene_path: String = ""
## 进入区域时播放的 AudioDefinition id；为空表示不切换音乐。
@export var bgm_id: String = ""
## 区域默认出生点 id；Portal 没有指定 spawn 时使用。
@export var default_spawn_id: String = "default"
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return zone_id
