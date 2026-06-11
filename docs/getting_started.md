# 快速上手

5 分钟内让项目跑起来。

---

## 前置条件

- Godot 4.6.3 stable（本 repo 当前目标版本）
- 一个空白 Godot 项目（或现有项目）

---

## 1. 安装插件

将 `addons/mkit/` 整个目录复制到你的项目下，保持路径不变：

```
res://addons/mkit/
```

---

## 2. 启用插件，注册 Autoload

1. 打开 **Project → Project Settings → Plugins**
2. 找到 **mkit**，将状态切换为 **Enable**

插件启用后会自动注册唯一的 autoload：`ServiceRegistry`（Node，全局可用）。

> 如果手动注册：**Project → Project Settings → Autoload** → 添加 `res://addons/mkit/kernel/services/service_registry.gd`，名称设为 `ServiceRegistry`。

---

## 3. 创建 Bootstrap 场景

1. 新建场景，根节点选 **Node**，保存为 `res://bootstrap.tscn`
2. 添加子节点，类型选 **GameBootstrap**
3. 在 Inspector 中配置 `GameBootstrap` 的常用属性：

   | 属性 | 说明 | 示例值 |
   |------|------|--------|
   | `resource_databases` | 存放你的 `.tres` 内容数据库数组 | 暂时留空 |
   | `initial_scene_path` | 启动完成后跳转的场景路径 | `"res://game/main.tscn"` |
   | `save_path` | 可选存档文件路径；留空使用 `SaveService` 默认值 | `""` |

4. 将此场景设为项目主场景：**Project → Project Settings → Application → Run → Main Scene** → 选 `bootstrap.tscn`

---

## 4. 运行验证

**步骤：**

1. 按 **F5**（或点击编辑器顶部工具栏的 ▶ 按钮）运行项目

2. 查看编辑器底部的 **Output** 面板（如未显示：菜单 **Editor → Editor Bottom Panel → Output**）

**预期输出（顺序可能不同）：**

```
[mkit] GameBootstrap runtime services: actions, audio, commands, content,
effects, events, pool, random, save, scenes, time
```

看到上述输出说明 Bootstrap 成功运行，kernel 服务在线。若你改用 `ModuleBootstrap`，还会看到 `combat`、`dialogue`、`loot`、`progression`、`quest`、`shop`、`world`。`ui` 服务由场景中的 `UIManager` 节点自注册，所以只有游戏场景包含 UIManager 且已进入该场景后才会出现。

这一步只是安装验证，不是最终体验。下一步应该让你看到一个能移动、能交互、能触发 mkit command/effect 的可玩切片。

### 运行后建议的收口验证

改动 addon 代码或文档时，建议额外跑三项门禁：
- `make ut`
- `make int`
- `make docs-api`（改了公开 API 或 `##` doc comment 时）
- `make docs-check`

> **没看到输出？** 确认 `bootstrap.tscn` 已设为主场景（Project Settings → Application → Run → Main Scene），且 `GameBootstrap` 节点存在于场景根节点下。

---

## 5. 10 分钟可玩切片

最快的可见成果是直接运行 repo 自带的 village RPG demo：

1. 在 FileSystem 面板中右键 `game/bootstrap.tscn` → **Set as Main Scene**
2. 按 **F5** 运行
3. 用 **WASD** 移动玩家
4. 走到 `Elder Room` 门口，按 **E** 进入
5. 靠近 Elder，按 **E** 对话并接任务
6. 回到 Village，走到 `Field Gate`，按 **E** 去 Field
7. 靠近 Field Beast，按 **Space/J** 近战，或按 **Q** 释放 Firebolt

你应该能看到：玩家移动、传送门切换场景、对话 UI、任务 HUD、伤害/VFX、敌人死亡和掉落日志。这比只打印 service ids 更接近真实项目的第一步完成体验。

想从一个小起点开始改自己的项目时，优先看 `game_template/`。它只有 bootstrap、一个 starter scene、一个能移动/攻击的玩家、一个敌人和一条任务，适合作为第一份可删改代码。`game/` 下的 village RPG demo 是完整 showcase，适合对照系统能力，不建议整段复制根脚本。

| 你要改的部分 | 从这里开始 |
|--------------|------------|
| 最小起点 | `game_template/bootstrap.tscn`, `game_template/starter_scene.tscn` |
| 完整能力对照 | `game/bootstrap.tscn`, `game/village_rpg_demo.tscn` |
| 内容数据库样例 | `game/resources/village_rpg_content.tres` |
| 场景/传送门样例 | `game/scenes/village.tscn`, `game/scenes/field.tscn` |
| 游戏侧 UI 样例 | `game/ui/` |

