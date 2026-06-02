# ExperienceCurve

## 概念说明

ExperienceCurve 的当前参考文档由实际代码声明补齐。该条目用于记录代码中已经存在但 docs/ref 原先缺失的类型。

## 设计目的

以当前实现为准，提供字段和公开接口索引，便于后续补充更详细的业务语义说明。

## 文件

`res://addons/mkit/modules/progression/experience_curve.gd`

## 字段说明

- **max_level**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **xp_thresholds**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **base_xp**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **growth_factor**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
## 接口

```gdscript
class_name ExperienceCurve
extends Resource
@export var max_level: int = 20
@export var xp_thresholds: Array[int] = []
@export var base_xp: int = 100
@export var growth_factor: float = 1.5
func get_xp_required(level: int) -> int
```

