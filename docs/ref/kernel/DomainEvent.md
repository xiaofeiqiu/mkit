# DomainEvent

**层：** Kernel  
**文件：** `addons/mkit/kernel/events/domain_event.gd`  
**继承：** `extends RefCounted`

## 职责

领域事件的统一数据载体。每次 `EventService.emit_*` 都会构造一个 `DomainEvent` 入队 `recent_events` 并通过 `domain_event_emitted` 广播。`QuestService` 等"通用订阅者"读它的 `event_type` / `payload` 来工作。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `event_type` | `String` | `""` | 事件类型（`"damage_applied"` / `"enemy_killed"` …）|
| `event_id` | `String` | `""` | 唯一 id（`type_时间戳`）|
| `timestamp` | `float` | `0.0` | 发生时间（秒）|
| `source_id` | `String` | `""` | 来源实体 id |
| `target_id` | `String` | `""` | 目标实体 id |
| `payload` | `Dictionary` | `{}` | 事件附加数据 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static create(type, source="", target="", data={})` | `DomainEvent` | 构造并填好 `event_id` / `timestamp` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 通用订阅里读事件
events.domain_event_emitted.connect(func(e: DomainEvent) -> void:
    if e.event_type == "enemy_killed":
        print("击杀 faction=%s" % e.payload.get("faction", "?"))
)
```

## 相关

- → [EventService](EventService.md)（创建并广播）
- → [ref/modules/QuestService.md](../modules/QuestService.md)（按 `event_type`/`payload` 匹配任务目标）
