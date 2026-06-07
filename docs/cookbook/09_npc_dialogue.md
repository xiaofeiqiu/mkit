# Recipe 09：NPC 交互 + 对话树  ·  难度 ★★★  ·  预计 30 分钟

## 本篇结束后，你的项目新增了什么

场景里有一个 NPC。玩家走近并按交互键 → 弹出对话框，显示 NPC 台词；带分支的节点显示选项按钮，玩家点选推进；对话走到末尾自动结束并发 `dialogue_ended`。对话数据全部由 `.tres` 配置，运行时由 `DialogueService` 这台小状态机驱动。

## 前置

- 需完成：[Recipe 02](02_player_entity.md)（玩家实体，可移动）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `DialogueDefinition` (.tres)：节点 + 选项树 | `DialogueService` 按 `start_node_id` 推进，求值选项 `conditions` |
| 给 NPC 挂 `DialogueInteractable`（带 `dialogue_id`）| `_interact_impl()` 调 `DialogueService.start()` 并发 `npc_talked` |
| 给玩家挂 `InteractionComponent`（Area2D），按键调 `try_interact()` | 进入/离开范围自动聚焦可交互对象 |
| 搭一个对话框 UI，`bind()` 到 `DialogueService` | 发 `node_entered` / `choices_presented` / `dialogue_ended` 信号驱动 UI |

## 步骤

### 步骤 1：创建 DialogueDefinition

新建 Resource → `DialogueDefinition`，存为 `res://data/dialogue/elder_intro.tres`：

| 字段 | 值 |
|------|----|
| `dialogue_id` | `"dialogue.elder_intro"` |
| `start_node_id` | `"greet"` |
| `nodes` | 见下（3 个 `DialogueNode`）|

`nodes` 里建 3 个 `DialogueNode`（内联 Resource）：

```
# node[0] —— 开场，带 2 个选项
node_id      = "greet"
speaker_id   = "村长"
text         = "勇者，村子最近被野兽侵扰…"
choices      = [choice_ask, choice_leave]
next_node_id = ""        # 有 choices 时忽略 next_node_id

# node[1] —— 回答，无选项，按键继续
node_id      = "info"
speaker_id   = "村长"
text         = "它们藏在东边的房间里。"
choices      = []
next_node_id = ""        # 空 → 此节点后对话结束

# node[2] —— 告别
node_id      = "bye"
speaker_id   = "村长"
text         = "保重。"
choices      = []
next_node_id = ""
```

两个 `DialogueChoice`（内联 Resource）：

```
choice_ask:   text = "野兽在哪？"  next_node_id = "info"   conditions = []   effects = []
choice_leave: text = "再见。"      next_node_id = "bye"    conditions = []   effects = []
```

> `DialogueChoice.effects` 就是挂"对话后果"的地方——[Recipe 10](10_quest.md) 会在某个选项上挂 `AcceptQuestEffect`，让"答应帮忙"直接接下任务。`DialogueNode.on_enter_effects` 则在进入节点时触发（如播放音效、给提示）。

把 `elder_intro.tres` 加入 `ResourceDatabase.resources`。

### 步骤 2：搭建 NPC，挂 DialogueInteractable

`InteractionComponent` 检测重叠的 `Area2D`，并取其名为 `Interactable` 的子节点。NPC 场景这样搭：

```
NpcElder  (Node2D)
├── EntityIdentity        # entity_id="npc.elder", faction="npc"
├── InteractArea  (Area2D)
│   ├── CollisionShape2D  # 交互范围
│   └── Interactable  (DialogueInteractable)   # 名字必须是 "Interactable"
└── Presentation/ ...（精灵）
```

`DialogueInteractable`（`Interactable` 子类）配置：
- `dialogue_id` = `"dialogue.elder_intro"`
- `npc_id` = `"npc.elder"`（交谈时会发 `EventService.npc_talked`）
- `display_text` = `"交谈"`

### 步骤 3：给玩家挂 InteractionComponent

在玩家实体下加一个 `InteractionComponent`（`extends Area2D`）+ 一个 `CollisionShape2D`：

```
PlayerEntity  (EntityRoot)
├── ...（Recipe 02 已有的节点）
└── InteractionComponent  (Area2D)
    └── CollisionShape2D
```

`InteractionComponent._ready()` 自动连好 `area_entered` / `area_exited`。当它与 NPC 的 `InteractArea` 重叠时，`current_interactable` 指向 NPC 的 `DialogueInteractable`，并发 `interactable_focused` 信号（可用来显示"按 E 交谈"提示）。

