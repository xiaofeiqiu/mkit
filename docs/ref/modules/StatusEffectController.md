# StatusEffectController

**层：** Module  
**文件：** `addons/mkit/modules/combat/status_effects/status_effect_controller.gd`  
**继承：** `extends SaveableComponent`

## 职责

实体的状态效果管理器，挂在 `Controllers/StatusEffectController`。`apply_status` 施加状态（按 `stack_rule` 叠加并挂属性修饰器），每帧 tick 触发 `effects_on_tick`，到期移除并跑 `effects_on_remove`、卸下修饰器。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `apply_status(status_id, source, stacks := 1, duration_override := -1.0) -> bool` | `bool` | 施加/叠加状态 |
| `remove_status(status_id) -> void` | — | 立即移除 |
| `has_status(status_id) -> bool` | `bool` | 是否拥有 |
| `get_definition(status_id) -> StatusEffectDefinition` | — | 查定义 |

## 信号

`status_applied(status_id, stacks)` · `status_removed(status_id)` · `status_ticked(status_id)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var ctrl := EntityContract.get_controller(enemy, "StatusEffectController") as StatusEffectController
ctrl.apply_status("status.poison", attacker, 1, -1.0)
```

### 典型场景（Level 2）

```gdscript
# 施加状态并在结束时反馈；两条入口对照
func poison_and_watch(target: Node, attacker: Node) -> void:
    var ctrl := EntityContract.get_controller(target, "StatusEffectController") as StatusEffectController
    if ctrl == null:
        push_warning("目标无 StatusEffectController")   # 失败路径
        return
    ctrl.status_removed.connect(func(id: String):
        if id == "status.poison":
            print("中毒结束")
    )
    if ctrl.apply_status("status.poison", attacker, 2):   # 叠 2 层
        print("已中毒，当前 %d 层" % 2)
```

> 也可不直接调用：伤害的 `on_hit_statuses` 命中后由 `HealthComponent` 自动转交到这里。存档时是 `SaveableComponent`，需由 `Saveable` 代理收集。

## 相关

- → [StatusEffectDefinition](StatusEffectDefinition.md) · [StatusEffectInstance](StatusEffectInstance.md) · [ApplyStatusEffect](ApplyStatusEffect.md)
- → [pipeline.md — Status Effect Tick](../../pipeline.md#19-status-effect-tick) · [cookbook/12_status_effects.md](../../cookbook/12_status_effects.md)
