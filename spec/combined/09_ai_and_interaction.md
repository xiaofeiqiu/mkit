# AI and Interaction

---

# 18. AI 模块接口设计

---

## 18.1 Brain

### 概念说明

- 是什么：AI 决策组件基类。
- 负责什么：观察局势并发出命令，而不是直接修改 gameplay 系统。
- 为什么需要：AI 和玩家走同一条命令链路，敌人行为才容易测试和替换。

```gdscript
class_name Brain
extends Node

@export var enabled: bool = true
@export var think_interval: float = 0.2

var _timer: float = 0.0
var command_router: CommandRouter = null
var target: Node = null

func _ready() -> void:
    command_router = ServiceRegistry.get_service("commands") as CommandRouter

func _process(delta: float) -> void:
    if not enabled:
        return
    _timer -= delta
    if _timer <= 0:
        _timer = think_interval
        think()

func think() -> void:
    pass

func issue_command(command_type: String, payload: Dictionary = {}) -> bool:
    var source_id := _get_owner_id()
    var cmd := GameCommand.create(command_type, source_id, source_id, payload)
    return command_router.dispatch(cmd)

func _get_owner_id() -> String:
    var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
    return identity.entity_id if identity != null else owner.name
```

#### 字段说明
- **enabled**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **think_interval**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**Brain** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **_process()**：内部辅助函数。实际例子：由 **Brain** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **think()**：公开 API。实际例子：外部系统通过它请求 **Brain** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **issue_command()**：公开 API。实际例子：外部系统通过它请求 **Brain** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_get_owner_id()**：内部辅助函数。实际例子：由 **Brain** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.70 Brain 使用示例

#### 详细实际用例

- 真实场景：BossBrain 判断血量低于 50% 后发出 cast_ability 命令释放狂暴，而不是直接给自己加攻击。
- 怎么使用：AI 只产生命令，后续仍走 CommandReceiver、StateMachine、AbilityController。
- 验证重点：把同一命令从 AI 换成测试脚本发出，行为结果应一致。
### 自定义 BossBrain

```gdscript
class_name BossBrain
extends Brain

func think() -> void:
    if target == null:
        target = get_tree().get_first_node_in_group("player")
        return

    var hp := owner.get_node("Components/HealthComponent") as HealthComponent
    var hp_percent := hp.current_hp / hp.get_max_hp()

    if hp_percent < 0.5:
        issue_command(BuiltinCommands.CAST_ABILITY, {"ability_id": "ability.boss_rage"})
    else:
        issue_command(BuiltinCommands.ATTACK, {"target": target})
```

---

---

---

## 18.2 SimpleAIEnemyBrain

### 概念说明

- 是什么：早期可用的简单敌人 AI。
- 负责什么：发现目标、追击、进入攻击距离后攻击，否则停止或巡逻。
- 为什么需要：在核心战斗稳定前，不应该先做复杂行为树；简单 AI 足够验证 vertical slice。

```gdscript
class_name SimpleAIEnemyBrain
extends Brain

@export var detection_range: float = 240.0
@export var attack_range: float = 48.0
@export var target_group: String = "player"

func _ready() -> void:
    super._ready()
    target = get_tree().get_first_node_in_group(target_group)

func think() -> void:
    if target == null:
        return

    var distance := owner.global_position.distance_to(target.global_position)

    if distance <= attack_range:
        issue_command(BuiltinCommands.ATTACK, {"target": target})
    elif distance <= detection_range:
        var direction := (target.global_position - owner.global_position).normalized()
        issue_command(BuiltinCommands.MOVE, {"direction": direction})
    else:
        issue_command(BuiltinCommands.STOP_MOVE, {})
```

#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**SimpleAIEnemyBrain** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **think()**：公开 API。实际例子：外部系统通过它请求 **SimpleAIEnemyBrain** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

---

### 27.71 SimpleAIEnemyBrain 使用示例

#### 详细实际用例

- 真实场景：goblin 发现 240px 内的玩家就追击，进入 48px 后发 attack 命令，玩家离开范围后 stop_move。
- 怎么使用：早期 vertical slice 用 SimpleAI，不急着做完整行为树。
- 验证重点：敌人不会直接改玩家 HP；攻击仍通过状态机和 Hitbox/Hurtbox 发生。
### Enemy 场景挂载

```text
Goblin.tscn
  CharacterBody2D
    EntityIdentity
    CommandReceiver
    StateMachine
    Components
    Controllers
    AI
      SimpleAIEnemyBrain
```

### Inspector 配置

```text
SimpleAIEnemyBrain.detection_range = 240
SimpleAIEnemyBrain.attack_range = 48
SimpleAIEnemyBrain.target_group = "player"
```

### 运行时行为

```text
如果 player 在 48px 内：发 AttackCommand
如果 player 在 240px 内：发 MoveCommand
否则：发 StopMoveCommand
```

