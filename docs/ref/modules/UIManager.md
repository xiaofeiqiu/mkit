# UIManager

**层：** Module  
**文件：** `addons/mkit/modules/ui/ui_manager.gd`  
**继承：** `extends Node`  
**服务 ID：** `"ui"`（节点 `_ready()` 时自注册，若尚未存在）

## 职责

屏幕栈管理器。按 `screen_id` 实例化 UI 场景、维护打开栈、可选 modal 暂停 gameplay time。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `screen_root_path` | `NodePath`（@export）| `"ScreenRoot"` | UI 实例挂载容器 |
| `screen_scene_map` | `Dictionary`（@export）| `{}` | screen_id → PackedScene 路径 |
| `screen_stack` | `Array[String]` | `[]` | 打开顺序 |
| `active_screens` | `Dictionary` | `{}` | screen_id → Node |
| `modal_screens` | `Array[String]` | `[]` | modal screen id |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `open_screen(screen_id: String, data: Dictionary = {}, modal: bool = false) -> Node` | `Node` | 打开或返回已打开 screen；若节点有 `setup` 会传入 data |
| `close_screen(screen_id: String) -> void` | — | 关闭指定 screen |
| `close_top_screen() -> void` | — | 关闭栈顶 |
| `is_screen_open(screen_id: String) -> bool` | `bool` | 是否打开 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `screen_opened` | `screen_id` | 打开成功 |
| `screen_closed` | `screen_id` | 关闭成功 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var ui: UIManager = ServiceRegistry.get_service("ui") as UIManager
ui.open_screen("inventory", {}, true)
```

### 典型场景（Level 2）

```gdscript
func show_rewards(options: Array[RewardOption], director: RunDirector) -> void:
    var ui: UIManager = ServiceRegistry.get_service("ui") as UIManager
    if ui == null:
        return
    ui.open_screen("reward_selection", {"options": options, "run_director": director}, true)
```

## 相关

- → [RewardSelectionUI](RewardSelectionUI.md) · [DialogueUI](DialogueUI.md) · [ShopUI](ShopUI.md) · [TimeService](../kernel/TimeService.md)
- → [cookbook/08_loot_and_rewards.md](../../cookbook/08_loot_and_rewards.md)