---

## 6. 注册内容数据库（可选）

游戏配置（技能、物品、任务定义等）通过 `ResourceDatabase` 统一管理：

1. 在 FileSystem 中右键 → **New Resource** → 选 `ResourceDatabase`，保存为 `res://game/content_db.tres`
2. 在 Inspector 中将你的 `ContentDefinition` 资源添加到 `resources` 数组
3. 将 `content_db.tres` 拖入 `GameBootstrap.resource_databases` 数组

---

## 7. 运行内置 Demo

mkit 附带一个可直接运行的 village RPG demo，覆盖了从战斗、技能、任务到存档的完整 RPG loop。

**运行方法：**

项目主场景已预设为 demo 的 bootstrap，直接按 **F5** 即可启动。

> 如果主场景被改动过，在 FileSystem 面板中右键 `game/bootstrap.tscn` → **Set as Main Scene**，再按 F5。

**主流程操作：**

| 类别 | 操作 | 按键 |
|------|------|------|
| 移动 | 移动 | **WASD** |
| 交互 | 当前可交互对象：传送门、Elder、Village Supply、Trial Cave | **E** 或 **Enter** |
| 战斗 | 近战攻击 | **Space** 或 **J** |
| 战斗 | 冲刺 | **Shift** |
| 战斗 | 释放 Firebolt 技能 | **Q** |
| 对话/奖励 | 选择第 1/2/3 个可见选项 | **1** / **2** / **3** |
| 商店 | 打开商店后购买药水 / 出售兽爪 | **B** / **V** |
| 物品 | 使用药水 | **H** |

**开发演示快捷键：**

这些键用于 smoke、存档和调试，不是玩家主流程必须记住的操作。

| 类别 | 操作 | 按键 |
|------|------|------|
| 存档 | 保存 / 读取本地 demo 状态 | **F6** / **F7** |
| 调试 | 即时击败田野野兽 / DebugOverlay | **K** / **F3** |
| 窗口 | 切换全屏 | **F11** 或 **Alt/Command+Enter** |

**通关流程（完整 RPG loop）：**

1. **村庄出发**：启动后进入村庄场景。走到 Elder Room 门口，按 **E** 进入；靠近长老后按 **E** 对话并接取田野报告任务。

2. **前往田野**：回到 Village 后走到 Field Gate 区域内按 **E** 穿越传送门进入 Field。用 **WASD** 靠近 Field Beast，**Space/J** 近战或 **Q** 施放 Firebolt。Firebolt 每次成功施放都会飞出投射物；距离内命中时造成伤害并施加 burn，距离外则飞出后打空。右侧 HUD 会显示 Field Beast 的 HP / burn 状态；击杀后敌人会从画面移除，任务目标自动推进并掉落兽爪。（调试快捷键：**K** 直接击败野兽跳过战斗）

3. **返回村庄**：走到 Village Gate 区域内按 **E** 返回村庄。进入 Elder Room 后靠近长老按 **E** 再次对话，交还任务领取奖励；对话选项可用 **1/2/3** 选择。

4. **商店操作**（可选）：对话结束后商店解锁。走到 Village Supply 区域内按 **E** 打开商店，**B** 购买药水，**V** 出售兽爪。若背包里有 Field Blade，离开交互区域后按 **E** 装备，属性立即生效。按 **H** 使用药水恢复血量。

5. **进入试炼**：在 Field 走到 Trial Cave 洞口区域内按 **E**，触发三房间序列（RunDirector）。每个房间清除所有敌人后弹出奖励界面，按 **1**、**2** 或 **3** 选择奖励，奖励效果立即应用。三个房间全部通过即完成试炼。

6. **存档**：任意时刻按 **F6** 保存，**F7** 读取。存档覆盖任务状态、库存、等级与装备。

---

## 下一步

| 目标 | 文档 |
|------|------|
| 理解三层架构和服务注册模式 | [architecture.md](architecture.md) |
| 查看版本/兼容性承诺 | [compatibility.md](compatibility.md) |
| 理解命令→状态→动作→效果管线 | [concepts.md](concepts.md) |
| 按步骤构建完整 RPG | [cookbook/01_bootstrap.md](cookbook/01_bootstrap.md) |
| 查术语定义 | [glossary.md](glossary.md) |
| 查看当前限制和后续路线 | [roadmap.md](roadmap.md) |
