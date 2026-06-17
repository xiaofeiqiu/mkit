# Recipe 20：自定义服务与事件目录  ·  难度 ★★★  ·  预计 30 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

项目里多了一个**你自己的领域服务**：`ReputationService`（阵营声望），有自己的事件目录（`ReputationEvents`），通过自定义 bootstrap 和内置服务一起注册，能用 `ServiceRegistry.get_port()` 全局访问，声望变化发领域事件供任务/UI 订阅，并且开箱即存档。这是把 mkit「12 个内置模块」的套路复制到你自己领域的完整模板——内置模块怎么写，你的就怎么写。

## 前置

- 需完成：[Recipe 01](01_bootstrap.md)（理解 bootstrap 流程）
- 用到的概念：[architecture.md](../architecture.md)（分层：你的服务属于 Game Content 层，但形态和 module 服务一致）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 服务类（`extends Saveable`，定义 `SERVICE_ID`）| `GameBootstrap` 把 Node 服务挂到 `ServiceRegistry` 下并注册 |
| 事件目录类（常量 + 静态构造 `DomainEvent`）| `EventService` 派发给订阅者、记录 `recent_events` |
| 继承 `ModuleBootstrap`，override `_build_services()` 追加 | 服务注册完成后逐个回调 `_on_services_ready()` |
| （可选）自己的类型化门面 `Game.reputation()` | `ServiceRegistry.get_port()` 提供底层查找 |

## 本篇路径

### Minimal path：已有调用点直接取服务

1. 先按步骤 1 / 2 写好 `ReputationEvents` 和 `ReputationService`。
2. 按步骤 3 让你的 bootstrap 继承 `ModuleBootstrap`，并在 `_build_services()` 里注册 `ReputationService.SERVICE_ID`。
3. 运行 bootstrap 后，在任意脚本里取服务并检查：

```gdscript
var reputation := ServiceRegistry.get_port(ReputationService.SERVICE_ID) as ReputationService
if reputation == null:
    push_error("ReputationService 未注册")
    return
reputation.add_reputation("faction.village", 5)
```

4. 连接 `reputation.reputation_changed`，确认 UI 或 log 收到新数值。
5. 调用点多时，再加 `Game.reputation()` 门面，避免到处写字符串和强转。

这是普通领域服务调用，不需要 `CommandService` 或 `GameAction`。

### Standard path：从现有 pipeline 的结果回调接入

1. 声望来自任务完成时，订阅任务事件，而不是写一条新的任务流程：

```gdscript
Mkit.events().subscribe("quest_completed", func(event: DomainEvent):
    Game.reputation().add_reputation("faction.village", 25)
)
```

2. 声望来自对话选择、商店购买或交互结果时，也在对应 effect、service callback 或事件订阅里调用 `add_reputation(...)`。
3. `ReputationService.add_reputation()` 内部统一发节点信号和 `ReputationEvents.reputation_changed(...)`。
4. UI、任务或成就订阅 `ReputationEvents`，不要在每个调用点手拼 payload。
5. 验证方式：完成任务后声望增长，HUD 和事件订阅者都收到同一个变化。

### Advanced path：跨系统通知只加 typed event factory

1. 需要“达到 friendly 后解锁商店折扣”这类跨系统响应时，在 `ReputationEvents` 中新增常量和静态构造函数。
2. `ReputationService` 检测到阈值跨越时发 typed event：

```gdscript
Mkit.events().emit_domain_event(ReputationEvents.rank_reached(faction_id, "friendly"))
```

3. 商店 UI、任务或成就系统订阅 `ReputationEvents.REPUTATION_RANK_REACHED`。
4. 不需要为一个自定义服务新增 event DSL、module graph 或 action 层。
5. 只有服务自己的行为需要跨帧、可取消或统一 effect 链时，才考虑 `GameAction`；声望数值变化不需要。

## 关键认知：服务 = 注册进 ServiceRegistry 的普通 Node

