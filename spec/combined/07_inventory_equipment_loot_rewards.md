# Inventory, Equipment, Loot, and Rewards

---

# 14. Inventory / Equipment 模块接口设计

---

## 14.1 ItemDefinition

### 概念说明

- 是什么：一个物品类型的静态定义，例如小药水、铁剑、钥匙、金币袋。
- 负责什么：定义物品 ID、类型、是否可堆叠、装备槽、使用效果、属性修改和标签。
- 为什么需要：掉落表、商店、背包、装备和存档都应该引用 item.potion_small 这种稳定定义 ID。
`res://addons/mkit/modules/inventory/item_definition.gd`

```gdscript
class_name ItemDefinition
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: String = "material" # weapon, armor, consumable, material, quest
@export var rarity: String = "common"
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var equipment_slot: String = ""
@export var tags: Array[String] = []
@export var use_conditions: Array[Condition] = []
@export var use_effects: Array[GameEffect] = []
@export var stat_modifiers: Array[StatModifierDefinition] = []
```

#### 字段说明
- **item_id**：物品定义 ID。例：item.potion_small 用于从 ContentRegistry 找到药水定义。
- **rarity**：稀有度。例：common、rare、legendary，用于掉落权重和 UI 颜色。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **use_conditions**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **use_effects**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **stat_modifiers**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

---

### 27.49 ItemDefinition 使用示例

#### 详细实际用例

- 真实场景：`item.sword_iron` 定义为 weapon，可装备到 weapon slot，提供 attack_power +5；`item.potion_small` 定义为 consumable，使用时 Heal 30。
- 怎么使用：物品类型、堆叠规则、装备槽、效果和 stat modifier 写在定义里。
- 验证重点：掉落表和商店只引用 item_id；UI 通过定义显示图标和描述。
### Iron Sword

```gdscript
var sword := ItemDefinition.new()
sword.item_id = "item.sword_iron"
sword.display_name = "Iron Sword"
sword.description = "A reliable iron sword."
sword.item_type = "weapon"
sword.rarity = "common"
sword.stackable = false
sword.max_stack = 1
sword.equipment_slot = "weapon"
sword.tags = ["weapon", "sword", "melee"]

var attack_mod := StatModifierDefinition.new()
attack_mod.modifier_id = "mod.sword_iron.attack"
attack_mod.stat_id = "attack_power"
attack_mod.operation = StatModifierDefinition.Operation.FLAT_ADD
attack_mod.value = 5.0
sword.stat_modifiers = [attack_mod]
```

### Small Potion

```gdscript
var potion := ItemDefinition.new()
potion.item_id = "item.potion_small"
potion.display_name = "Small Potion"
potion.item_type = "consumable"
potion.stackable = true
potion.max_stack = 10

var heal := HealEffect.new()
heal.effect_id = "effect.potion_small_heal"
heal.amount = 25.0
potion.use_effects = [heal]
```

---

---

---

## 14.2 ItemInstance

### 概念说明

- 是什么：背包里一件具体物品或一组堆叠物品。
- 负责什么：记录 instance_id、definition_id、数量、耐久、随机词缀、强化等级和运行时元数据。
- 为什么需要：两把铁剑都来自 item.sword_iron，但一把 +12% 暴击、一把耐久 30%，所以必须有不同实例。
`res://addons/mkit/modules/inventory/item_instance.gd`

```gdscript
class_name ItemInstance
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var quantity: int = 1
var rolled_affixes: Array[StatModifier] = []
var durability: float = 1.0
var upgrade_level: int = 0
var metadata: Dictionary = {}

static func create(definition_id: String, quantity: int = 1) -> ItemInstance:
    var item := ItemInstance.new()
    item.instance_id = "item_%d" % Time.get_ticks_usec()
    item.definition_id = definition_id
    item.quantity = quantity
    return item

func to_save_data() -> Dictionary:
    return {
        "instance_id": instance_id,
        "definition_id": definition_id,
        "quantity": quantity,
        "durability": durability,
        "upgrade_level": upgrade_level,
        "metadata": metadata
    }

static func from_save_data(data: Dictionary) -> ItemInstance:
    var item := ItemInstance.new()
    item.instance_id = str(data.get("instance_id", ""))
    item.definition_id = str(data.get("definition_id", ""))
    item.quantity = int(data.get("quantity", 1))
    item.durability = float(data.get("durability", 1.0))
    item.upgrade_level = int(data.get("upgrade_level", 0))
    item.metadata = data.get("metadata", {})
    return item
```

