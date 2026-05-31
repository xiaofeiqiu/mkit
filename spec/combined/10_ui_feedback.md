# UI and Feedback

---

# 20. UI / Feedback 模块接口设计

---

## 20.1 UIManager

### 概念说明

- 是什么：UI 屏幕和弹窗的管理器。
- 负责什么：打开/关闭界面、堆叠弹窗、阻塞 gameplay 输入并处理暂停。
- 为什么需要：UI 不应该直接控制玩法系统，但需要统一管理屏幕流。

```gdscript
class_name UIManager
extends Node

signal screen_opened(screen_id: String)
signal screen_closed(screen_id: String)

@export var screen_root_path: NodePath = NodePath("ScreenRoot")
@export var screen_scene_map: Dictionary = {}

var screen_stack: Array[String] = []
var active_screens: Dictionary = {}
var modal_screens: Array[String] = []

func _ready() -> void:
    if not ServiceRegistry.has_service("ui"):
        ServiceRegistry.register_service("ui", self)

func open_screen(screen_id: String, data: Dictionary = {}, modal: bool = false) -> Node:
    if active_screens.has(screen_id):
        return active_screens[screen_id]

    if not screen_scene_map.has(screen_id):
        push_error("Unknown screen: %s" % screen_id)
        return null

    var scene := load(screen_scene_map[screen_id]) as PackedScene
    var screen := scene.instantiate()
    get_node(screen_root_path).add_child(screen)

    if "setup" in screen:
        screen.setup(data)

    active_screens[screen_id] = screen
    screen_stack.append(screen_id)
    if modal:
        modal_screens.append(screen_id)
        _set_gameplay_paused(true)
    screen_opened.emit(screen_id)
    return screen

func close_screen(screen_id: String) -> void:
    if not active_screens.has(screen_id):
        return
    var screen := active_screens[screen_id] as Node
    active_screens.erase(screen_id)
    screen_stack.erase(screen_id)
    modal_screens.erase(screen_id)
    screen.queue_free()
    if modal_screens.is_empty():
        _set_gameplay_paused(false)
    screen_closed.emit(screen_id)

func close_top_screen() -> void:
    if screen_stack.is_empty():
        return
    close_screen(screen_stack[-1])

func is_screen_open(screen_id: String) -> bool:
    return active_screens.has(screen_id)

func _set_gameplay_paused(value: bool) -> void:
    if not ServiceRegistry.has_service("time"):
        return
    var time := ServiceRegistry.get_service("time") as TimeService
    if time != null:
        time.set_paused(value)
```

#### 字段说明
- **screen_root_path**：资源或节点路径。例：用 screen_root_path 指向场景或节点，方便在 Inspector 中配置。
- **modal_screens**：当前阻塞玩法输入的界面栈。例：奖励选择和暂停菜单都打开时，只有两个 modal 都关闭才恢复 gameplay 时间。
#### 信号说明
- **screen_opened**：当 **UIManager** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **screen_closed**：当 **UIManager** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：进入场景树后把 UIManager 注册为 `"ui"` 服务，供 RunDirector、RewardSelectionUI 和输入层调用。
- **open_screen()**：公开 API。实际例子：外部系统通过它请求 **UIManager** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **close_screen()**：公开 API。实际例子：外部系统通过它请求 **UIManager** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **close_top_screen()**：公开 API。实际例子：外部系统通过它请求 **UIManager** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **is_screen_open()**：状态查询。实际例子：AI 调用 is_screen_open 判断目标是不是敌对阵营或 Action 是否结束。
- **_set_gameplay_paused()**：内部辅助函数。实际例子：打开 modal 奖励界面时暂停 TimeService，关闭最后一个 modal 后恢复。

---

### 27.74 UIManager 使用示例

#### 详细实际用例

- 真实场景：清房间后 RunDirector 请求 UIManager 打开 reward_selection popup，并阻塞玩家移动输入。
- 怎么使用：所有界面打开/关闭都走 UIManager，玩法系统只传数据，不直接实例化具体按钮。
- 验证重点：关闭弹窗后 gameplay 输入恢复；按 Esc 关闭顶层 UI 不影响底层 HUD。
### 打开背包

```gdscript
func open_inventory() -> void:
    var ui := ServiceRegistry.get_service("ui") as UIManager
    ui.open_screen("inventory", {"owner_id": "player_001"}, true)
```