mkit 没有「服务基类」魔法：一个服务就是一个 Node（要存档则 `extends Saveable`），约定三件事——

1. 有 `const SERVICE_ID: String`，bootstrap 用它注册；
2. 通过 `ServiceRegistry.get_port(SERVICE_ID)` 被全局取用（`Mkit` 门面只是给内置服务做的类型化包装）；
3. 状态变化时发**领域事件**（事件构造集中在一个 `XxxEvents` 目录类，别在调用点手拼 payload）。

## 步骤

### 步骤 1：写事件目录

模仿 `InventoryEvents` / `CombatEvents`：常量 + 静态构造函数，事件结构只在这里定义一次。

```gdscript
# res://game/services/reputation_events.gd
class_name ReputationEvents
extends RefCounted

const REPUTATION_CHANGED := "reputation_changed"
const REPUTATION_RANK_REACHED := "reputation_rank_reached"


static func reputation_changed(faction_id: String, amount: int, total: int) -> DomainEvent:
    return DomainEvent.create(
        REPUTATION_CHANGED, faction_id, "",
        {"faction_id": faction_id, "amount": amount, "total": total}
    )


static func rank_reached(faction_id: String, rank: String) -> DomainEvent:
    return DomainEvent.create(
        REPUTATION_RANK_REACHED, faction_id, "", {"faction_id": faction_id, "rank": rank}
    )
```

### 步骤 2：写服务

```gdscript
# res://game/services/reputation_service.gd
class_name ReputationService
extends Saveable   # 需要存档就继承 Saveable；纯运行时服务用 extends Node

signal reputation_changed(faction_id: String, total: int)

const SERVICE_ID: String = "reputation"
const RANK_THRESHOLDS := {"friendly": 100, "honored": 500}

var _reputation: Dictionary = {}   # faction_id -> int


func _ready() -> void:
    if save_id == "":
        save_id = "reputation"


func add_reputation(faction_id: String, amount: int) -> void:
    if faction_id.strip_edges() == "" or amount == 0:
        return
    var old_total: int = _reputation.get(faction_id, 0)
    var total := old_total + amount
    _reputation[faction_id] = total
    reputation_changed.emit(faction_id, total)
    var events := Mkit.events()
    if events != null:
        events.emit_domain_event(ReputationEvents.reputation_changed(faction_id, amount, total))
        for rank in RANK_THRESHOLDS:
            var threshold: int = RANK_THRESHOLDS[rank]
            if old_total < threshold and total >= threshold:
                events.emit_domain_event(ReputationEvents.rank_reached(faction_id, rank))


func get_reputation(faction_id: String) -> int:
    return _reputation.get(faction_id, 0)


func to_save_data() -> Dictionary:
    return {"reputation": _reputation}


func from_save_data(data: Dictionary) -> void:
    _reputation = data.get("reputation", {})
```

要点和内置服务一致：节点信号给直连方（UI），领域事件给解耦方（任务、成就）；`Saveable` + 唯一 `save_id`，`SaveService.save_game()` 自动收进 `roots.reputation`。

### 步骤 3：通过自定义 bootstrap 注册

继承 `ModuleBootstrap`（保留全部内置模块服务），追加自己的：

```gdscript
# res://game/game_bootstrap.gd
class_name MyGameBootstrap
extends ModuleBootstrap


func _build_services() -> Dictionary:
    var services := super()
    services[ReputationService.SERVICE_ID] = ReputationService.new()
    return services
```

把 bootstrap 场景里的节点脚本从 `ModuleBootstrap` 换成它（`resource_databases` / `initial_scene_path` 配置不变）。Node 服务会被挂到 `ServiceRegistry` 节点下、随其生命周期管理；替换内置实现也是同一个口子（如 `services[LootService.SERVICE_ID] = MyLootService.new()`）。

> 服务之间要互相拿引用，别在 `_ready` 里抢时序——实现 `_on_services_ready()`，bootstrap 在**全部服务注册完**后逐个回调它。

