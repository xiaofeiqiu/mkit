# Debugging

当系统不按预期运行时的第一查阅点。

---

## 内置调试工具

### DebugOverlay

在场景树里添加 `DebugOverlay` 节点（`extends CanvasLayer`），运行时屏幕左上角实时显示：
- 已注册的服务 ID 列表
- `watch_entity_path` 实体的当前状态路径、最近命令、HP
- 最近 5 条领域事件名称
- `last_failed_transition_reason`（如有）

```gdscript
# Inspector 配置
# watch_entity_path = NodePath("../Player")
# visible_on_start = true
# show_registered_services = true

# 运行时切换显隐
var overlay := ServiceRegistry.get_service("debug") as DebugOverlay
if overlay != null:
    overlay.toggle()
```

也可实现 `get_debug_status_lines() -> Array[String]` 方法挂到 `status_provider_path`，注入自定义行。

---

### EventService.recent_events

回放最近 100 个领域事件，确认事件是否发出、顺序是否正确：

```gdscript
var events := ServiceRegistry.get_service("events") as EventService
for event in events.recent_events:
    print("[%.2f] %s  source=%s target=%s" % [
        event.timestamp, event.event_type,
        event.source_id, event.target_id
    ])
```

也可订阅 `domain_event_emitted` 信号获取实时推送：

```gdscript
events.domain_event_emitted.connect(func(e: DomainEvent) -> void:
    print("event: %s payload=%s" % [e.event_type, e.payload])
)
```

---

### EffectService trace

`EffectService.trace_enabled`（默认 `true`）记录每次 `execute()` 的结果到 `recent_results`，定位"技能放了但没效果"：

```gdscript
var effects := ServiceRegistry.get_service("effects") as EffectService
for result in effects.recent_results:
    if not result.success:
        print("FAIL  %s: %s" % [result.effect_id, result.failure_reason])
    else:
        print("OK    %s payload=%s" % [result.effect_id, result.payload])
```

---

### CombatService trace

`DamageResult.trace` 记录伤害各阶段中间值：

```gdscript
# DealDamageEffect._apply_impl 返回后：
var result: DamageResult = ...
print(result.trace)
# 输出示例：
# {"base": 20.0, "after_attack_power": 35.0, "after_damage_multiplier": 35.0,
#  "after_crit": 52.5, "after_defense": 42.5}
```

---

### StateMachine 诊断

```gdscript
var sm := entity.get_node("StateMachine") as StateMachine

# 当前状态完整路径
print(sm.get_current_path())           # "Root/Combat/Attack"

# 最近一次成功 transition 的原因
print(sm.last_transition_reason)       # "attack_command"

# 最近一次失败 transition 的原因
print(sm.last_failed_transition_reason) # "Current state chain cannot exit"

# 监听 transition 失败
sm.transition_failed.connect(func(from: String, to: String, reason: String) -> void:
    print("transition FAILED: %s → %s  reason=%s" % [from, to, reason])
)
```

---

### RandomService 固定种子

复现概率性 bug（暴击、掉落、闪避）：

```gdscript
var rng := ServiceRegistry.get_service("random") as RandomService
rng.set_seed(12345)    # 固定种子，每次运行结果相同
```

---

## 常见问题速查表

| 现象 | 先检查 | 常见原因 |
|------|--------|----------|
| 技能按了没反应 | `AbilityController.get_cast_failure_reason(id, ctx)` | 冷却中、cost 不足、conditions 不满足、ability_id 未注册 |
| Effect 执行了但没效果 | `EffectService.recent_results` 查失败条目 | `conditions` 未通过、`_apply_impl` 未 override、`context.target` 为 null |
| 状态没切换 | `StateMachine.last_failed_transition_reason` | `can_enter()` 返回 false、路径拼错、HFSM 层级匹配不到 |
| 动画不播 | `Presentation/AnimationPlayer` 是否存在；`anim.has_animation(name)` | 节点路径不符合实体约定；Action 中 `has_animation` 检查失败后静默跳过 |
| 存档读取后数据丢失 | `to_save_data()` 返回值；节点 `name` 与 save key 的匹配 | 忘记 override；`get_save_id()` 返回空串；节点 name 与存档 key 不匹配 |
| 服务取到 null | `ServiceRegistry.has_service("id")` | Bootstrap 未运行；服务 ID 拼错；测试环境未注册 |
| 实体组件找不到兄弟 | `owner.get_node_or_null("Components/XxxComponent")` | 节点路径不符合实体约定布局（EntityRoot / Components / Controllers / Presentation） |
| Command 发出但无响应 | `CommandService.command_failed` 信号 | `target_id` 为空、接收方未注册、`receive_command` 返回 false |
| Action 一直不结束 | `ActionService.active_actions` 列表 | `GameAction.complete()` 或 `cancel()` 未被调用；`_on_update` 判断条件有 bug |
| ContentService 报 duplicate id | 启动日志 | 两个 `.tres` 的 `get_content_id()` 返回了相同字符串 |

---

## 调试模式检查清单

遇到"系统不动"时，按顺序检查：

1. **服务在线**：`ServiceRegistry.has_service("xxx")` → 若 false，Bootstrap 未运行或服务 ID 拼错
2. **命令到达**：订阅 `CommandService.command_dispatched` / `command_failed`，确认命令被发出且被路由
3. **状态响应**：打印 `sm.get_current_path()`，检查 `last_failed_transition_reason`
4. **Effect 执行**：`EffectService.recent_results`，找 `success = false` 条目
5. **事件发出**：`EventService.recent_events`，确认预期事件出现
6. **表现层**：检查信号是否已连接，节点路径是否正确