#### 字段说明
- **instance_id**：运行时物品/对象实例 ID。例：两把 Iron Sword 都来自 item.sword_iron，但一把有暴击词缀、一把有耐久损耗，所以必须有不同 instance_id。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **quantity**：数量。例：药水 stack 数量是 3，金币掉落数量是 20。
- **rolled_affixes**：随机词缀。例：同一把 item.sword_iron 可以随机出 +12% crit chance。
- **durability**：耐久。例：武器每次攻击降低耐久，归零后需要修理或失效。
- **upgrade_level**：强化等级。例：+3 铁剑比普通铁剑有更高攻击 modifier。
#### 函数使用场景
- **create()**：工厂方法。实际例子：掉落系统创建 ItemInstance 或 DomainEvent 时，用 create 保证 ID、时间戳和默认字段一次性设置完整。
- **to_save_data()**：序列化。实际例子：保存游戏时把背包、装备、RunState 转成 Dictionary。
- **from_save_data()**：反序列化。实际例子：读档时用存档 Dictionary 恢复玩家 HP、位置和背包。

---

### 27.50 ItemInstance 使用示例

#### 详细实际用例

- 真实场景：玩家背包里有两把铁剑，第一把 instance_id=sword_001，带暴击词缀；第二把 sword_002，耐久只剩 40。
- 怎么使用：背包和装备操作都针对 ItemInstance；Definition 只说明“铁剑是什么类型”。
- 验证重点：装备 sword_001 后应用它自己的词缀；丢弃 sword_002 不影响 sword_001。
```gdscript
var sword_instance := ItemInstance.create("item.sword_iron", 1)
sword_instance.durability = 0.85
sword_instance.metadata["found_in_room"] = "room_003"
```

### 存档 / 读档

```gdscript
var data := sword_instance.to_save_data()
var restored := ItemInstance.from_save_data(data)
```

---

---

---

## 14.3 InventorySlot

### 概念说明

- 是什么：背包中的一个格子或存储位置。
- 负责什么：保存该格子里的 ItemInstance、数量、锁定状态或槽位元数据。
- 为什么需要：UI 网格、快捷栏、背包容量和物品移动都需要明确的 slot，而不是只有一个散列表。
```gdscript
class_name InventorySlot
extends RefCounted

var index: int = -1
var item: ItemInstance = null

func is_empty() -> bool:
    return item == null

func clear() -> void:
    item = null
```

#### 函数使用场景
- **is_empty()**：状态查询。实际例子：AI 调用 is_empty 判断目标是不是敌对阵营或 Action 是否结束。
- **clear()**：清理/重置入口。实际例子：切换存档、退出 run 或重启测试时调用，让 **InventorySlot** 清空自己的运行时缓存。

---

### 27.51 InventorySlot 使用示例

#### 详细实际用例

- 真实场景：背包 UI 有 20 个格子，第 0 格放 3 瓶小药水，第 1 格放一把铁剑，第 2 格为空。
- 怎么使用：Slot 保存当前 item/quantity/锁定状态，InventoryModel 用 slot 实现移动、堆叠和容量限制。
- 验证重点：拖动物品换格、堆叠药水、满包拾取失败都能按 slot 规则处理。
```gdscript
var slot := InventorySlot.new()
slot.index = 0
slot.item = ItemInstance.create("item.potion_small", 3)

if not slot.is_empty():
    print(slot.item.definition_id)
```

---

---

---

## 14.4 InventoryModel

### 概念说明

- 是什么：背包的纯数据模型，不负责 UI。
- 负责什么：添加、移除、堆叠、移动、查找、序列化和恢复物品实例。
- 为什么需要：玩家即使没有打开背包界面，也可能拾取、消耗、保存和恢复物品；这些逻辑应该独立于 UI。
```gdscript
class_name InventoryModel
extends RefCounted

var owner_id: String = ""
var capacity: int = 30
var slots: Array[InventorySlot] = []

func setup(slot_count: int) -> void:
    capacity = slot_count
    slots.clear()
    for i in range(slot_count):
        var slot := InventorySlot.new()
        slot.index = i
        slots.append(slot)

func find_first_empty_slot() -> InventorySlot:
    for slot in slots:
        if slot.is_empty():
            return slot
    return null

func find_stackable_slot(definition: ItemDefinition, item: ItemInstance) -> InventorySlot:
    if not definition.stackable:
        return null
    for slot in slots:
        if slot.item != null and slot.item.definition_id == item.definition_id and slot.item.quantity < definition.max_stack:
            return slot
    return null

func get_items() -> Array[ItemInstance]:
    var result: Array[ItemInstance] = []
    for slot in slots:
        if slot.item != null:
            result.append(slot.item)
    return result
```

