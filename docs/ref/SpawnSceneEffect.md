# SpawnSceneEffect

## 概念说明

SpawnSceneEffect 是生成一个场景实例的通用内置 Effect。它从 scene_path 或 ObjectPool 创建节点，设置位置/方向，并把 GameplayContext 传给生成物。投射物、地面掉落、陷阱、召唤物和一次性 VFX 都可能由技能或奖励触发；通用生成效果比写死投射物专用效果更可复用。

## 设计目的

提供一个配置化的场景生成 Effect，使火球投射物、毒雾区域、召唤物等都通过同一个 Effect 生成，支持 ObjectPool 复用，避免在各个技能脚本中重复写加载/实例化/位置初始化代码。

## 文件

`res://addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd`

## 接口

```gdscript
class_name SpawnSceneEffect
extends GameEffect

@export var scene_path: String = ""
@export var use_object_pool: bool = true
@export var parent_group: String = ""
@export var position_offset: Vector2 = Vector2.ZERO
@export var inherit_direction: bool = true

func _apply_impl(context: GameplayContext) -> EffectResult: ...
func _resolve_parent(context: GameplayContext) -> Node: ...
func _spawn_node(parent: Node) -> Node: ...
func _initialize_spawned(spawned: Node, context: GameplayContext) -> void: ...
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法，查找父节点、创建节点、初始化位置和方向，返回含 scene_path 和 spawned 节点引用的 EffectResult.ok。
- **`_resolve_parent(context)`**：按优先级查找父节点：context.payload["spawn_parent"] > parent_group > context.source.get_parent()。
- **`_spawn_node(parent)`**：若 `use_object_pool=true` 则从 ObjectPool acquire，否则 instantiate PackedScene 并 add_child 到 parent。
- **`_initialize_spawned(spawned, context)`**：设置 global_position（含 position_offset），若 `inherit_direction=true` 写入 direction 属性，再调用生成物的 `setup(context)` 方法（若存在）。

## 使用示例

```gdscript
var spawn := SpawnSceneEffect.new()
spawn.effect_id = "effect.spawn_fireball"
spawn.scene_path = "res://game/projectiles/fireball.tscn"
spawn.parent_group = "projectiles"
spawn.position_offset = Vector2(16, 0)
spawn.inherit_direction = true

var ctx := GameplayContext.new()
ctx.source = player
ctx.direction = Vector2.RIGHT
spawn.apply(ctx)
```
