# LogEffect

## 概念说明

LogEffect 是一个调试用途的内置效果，用于在技能、奖励或状态执行链路中插入可追踪的日志点。它把指定消息打印到控制台，并通过 EventRouter 发出一个 domain event，方便 DebugOverlay 和日志追踪捕获执行时序。

## 设计目的

提供一个零副作用的调试效果，可以挂入任意 effects 列表（AbilityDefinition、RewardDefinition、StatusEffectDefinition），在不修改玩法逻辑的情况下观察效果链路的执行时机和上下文，适合 Phase 0/1 验证阶段的管线调试。

## 文件

`res://addons/mkit/kernel/effects/builtin/log_effect.gd`

## 字段说明

- **message**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **event_type**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name LogEffect
extends GameEffect
@export var message: String = "log"
@export var event_type: String = "log"
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法，在效果执行时向控制台输出消息，并通过 EventRouter 发出 DomainEvent（event_type 可自定义）。EffectExecutor 调用 `apply()` 时触发。始终返回 `EffectResult.ok`，不会阻断后续效果执行。

## 使用示例

### 在技能效果链中插入日志

```gdscript
var log_effect := LogEffect.new()
log_effect.effect_id = "effect.debug_log"
log_effect.message = "Fireball hit"
log_effect.event_type = "debug.fireball_hit"

# 插入到 fireball effects 列表中
fireball_definition.effects = [damage_effect, log_effect, burn_effect]
```

### 输出示例

```text
[LogEffect] Fireball hit (source=Player target=Goblin)
```
