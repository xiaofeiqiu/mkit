# 快速上手

5 分钟内让项目跑起来。

---

## 前置条件

- Godot 4.7-dev（本 repo 当前目标版本）
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
3. 在 Inspector 中配置 `GameBootstrap` 的两个属性：

   | 属性 | 说明 | 示例值 |
   |------|------|--------|
   | `resource_databases` | 存放你的 `.tres` 内容数据库数组 | 暂时留空 |
   | `initial_scene_path` | 启动完成后跳转的场景路径 | `"res://game/main.tscn"` |

4. 将此场景设为项目主场景：**Project → Project Settings → Application → Run → Main Scene** → 选 `bootstrap.tscn`

---

## 4. 运行验证

**步骤：**

1. 在任意节点脚本的 `_ready()` 中临时加入以下代码：

   ```gdscript
   func _ready() -> void:
       var ids := ServiceRegistry.get_registered_service_ids()
       print("Services online: ", ids)
   ```

2. 按 **F5**（或点击编辑器顶部工具栏的 ▶ 按钮）运行项目

3. 查看编辑器底部的 **Output** 面板（如未显示：菜单 **Editor → Editor Bottom Panel → Output**）

**预期输出（顺序可能不同）：**

```
Services online: ["actions", "ads", "analytics", "audio", "cloud_save",
  "commands", "combat", "content", "dialogue", "effects", "events",
  "iap", "loot", "pool", "progression", "quest", "random", "save",
  "scenes", "shop", "time", "world"]
```

看到上述输出说明 Bootstrap 成功运行，内置服务在线。`ui` 服务由场景中的 `UIManager` 节点自注册，所以只有游戏场景包含 UIManager 且已进入该场景后才会出现。

### 运行后建议的收口验证

改动 addon 代码或文档时，建议额外跑三项门禁：
- `make ut`
- `make int`
- `make docs-check`

> **没看到输出？** 确认 `bootstrap.tscn` 已设为主场景（Project Settings → Application → Run → Main Scene），且 `GameBootstrap` 节点存在于场景根节点下。

---

## 5. 注册内容数据库（可选）

游戏配置（技能、物品、任务定义等）通过 `ResourceDatabase` 统一管理：

1. 在 FileSystem 中右键 → **New Resource** → 选 `ResourceDatabase`，保存为 `res://game/content_db.tres`
2. 在 Inspector 中将你的 `ContentDefinition` 资源添加到 `resources` 数组
3. 将 `content_db.tres` 拖入 `GameBootstrap.resource_databases` 数组

---

## 6. 运行内置 Demo

mkit 附带一个可直接运行的 village RPG demo，覆盖了从战斗、技能、任务到存档的完整 RPG loop。

**运行方法：**

项目主场景已预设为 demo 的 bootstrap，直接按 **F5** 即可启动。

> 如果主场景被改动过，在 FileSystem 面板中右键 `game/bootstrap.tscn` → **Set as Main Scene**，再按 F5。

**完整操作键位：**

| 类别 | 操作 | 按键 |
|------|------|------|
| 移动 | 移动 | **WASD** 或 **方向键** |
| 战斗 | 近战攻击 | **Space** 或 **J** |
| 战斗 | 冲刺 | **Shift** |
| 战斗 | 释放 Firebolt 技能 | **Q** 或 **F** |
| 世界 | 进出 Field（田野） | **G** |
| 世界 | 进出 Elder Room（村长室） | **R** |
| 世界 | 进入 Trial Cave（试炼序列） | **C** |
| NPC | 与长老对话 / 推进对话 | **T** |
| NPC | 向长老请求祝福 | **Y** |
| NPC | 接取人工任务 | **M** |
| 物品 | 购买药水 | **B** |
| 物品 | 出售兽爪 | **V** |
| 物品 | 使用药水 | **H** |
| 物品 | 装备 / 卸下 Field Blade | **E** |
| 试炼 | 选择奖励 1 / 2 / 3 | **1** / **2** / **3** |
| 存档 | 保存 / 读取 | **S** / **L** |
| 调试 | 即时击败田野野兽 | **K** |
| 调试 | 显示 / 隐藏 DebugOverlay | **F3** |

**通关流程（完整 RPG loop）：**

1. **村庄出发**：启动后进入村庄场景。按 **T** 与长老对话，接取田野报告任务（对话中按 T 推进 / 选择选项）。

2. **前往田野**：按 **G** 穿越传送门进入 Field。用 **WASD** 靠近 Field Beast，**Space** 近战或 **Q/F** 施放 Firebolt。Firebolt 会先造成伤害并施加 burn，右侧 HUD 会显示 Field Beast 的 HP / burn 状态；击杀后敌人会从画面移除，任务目标自动推进并掉落兽爪。（调试快捷键：**K** 直接击败野兽跳过战斗）

3. **返回村庄**：按 **G** 返回村庄。按 **T** 再次与长老对话，交还任务领取奖励，可选择接受祝福（**Y**）。

4. **商店操作**（可选）：对话结束后商店解锁。按 **B** 购买药水，**V** 出售兽爪。若背包里有 Field Blade，按 **E** 装备，属性立即生效。按 **H** 使用药水恢复血量。

5. **进入试炼**：按 **C** 进入 Trial Cave，触发三房间序列（RunDirector）。每个房间清除所有敌人后弹出奖励界面，按 **1**、**2** 或 **3** 选择奖励，奖励效果立即应用。三个房间全部通过即完成试炼。

6. **存档**：任意时刻按 **S** 保存，**L** 读取。存档覆盖任务状态、库存、等级与装备。

---

## 下一步

| 目标 | 文档 |
|------|------|
| 理解三层架构和服务注册模式 | [architecture.md](architecture.md) |
| 理解命令→状态→动作→效果管线 | [concepts.md](concepts.md) |
| 按步骤构建完整 RPG | [cookbook/01_bootstrap.md](cookbook/01_bootstrap.md) |
| 查术语定义 | [glossary.md](glossary.md) |
| 对照大改架构目标 | `spec/architect.md` |
