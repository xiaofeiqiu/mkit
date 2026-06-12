# Demo Game

这个目录是 mkit 的可运行样例游戏内容，入口是：

```bash
make demo-test
```

或者在 Godot 中运行 `res://game/bootstrap.tscn`。

## 定位

`game/village_rpg_demo.tscn` 是完整 showcase，用来覆盖 combat、dialogue、quest、shop、world/run、loot、save、UI、audio 和 VFX 的组合效果。想从更小的项目模板开始，请先看 `game_template/`。自动 smoke 流程和存档 payload 校验分别在 `game/demo_auto_run_verifier.gd`、`game/demo_save_payload_verifier.gd`，不是普通玩法脚本必须复制的结构。

## 操作

| 类别 | 操作 | 按键 |
|------|------|------|
| 移动 | 移动 | `WASD` |
| 交互 | 当前可交互对象：传送门、Elder、Village Supply、Trial Cave | `E` / `Enter` |
| 战斗 | 近战攻击 | `Space` / `J` |
| 战斗 | Dash | `Shift` |
| 战斗 | 释放 Firebolt | `Q` |
| 对话/试炼 | 选择第 1/2/3 个可见选项 | `1` / `2` / `3` |
| 商店 | 商店打开后购买 Herb Potion / 出售 Beast Claw | `B` / `V` |
| 物品 | 使用 Herb Potion | `H` |
| 存档 | 保存本地 demo 状态 | `F6` |
| 存档 | 读取本地 demo 状态 | `F7` |
| 调试 | 直接击败 Field Beast | `K` |
| 调试 | 切换 debug overlay | `F3` |
| 窗口 | 切换全屏 | `F11` / `Alt+Enter` / `Command+Enter` |

Demo 默认以窗口模式启动。需要全屏时使用上面的快捷键手动切换。

## 视觉反馈

- 玩家攻击时会显示当前 melee hitbox。
- Firebolt 每次成功施放都会生成飞行投射物；目标超出命中距离时投射物会飞出但不会造成伤害或 burn。
- HUD 底部显示当前 1-3 个可执行动作，右侧日志显示玩家可读事件。
- 传送门、商店和 Trial Cave 都通过 mkit `InteractionComponent` 的区域 focus 触发，离开区域后按键不会生效。