---

---

---

# 19. Interaction 模块接口设计

---

## 19.1 Interactable

### 概念说明

- 是什么：世界中可被互动的对象。
- 负责什么：提供显示文本、互动条件和执行逻辑。
- 为什么需要：宝箱、门、NPC、祭坛、开关都可以共享同一个互动协议。

```gdscript
class_name Interactable
extends Node

@export var interaction_id: String = ""
@export var display_text: String = "Interact"
@export var conditions: Array[Condition] = []

func can_interact(context: GameplayContext) -> bool:
    return ConditionEvaluator.evaluate_all(conditions, context)

func interact(context: GameplayContext) -> bool:
    if not can_interact(context):
        return false
    return _interact_impl(context)

func _interact_impl(context: GameplayContext) -> bool:
    return true
```

#### 字段说明
- **interaction_id**：稳定 ID 字段。例：Interactable 通过 interaction_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。
#### 函数使用场景
- **can_interact()**：合法性检查。实际例子：释放技能前先调用 can_interact，失败时 UI 显示冷却中或目标太远。
- **interact()**：公开 API。实际例子：外部系统通过它请求 **Interactable** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_interact_impl()**：内部辅助函数。实际例子：由 **Interactable** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.72 Interactable 使用示例

#### 详细实际用例

- 真实场景：宝箱继承 Interactable，玩家按 E 后打开宝箱并 roll `loot.chest_common`。
- 怎么使用：Interactable 负责“能否互动”和“互动后做什么”；InteractionComponent 负责发现和触发它。
- 验证重点：已打开宝箱再次互动返回 false；UI 提示能显示正确 display_text。
### ChestInteractable

```gdscript
class_name ChestInteractable
extends Interactable

@export var loot_table_id: String = "loot.chest_common"
var opened: bool = false

func _interact_impl(context: GameplayContext) -> bool:
    if opened:
        return false
    opened = true

    var loot := LootSystem.new().roll_table(loot_table_id, context)
    var inventory := context.source.get_node("Controllers/InventoryController") as InventoryController
    for item in loot.item_instances:
        inventory.add_item(item)

    return true
```

---

---

---

## 19.2 InteractionComponent

### 概念说明

- 是什么：实体寻找并触发互动对象的组件。
- 负责什么：追踪当前聚焦对象、发出 UI 提示信号并构造 GameplayContext 调用 interact。
- 为什么需要：键鼠、手柄、触屏、AI 或教程脚本都应该能走同一套互动逻辑。

```gdscript
class_name InteractionComponent
extends Area2D

signal interactable_focused(interactable: Interactable)
signal interactable_unfocused(interactable: Interactable)

var current_interactable: Interactable = null

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

func try_interact() -> bool:
    if current_interactable == null:
        return false
    var ctx := GameplayContext.new()
    ctx.source = owner
    ctx.target = current_interactable.owner
    return current_interactable.interact(ctx)

func _on_area_entered(area: Area2D) -> void:
    var interactable := area.get_node_or_null("Interactable") as Interactable
    if interactable != null:
        current_interactable = interactable
        interactable_focused.emit(interactable)

func _on_area_exited(area: Area2D) -> void:
    var interactable := area.get_node_or_null("Interactable") as Interactable
    if interactable != null and interactable == current_interactable:
        interactable_unfocused.emit(interactable)
        current_interactable = null
```

#### 信号说明
- **interactable_focused**：当 **InteractionComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **interactable_unfocused**：当 **InteractionComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**InteractionComponent** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **try_interact()**：公开 API。实际例子：外部系统通过它请求 **InteractionComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_on_area_entered()**：内部辅助函数。实际例子：由 **InteractionComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_area_exited()**：内部辅助函数。实际例子：由 **InteractionComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.73 InteractionComponent 使用示例

#### 详细实际用例

- 真实场景：玩家靠近宝箱时，InteractionComponent 发现最近 Interactable，HUD 显示 “Press E”；按 E 后构造 GameplayContext 调用 interact。
- 怎么使用：把检测范围、聚焦对象和交互触发放在组件里，输入层只发起 try_interact。
- 验证重点：离开范围后提示消失；多个可互动对象时选择最近或优先级最高的。
### Player 按 E 交互

```gdscript
func _process(delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        var interaction := $Components/InteractionComponent as InteractionComponent
        interaction.try_interact()
```

### UI 显示交互提示

```gdscript
func _ready() -> void:
    var interaction := $Components/InteractionComponent as InteractionComponent
    interaction.interactable_focused.connect(_on_focus)
    interaction.interactable_unfocused.connect(_on_unfocus)

func _on_focus(interactable: Interactable) -> void:
    $HUD.show_prompt(interactable.display_text)

func _on_unfocus(interactable: Interactable) -> void:
    $HUD.hide_prompt()
```

---

