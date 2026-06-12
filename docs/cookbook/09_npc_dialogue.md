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

## 本篇路径

### Minimal path：剧情脚本直接开对话

1. 先按步骤 1 创建 `res://data/dialogue/elder_intro.tres`，并把它加入 `ResourceDatabase.resources`。
2. 在场景里放一个 NPC 节点，例如 `Elder`，脚本或主场景能拿到 `player` 和 `elder` 两个节点。
3. 在剧情脚本里直接启动对话：

```gdscript
func start_intro_dialogue(player: Node, elder: Node) -> void:
    var ctx := GameplayContext.from_nodes(player, elder)
    if not Mkit.dialogue().start("dialogue.elder_intro", ctx):
        push_warning("dialogue.elder_intro 没有注册或无法启动")
```

4. 如果 `DialogueUI` 已经 bind 到 `DialogueService`，界面会显示 `greet` 节点文本。
5. 这条路径适合 cutscene 或测试；没有靠近检测，也不需要 `InteractionComponent`。

### Standard path：玩家按交互键

1. 给玩家加 `InteractionComponent` 和碰撞形状，输入脚本里按 `interact` 时调用 `interaction_component.try_interact()`。
2. NPC 场景按这个结构搭：

```text
Elder  (Node2D)
└── InteractArea  (Area2D)
    ├── CollisionShape2D
    └── Interactable  (DialogueInteractable)
```

3. 在 `DialogueInteractable` 的 Inspector 里填 `dialogue_id = "dialogue.elder_intro"`，节点名必须是 `Interactable`。
4. 玩家走近 NPC，`InteractionComponent` 聚焦该 interactable；按交互键后它调用 `DialogueService.start(...)`。
5. 验证方式：走近出现提示，按键打开对话；离开范围后按键不再触发。

### Advanced path：只知道 id 时先路由命令

1. 确认玩家 `CommandReceiver.auto_register = true`，receiver id 是 `"player"`。
2. 剧情系统只有玩家 id，没有玩家节点引用时，发送交互命令：

```gdscript
var command := GameCommand.create("interact", "script", "player")
Mkit.commands().dispatch(command)
```

3. 玩家实体收到命令后，在自己的 command handler 中调用 `InteractionComponent.try_interact()`。
4. 后续仍然走 Standard path：当前聚焦对象是 `DialogueInteractable`，它启动对话。
5. 如果剧情脚本已经拿到 `player` 节点，直接调用 `try_interact()`，不要走 `CommandService`。

## 步骤

### 步骤 1：创建 DialogueDefinition

新建 Resource → `DialogueDefinition`，存为 `res://data/dialogue/elder_intro.tres`：

| 字段 | 值 |
|------|----|
| `dialogue_id` | `"dialogue.elder_intro"` |
| `start_node_id` | `"greet"` |
| `nodes` | 见下（4 个 `DialogueNode`）|

`nodes` 里建 4 个 `DialogueNode`（内联 Resource）：

```
# node[0] —— 开场，带 3 个选项
node_id      = "greet"
speaker_id   = "村长"
text         = "勇者，村子最近被野兽侵扰…"
choices      = [choice_ask, choice_whisper, choice_leave]
next_node_id = ""        # 有 choices 时忽略 next_node_id

# node[1] —— 回答，无选项，按键继续
node_id      = "info"
speaker_id   = "村长"
text         = "它们藏在东边的房间里。"
choices      = []
next_node_id = "bye"     # 无 choices 时，advance() 会进入这个节点

# node[2] —— 近距离低声线索
node_id      = "secret"
speaker_id   = "村长"
text         = "别告诉别人：旧井旁有一条近路。"
choices      = []
next_node_id = "bye"

# node[3] —— 告别
node_id      = "bye"
speaker_id   = "村长"
text         = "保重。"
choices      = []
next_node_id = ""
```

`DialogueNode.next_node_id` 只在 `choices` 为空时生效：UI 调 `DialogueService.advance()` 后，如果 `next_node_id` 非空就进入对应节点；如果为空就结束对话。有选项的节点由 `DialogueChoice.next_node_id` 决定跳转，节点自己的 `next_node_id` 会被忽略。

三个 `DialogueChoice`（内联 Resource）：

```
choice_ask:   text = "野兽在哪？"  next_node_id = "info"   conditions = []   effects = []
choice_whisper:
  text         = "悄声问：你还知道什么？"
  next_node_id = "secret"
  conditions   = [TargetInRangeCondition(condition_id="elder_close_talk", range=48.0)]
  effects      = []
choice_leave: text = "再见。"      next_node_id = "bye"    conditions = []   effects = []
```

> `DialogueChoice.effects` 就是挂"对话后果"的地方——[Recipe 10](10_quest.md) 会在某个选项上挂 `AcceptQuestEffect`，让"答应帮忙"直接接下任务。`DialogueNode.on_enter_effects` 则在进入节点时触发（如播放音效、给提示）。
>
> `DialogueChoice.conditions` 是选项的**显示门禁**：`get_available_choices()` 会静默隐藏不满足条件的选项（不会显示成灰色）。上面的 `choice_whisper` 只有玩家离 NPC owner 48 像素内才显示；context 来自 `DialogueInteractable.interact(ctx)`，所以 `source=玩家`、`target=NPC owner`。更复杂的"声望够才显示"可按 [Recipe 20](20_custom_service.md) 写 `ReputationCondition`。条件系统详见 [Recipe 21](21_conditions.md)。

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
        var interaction := EntityContract.get_controller(self, "InteractionComponent") as InteractionComponent
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
    var dialogue := Mkit.dialogue()
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
        var dialogue := Mkit.dialogue()
        if dialogue != null and dialogue.is_active():
            if dialogue.get_available_choices().is_empty():
                dialogue.advance()
```

`bind()` 已把 `node_entered` → 更新 `SpeakerLabel`/`TextLabel`，`choices_presented` → 在 `ChoiceContainer` 生成按钮（按钮点击调 `choose(index)`），`dialogue_ended` → 隐藏面板。**有选项的节点**靠按钮推进，**无选项的节点**靠你在 `advance()` 上调用推进。

## 运行验证

1. 玩家走近 NPC → `interactable_focused` 触发（可打 log 确认聚焦）
2. 按交互键 → 对话框出现，显示"村长：勇者，村子最近被野兽侵扰…"；48 像素内显示 3 个选项，较远时 `choice_whisper` 被条件隐藏
3. 点"野兽在哪？" → 进入 `info` 节点，按交互键继续 → 进入 `bye`，再按一次 → 对话结束、面板隐藏
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

- [DialogueService ref](../generated/html/classes/DialogueService.html) — start / choose / advance / end
- [DialogueDefinition ref](../generated/html/classes/DialogueDefinition.html) · [DialogueNode ref](../generated/html/classes/DialogueNode.html) · [DialogueChoice ref](../generated/html/classes/DialogueChoice.html)
- [Interactable ref](../generated/html/classes/Interactable.html) · [InteractionComponent ref](../generated/html/classes/InteractionComponent.html)
- [pipeline.md — Dialogue](../pipeline.md#15-dialogue)
- [cookbook/10_quest.md](10_quest.md) — 在对话选项里接受任务