#### 字段说明
- **owner_id**：稳定 ID 字段。例：InventoryModel 通过 owner_id 引用某个定义或运行时对象，避免直接保存节点路径。
#### 函数使用场景
- **setup()**：公开 API。实际例子：外部系统通过它请求 **InventoryModel** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **find_first_empty_slot()**：公开 API。实际例子：外部系统通过它请求 **InventoryModel** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **find_stackable_slot()**：公开 API。实际例子：外部系统通过它请求 **InventoryModel** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **get_items()**：读取数据入口。实际例子：CombatResolver 通过 get_items 获取最终攻击力，而不是直接读内部变量。

---

### 27.52 InventoryModel 使用示例

#### 详细实际用例

- 真实场景：玩家拾取药水，InventoryModel 查找已有药水堆叠；如果堆叠未满就加数量，否则找空格。
- 怎么使用：所有背包数据操作放在 model；UI 只渲染 model 状态，Controller 负责接外部请求。
- 验证重点：不打开 UI 也能拾取和保存；读档后 slot/item/quantity 恢复一致。
```gdscript
var model := InventoryModel.new()
model.setup(20)

var empty_slot := model.find_first_empty_slot()
empty_slot.item = ItemInstance.create("item.potion_small", 1)

var all_items := model.get_items()
print(all_items.size())
```

---

---

---

## 14.5 InventoryController

### 概念说明

- 是什么：实体背包操作的场景控制器。
- 负责什么：连接拾取、命令、UI、存档和 InventoryModel。
- 为什么需要：背包数据和 UI 需要解耦；即使背包界面没打开，拾取和存档也应该正常工作。

```gdscript
class_name InventoryController
extends Node

signal inventory_changed
signal item_added(item: ItemInstance)
signal item_removed(item: ItemInstance)

@export var capacity: int = 30

var model := InventoryModel.new()
var content: ContentRegistry = null

func _ready() -> void:
    content = ServiceRegistry.get_service("content") as ContentRegistry
    model.setup(capacity)
    model.owner_id = _get_owner_id()

func can_add_item(item: ItemInstance) -> bool:
    var definition := get_item_definition(item.definition_id)
    if definition == null:
        return false
    if model.find_stackable_slot(definition, item) != null:
        return true
    return model.find_first_empty_slot() != null

func add_item(item: ItemInstance) -> bool:
    var definition := get_item_definition(item.definition_id)
    if definition == null:
        return false

    var remaining := item.quantity
    var original_quantity := item.quantity

    if definition.stackable:
        for slot in model.slots:
            if slot.item != null and slot.item.definition_id == item.definition_id:
                var space := definition.max_stack - slot.item.quantity
                var moved := min(space, remaining)
                slot.item.quantity += moved
                remaining -= moved
                if remaining <= 0:
                    item_added.emit(item)
                    _emit_inventory_changed()
                    return true

    while remaining > 0:
        var empty := model.find_first_empty_slot()
        if empty == null:
            item.quantity = remaining
            if remaining < original_quantity:
                item_added.emit(item)
            _emit_inventory_changed()
            return false
        var new_stack := ItemInstance.create(item.definition_id, min(remaining, definition.max_stack))
        empty.item = new_stack
        remaining -= new_stack.quantity

    item_added.emit(item)
    _emit_inventory_changed()
    return true

func remove_item_by_instance_id(instance_id: String, quantity: int = 1) -> bool:
    for slot in model.slots:
        if slot.item != null and slot.item.instance_id == instance_id:
            slot.item.quantity -= quantity
            if slot.item.quantity <= 0:
                var removed := slot.item
                slot.clear()
                item_removed.emit(removed)
            _emit_inventory_changed()
            return true
    return false

func find_item(instance_id: String) -> ItemInstance:
    for slot in model.slots:
        if slot.item != null and slot.item.instance_id == instance_id:
            return slot.item
    return null

func get_item_definition(item_id: String) -> ItemDefinition:
    if content == null:
        content = ServiceRegistry.get_service("content") as ContentRegistry
    return content.get_resource(item_id) as ItemDefinition

func to_save_data() -> Dictionary:
    var items: Array = []
    for slot in model.slots:
        items.append(slot.item.to_save_data() if slot.item != null else null)
    return {"capacity": capacity, "items": items}

func from_save_data(data: Dictionary) -> void:
    capacity = int(data.get("capacity", capacity))
    model.setup(capacity)
    var items: Array = data.get("items", [])
    for i in range(min(items.size(), model.slots.size())):
        if items[i] != null:
            model.slots[i].item = ItemInstance.from_save_data(items[i])
    _emit_inventory_changed()

func _emit_inventory_changed() -> void:
    inventory_changed.emit()
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_inventory_changed(_get_owner_id())

func _get_owner_id() -> String:
    var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
    return identity.entity_id if identity != null else owner.name
```

