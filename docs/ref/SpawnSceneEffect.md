# SpawnSceneEffect

## 概念说明

SpawnSceneEffect 是生成一个场景实例的通用内置 Effect。它从 scene_path 加载 PackedScene，按 GameplayContext 的位置、来源实体或目标实体决定生成位置，并可把方向传给生成物。投射物、地面掉落、陷阱、召唤物和一次性 VFX 都可能由技能或奖励触发；通用生成效果比写死投射物专用效果更可复用。

## 设计目的

提供一个配置化的场景生成 Effect，使火球投射物、毒雾区域、召唤物等都通过同一个 Effect 生成，避免在各个技能脚本中重复写加载、实例化和位置初始化代码。

## 文件

`res://addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd`

## 字段说明

- **scene_path**：要生成的场景路径。例：火球技能生成 `res://game/projectiles/fireball.tscn`。
- **spawn_at_target**：代码字段。为 true 时优先在目标位置生成。

## 接口

```gdscript
class_name SpawnSceneEffect
extends GameEffect
@export var scene_path: String = ""
@export var spawn_at_target: bool = false
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法。校验 scene_path，加载并实例化 PackedScene，把实例添加到 current_scene；若实例是 Node2D，则设置 global_position。位置优先使用 context.position；`spawn_at_target=true` 且 context.target 是 Node2D 时使用目标位置，否则若 context.source 是 Node2D 则使用来源实体位置。若 context.direction 非零且生成物有 `set_direction()` 方法，会调用该方法写入方向。

## 使用示例

```gdscript
var spawn := SpawnSceneEffect.new()
spawn.effect_id = "effect.spawn_fireball"
spawn.scene_path = "res://game/projectiles/fireball.tscn"
spawn.spawn_at_target = false

var ctx := GameplayContext.new()
ctx.source = player
ctx.direction = Vector2.RIGHT
spawn.apply(ctx)
```
