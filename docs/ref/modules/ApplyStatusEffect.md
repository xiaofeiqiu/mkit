# ApplyStatusEffect

**层：** Module  
**文件：** `addons/mkit/modules/combat/status_effects/apply_status_effect.gd`  
**继承：** `extends GameEffect`

## 职责

效果：给 `context.target` 的 `StatusEffectController` 施加一个状态。把"上毒/上 buff"挂进技能或动作的 effect 链。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `status_id` | `String` | `""` | 要施加的状态 |
| `stacks` | `int` | `1` | 层数 |
| `duration_override` | `float` | `-1.0` | 覆盖时长（`-1` 用定义值）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 失败：`no_target` / `no_status_controller` / `apply_failed:<id>` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 配进 AbilityDefinition.effects：火球命中上毒
var poison := ApplyStatusEffect.new()
poison.status_id = "status.poison"
poison.stacks = 1
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [StatusEffectController](StatusEffectController.md)
- → [cookbook/12_status_effects.md](../../cookbook/12_status_effects.md)