#### 信号说明
- **inventory_changed**：当 **InventoryController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **item_added**：当 **InventoryController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **item_removed**：当 **InventoryController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**InventoryController** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **can_add_item()**：合法性检查。实际例子：释放技能前先调用 can_add_item，失败时 UI 显示冷却中或目标太远。
- **add_item()**：添加操作。实际例子：玩家拾取药水时 add_item 把 ItemInstance 放入背包。
- **remove_item_by_instance_id()**：移除操作。实际例子：使用药水后 remove_item 减少堆叠数量。
- **find_item()**：公开 API。实际例子：外部系统通过它请求 **InventoryController** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **get_item_definition()**：读取数据入口。实际例子：CombatResolver 通过 get_item_definition 获取最终攻击力，而不是直接读内部变量。
- **to_save_data()**：序列化。实际例子：保存游戏时把背包、装备、RunState 转成 Dictionary。
- **from_save_data()**：反序列化。实际例子：读档时用存档 Dictionary 恢复玩家 HP、位置和背包。
- **_emit_inventory_changed()**：内部辅助函数。实际例子：背包内容变化后发出本地信号和 EventRouter.inventory_changed。
- **_get_owner_id()**：内部辅助函数。实际例子：由 **InventoryController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.53 InventoryController 使用示例

#### 详细实际用例

- 真实场景：玩家走到掉落物上，Pickup 调用 InventoryController.add_item()；成功后发 inventory_changed，HUD 播放拾取提示。
- 怎么使用：场景交互、命令、UI、存档都通过 controller 访问背包 model。
- 验证重点：满包时返回失败并不销毁地面物品；成功拾取时 UI 和音效响应事件。
### 添加物品

```gdscript
var inventory := player.get_node("Controllers/InventoryController") as InventoryController
var item := ItemInstance.create("item.potion_small", 3)

if inventory.can_add_item(item):
    inventory.add_item(item)
```

### 删除物品

```gdscript
inventory.remove_item_by_instance_id(item.instance_id, 1)
```

### 保存背包

```gdscript
var save_data := inventory.to_save_data()
```

### 恢复背包

```gdscript
inventory.from_save_data(save_data)
```

---

---

---

## 14.6 EquipmentController

### 概念说明

- 是什么：装备槽和装备属性的控制器。
- 负责什么：校验槽位、装备/卸下物品、应用/移除属性 modifier。
- 为什么需要：装备会影响属性、技能和 UI，所以需要独立于普通背包存储。

```gdscript
class_name EquipmentController
extends Node

signal equipment_changed(slot_id: String, item: ItemInstance)

@export var allowed_slots: Array[String] = ["weapon", "helmet", "armor", "ring", "amulet"]

var equipped: Dictionary = {} # slot_id -> ItemInstance
var content: ContentRegistry = null

func _ready() -> void:
    content = ServiceRegistry.get_service("content") as ContentRegistry

func can_equip(item: ItemInstance, slot_id: String) -> bool:
    if item == null:
        return false
    if not allowed_slots.has(slot_id):
        return false
    var definition := get_item_definition(item.definition_id)
    if definition == null:
        return false
    return definition.equipment_slot == slot_id

func equip(item: ItemInstance, slot_id: String) -> bool:
    if not can_equip(item, slot_id):
        return false

    if equipped.has(slot_id):
        unequip(slot_id)

    equipped[slot_id] = item
    _apply_item_modifiers(item)
    equipment_changed.emit(slot_id, item)
    return true

func unequip(slot_id: String) -> ItemInstance:
    if not equipped.has(slot_id):
        return null
    var item := equipped[slot_id] as ItemInstance
    _remove_item_modifiers(item)
    equipped.erase(slot_id)
    equipment_changed.emit(slot_id, null)
    return item

func get_equipped(slot_id: String) -> ItemInstance:
    return equipped.get(slot_id, null)

func _apply_item_modifiers(item: ItemInstance) -> void:
    var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats == null:
        return
    var definition := get_item_definition(item.definition_id)
    if definition == null:
        return
    for mod_def in definition.stat_modifiers:
        stats.add_modifier(StatModifier.from_definition(mod_def, item.instance_id))
    for rolled in item.rolled_affixes:
        rolled.source_id = item.instance_id
        stats.add_modifier(rolled)

func _remove_item_modifiers(item: ItemInstance) -> void:
    var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats != null:
        stats.remove_modifiers_from_source(item.instance_id)

func get_item_definition(item_id: String) -> ItemDefinition:
    if content == null:
        content = ServiceRegistry.get_service("content") as ContentRegistry
    return content.get_resource(item_id) as ItemDefinition
```

