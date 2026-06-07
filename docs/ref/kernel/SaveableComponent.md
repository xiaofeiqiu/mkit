# SaveableComponent

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/saveable_component.gd`  
**继承：** `extends Node`

## 职责

**组件级存档契约**。与 `Saveable` 同接口，键由节点 `name` 决定（实体内唯一）。`HealthComponent`、`StatsComponent`、`AbilityController`、`InventoryController`、`EquipmentController`、`ResourcePoolComponent`、`StatusEffectController` 都继承它。

> ⚠️ **`SaveService` 不会自动收集 `SaveableComponent`。** 要持久化它，必须由所属实体上的一个 [Saveable](Saveable.md) 代理主动收集（见该页 Level 2）。单独挂一个 SaveableComponent 不会进存档——这是最常见的"背包没存上"坑。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_save_key() -> String` | `String` | 默认返回节点 `name`（同实体内须唯一）|
| `to_save_data() -> Dictionary` | `Dictionary` | **override** 返回要存的数据 |
| `from_save_data(data: Dictionary) -> void` | — | **override** 从数据恢复 |

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name AmmoComponent
extends SaveableComponent

var rounds: int = 30

func to_save_data() -> Dictionary:
    return {"rounds": rounds}

func from_save_data(data: Dictionary) -> void:
    rounds = int(data.get("rounds", 30))
```

> 别在运行时改组件节点名——`get_save_key()` 默认就是 name，改名会导致读档对不上。

## 相关

- → [Saveable](Saveable.md)（全局契约，负责收集 SaveableComponent）· [SaveService](SaveService.md)
- → [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)（步骤 4：收集模式）
