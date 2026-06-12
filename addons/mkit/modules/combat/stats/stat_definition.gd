class_name StatDefinition
extends ContentDefinition
## 说明：`StatDefinition` 是 属性系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `StatDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册属性定义时使用的稳定 id；StatsComponent 的 base_stats 按它取值。
@export var stat_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 该属性未被组件显式配置时使用的基础值。
@export var default_value: float = 0.0
## 属性计算后的最小允许值；使用 -INF 表示不限制下界。
@export var min_value: float = -INF
## 属性计算后的最大允许值；使用 INF 表示不限制上界。
@export var max_value: float = INF
## 该属性是否按百分比展示；只影响显示约定，不改变内部数值单位。
@export var is_percent: bool = false


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `StatDefinition` 的领域契约一致。
func get_content_id() -> String:
	return stat_id