#### 信号说明
- **equipment_changed**：当 **EquipmentController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**EquipmentController** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **can_equip()**：合法性检查。实际例子：释放技能前先调用 can_equip，失败时 UI 显示冷却中或目标太远。
- **equip()**：装备操作。实际例子：玩家装备铁剑时应用 attack_power +5，卸下时移除该 modifier。
- **unequip()**：装备操作。实际例子：玩家装备铁剑时应用 attack_power +5，卸下时移除该 modifier。
- **get_equipped()**：读取数据入口。实际例子：CombatResolver 通过 get_equipped 获取最终攻击力，而不是直接读内部变量。
- **_apply_item_modifiers()**：内部辅助函数。实际例子：由 **EquipmentController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_remove_item_modifiers()**：内部辅助函数。实际例子：由 **EquipmentController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **get_item_definition()**：读取数据入口。实际例子：CombatResolver 通过 get_item_definition 获取最终攻击力，而不是直接读内部变量。

---

---

### 27.54 EquipmentController 使用示例

#### 详细实际用例

- 真实场景：玩家把铁剑拖到 weapon slot，EquipmentController 校验物品类型，装备成功后给 StatsComponent 添加 attack_power +5 modifier。
- 怎么使用：装备/卸下都走 controller，背包 UI 不直接改 StatsComponent。
- 验证重点：卸下装备后 modifier 移除；错误槽位如把头盔放武器槽应失败。
### 装备武器

```gdscript
var inventory := player.get_node("Controllers/InventoryController") as InventoryController
var equipment := player.get_node("Controllers/EquipmentController") as EquipmentController

var sword := inventory.find_item("item_instance_001")
if equipment.can_equip(sword, "weapon"):
    equipment.equip(sword, "weapon")
```

### 卸下装备

```gdscript
var old_weapon := equipment.unequip("weapon")
if old_weapon != null:
    inventory.add_item(old_weapon)
```

---

---

# 15. Loot / Reward 模块接口设计

---

## 15.1 LootEntry

### 概念说明

- 是什么：掉落表中的一个候选掉落项。
- 负责什么：定义可能掉落什么内容、权重是多少、最小/最大数量是多少、是否有条件。
- 为什么需要：一个 goblin_common 掉落表可能包含药水、金币、普通剑和空掉落，每个候选都需要独立权重。
```gdscript
class_name LootEntry
extends Resource

@export var content_id: String = ""
@export var weight: float = 1.0
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export var conditions: Array[Condition] = []
```

#### 字段说明
- **content_id**：稳定 ID 字段。例：LootEntry 通过 content_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **weight**：权重。例：普通药水 weight=10，稀有武器 weight=1。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。

---

### 27.55 LootEntry 使用示例

#### 详细实际用例

- 真实场景：`loot.goblin_common` 里有 potion_entry(weight=10, quantity=1-2)、gold_entry(weight=20)、sword_entry(weight=1)。
- 怎么使用：每个 entry 描述一个候选掉落，不负责实际随机；LootSystem 根据权重选择。
- 验证重点：调高 sword_entry weight 后，测试滚动中剑出现概率应上升。
```gdscript
var entry := LootEntry.new()
entry.content_id = "item.potion_small"
entry.weight = 10.0
entry.min_quantity = 1
entry.max_quantity = 3
```

---

---

---

## 15.2 LootTableDefinition

### 概念说明

- 是什么：一张完整掉落表的静态定义。
- 负责什么：组合多个 LootEntry，设置 roll 次数、是否允许空掉落、空掉落权重和整体规则。
- 为什么需要：敌人、宝箱、Boss、商店库存都可以通过掉落表生成奖励，而不是在死亡脚本里写随机逻辑。
```gdscript
class_name LootTableDefinition
extends Resource

@export var loot_table_id: String = ""
@export var rolls: int = 1
@export var entries: Array[LootEntry] = []
@export var allow_empty: bool = true
@export var empty_weight: float = 0.0
```

