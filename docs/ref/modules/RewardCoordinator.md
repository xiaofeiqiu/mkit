# RewardCoordinator

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/reward_coordinator.gd`  
**继承：** `extends RefCounted`

## 职责

Run 奖励应用桥。把 `RewardOption` 转成带 `run_id`、source、target 的 `GameplayContext`，并调用 `"loot"` 服务应用奖励。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `player_group` | `String` | `"player"` | 从 `SceneTree` 查找奖励目标 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `apply_reward(option: RewardOption, run_id: String, tree: SceneTree) -> bool` | `bool` | 调 `LootService.apply_selected()` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var coordinator := RewardCoordinator.new()
coordinator.apply_reward(option, run_id, get_tree())
```

### 典型场景（Level 2）

```gdscript
func apply_first_reward(options: Array[RewardOption], run_id: String) -> bool:
    if options.is_empty():
        return false
    var coordinator := RewardCoordinator.new()
    coordinator.player_group = "player"
    return coordinator.apply_reward(options[0], run_id, get_tree())
```

## 相关

- → [RunDirector](RunDirector.md) · [RewardOption](RewardOption.md) · [LootService](LootService.md)

