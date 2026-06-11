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
var overlay := ServiceRegistry.get_port("debug") as DebugOverlay
if overlay != null:
    overlay.toggle()
```

也可实现 `get_debug_status_lines() -> Array[String]` 方法挂到 `status_provider_path`，注入自定义行。

demo 的 `game/village_rpg_demo.gd` 已通过 `status_provider_path` 聚合当前 zone、run 状态、交互 focus、最近 failed command、最近 failed effect 和 missing service。普通 HUD 保留玩家信息，开发诊断优先看 DebugOverlay。

---

### EventService.recent_events

回放最近 100 个领域事件，确认事件是否发出、顺序是否正确：

```gdscript
var events := Mkit.events()
for event in events.recent_events:
    print("[%.2f] %s  source=%s target=%s" % [
        event.timestamp, event.event_type,
        event.source_id, event.target_id
    ])
```

也可订阅所有领域事件获取实时推送：

```gdscript
events.subscribe(EventService.ANY_EVENT, func(e: DomainEvent) -> void:
    print("event: %s payload=%s" % [e.event_type, e.payload])
)
```

`domain_event_emitted` 信号仍会发出，但只建议 DebugOverlay、录制/回放工具这类 firehose 调试用途直接连接。

---

### EffectService trace

`EffectService.trace_enabled`（默认 `false`，调试时手动打开）开启后记录每次 `execute()` 的结果到 `recent_results`，定位"技能放了但没效果"：

```gdscript
var effects := Mkit.effects()
effects.trace_enabled = true
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
var sm := EntityContract.get_state_machine(entity)

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
var rng := Mkit.random()
rng.set_seed(12345)    # 固定种子，每次运行结果相同
```

---

## 按症状选择工具

| 现象 | 先看哪里 | 下一步 |
|------|----------|--------|
| 按键没反应 | DebugOverlay 的 `Focus`、`Last command`、`Last failed command` | 确认玩家是否在交互区域内，或实体是否有 `CommandReceiver` |
| 技能没有伤害 | DebugOverlay 的 `Last failed effect`，再看 `EffectService.recent_results` | 检查 target、range、cooldown、mana cost 和 effect conditions |
| 事件没有到 UI | `EventService.recent_events` | 确认事件类型是否正确，UI 信号是否已连接 |
| 存档没有恢复 | Output 中的 Save 日志，之后看 `SaveService` payload | 检查 save scope、`get_save_id()`、节点名称和 load 顺序 |
| 场景没有切换 | DebugOverlay 的 `Focus` 与 Output 中的 `[WORLD]` 日志 | 确认 `WorldService.current_zone_id`、Portal `target_zone_id`、SceneService 路由 |

---

## 常见问题速查表

| 现象 | 先检查 | 常见原因 |
|------|--------|----------|
| 技能按了没反应 | `AbilityController.get_cast_failure_reason(id, ctx)` | 冷却中、cost 不足、conditions 不满足、ability_id 未注册 |
| Effect 执行了但没效果 | `EffectService.recent_results` 查失败条目 | `conditions` 未通过、`_apply_impl` 未 override、`context.target` 为 null |
| 状态没切换 | `StateMachine.last_failed_transition_reason` | `can_enter()` 返回 false、路径拼错、HFSM 层级匹配不到 |
| 动画不播 | `Presentation/AnimationPlayer` 是否存在；`anim.has_animation(name)` | 默认表现节点缺失；Action 中 `has_animation` 检查失败后静默跳过 |
| 存档读取后数据丢失 | `to_save_data()` 返回值；节点 `name` 与 save key 的匹配 | 忘记 override；`get_save_id()` 返回空串；节点 name 与存档 key 不匹配 |
| 服务取到 null | `Mkit.xxx()` / `ServiceRegistry.get_registered_service_ids()` | Bootstrap 未运行；服务常量用错；测试环境未注册；UIManager 尚未进入场景自注册 |
| 实体组件找不到兄弟 | `EntityContract.get_component(owner, "XxxComponent")` 的 warning | 默认布局缺少 `Components/` / `Controllers/` 成员，或节点不在 `EntityRoot` 下 |
| Command 发出但无响应 | DebugOverlay 的 `Last command`；按 id 路由时再看 `CommandService.command_failed` 信号 | State 未处理该命令、`target_id` 为空、接收方未注册、`receive_command` 返回 false |
| Action 一直不结束 | `ActionService.active_actions` 列表 | `GameAction.complete()` 或 `cancel()` 未被调用；`_on_update` 判断条件有 bug |
| ContentService 报 duplicate id | 启动日志 | 两个 `.tres` 的 `get_content_id()` 返回了相同字符串 |

---

## 调试模式检查清单

遇到"系统不动"时，按顺序检查：

1. **服务在线**：`Mkit.xxx() != null`，或打印 `ServiceRegistry.get_registered_service_ids()` → 若为 null，Bootstrap 未运行或服务常量用错
2. **命令到达**：看 `CommandReceiver.command_history` / DebugOverlay 的 `Last command`；按 id 路由时再订阅 `CommandService.command_dispatched` / `command_failed`
3. **状态响应**：打印 `sm.get_current_path()`，检查 `last_failed_transition_reason`
4. **Effect 执行**：`EffectService.recent_results`，找 `success = false` 条目
5. **事件发出**：`EventService.recent_events`，确认预期事件出现
6. **表现层**：检查信号是否已连接，`EntityContract` / 导出 `NodePath` 是否正确