#### 字段说明
- **loot_table_id**：稳定 ID 字段。例：LootTableDefinition 通过 loot_table_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **rolls**：掉落表掷骰次数。例：Boss 宝箱 rolls=3，普通敌人 rolls=1。
- **entries**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **allow_empty**：是否允许空掉落。例：普通小怪可以空掉落，Boss 宝箱不应该空。
- **empty_weight**：空掉落权重。例：empty_weight 越高，普通怪越可能不掉东西。

---

### 27.56 LootTableDefinition 使用示例

#### 详细实际用例

- 真实场景：普通 goblin 死亡 roll 一次，可空掉落；Boss 宝箱 roll 三次，不允许空掉落。
- 怎么使用：把 rolls、allow_empty、empty_weight 和 entries 配在表里，让敌人或宝箱只引用 loot_table_id。
- 验证重点：普通怪可能不掉，Boss 必掉；同 seed 下结果可复现。
```gdscript
var table := LootTableDefinition.new()
table.loot_table_id = "loot.goblin_common"
table.rolls = 1
table.allow_empty = true
table.empty_weight = 5.0

table.entries = [
    potion_entry,
    gold_entry,
    sword_entry
]
```

---

---

---

## 15.3 LootRollResult

### 概念说明

- 是什么：一次掉落表掷骰后的生成结果。
- 负责什么：保存生成出的物品实例、货币、被选中的 entry 和调试信息。
- 为什么需要：LootSystem 只负责生成结果；至于是直接进背包、掉在地上还是显示在宝箱 UI，由上层流程决定。
```gdscript
class_name LootRollResult
extends RefCounted

var item_instances: Array[ItemInstance] = []
var currency: Dictionary = {}
var debug_rolls: Array[Dictionary] = []
```

---

### 27.57 LootRollResult 使用示例

#### 详细实际用例

- 真实场景：一次宝箱 roll 结果包含 15 gold 和 1 个 `item.potion_small` ItemInstance。
- 怎么使用：LootSystem 返回 result 后，上层决定直接进背包、生成地面掉落，还是展示宝箱 UI。
- 验证重点：result 中的 item_instances 是运行时实例，不能只是 definition id。
```gdscript
var result := LootRollResult.new()
result.item_instances.append(ItemInstance.create("item.potion_small", 2))
result.currency["gold"] = 15
```

---

---

---

## 15.4 LootSystem

### 概念说明

- 是什么：掉落表生成服务。
- 负责什么：按权重、条件、数量范围和随机种子生成 LootRollResult。
- 为什么需要：敌人死亡、宝箱、Boss、商店库存都需要一致且可测试的掉落逻辑。

```gdscript
class_name LootSystem
extends RefCounted

func roll_table(table_id: String, context: GameplayContext) -> LootRollResult:
    var content := ServiceRegistry.get_service("content") as ContentRegistry
    var table := content.get_resource(table_id) as LootTableDefinition
    if table == null:
        return LootRollResult.new()
    return roll(table, context)

func roll(table: LootTableDefinition, context: GameplayContext) -> LootRollResult:
    var result := LootRollResult.new()
    var random := ServiceRegistry.get_service("random") as RandomService

    for i in range(table.rolls):
        var candidates := _get_valid_entries(table, context)
        var total_weight := table.empty_weight if table.allow_empty else 0.0
        for entry in candidates:
            total_weight += entry.weight

        if total_weight <= 0:
            continue

        var roll := random.randf_range(0.0, total_weight) if random != null else randf_range(0.0, total_weight)
        if table.allow_empty and roll < table.empty_weight:
            result.debug_rolls.append({"roll": roll, "result": "empty"})
            continue

        var cursor := table.empty_weight if table.allow_empty else 0.0
        for entry in candidates:
            cursor += entry.weight
            if roll <= cursor:
                var quantity := _roll_quantity(entry)
                result.item_instances.append(ItemInstance.create(entry.content_id, quantity))
                result.debug_rolls.append({"roll": roll, "result": entry.content_id, "quantity": quantity})
                break

    return result

func _get_valid_entries(table: LootTableDefinition, context: GameplayContext) -> Array[LootEntry]:
    var result: Array[LootEntry] = []
    for entry in table.entries:
        if ConditionEvaluator.evaluate_all(entry.conditions, context):
            result.append(entry)
    return result

func _roll_quantity(entry: LootEntry) -> int:
    if entry.min_quantity >= entry.max_quantity:
        return entry.min_quantity
    var random := ServiceRegistry.get_service("random") as RandomService
    if random != null:
        return random.randi_range(entry.min_quantity, entry.max_quantity)
    return randi_range(entry.min_quantity, entry.max_quantity)
```

