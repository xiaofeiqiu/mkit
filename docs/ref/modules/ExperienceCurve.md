# ExperienceCurve

**层：** Module  
**文件：** `addons/mkit/modules/progression/experience_curve.gd`  
**继承：** `extends Resource`

## 职责

升级阈值曲线（`.tres`）。`ExperienceComponent` 用 `get_xp_required(level)` 取每级所需 XP——优先用显式表 `xp_thresholds`，缺省走指数公式。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `max_level` | `int` | `20` | 满级 |
| `xp_thresholds` | `Array[int]` | `[]` | 逐级所需（优先于公式）|
| `base_xp` | `int` | `100` | 公式首级所需 |
| `growth_factor` | `float` | `1.5` | 公式增长系数 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_xp_required(level) -> int` | `int` | 该级升级所需 XP（满级返回 0）|

## 公式

`xp_required(level) = base_xp × growth_factor^(level-1)`（`xp_thresholds` 内有值则取表）

## 相关

- → [ExperienceComponent](ExperienceComponent.md)
