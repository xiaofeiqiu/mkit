# Recipe 18：UI 面板与 HUD  ·  难度 ★★☆  ·  预计 25 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

游戏有了两类 UI 并各归其位：一个**常驻 HUD**（血条 + 金币数，订阅组件信号与领域事件实时刷新），和一个**可开关的背包面板**（走 `UIManager` 的 screen 栈管理，modal 打开时游戏自动暂停）。此前血条、商店 UI 都散在各 Recipe 里捎带出现；这一篇讲清 mkit 里 UI 接入的两种标准姿势。

## 前置

- 需完成：[Recipe 03](03_health_and_stats.md)（有 `HealthComponent`）；背包面板部分需要 [Recipe 16](16_items_and_inventory.md)
- 用到的概念：[concepts.md — 模型 1：标准管线](../concepts.md#模型-1标准管线时序图)（⑨ 广播事件 → UI 订阅）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| HUD 场景（Control），订阅信号/事件刷新显示 | 组件与服务在状态变化时发信号（`health_changed`、`currency_changed`…）和领域事件 |
| 面板场景 + 可选的 `setup(data)` 方法 | `UIManager.open_screen()` 实例化、挂载、入栈、调 `setup` |
| 主场景挂 `UIManager` + `ScreenRoot`，配 `screen_scene_map` | screen 去重、modal 时 `TimeService.set_paused(true)`、关闭时恢复 |

## 关键认知：HUD 订阅，面板走 UIManager

- **常驻 HUD**（血条、金币、Buff 图标）：自己放在 `CanvasLayer` 下常驻场景，**拉取数据靠订阅**——绝不每帧轮询。游戏逻辑不知道 HUD 存在。
- **开关面板**（背包、商店、奖励选择）：注册进 `UIManager.screen_scene_map`，用 `open_screen/close_screen` 管理。同一 screen 不会重复打开；`modal=true` 自动暂停 `TimeService`（物理时间不受影响，UI 自身照常响应）。

`UIManager` **不在** `ModuleBootstrap` 的默认服务里——它是场景节点，`_ready()` 时把自己注册为 `"ui"` 服务，之后才能用 `Mkit.ui()` 取到。

## 步骤

### 步骤 1：搭 HUD 场景

```text
Main
└── HudLayer  (CanvasLayer)
    └── Hud  (Control，挂下面的脚本)
        ├── HealthBar   (ProgressBar)
        └── GoldLabel   (Label)
```

### 步骤 2：血条订阅 HealthComponent

```gdscript
# res://game/ui/hud.gd
extends Control

@export var player_path: NodePath
@onready var health_bar: ProgressBar = $HealthBar
@onready var gold_label: Label = $GoldLabel


func _ready() -> void:
    var player := get_node(player_path)
    var health := EntityContract.get_component(player, "HealthComponent") as HealthComponent
    if health != null:
        health.health_changed.connect(_on_health_changed)
        _on_health_changed(health.current_hp, health.get_max_hp())   # 初始值


func _on_health_changed(current: float, max_value: float) -> void:
    health_bar.max_value = max_value
    health_bar.value = current
```

拿得到节点引用时**优先连节点信号**（类型化、带完整参数）。

### 步骤 3：金币订阅服务信号

```gdscript
func _ready() -> void:
    # ...步骤 2 的内容...
    var progression := Mkit.progression()
    if progression != null:
        progression.currency_changed.connect(func(currency_id: String, amount: int):
            if currency_id == "gold":
                gold_label.text = str(amount)
        )
        gold_label.text = str(progression.get_currency("gold"))
```

### 步骤 4：跨系统提示用领域事件

拿不到源头节点引用（敌人死亡、物品入包）时，订阅 `EventService`：

```gdscript
Mkit.events().subscribe(InventoryEvents.INVENTORY_CHANGED, func(event: DomainEvent):
    if event.payload.get("change_type", "") == "added":
        _show_toast("获得 %s x%d" % [event.payload.get("item_id"), event.payload.get("quantity", 1)])
)
```

> 节点信号 vs 领域事件怎么选：能直连就直连；要解耦（发送方不知道谁在听、跨场景）就走事件总线。

### 步骤 5：主场景挂 UIManager

（Recipe 08 已做过则只需补 map。）主场景加 `UIManager` 节点和它的 `ScreenRoot` 子节点：

```text
Main
├── UIManager
│   └── ScreenRoot  (Control / CanvasLayer)   # screen_root_path 默认 "ScreenRoot"
└── HudLayer ...
```

Inspector 配置 `screen_scene_map`：

```
screen_scene_map = {
    "inventory": "res://game/ui/inventory_panel.tscn"
}
```

### 步骤 6：写背包面板（setup 约定）

`open_screen()` 实例化场景后，如果根节点有 `setup(data)` 方法就会调用——这是给面板传数据的约定：

```gdscript
# res://game/ui/inventory_panel.gd（挂在面板根 Control 上）
extends Control

var _inventory: InventoryController = null


func setup(data: Dictionary) -> void:
    _inventory = data.get("inventory")
    _inventory.inventory_changed.connect(_render)
    _render()


func _render() -> void:
    # 遍历 _inventory.model.slots，slot.item 为 null 表示空格
    for slot in _inventory.model.slots:
        pass   # 生成/更新格子控件


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Mkit.ui().close_screen("inventory")
```

### 步骤 7：按键开关面板

```gdscript
# 主场景脚本
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_inventory"):
        var ui := Mkit.ui()
        if ui == null:
            return
        if ui.is_screen_open("inventory"):
            ui.close_screen("inventory")
        else:
            var inventory := EntityContract.get_controller(_player, "InventoryController")
            ui.open_screen("inventory", {"inventory": inventory}, true)   # modal=true → 暂停游戏
```

`open_screen` 返回实例（已打开则返回已有的）；`close_top_screen()` 适合做统一的 Esc 关闭。

## 运行验证

1. 被打 → 血条立刻下降；开局显示满血（步骤 2 的初始刷新）
2. 加金币（`progression.add_currency("gold", 50)`）→ `GoldLabel` 更新
3. 按背包键 → 面板打开、游戏暂停（敌人停止移动）；再按 → 关闭、恢复
4. 面板开着时拾取物品 → 格子实时刷新（`inventory_changed` 接通）
5. 连按两次打开键 → 只有一个面板实例

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `Mkit.ui()` 返回 null | 场景里没有 `UIManager` 节点（它不是 bootstrap 注册的服务）| 主场景挂 `UIManager`，等它 `_ready` 后再调用 |
| `unknown screen 'xxx'` | `screen_scene_map` 没配该 id 或路径拼错 | 检查 map 的 key 和 .tscn 路径 |
| 面板打开但游戏没暂停 | `open_screen` 没传 `modal=true` | 第三个参数传 `true` |
| 关闭面板后游戏仍暂停 | 面板被直接 `queue_free` 而不是 `close_screen` | 一律通过 `UIManager` 关闭，让它维护 modal 栈 |
| HUD 不更新 | 只在 `_ready` 读了一次值，没订阅信号 | 连接 `health_changed` 等信号；别每帧轮询 |
| 面板里数据为空 | 根节点没实现 `setup(data)`，或 open 时没传数据 | 对齐 setup 约定 |

## 延伸阅读

- [UIManager ref](../generated/html/classes/UIManager.html) — open/close/栈/modal
- [Recipe 08](08_loot_and_rewards.md) 奖励选择 UI · [Recipe 09](09_npc_dialogue.md) DialogueUI · [Recipe 14](14_shop.md) ShopUI — 三个内置 screen 的实例
- [debugging.md — EventService.recent_events](../debugging.md#eventservicerecent_events) — 事件没到 UI 时先看这里