#### 函数使用场景
- **roll_table()**：随机生成。实际例子：敌人死亡时 roll_table 生成金币、药水或空掉落。
- **roll()**：随机生成。实际例子：敌人死亡时 roll_table 生成金币、药水或空掉落。
- **_get_valid_entries()**：内部辅助函数。实际例子：由 **LootSystem** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_roll_quantity()**：内部辅助函数。实际例子：由 **LootSystem** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.58 LootSystem 使用示例

#### 详细实际用例

- 真实场景：goblin 死亡时，EnemyDropOnDeath 请求 LootSystem.roll_table("loot.goblin_common")，得到物品和金币结果。
- 怎么使用：LootSystem 只负责生成结果，不直接修改玩家背包，避免掉落逻辑和背包逻辑耦合。
- 验证重点：传入固定 seed 时掉落可复现；条件不满足的 entry 不进入候选池。
```gdscript
var loot_system := LootSystem.new()
var ctx := GameplayContext.new()
ctx.source = enemy
ctx.target = player
ctx.payload["room_id"] = "room_001"

var result := loot_system.roll_table("loot.goblin_common", ctx)

var inventory := player.get_node("Controllers/InventoryController") as InventoryController
for item in result.item_instances:
    inventory.add_item(item)
```

---

---

---

## 15.5 RewardOption

### 概念说明

- 是什么：一次奖励选择界面里的一个可选项。
- 负责什么：保存展示文本、稀有度、来源、效果列表和选择后要应用的内容。
- 为什么需要：Roguelike 常见“三选一升级”，UI 需要显示它，RewardSystem 需要执行它，RunDirector 需要知道玩家选了哪个。
```gdscript
class_name RewardOption
extends RefCounted

var reward_id: String = ""
var display_name: String = ""
var description: String = ""
var icon: Texture2D = null
var rarity: String = "common"
var source: String = ""
var effects: Array[GameEffect] = []
var payload: Dictionary = {}
```

#### 字段说明
- **reward_id**：稳定 ID 字段。例：RewardOption 通过 reward_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **rarity**：稀有度。例：common、rare、legendary，用于掉落权重和 UI 颜色。
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **effects**：玩法结果列表。例：DealDamageEffect 后接 ApplyStatusEffect(status.burn)。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。

---

### 27.60 RewardOption 使用示例

#### 详细实际用例

- 真实场景：清房间后 UI 展示三个 RewardOption：+20% attack、+10 max hp、+1 projectile。玩家只能选一个。
- 怎么使用：Option 是 UI 和 RewardSystem 之间的展示/执行载体，里面带 display data 和 effects。
- 验证重点：玩家点击后只应用被选中的 option，其他 option 不应产生效果。
```gdscript
var option := RewardOption.new()
option.reward_id = "reward.attack_plus_20"
option.display_name = "Power Up"
option.description = "+20% attack power"
option.rarity = "common"
option.effects = reward.effects
```

---

---

---

## 15.6 RewardDefinition

### 概念说明

- 是什么：一个可能出现的奖励的静态定义。
- 负责什么：定义奖励 ID、显示信息、稀有度、权重、出现条件和效果列表。
- 为什么需要：+20% attack、+1 projectile、解锁火球、永久 HP +5 都可以用同一套奖励模型表达。
```gdscript
class_name RewardDefinition
extends Resource

@export var reward_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export var weight: float = 1.0
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []
```

#### 字段说明
- **reward_id**：稳定 ID 字段。例：RewardDefinition 通过 reward_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **rarity**：稀有度。例：common、rare、legendary，用于掉落权重和 UI 颜色。
- **weight**：权重。例：普通药水 weight=10，稀有武器 weight=1。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。
- **effects**：玩法结果列表。例：DealDamageEffect 后接 ApplyStatusEffect(status.burn)。

---

### 27.59 RewardDefinition 使用示例

#### 详细实际用例

