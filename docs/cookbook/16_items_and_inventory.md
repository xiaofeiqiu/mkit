# Recipe 16：物品与背包  ·  难度 ★★☆  ·  预计 25 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

玩家拥有一个完整的物品路径：定义一个**治疗药水**（`ItemDefinition` + `use_effects`），通过效果或代码放进背包（`InventoryController`），按键**使用**它——执行效果链、回血、扣数量；再定义一把**铁剑**装备到 `weapon` 槽位（`EquipmentController`），属性加成自动挂到 `StatsComponent`。背包随实体存档（Recipe 11 的 `EntitySaveAgent`）。

Recipe 08（掉落）和 Recipe 14（商店）里物品只是顺带出现；这一篇把「定义 → 入包 → 使用 → 装备」整条路径独立讲清。

## 前置

- 需完成：[Recipe 03](03_health_and_stats.md)（玩家有 `HealthComponent` / `StatsComponent`）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `ItemDefinition` (.tres)：类型 / 堆叠 / `use_effects` / `stat_modifiers` | `ContentService` 注册、按 `item_id` 查询 |
| 给玩家挂 `Controllers/InventoryController`（设 `capacity`）| `add_item()` 自动堆叠 / 找空格 / 容量校验，发 `item_added` + `inventory_changed` 领域事件 |
| 使用物品：执行 `use_effects` 后 `remove_item_by_instance_id()` | `EffectService.execute_many()` 跑效果链并记录 trace |
| 装备物品：挂 `EquipmentController`，调 `equip()` | 校验 `equipment_slot`，把 `stat_modifiers` 挂上/摘下 `StatsComponent` |

## 关键认知：definition 与 instance 是两层

- **`ItemDefinition`**（`extends ContentDefinition`，.tres）：静态数据——名字、堆叠规则、使用效果、装备加成。入 `ResourceDatabase`，全游戏共享一份。
- **`ItemInstance`**（`extends RefCounted`，运行时创建）：背包里实际放的东西——`instance_id`（唯一）、`definition_id`（指回定义）、`quantity`、耐久、词缀。用 `ItemInstance.create("item.potion", 3)` 构造。

背包 API 按两种 id 各有入口：`find_item(instance_id)` / `find_item_by_definition(definition_id)`；**移除只认 `instance_id`**（`remove_item_by_instance_id`）。

## 步骤

### 步骤 1：创建可使用的 ItemDefinition（治疗药水）

新建 Resource → `ItemDefinition`，存为 `res://data/items/potion.tres`：

| 字段 | 值 |
|------|----|
| `item_id` | `"item.potion"` |
| `display_name` | `"治疗药水"` |
| `icon` | `res://game/ui/icons/potion.png`（可留空）|
| `item_type` | `"consumable"` |
| `stackable` | `true`，`max_stack` = `99` |
| `value` | `20`（商店买卖价的基准，见 [Recipe 14](14_shop.md)）|
| `use_effects` | `[res://data/effects/potion_heal.tres]` |
| `use_conditions` | `[]`（可挂 `Condition` 限制使用时机）|

`ItemDefinition.icon` 是 UI 字段：mkit 背包和装备逻辑不读取它，但 [Recipe 18](18_ui_hud.md) 的背包格子可以用它渲染图标。没有图标时，UI 应回退到 `display_name`、首字母或空格样式。

`potion_heal.tres` 是一个 `HealEffect`：`effect_id="potion_heal"`, `base_amount=40.0`。

把 `ItemDefinition` 加入 `ResourceDatabase.resources`。`HealEffect` 是 `GameEffect`（非 `ContentDefinition`），不需要入库。

### 步骤 2：给玩家挂 InventoryController

在玩家实体的 `Controllers/` 下加 `InventoryController` 节点，Inspector 设 `capacity = 30`（格子数）。

```text
Player  (EntityRoot)
├── Components/
│   ├── HealthComponent
│   └── StatsComponent
└── Controllers/
    └── InventoryController   # capacity = 30
```

### 步骤 3：把物品放进背包

两条路，按场景选：

**A. 数据驱动（推荐）**：在任何 effect 链（奖励、对话、任务奖励）里挂 `GrantItemEffect`：`item_id="item.potion"`, `quantity=3`, `give_to_source=true`。它会找到接收者的 `Controllers/InventoryController`，背包放不下则整体失败（不会放一半）。

**B. 代码直加**（调试 / 初始装备）：

```gdscript
var inventory := EntityContract.get_controller(player, "InventoryController") as InventoryController
var potion := ItemInstance.create("item.potion", 3)
if not inventory.add_item(potion):
    print("背包满了")
```

`add_item()` 对可堆叠物品先填已有堆（按 `max_stack` 上限），再找空格；空间不足直接返回 `false`，物品数量不变。

### 步骤 4：使用物品

mkit 不预设「使用」按键——你来接线：找到实例 → 跑 `use_effects` → 扣数量：

```gdscript
func use_item(player: Node, definition_id: String) -> bool:
    var inventory := EntityContract.get_controller(player, "InventoryController") as InventoryController
    if inventory == null:
        return false
    var item := inventory.find_item_by_definition(definition_id)
    if item == null:
        return false   # 背包里没有
    var definition := inventory.get_item_definition(definition_id)
    if definition == null or definition.use_effects.is_empty():
        return false   # 不可使用的物品
    var ctx := GameplayContext.new().with_source(player).with_target(player)
    if not ConditionEvaluator.evaluate_all(definition.use_conditions, ctx):
        return false   # use_conditions 不满足（如满血禁用药水）
    Mkit.effects().execute_many(definition.use_effects, ctx, true)
    return inventory.remove_item_by_instance_id(item.instance_id, 1)
```

