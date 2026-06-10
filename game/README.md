# Demo Game

这个目录是 mkit 的可运行样例游戏内容，入口是：

```bash
make demo-test
```

或者在 Godot 中运行 `res://game/bootstrap.tscn`。

## 操作

| 类别 | 操作 | 按键 |
|------|------|------|
| 移动 | 移动 | `WASD` |
| 战斗 | 近战攻击 | `Space` / `J` |
| 战斗 | Dash | `Shift` |
| 战斗 | 释放 Firebolt | `Q` / `F` |
| 世界 | 在 Field Gate / Village Gate 区域内进入/离开 Field | `G` |
| 世界 | 在 Elder Room 门口区域内进入/离开 Elder Room | `R` |
| 世界 | 在 Field 的 Trial Cave 洞口区域内进入 Trial Cave；洞内离开 | `C` |
| NPC | 和 Elder 对话，或推进当前对话 | `T` |
| NPC | 领取 Elder blessing | `Y` |
| NPC | 完成手动任务示例 | `M` |
| 物品 | 站在 Village Supply 区域内购买 potion | `B` |
| 物品 | 站在 Village Supply 区域内出售 beast claw | `V` |
| 物品 | 使用 potion | `H` |
| 物品 | 装备/卸下 Field Blade | `E` |
| 试炼 | 选择 Trial reward | `1` / `2` / `3` |
| 存档 | 保存本地 demo 状态 | `F6` |
| 存档 | 读取本地 demo 状态 | `F7` |
| 平台 | 触发 rewarded revive 示例 | `N` |
| 平台 | 站在 Village Supply 区域内触发 gold pack 示例 | `P` |
| 云存档 | 保存到 cloud slot 示例 | `O` |
| 云存档 | 从 cloud slot 示例读取 | `U` |
| 调试 | 直接击败 Field Beast | `K` |
| 调试 | 切换 debug overlay | `F3` |
| 窗口 | 切换全屏 | `F11` / `Alt+Enter` / `Command+Enter` |

Demo 默认以窗口模式启动。需要全屏时使用上面的快捷键手动切换。

## 视觉反馈

- 玩家攻击时会显示当前 melee hitbox。
- Firebolt 会生成飞行投射物，命中时播放 hit VFX。
- HUD 只保留状态和短日志，完整操作说明不再显示在游戏画面里。
- 传送门、商店和 Trial Cave 都通过 mkit `InteractionComponent` 的区域 focus 触发，离开区域后按键不会生效。