### 步骤 4：访问服务

```gdscript
var reputation := ServiceRegistry.get_port(ReputationService.SERVICE_ID) as ReputationService
reputation.add_reputation("faction.village", 10)
```

调用点多的话，照 `Mkit` 的样子给项目写个门面，换来类型提示和补全：

```gdscript
# res://game/game.gd
class_name Game
extends RefCounted


static func reputation() -> ReputationService:
    return ServiceRegistry.get_port(ReputationService.SERVICE_ID) as ReputationService
```

### 步骤 5：和现有系统接线

声望来源——任务完成加声望（订阅 quest 事件，无需改 mkit 代码）：

```gdscript
# 任意常驻脚本
Mkit.events().subscribe("quest_completed", func(event: DomainEvent):
    Game.reputation().add_reputation("faction.village", 25)
)
```

声望消费——UI 显示与达标提示：

```gdscript
Game.reputation().reputation_changed.connect(func(faction_id, total): _refresh_label(faction_id, total))
Mkit.events().subscribe(ReputationEvents.REPUTATION_RANK_REACHED, func(event: DomainEvent):
    _show_toast("已达到 %s 声望：%s" % [event.payload.faction_id, event.payload.rank])
)
```

还可以写一个 `Condition` 子类（`ReputationCondition`：`get_reputation(faction) >= required`），挂到对话选项、商店 entry、`Interactable.conditions` 上——你的服务就接入了 mkit 所有数据驱动的门禁点。

### 步骤 6：用 DebugOverlay 验证注册

运行游戏，控制台应输出：

```text
[mkit] GameBootstrap runtime services: events, content, ..., loot, reputation
```

`DebugOverlay`（`show_registered_services = true`，见 [debugging.md](../debugging.md#debugoverlay)）也会列出 `reputation`。如果还想把服务自己的诊断行接进 overlay，常用配置是：`watch_entity_path` 指向要观察的实体，`status_provider_path` 指向实现 `get_debug_status_lines()` 的节点，`visible_on_start` 控制启动时是否默认显示。

## 运行验证

1. 启动日志的服务列表里有 `reputation`
2. `add_reputation("faction.village", 10)` → 信号触发、`EventService.recent_events` 出现 `reputation_changed`
3. 累计到 100 → 收到 `reputation_rank_reached`（`rank="friendly"`），且只发一次
4. 完成任务 → 声望 +25（事件接线生效）
5. 存档重启 → `roots.reputation` 在存档文件里，声望值恢复

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `get_port` 返回 null | bootstrap 场景还挂着 `ModuleBootstrap`，没用你的子类 | 换成 `MyGameBootstrap` |
| 服务 `_ready` 里取别的服务为 null | 注册顺序未保证 | 改用 `_on_services_ready()` 钩子 |
| 事件没人收到 | 订阅的字符串和目录常量拼写不一致 | 始终引用 `ReputationEvents.REPUTATION_CHANGED`，不要手写字符串 |
| 声望没存上 | 服务 `extends Node` 而非 `Saveable`，或 `save_id` 与别人重复 | `extends Saveable`，`save_id` 全局唯一 |
| 重启后服务重复注册错误 | bootstrap 场景被二次加载，或手动注册了同一个 service id | `initial_scene_path` 别指向 bootstrap 自己所在场景；确实要替换时用显式替换流程 |

## 延伸阅读

- [GameBootstrap ref](../generated/html/classes/GameBootstrap.html) · [ModuleBootstrap ref](../generated/html/classes/ModuleBootstrap.html) — `_build_services` 的两层组合根
- [EventService ref](../generated/html/classes/EventService.html) · [DomainEvent ref](../generated/html/classes/DomainEvent.html)
- [architecture.md](../architecture.md) — 分层与组合根 · [concepts.md](../concepts.md)
- 内置事件目录源码：`addons/mkit/modules/*/{*_events.gd}` — 最好的参考样例