- 真实场景：`reward.attack_plus_20` 定义显示为 “Power Up”，效果是给当前 run 添加 attack_power +20% modifier。
- 怎么使用：奖励候选作为 Resource 配置，RewardSystem 根据权重和条件生成 RewardOption。
- 验证重点：奖励定义不直接操作 UI；同一奖励可以用于房间奖励、宝箱选择或商店。
```gdscript
var reward := RewardDefinition.new()
reward.reward_id = "reward.attack_plus_20"
reward.display_name = "Power Up"
reward.description = "+20% attack power for this run."
reward.rarity = "common"
reward.weight = 10.0

var mod_effect := ApplyStatModifierEffect.new()
mod_effect.stat_id = "attack_power"
mod_effect.operation = StatModifierDefinition.Operation.PERCENT_ADD
mod_effect.value = 0.20
mod_effect.duration = -1.0

reward.effects = [mod_effect]
```

> `ApplyStatModifierEffect` 的定义见 `04_conditions_and_effects.md` 的 §7.9，它把
> reward/upgrade 的属性加成统一走 StatsComponent.add_modifier。

---

---

---

## 15.7 RewardSystem

### 概念说明

- 是什么：玩家可选择奖励的生成和应用系统。
- 负责什么：生成三选一、商店选择、房间奖励等选项，并执行玩家选择的效果。
- 为什么需要：Roguelike 的核心循环常常是清房间后选奖励，所以它必须独立于具体 UI。

```gdscript
class_name RewardSystem
extends RefCounted

func generate_options(pool_ids: Array[String], count: int, context: GameplayContext) -> Array[RewardOption]:
    var content := ServiceRegistry.get_service("content") as ContentRegistry
    var candidates: Array[RewardDefinition] = []

    for id in pool_ids:
        var def := content.get_resource(id) as RewardDefinition
        if def != null and ConditionEvaluator.evaluate_all(def.conditions, context):
            candidates.append(def)

    var result: Array[RewardOption] = []
    while result.size() < count and candidates.size() > 0:
        var selected := _weighted_pick(candidates)
        candidates.erase(selected)
        result.append(_build_option(selected))

    return result

func apply_selected(option: RewardOption, context: GameplayContext) -> bool:
    if option == null:
        return false
    var executor := ServiceRegistry.get_service("effects") as EffectExecutor
    var results := executor.execute_many(option.effects, context, true)
    for r in results:
        if not r.success:
            return false

    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_reward_selected(option.reward_id, context.source.name if context.source != null else "")
    return true

func _weighted_pick(candidates: Array[RewardDefinition]) -> RewardDefinition:
    var total := 0.0
    for c in candidates:
        total += c.weight
    var random := ServiceRegistry.get_service("random") as RandomService
    var roll := random.randf_range(0.0, total) if random != null else randf_range(0.0, total)
    var cursor := 0.0
    for c in candidates:
        cursor += c.weight
        if roll <= cursor:
            return c
    return candidates[0]

func _build_option(def: RewardDefinition) -> RewardOption:
    var option := RewardOption.new()
    option.reward_id = def.reward_id
    option.display_name = def.display_name
    option.description = def.description
    option.icon = def.icon
    option.rarity = def.rarity
    option.effects = def.effects.duplicate()
    return option
```

#### 函数使用场景
- **generate_options()**：生成内容。实际例子：清房间后 RewardSystem.generate_options 生成三选一奖励。
- **apply_selected()**：应用玩法结果。实际例子：RewardSystem 应用 +20% attack 的奖励 Effect。
- **_weighted_pick()**：内部辅助函数。实际例子：由 **RewardSystem** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_build_option()**：内部辅助函数。实际例子：由 **RewardSystem** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.61 RewardSystem 使用示例

#### 详细实际用例

- 真实场景：RoomController 检测清房间，RunDirector 请求 RewardSystem 从奖励池里生成三个符合条件的选项。
- 怎么使用：生成和应用奖励都走 RewardSystem；RewardSelectionUI 只负责显示和提交选择。
- 验证重点：已选过的唯一奖励不再出现；不满足条件的奖励不会生成。
### 生成三选一奖励

```gdscript
var reward_system := RewardSystem.new()
var ctx := GameplayContext.new()
ctx.source = player
ctx.run_id = "run_001"

var options := reward_system.generate_options([
    "reward.attack_plus_20",
    "reward.max_hp_plus_10",
    "reward.projectile_plus_1",
    "reward.move_speed_plus_15"
], 3, ctx)
```

### 应用玩家选择

```gdscript
func on_reward_clicked(option: RewardOption) -> void:
    var ctx := GameplayContext.new()
    ctx.source = player
    ctx.run_id = current_run.run_id

    var reward_system := RewardSystem.new()
    if reward_system.apply_selected(option, ctx):
        print("Reward applied: ", option.reward_id)
```

---