### 打开奖励选择

```gdscript
func show_rewards(options: Array[RewardOption], run_director: RunDirector) -> void:
    var ui := ServiceRegistry.get_service("ui") as UIManager
    ui.open_screen("reward_selection", {
        "options": options,
        "run_director": run_director
    }, true)
```

### 关闭顶部 UI

```gdscript
if Input.is_action_just_pressed("ui_cancel"):
    $UIManager.close_top_screen()
```

---

---

---

## 20.2 RewardSelectionUI 伪代码

### 概念说明

- 是什么：奖励选择界面。
- 负责什么：展示奖励选项并把玩家选择传给 RunDirector 或 RewardSystem。
- 为什么需要：它是清房间后选择升级这一核心体验的可视层。

```gdscript
class_name RewardSelectionUI
extends Control

var options: Array[RewardOption] = []
var run_director: RunDirector = null

func setup(data: Dictionary) -> void:
    options = data.get("options", [])
    run_director = data.get("run_director", null)
    _render_options()

func _render_options() -> void:
    for option in options:
        var button := Button.new()
        button.text = "%s\n%s" % [option.display_name, option.description]
        button.pressed.connect(func(): _on_option_selected(option))
        $OptionContainer.add_child(button)

func _on_option_selected(option: RewardOption) -> void:
    if run_director != null:
        run_director.select_reward(option)
    var ui: UIManager = null
    if ServiceRegistry.has_service("ui"):
        ui = ServiceRegistry.get_service("ui") as UIManager
    if ui != null:
        ui.close_screen("reward_selection")
    else:
        queue_free()
```

#### 字段说明
- **options**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 函数使用场景
- **setup()**：公开 API。实际例子：外部系统通过它请求 **RewardSelectionUI** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_render_options()**：内部辅助函数。实际例子：由 **RewardSelectionUI** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_option_selected()**：内部辅助函数。实际例子：玩家点击一个奖励后提交给 RunDirector，并通过 UIManager 关闭 modal 以恢复 gameplay 时间。

---

### 27.75 RewardSelectionUI 使用示例

#### 详细实际用例

- 真实场景：RewardSelectionUI 收到三个 RewardOption，生成三个按钮；玩家点击 “+1 projectile” 后通知 RunDirector.select_reward(option) 并关闭界面。
- 怎么使用：UI 只展示和提交选择，不自己执行奖励效果；效果由 RewardSystem 应用。
- 验证重点：连点按钮不会重复应用奖励；选项描述和 rarity 显示正确。
```gdscript
func setup(data: Dictionary) -> void:
    options = data["options"]
    run_director = data["run_director"]
    _render_options()
```

### 创建按钮

```gdscript
func _render_options() -> void:
    for option in options:
        var button := Button.new()
        button.text = "%s\n%s" % [option.display_name, option.description]
        button.pressed.connect(func():
            run_director.select_reward(option)
            ServiceRegistry.get_service("ui").close_screen("reward_selection")
        )
        $OptionContainer.add_child(button)
```

---

---

---

## 20.3 FeedbackSystem

### 概念说明

- 是什么：玩法事件到表现反馈的桥。
- 负责什么：监听伤害、死亡、拾取等事件并播放音效、VFX、伤害数字、震屏。
- 为什么需要：Combat 代码不应该直接知道怎么播放声音或生成特效。

```gdscript
class_name FeedbackSystem
extends Node

@export var damage_number_system_path: NodePath
@export var vfx_spawner_path: NodePath
@export var audio_manager_path: NodePath

var damage_numbers: DamageNumberSystem
var vfx: VFXSpawner
var audio: AudioManager

func _ready() -> void:
    damage_numbers = get_node_or_null(damage_number_system_path) as DamageNumberSystem
    vfx = get_node_or_null(vfx_spawner_path) as VFXSpawner
    audio = get_node_or_null(audio_manager_path) as AudioManager

    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.damage_applied.connect(_on_damage_applied)
        events.entity_died.connect(_on_entity_died)

func _on_damage_applied(result: DamageResult) -> void:
    if result.target != null:
        if damage_numbers != null:
            damage_numbers.show_number(result.target.global_position, result.final_amount, result.was_critical)
        if vfx != null:
            vfx.spawn("hit", result.target.global_position)
        if audio != null:
            audio.play_sfx("hit")

func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
    if entity_ref != null:
        if vfx != null:
            vfx.spawn("death", entity_ref.global_position)
        if audio != null:
            audio.play_sfx("death")
```

