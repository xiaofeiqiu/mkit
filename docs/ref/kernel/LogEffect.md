# LogEffect

**层：** Kernel  
**文件：** `addons/mkit/kernel/effects/builtin/log_effect.gd`  
**继承：** `extends GameEffect`

## 职责

内置调试效果：打印一条日志并发一个 `DomainEvent`。用于在 effect 链里插探针，确认某一跳确实执行到了。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `message` | `String`（@export）| `"log"` | 打印与事件 payload 里的文案 |
| `event_type` | `String`（@export）| `"log"` | 发出的 `DomainEvent.event_type` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | `print` + `EventService.emit_domain_event`，总是成功 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 临时插到 on_complete_effects 第一个，确认动作完成时 effect 链有跑
var probe := LogEffect.new()
probe.message = "attack landed"
action.on_complete_effects = [probe, deal_damage_effect]
```

## 相关

- → [GameEffect](GameEffect.md) · [EventService](EventService.md)
- → [debugging.md](../../debugging.md)
