# GameplayContext

**层：** Kernel  
**文件：** `addons/mkit/kernel/context/gameplay_context.gd`  
**继承：** `extends RefCounted`

## 职责

整条 Effect 管线的共享信使。沿 Effect 链传递，每个 Effect 从中读取 source / target / amount 等，也可写入供下游 Effect 使用。`ActionContext` 继承本类并添加 Action 特有字段。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `source` | `Node` | `null` | 发起动作的实体节点 |
| `target` | `Node` | `null` | 受击目标实体节点 |
| `instigator` | `Node` | `null` | 间接发起者（如召唤物的主人）|
| `ability_id` | `String` | `""` | 触发此 context 的技能 ID |
| `item_id` | `String` | `""` | 触发此 context 的物品 ID |
| `status_id` | `String` | `""` | 触发此 context 的状态效果 ID |
| `room_id` | `String` | `""` | 当前房间 ID |
| `run_id` | `String` | `""` | 当前 run ID |
| `position` | `Vector2` | `Vector2.ZERO` | 事件发生位置（如技能落点）|
| `direction` | `Vector2` | `Vector2.ZERO` | 方向（如击退方向）|
| `amount` | `float` | `0.0` | 通用数值（如伤害量、治疗量）|
| `tags` | `Array[String]` | `[]` | 上下文标签（如 `["aoe","fire"]`）|
| `payload` | `Dictionary` | `{}` | 任意附加数据 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static from_command(cmd, source_node, target_node) -> GameplayContext` | `GameplayContext` | 从 `GameCommand` 创建，自动拷贝 direction / position / ability_id / item_id |
| `with_source(node: Node) -> GameplayContext` | `GameplayContext` | 链式设置 source，返回自身 |
| `with_target(node: Node) -> GameplayContext` | `GameplayContext` | 链式设置 target，返回自身 |
| `with_payload_value(key: String, value) -> GameplayContext` | `GameplayContext` | 链式写入 payload |
| `get_payload_value(key: String, default = null)` | `Variant` | 安全读取 payload |
| `has_tag(tag: String) -> bool` | `bool` | 检查 tags 是否包含指定标签 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var ctx := GameplayContext.new()
ctx.source = self
ctx.target = enemy
```

### 典型场景（Level 2）

```gdscript
# 从命令创建 context
func _on_command_received(cmd: GameCommand) -> void:
    var ctx := GameplayContext.from_command(cmd, owner_entity, _find_target(cmd.target_id))
    # ctx.direction / position / ability_id 已从 cmd.payload 自动填充

    var effects_svc := Mkit.effects()
    if effects_svc == null:
        return
    effects_svc.execute(my_effect, ctx)


# 链式构建（一行完成）
func _make_ctx(src: Node, tgt: Node) -> GameplayContext:
    return GameplayContext.new() \
        .with_source(src) \
        .with_target(tgt) \
        .with_payload_value("hit_type", "ranged")


# Effect 链中上游写入，下游读取
class_name ScaleByDistanceEffect
extends GameEffect

func _apply_impl(ctx: GameplayContext) -> EffectResult:
    # 上游 Effect 可能已经把计算结果写入 payload
    var base := ctx.get_payload_value("scaled_amount", ctx.amount)
    # 写入供下游 Effect 使用
    ctx.with_payload_value("scaled_amount", base * 1.5)
    return EffectResult.ok(effect_id)
```

> **注意：** 不要在 context 里存 Node 引用以外的重型对象（PackedScene、大数组等）；context 沿链共享，过重的对象会影响 GC。

## 相关

- → [ActionContext](ActionContext.md) — 继承 GameplayContext，添加 action_id / duration / phase
- → [GameCommand](GameCommand.md) — `from_command` 的输入
- → [GameEffect](GameEffect.md) — `_apply_impl` 的参数类型
- → [concepts.md — 模型 2：GameplayContext 是共享信使](../../concepts.md#模型-2gameplaycontext-是共享信使)