> 让两个 Area2D 能相互检测：确认它们的 **collision layer / mask** 有交集，且 `CollisionShape2D` 有实际形状。

### 步骤 4：按交互键触发对话

在玩家输入脚本里，按交互键时调 `try_interact()`：

```gdscript
# 玩家输入控制器 _process 中
func _process(_delta: float) -> void:
    # ...（移动/攻击输入）
    if Input.is_action_just_pressed("interact"):
        var interaction := owner.get_node_or_null("InteractionComponent") as InteractionComponent
        if interaction != null:
            if not interaction.try_interact():
                # 附近没有可交互对象，或对方拒绝（conditions 不满足）
                pass
```

`try_interact()` → `DialogueInteractable.interact(ctx)`（先过 `conditions`）→ `DialogueService.start("dialogue.elder_intro", ctx)`。`start()` 在已有对话进行中时返回 `false`，天然防止重复打开。

### 步骤 5：搭对话框 UI 并绑定

新建一个 `DialogueUI`（`extends Control`）场景，子节点名字要对上内置实现：

```
DialogueUI  (DialogueUI)
├── SpeakerLabel    (Label)        # 显示 speaker_id
├── TextLabel       (Label)        # 显示 text
└── ChoiceContainer (VBoxContainer)# 选项按钮容器
```

把它放进主场景（如挂在 CanvasLayer 下），在 `_ready` 里 `bind()` 到 `DialogueService`：

```gdscript
# res://game/ui/dialogue_ui_host.gd（挂在 DialogueUI 上，或主场景里）
extends DialogueUI


func _ready() -> void:
    var dialogue := ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
    if dialogue == null:
        push_error("DialogueService unavailable")
        return
    bind(dialogue)
    # 对话开始时显示面板
    dialogue.dialogue_started.connect(func(_id: String): visible = true)


func _unhandled_input(event: InputEvent) -> void:
    # 无选项的文本节点：按键继续
    if not visible:
        return
    if event.is_action_pressed("interact"):
        var dialogue := ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
        if dialogue != null and dialogue.is_active():
            if dialogue.get_available_choices().is_empty():
                dialogue.advance()
```

`bind()` 已把 `node_entered` → 更新 `SpeakerLabel`/`TextLabel`，`choices_presented` → 在 `ChoiceContainer` 生成按钮（按钮点击调 `choose(index)`），`dialogue_ended` → 隐藏面板。**有选项的节点**靠按钮推进，**无选项的节点**靠你在 `advance()` 上调用推进。

## 运行验证

1. 玩家走近 NPC → `interactable_focused` 触发（可打 log 确认聚焦）
2. 按交互键 → 对话框出现，显示"村长：勇者，村子最近被野兽侵扰…" + 两个选项按钮
3. 点"野兽在哪？" → 进入 `info` 节点，显示新台词，按交互键继续 → 对话结束、面板隐藏
4. `EventService.recent_events` 里能看到 `npc_talked`、`dialogue_started`、`dialogue_ended`

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 按键无反应 | 两个 Area2D 没重叠 | 检查 collision layer/mask 与 CollisionShape2D 形状 |
| `try_interact()` 总返回 false | NPC 的 Area2D 子节点没命名 `Interactable` | 子节点名必须精确是 `Interactable` |
| 对话框不更新 | `DialogueUI` 子节点名不对，或没 `bind()` | 子节点须为 `SpeakerLabel`/`TextLabel`/`ChoiceContainer` |
| 文本节点卡住不结束 | 无选项节点要手动 `advance()` | 在输入里对无选项节点调 `dialogue.advance()` |
| 对话开不了 | 已有对话进行中（`is_active()` 为真）| `start()` 同一时间只允许一段对话；先 `end()` |
| 选项点了没后果 | 选项 `effects` 为空 | 在 `DialogueChoice.effects` 挂 effect（见 Recipe 10）|

## 延伸阅读

- [DialogueService ref](../ref/modules/DialogueService.md) — start / choose / advance / end
- [DialogueDefinition ref](../ref/modules/DialogueDefinition.md) · [DialogueNode ref](../ref/modules/DialogueNode.md) · [DialogueChoice ref](../ref/modules/DialogueChoice.md)
- [Interactable ref](../ref/modules/Interactable.md) · [InteractionComponent ref](../ref/modules/InteractionComponent.md)
- [pipeline.md — Dialogue](../pipeline.md#15-dialogue)
- [cookbook/10_quest.md](10_quest.md) — 在对话选项里接受任务
