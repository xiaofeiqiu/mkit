# ExperienceComponent

**层：** Module  
**文件：** `addons/mkit/modules/progression/experience_component.gd`  
**继承：** `extends Saveable`

## 职责

实体的经验与等级，挂在实体下。`add_xp` 累计、跨级时发 `level_up`，溢出 XP 结转下一级。是 `Saveable`（`save_id="experience"`），开箱即存。等级阈值来自 `ExperienceCurve`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `curve` | `ExperienceCurve`（@export）| `null` | 升级曲线 |
| `starting_level` | `int`（@export）| `1` | 起始等级 |
| `current_level` | `int` | `1` | 当前等级 |
| `current_xp` | `int` | `0` | 当前级内 XP |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `add_xp(amount) -> void` | — | 加 XP（满级或无 curve 时忽略）|
| `get_xp_to_next_level() -> int` | `int` | 距升级还差多少 |
| `get_level_progress() -> float` | `float` | 当前级进度 `[0,1]` |

## 信号

`level_up(old_level, new_level)` · `xp_changed(current_xp, xp_to_next)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var xp := player.get_node("ExperienceComponent") as ExperienceComponent
xp.level_up.connect(func(o: int, n: int): print("升级 %d→%d" % [o, n]))
xp.add_xp(50)
```

> 击杀给经验需自己接线（监听 `EventService.entity_died` → `add_xp`），见 [cookbook/11](../../cookbook/11_progression_and_save.md)。

## 相关

- → [ExperienceCurve](ExperienceCurve.md) · [ProgressionService](ProgressionService.md)
- → [pipeline.md — Progression / Level Up](../../pipeline.md#17-progression--level-up)
