# Recipe 17：交互区域  ·  难度 ★★☆  ·  预计 20 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

场景里多了一座**治疗泉**：玩家走近时出现「按 E 饮用」提示，按交互键执行你自定义的逻辑（回血并发领域事件），走开提示消失。这套「靠近 → 提示 → 按键触发 X」的通用模式，正是 NPC 对话（[Recipe 09](09_npc_dialogue.md)）和传送门（[Recipe 15](15_world_zone_transition.md)）底下用的同一对类：`Interactable` + `InteractionComponent`。

## 前置

- 需完成：[Recipe 02](02_player_entity.md)（玩家实体可移动）；建议先看 [Recipe 03](03_health_and_stats.md)（示例会回血）
- 用到的概念：[concepts.md — 模型 5：扩展点地图](../concepts.md#模型-5扩展点地图你写什么--mkit-管什么)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 继承 `Interactable`，override `_interact_impl()` 写触发逻辑 | `interact()` 先跑 `conditions`，不满足直接拒绝 |
| 场景里搭 `Area2D` + 名为 `Interactable` 的子节点 | `InteractionComponent` 自动检测重叠，维护 `current_interactable` |
| 玩家按键时调 `try_interact()` | 构造 `GameplayContext`（source=玩家，target=交互物 owner）并派发 |
| 监听 `interactable_focused/unfocused` 显示提示 | 进出范围自动发信号 |

## 关键认知：约定两个节点名

`InteractionComponent`（挂玩家，`extends Area2D`）检测到重叠 `Area2D` 时，会取对方**名为 `Interactable` 的子节点**——名字必须精确匹配。一个交互物的标准结构：

```text
HealingFountain  (Node2D)
└── InteractArea  (Area2D)
    ├── CollisionShape2D            # 交互范围
    └── Interactable  (你的子类)    # 节点名必须是 "Interactable"
```

内置子类已有两个：`DialogueInteractable`（对话）和 `Portal`(区域跳转)。本篇写第三种——你自己的。

## 步骤

### 步骤 1：写一个 Interactable 子类

```gdscript
# res://game/world/healing_fountain_interactable.gd
class_name HealingFountainInteractable
extends Interactable

@export var heal_effect: GameEffect = null   # 配一个 HealEffect .tres
@export var cooldown_seconds: float = 10.0

var _last_used: float = -INF


func _interact_impl(context: GameplayContext) -> bool:
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_used < cooldown_seconds:
        return false
    if heal_effect == null or context.source == null:
        return false
    var ctx := GameplayContext.new().with_source(context.source).with_target(context.source)
    var result := Mkit.effects().execute(heal_effect, ctx)
    if not result.success:
        return false
    _last_used = now
    Mkit.events().emit_event("fountain_used", "", "", {"by": context.source.name})
    return true
```

只需 override `_interact_impl()`；`interact()` 入口会先用 `ConditionEvaluator` 跑 `conditions`，不满足就不会进到这里。

### 步骤 2：搭交互物场景

按「关键认知」的结构搭 `res://game/world/healing_fountain.tscn`，`Interactable` 节点挂上面的脚本，Inspector 配置：

- `interaction_id` = `"interact.fountain"`
- `display_text` = `"饮用"`（给提示 UI 用）
- `conditions` = `[TargetInRangeCondition(condition_id="fountain_close", range=48.0)]`
- `heal_effect` = 一个 `HealEffect`（`base_amount=40`）

`TargetInRangeCondition` 让"看到提示"和"真正能饮用"分开：`InteractionComponent` 的 Area2D 可以稍大，方便显示提示；按 E 时还会在进入 `_interact_impl()` 前检查玩家到泉水 owner 的距离是否 ≤ 48 像素。需要「完成某任务后才开放」这类规则时，把自定义 `Condition` 加进同一个数组，写法见 [Recipe 21](21_conditions.md)。

> 让两个 Area2D 能相互检测：collision **layer / mask** 要有交集，且 `CollisionShape2D` 配了实际形状。

### 步骤 3：给玩家挂 InteractionComponent

（Recipe 09 已做过则跳过。）玩家实体下加 `InteractionComponent`（`extends Area2D`）+ `CollisionShape2D`。它在 `_ready` 自动连好 `area_entered/area_exited`，进出范围时维护 `current_interactable` 并发 focus 信号。

### 步骤 4：按键触发

```gdscript
# 玩家输入脚本
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        var interaction := EntityContract.get_controller(owner, "InteractionComponent") as InteractionComponent
        if interaction != null and not interaction.try_interact():
            pass   # 附近没有交互物 / conditions 不满足 / 冷却中
```

`try_interact()` 用 `GameplayContext.from_nodes(owner, current_interactable.owner)` 构造上下文——所以 `_interact_impl` 里 `context.source` 是玩家、`context.target` 是交互物的 owner。

### 步骤 5：显示「按 E」提示

```gdscript
# HUD 脚本（参见 Recipe 18）
func _ready() -> void:
    var interaction := player.get_node("InteractionComponent") as InteractionComponent
    interaction.interactable_focused.connect(func(i: Interactable):
        prompt_label.text = "按 E %s" % i.display_text
        prompt_label.visible = true
    )
    interaction.interactable_unfocused.connect(func(_i):
        prompt_label.visible = false
    )
```

### 步骤 6：（可选）踩上去自动触发

不想按键、希望「踩到就触发」（陷阱、拾取点）？不用 `InteractionComponent`，直接连交互区自己的信号：

```gdscript
# 挂在 InteractArea (Area2D) 上
func _ready() -> void:
    body_entered.connect(func(body: Node):
        var interactable := get_node("Interactable") as Interactable
        interactable.interact(GameplayContext.from_nodes(body, owner))
    )
```

按键式（步骤 4）适合明确动作；自动式适合无提示的触发器。两种共用同一个 `Interactable`，`conditions` 照常生效。

## 运行验证

1. 玩家走近泉水 → 提示「按 E 饮用」出现；走开 → 消失
2. 打残血后按 E → HP +40，`EventService.recent_events` 出现 `fountain_used`
3. 10 秒内再按 E → 无效果（冷却）
4. 给 `conditions` 挂一个不满足的条件 → `try_interact()` 返回 false，效果不执行

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `try_interact()` 总返回 false | 交互物的子节点没命名 `Interactable` | 节点名必须精确是 `Interactable` |
| 走近没有 focus 信号 | 两个 Area2D 的 layer/mask 无交集，或形状缺失 | 对齐 collision layer/mask，配 `CollisionShape2D` |
| 提示出现但按键无效 | `conditions` 不满足，或 `_interact_impl` 返回 false | 用返回值/打印排查是哪一层拒绝 |
| 同时站进两个交互区只认一个 | `current_interactable` 只保存最后进入的一个 | 把交互区错开，或自行扩展为列表 |
| 离开后提示不消失 | 交互物在范围内被 `queue_free`，`area_exited` 没机会触发 | 移除交互物前手动发 unfocus / 隐藏提示 |

## 延伸阅读

- [Interactable ref](../generated/html/classes/Interactable.html) · [InteractionComponent ref](../generated/html/classes/InteractionComponent.html)
- [DialogueInteractable ref](../generated/html/classes/DialogueInteractable.html)（[Recipe 09](09_npc_dialogue.md)）· [Portal ref](../generated/html/classes/Portal.html)（[Recipe 15](15_world_zone_transition.md)）
- [concepts.md — 模型 5：扩展点地图](../concepts.md#模型-5扩展点地图你写什么--mkit-管什么)
