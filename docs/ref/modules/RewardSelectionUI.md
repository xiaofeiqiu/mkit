# RewardSelectionUI

**层：** Module  
**文件：** `addons/mkit/modules/ui/reward_selection_ui.gd`  
**继承：** `extends Control`

## 职责

Run 奖励选择界面。`setup(data)` 读取 `options` 和 `run_director`，为每个 `RewardOption` 创建按钮，点击后调用 `RunDirector.select_reward()`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `options` | `Array[RewardOption]` | `[]` | 展示的选项 |
| `run_director` | `RunDirector` | `null` | 奖励选择回调目标 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `setup(data: Dictionary) -> void` | — | 读取 data 并渲染按钮 |

## 使用模式

### 最小示例（Level 1）

```gdscript
$RewardSelectionUI.setup({"options": options, "run_director": director})
```

### 典型场景（Level 2）

```gdscript
func show_reward_screen(options: Array[RewardOption], director: RunDirector) -> void:
    var ui: UIManager = ServiceRegistry.get_service("ui") as UIManager
    if ui == null:
        return
    ui.open_screen("reward_selection", {"options": options, "run_director": director}, true)
```

## 相关

- → [RewardOption](RewardOption.md) · [RunDirector](RunDirector.md) · [UIManager](UIManager.md)
- → [cookbook/08_loot_and_rewards.md](../../cookbook/08_loot_and_rewards.md)

