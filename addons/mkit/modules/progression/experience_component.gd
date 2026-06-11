class_name ExperienceComponent
extends Saveable
## 说明：`ExperienceComponent` 是 成长系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := ExperienceComponent.new()`

## 当 `ExperienceComponent` 发生 `level up` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal level_up(old_level: int, new_level: int)
## 当 `ExperienceComponent` 发生 `xp changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal xp_changed(current_xp: int, xp_to_next: int)
## 编辑器配置：`curve` 表示 `ExperienceComponent` 的字段值，由 `ExperienceComponent` 的公开 API 读取或维护。
@export var curve: ExperienceCurve = null
## 编辑器配置：`starting_level` 表示 `ExperienceComponent` 的字段值，由 `ExperienceComponent` 的公开 API 读取或维护。
@export var starting_level: int = 1
## 运行时状态：`current_level` 表示当前值，由 `ExperienceComponent` 的公开 API 读取或维护。
var current_level: int = 1
## 运行时状态：`current_xp` 表示当前值，由 `ExperienceComponent` 的公开 API 读取或维护。
var current_xp: int = 0


func _ready() -> void:
	if save_id == "":
		save_id = "experience"
	current_level = starting_level


## 向当前集合或状态中增加数据，并保持 `ExperienceComponent` 的领域契约一致。
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	if curve == null or current_level >= curve.max_level:
		return
	current_xp += amount
	_check_level_ups()
	xp_changed.emit(current_xp, get_xp_to_next_level())


## 返回 `xp_to_next_level` 对应的数据或对象，并保持 `ExperienceComponent` 的领域契约一致。
func get_xp_to_next_level() -> int:
	if curve == null:
		return 0
	return max(0, curve.get_xp_required(current_level) - current_xp)


## 返回 `level_progress` 对应的数据或对象，并保持 `ExperienceComponent` 的领域契约一致。
func get_level_progress() -> float:
	if curve == null:
		return 0.0
	var required := curve.get_xp_required(current_level)
	if required <= 0:
		return 1.0
	return clampf(float(current_xp) / float(required), 0.0, 1.0)


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `ExperienceComponent` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {
		"current_level": current_level,
		"current_xp": current_xp,
	}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `ExperienceComponent` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	current_level = data.get("current_level", starting_level)
	current_xp = data.get("current_xp", 0)


func _check_level_ups() -> void:
	if curve == null:
		return
	while current_level < curve.max_level:
		var required := curve.get_xp_required(current_level)
		if current_xp < required:
			break
		current_xp -= required
		var old_level := current_level
		current_level += 1
		level_up.emit(old_level, current_level)
