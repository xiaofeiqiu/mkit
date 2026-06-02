# ExperienceComponent

## 概念说明

ExperienceComponent 的当前参考文档由实际代码声明补齐。该条目用于记录代码中已经存在但 docs/ref 原先缺失的类型。

## 设计目的

以当前实现为准，提供字段和公开接口索引，便于后续补充更详细的业务语义说明。

## 文件

`res://addons/mkit/modules/progression/experience_component.gd`

## 字段说明

- **curve**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **starting_level**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **current_level**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **current_xp**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
## 接口

```gdscript
class_name ExperienceComponent
extends Saveable
signal level_up(old_level: int, new_level: int)
signal xp_changed(current_xp: int, xp_to_next: int)
@export var curve: ExperienceCurve = null
@export var starting_level: int = 1
var current_level: int = 1
var current_xp: int = 0
func add_xp(amount: int) -> void
func get_xp_to_next_level() -> int
func get_level_progress() -> float
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

