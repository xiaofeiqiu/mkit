# AbilityInstance

**层：** Module  
**文件：** `addons/mkit/modules/combat/abilities/ability_instance.gd`  
**继承：** `extends RefCounted`

## 职责

技能的**运行时状态**：每个实体每个技能一份，跟踪冷却剩余、当前充能、等级。`AbilityController` 每帧 `tick()` 推进冷却。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `definition_id` | `String` | `""` | 对应 `AbilityDefinition.ability_id` |
| `owner` | `Node` | `null` | 持有实体 |
| `cooldown_remaining` | `float` | `0.0` | 剩余冷却 |
| `current_charges` | `int` | `1` | 当前充能 |
| `runtime_level` | `int` | `1` | 运行时等级 |
| `enabled` | `bool` | `true` | 是否可用 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `setup(definition, owner_entity) -> void` | — | 初始化 |
| `tick(delta) -> void` | — | 推进冷却，到点恢复充能 |
| `is_cooldown_ready() -> bool` | `bool` | `current_charges > 0` |
| `start_cooldown(definition, cooldown_reduction := 0.0) -> void` | — | 消耗一层并开始冷却 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 一般不直接构造，由 AbilityController.register_ability 创建并管理
var ctrl := EntityContract.get_controller(player, "AbilityController") as AbilityController
print(ctrl.get_cooldown_remaining("fireball"))
```

## 相关

- → [AbilityController](AbilityController.md) · [AbilityDefinition](AbilityDefinition.md)
