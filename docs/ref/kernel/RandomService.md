# RandomService

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/random_service.gd`  
**继承：** `extends RefCounted`  
**服务 ID：** `"random"`

## 职责

带种子的随机数源。`CombatService`（暴击/闪避）、`LootService`、`DungeonGenerator` 都走它，固定种子即可复现概率性行为——调试随机 bug 的关键。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `seed_value` | `int` | `0` | 当前种子 |
| `rng` | `RandomNumberGenerator` | — | 底层 RNG |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `set_seed(value: int) -> void` | — | 设种子（复现用）|
| `randomize_seed() -> int` | `int` | 随机化并返回新种子 |
| `randf() -> float` | `float` | `[0,1)` |
| `randi_range(from, to) -> int` | `int` | 整数闭区间 |
| `randf_range(from, to) -> float` | `float` | 浮点区间 |
| `chance(probability: float) -> bool` | `bool` | `randf() < clamp(p,0,1)` |
| `weighted_pick(entries: Array, weight_property := "weight")` | `Variant` | 按权重属性加权抽取 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var rng := Mkit.random()
rng.set_seed(12345)           # 固定种子 → 可复现
if rng.chance(0.25):
    print("暴击！")
```

## 相关

- → [ref/modules/CombatService.md](../modules/CombatService.md) · [ref/modules/LootService.md](../modules/LootService.md)
- → [debugging.md](../../debugging.md)（固定种子复现）
