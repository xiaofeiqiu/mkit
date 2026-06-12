class_name EntityDefinition
extends ContentDefinition
## 说明：`EntityDefinition` 是 实体系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `EntityDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册实体定义时使用的稳定 id；EntitySpawner 按它实例化实体场景。
@export var entity_definition_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 要加载或实例化的场景路径；应填写 res:// 开头的 .tscn 资源。
@export var scene_path: String = ""
## 生成实体时写入 EntityIdentity 的默认阵营。
@export var default_faction: String = "neutral"
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
## 实体基础属性表；key 为 stat id，value 为初始数值。
@export var base_stats: Dictionary = {}
## 初始化时授予实体的 AbilityDefinition id 列表；每项需已在 ContentService 注册。
@export var starting_ability_ids: Array[String] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `EntityDefinition` 的领域契约一致。
func get_content_id() -> String:
	return entity_definition_id
