# RandomService

## 概念说明

RandomService 是统一随机数服务。负责保存 run seed，提供 randf、randi_range、randf_range、chance、weighted_pick 等确定性随机 API。战斗暴击、掉落、奖励和地牢生成都需要随机；集中在一个服务里才能复现 bug、写测试和保存/恢复 run。

## 设计目的

将所有玩法随机操作统一经由此服务，确保在相同 seed 下行为可复现。所有模块（战斗、掉落、生成器）都不直接调用 Godot 的全局 `randf()`，而是通过 `"random"` 服务获取此对象。

## 文件

`res://addons/mkit/kernel/services/random_service.gd`

## 字段说明

- **seed_value**：当前随机种子。例：RunState 保存 seed_value 后，重新进入同一局可以复现房间图和掉落。
- **rng**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name RandomService
extends RefCounted
var seed_value: int = 0
var rng := RandomNumberGenerator.new()
func set_seed(value: int) -> void
func randomize_seed() -> int
func randf() -> float
func randi_range(from: int, to: int) -> int
func randf_range(from: float, to: float) -> float
func chance(probability: float) -> bool
func weighted_pick(entries: Array, weight_property: String = "weight")
```

## 函数使用场景

- **set_seed()**：写入随机种子。例：RunDirector.start_run 创建 seed 后设置到 RandomService，确保本局所有随机都可复现。
- **randomize_seed()**：生成随机种子并应用。例：玩家新开一局且未指定 seed 时使用。
- **randf()**：返回 [0, 1) 范围浮点随机数。例：CombatResolver 用它判断是否触发暴击。
- **randi_range()**：返回整数区间随机值。例：LootSystem 掷掉落数量。
- **randf_range()**：返回浮点区间随机值。例：VFXSpawner 给粒子轻微随机偏移。
- **chance()**：概率判定。例：状态效果按 30% 概率触发附加状态。
- **weighted_pick()**：权重选择。例：RewardSystem 从候选奖励池中按权重选出展示选项。

## 使用示例

### 设置 seed 并进行概率判定

```gdscript
var random := ServiceRegistry.get_service("random") as RandomService
random.set_seed(12345)

if random.chance(0.25):
    print("Critical roll succeeded")
```

### 权重掉落选择

```gdscript
var entries := [
    {"id": "item.potion_small", "weight": 10.0},
    {"id": "item.sword_iron", "weight": 1.0}
]
var picked := random.weighted_pick(entries)
print(picked["id"])
```