#### 字段说明
- **damage_number_system_path**：资源或节点路径。例：用 damage_number_system_path 指向场景或节点，方便在 Inspector 中配置。
- **vfx_spawner_path**：资源或节点路径。例：用 vfx_spawner_path 指向场景或节点，方便在 Inspector 中配置。
- **audio_manager_path**：资源或节点路径。例：用 audio_manager_path 指向场景或节点，方便在 Inspector 中配置。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**FeedbackSystem** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **_on_damage_applied()**：内部辅助函数。实际例子：由 **FeedbackSystem** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_on_entity_died()**：内部辅助函数。实际例子：由 **FeedbackSystem** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.76 FeedbackSystem 使用示例

#### 详细实际用例

- 真实场景：damage_applied 事件发出后，FeedbackSystem 在敌人位置播放 hit VFX、音效和伤害数字；entity_died 后播放死亡爆炸。
- 怎么使用：表现反馈监听事件，不让 CombatResolver 或 HealthComponent 直接生成 VFX。
- 验证重点：关闭 FeedbackSystem 不影响伤害结算；换一套 VFX 不需要改战斗代码。
### 自动响应 combat event

```gdscript
func _ready() -> void:
    var feedback := $FeedbackSystem as FeedbackSystem
    # FeedbackSystem 内部会连接 EventRouter.damage_applied 和 entity_died。
```

### 手动播放反馈

```gdscript
func play_pickup_feedback(position: Vector2) -> void:
    $FeedbackSystem.vfx.spawn("pickup", position)
    $FeedbackSystem.audio.play_sfx("pickup")
```

---

---

---

## 20.4 AudioManager

### 概念说明

- 是什么：音效和音乐播放的轻量管理器。
- 负责什么：按 audio_id 查找 AudioStream，播放 SFX/Music，并隔离具体音频节点和 bus 配置。
- 为什么需要：Combat、Inventory 和 Room 不应该直接操作 AudioStreamPlayer；FeedbackSystem 只发出 play_sfx 请求。

```gdscript
class_name AudioManager
extends Node

@export var sfx_map: Dictionary = {} # audio_id -> AudioStream
@export var music_map: Dictionary = {} # music_id -> AudioStream
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

var music_player: AudioStreamPlayer = null

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.bus = music_bus
    add_child(music_player)

func play_sfx(audio_id: String, volume_db: float = 0.0) -> void:
    if not sfx_map.has(audio_id):
        return
    var player := AudioStreamPlayer.new()
    player.stream = sfx_map[audio_id]
    player.bus = sfx_bus
    player.volume_db = volume_db
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func play_music(music_id: String, fade_seconds: float = 0.0) -> void:
    if music_player == null or not music_map.has(music_id):
        return
    music_player.stream = music_map[music_id]
    music_player.play()

func stop_music() -> void:
    if music_player != null:
        music_player.stop()
```

#### 字段说明
- **sfx_map**：音效资源表。例：hit、death、pickup 映射到对应 AudioStream。
- **music_map**：音乐资源表。例：main_menu、combat_room 映射到背景音乐。
- **sfx_bus**：音效 bus。例：设置为 SFX 后由音量选项统一控制。
- **music_bus**：音乐 bus。例：设置为 Music 后由设置界面控制。
#### 函数使用场景
- **_ready()**：创建音乐播放器。
- **play_sfx()**：播放一次性音效。实际例子：FeedbackSystem 收到 damage_applied 后播放 hit。
- **play_music()**：播放背景音乐。实际例子：RunDirector 进入 boss 房后播放 boss_theme。
- **stop_music()**：停止音乐。实际例子：回到主菜单前停止 run 音乐。

---

### 27.93 AudioManager 使用示例

#### 详细实际用例

- 真实场景：敌人受击事件发生后，FeedbackSystem 调用 `audio.play_sfx("hit")`。换音效、换 bus 或禁用音频都不需要改 CombatResolver。
- 怎么使用：Gameplay 只通过 FeedbackSystem 或 AudioManager 的 audio_id 播放声音；不要在伤害结算里直接创建 AudioStreamPlayer。
- 验证重点：缺失 audio_id 时静默失败或发 warning，不影响 gameplay。