绑个键即可：`if Input.is_action_just_pressed("use_potion"): use_item(self, "item.potion")`。

### 步骤 5：创建可装备的 ItemDefinition（铁剑）

新建 `res://data/items/iron_sword.tres`：

| 字段 | 值 |
|------|----|
| `item_id` | `"item.iron_sword"` |
| `display_name` | `"铁剑"` |
| `icon` | `res://game/ui/icons/iron_sword.png`（可留空）|
| `item_type` | `"equipment"` |
| `stackable` | `false` |
| `equipment_slot` | `"weapon"` |
| `stat_modifiers` | `[一个 StatModifierDefinition：stat_id="attack_power", operation=FLAT_ADD, value=10]` |

入库。在玩家 `Controllers/` 下再加一个 `EquipmentController`（默认 `allowed_slots` 已含 `"weapon"`）。

### 步骤 6：装备 / 卸下

```gdscript
var equipment := EntityContract.get_controller(player, "EquipmentController") as EquipmentController
var sword := inventory.find_item_by_definition("item.iron_sword")
if sword != null and equipment.equip(sword, "weapon"):
    inventory.remove_item_by_instance_id(sword.instance_id, 1)   # 装上后从背包移出

# 卸下：unequip 返回 ItemInstance，放回背包
var removed := equipment.unequip("weapon")
if removed != null:
    inventory.add_item(removed)
```

`equip()` 校验 `definition.equipment_slot == slot_id`，同槽已有装备会先自动 `unequip()`；`stat_modifiers`（和实例的 `rolled_affixes`）以 `instance_id` 为 source 挂到 `StatsComponent`，卸下时按 source 一次性移除——不会残留加成。

### 步骤 7：监听背包变化（UI / 任务）

节点信号（本地、带 `ItemInstance`）：

```gdscript
inventory.inventory_changed.connect(_refresh_inventory_ui)
inventory.item_added.connect(func(item: ItemInstance): print("获得 %s x%d" % [item.definition_id, item.quantity]))
equipment.equipment_changed.connect(func(slot: String, item): _refresh_equipment_ui(slot, item))
```

领域事件（全局、可被任务/成就订阅）：

```gdscript
Mkit.events().subscribe(InventoryEvents.INVENTORY_CHANGED, func(event: DomainEvent):
    print("背包变化：", event.payload)   # {owner_id, item_id, quantity, change_type}
)
```

### 步骤 8：随实体存档

`InventoryController` / `EquipmentController` 都是 `SaveableComponent`——**不会**被 `SaveService` 当全局 root 收集。按 [Recipe 11 步骤 4](11_progression_and_save.md#步骤) 给玩家挂 `EntitySaveAgent`，背包格子、装备槽（含词缀、耐久）就会写入 `entities.player.components`。

## 运行验证

1. `add_item` 3 瓶药水 → 背包同一格 `quantity=3`（堆叠生效）
2. 打残血后按使用键 → HP +40、药水变 2、`EventService.recent_events` 出现 `inventory_changed`
3. 装备铁剑 → `StatsComponent.get_stat_value("attack_power")` +10；卸下 → 恢复原值
4. `quick_save` → 重启 → 背包数量和已装备的剑都回来
5. 塞满 30 格后再 `add_item` → 返回 `false`，物品不丢失也不减半

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `add_item` 返回 false | 背包满，或 `item_id` 没入库（查不到 definition）| 检查容量；`ItemDefinition` 加入 `ResourceDatabase.resources` |
| 使用药水没效果 | `use_effects` 为空，或 context 没设 target | 配上 effect 链；`with_source(player).with_target(player)` |
| 用一次扣不掉数量 | `remove` 传了 `definition_id` | `remove_item_by_instance_id` 只认**实例 id** |
| `equip` 返回 false | `equipment_slot` 与槽位名不一致，或槽位不在 `allowed_slots` | 两边字符串完全一致（如都是 `"weapon"`）|
| 装备了属性没变 | 实体上没有 `StatsComponent`，或该 stat 无 baseline | 挂 `StatsComponent` 并定义 `attack_power` |
| 存档后背包丢失 | 没挂 `EntitySaveAgent` | 见 [Recipe 11](11_progression_and_save.md) 关键认知 |
| 堆叠物品报 `invalid max_stack` | `stackable=true` 但 `max_stack<=0` | `max_stack` 设正数 |

## 延伸阅读

- [ItemDefinition ref](../generated/html/classes/ItemDefinition.html) · [ItemInstance ref](../generated/html/classes/ItemInstance.html)
- [InventoryController ref](../generated/html/classes/InventoryController.html) · [EquipmentController ref](../generated/html/classes/EquipmentController.html)
- [GrantItemEffect ref](../generated/html/classes/GrantItemEffect.html) — 数据驱动发物品
- [Recipe 08](08_loot_and_rewards.md) 物品作为奖励 · [Recipe 14](14_shop.md) 物品买卖
