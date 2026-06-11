class_name ExperienceCurve
extends Resource
## 说明：`ExperienceCurve` 是 成长系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在成长系统中复用这段契约或状态时使用它。
## 示例：`var instance := ExperienceCurve.new()`

## 编辑器配置：`max_level` 表示最大值，由 `ExperienceCurve` 的公开 API 读取或维护。
@export var max_level: int = 20
## 编辑器配置：`xp_thresholds` 表示 `ExperienceCurve` 的字段值，由 `ExperienceCurve` 的公开 API 读取或维护。
@export var xp_thresholds: Array[int] = []
## 编辑器配置：`base_xp` 表示 `ExperienceCurve` 的字段值，由 `ExperienceCurve` 的公开 API 读取或维护。
@export var base_xp: int = 100
## 编辑器配置：`growth_factor` 表示 `ExperienceCurve` 的字段值，由 `ExperienceCurve` 的公开 API 读取或维护。
@export var growth_factor: float = 1.5


## 返回 `xp_required` 对应的数据或对象，并保持 `ExperienceCurve` 的领域契约一致。
func get_xp_required(level: int) -> int:
	if level >= max_level:
		return 0
	var index := level - 1
	if index < xp_thresholds.size():
		return xp_thresholds[index]
	return int(base_xp * pow(growth_factor, index))
