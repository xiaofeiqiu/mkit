class_name ExperienceCurve
extends Resource
## 说明：`ExperienceCurve` 是 成长系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在成长系统中复用这段契约或状态时使用它。
## 示例：`var instance := ExperienceCurve.new()`

## 可达到的最高等级；达到后继续获得经验不再提升等级。
@export var max_level: int = 20
## 各等级所需经验阈值；非空时优先于 base_xp/growth_factor 公式。
@export var xp_thresholds: Array[int] = []
## 公式生成经验阈值时的基础经验。
@export var base_xp: int = 100
## 公式生成经验阈值时的成长倍率；值越大后期升级越慢。
@export var growth_factor: float = 1.5


## 返回 `xp_required` 对应的数据或对象，并保持 `ExperienceCurve` 的领域契约一致。
func get_xp_required(level: int) -> int:
	if level >= max_level:
		return 0
	var index := level - 1
	if index < xp_thresholds.size():
		return xp_thresholds[index]
	return int(base_xp * pow(growth_factor, index))