```gdscript
$AudioManager.play_sfx("pickup")
$AudioManager.play_music("combat_room")
```

---

---

---

## 20.5 VFXSpawner

### 概念说明

- 是什么：视觉特效生成器。
- 负责什么：按 vfx_id 生成 PackedScene，设置位置、方向和自动清理。
- 为什么需要：伤害、死亡、拾取、房间清理等事件都需要 VFX，但玩法系统不应该知道具体特效场景。

```gdscript
class_name VFXSpawner
extends Node

@export var vfx_scene_map: Dictionary = {} # vfx_id -> scene_path
@export var auto_free_seconds: float = 2.0

func spawn(vfx_id: String, position: Vector2, direction: Vector2 = Vector2.ZERO) -> Node:
    if not vfx_scene_map.has(vfx_id):
        return null
    var scene := load(vfx_scene_map[vfx_id]) as PackedScene
    if scene == null:
        return null
    var node := scene.instantiate()
    add_child(node)
    if node is Node2D:
        node.global_position = position
        if direction != Vector2.ZERO:
            node.rotation = direction.angle()
    if node.has_method("play"):
        node.play()
    if auto_free_seconds > 0.0:
        get_tree().create_timer(auto_free_seconds).timeout.connect(node.queue_free)
    return node
```

#### 字段说明
- **vfx_scene_map**：特效场景表。例：hit、death、pickup 分别映射到不同 PackedScene。
- **auto_free_seconds**：自动清理时间。例：普通 hit VFX 2 秒后释放。
#### 函数使用场景
- **spawn()**：生成特效。实际例子：FeedbackSystem 在目标位置生成 hit VFX。

---

### 27.94 VFXSpawner 使用示例

#### 详细实际用例

- 真实场景：`entity_died` 事件发生后，FeedbackSystem 调用 `vfx.spawn("death", enemy.global_position)`，生成死亡爆炸。
- 怎么使用：VFXSpawner 只处理表现节点；不要让它修改 HP、房间状态或奖励。
- 验证重点：缺失 vfx_id 不影响战斗；特效播放完能自动释放。

```gdscript
$VFXSpawner.spawn("hit", enemy.global_position, Vector2.LEFT)
```

---

---

---

## 20.6 DamageNumberSystem

### 概念说明

- 是什么：伤害数字显示系统。
- 负责什么：生成伤害数字 UI/Node2D，设置数值、暴击样式和位置。
- 为什么需要：DamageResult 已经记录最终伤害；显示层应该读取这个结果，而不是自己重新计算伤害。

```gdscript
class_name DamageNumberSystem
extends Node

@export var damage_number_scene_path: String = ""
@export var default_offset: Vector2 = Vector2(0, -24)

func show_number(position: Vector2, amount: float, critical: bool = false) -> Node:
    if damage_number_scene_path == "":
        return null
    var scene := load(damage_number_scene_path) as PackedScene
    if scene == null:
        return null
    var node := scene.instantiate()
    add_child(node)
    if node is Node2D:
        node.global_position = position + default_offset
    if node.has_method("setup"):
        node.setup(amount, critical)
    return node
```

#### 字段说明
- **damage_number_scene_path**：伤害数字场景路径。例：指向 FloatingDamageNumber.tscn。
- **default_offset**：显示偏移。例：数字从敌人头顶上方弹出。
#### 函数使用场景
- **show_number()**：显示伤害数字。实际例子：FeedbackSystem 收到 DamageResult 后显示 final_amount。

---

### 27.95 DamageNumberSystem 使用示例

#### 详细实际用例

- 真实场景：CombatResolver 得到 final_amount=27，HealthComponent 发出 damage_applied，FeedbackSystem 调用 DamageNumberSystem.show_number 显示 27；暴击时 critical=true。
- 怎么使用：只显示 DamageResult 的结果，不重新读 StatsComponent 计算。
- 验证重点：闪避或 0 伤害是否显示由 FeedbackSystem 决定；DamageNumberSystem 不影响实际 HP。

```gdscript
$DamageNumberSystem.show_number(enemy.global_position, 27.0, true)
```

---

