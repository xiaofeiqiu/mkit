# Proposal: SaveableComponent 与 Duck-Typed 组件存档

## 背景

当前 mkit 的存档系统有两条契约：

- `Saveable`：全局级存档节点。`SaveService.save_game(root)` 会自动扫描场景树里的 `Saveable`，按 `get_save_id()` 写入存档。
- `SaveableComponent`：实体内部组件的存档基类。它提供 `get_save_key()`、`to_save_data()`、`from_save_data()`，但不会被 `SaveService` 自动收集，需要由所属实体上的 `Saveable` 代理主动收集。

这个边界是合理的：`SaveService` 负责全局存档对象，实体内部组件由实体自己的存档代理负责。问题在于 Godot / GDScript 只有单继承。有些 game 侧组件可能已经必须继承另一个组件基类，但仍然需要参与实体存档，这时无法再 `extends SaveableComponent`。

## 问题

如果坚持所有可存档组件都必须继承 `SaveableComponent`，会产生两个问题：

1. 继承冲突：组件已经继承 `InteractionComponent`、自定义状态组件、表现组件等基类时，无法同时继承 `SaveableComponent`。
2. 错误抽象压力：为了能存档，可能会把不相关的基类改成 `SaveableComponent`，导致组件边界变浑。

如果反过来让 `SaveService` 全局 duck type 扫描所有有 `to_save_data()` 的节点，也有明显风险：

1. 误收集：很多状态对象、运行时模型、工具节点可能也有 `to_save_data()`，但并不应该成为独立存档根。
2. key 冲突：实体组件的 key 通常只在实体内部唯一，不应该进入全局 `payload`。
3. 重复保存：同一个组件可能被实体代理保存一次，又被全局扫描保存一次。
4. scope 语义混乱：`SaveService` 的 scope 是给 `Saveable` 根对象用的，不适合每个普通组件自动参与。

## 设计目标

- 保留 `SaveService` 当前边界：只自动收集 `Saveable`。
- 保留 `SaveableComponent`：继续作为 mkit 标准组件的强类型基类。
- 支持 game 侧特殊组件通过 duck type 参与实体存档，解决单继承限制。
- 让“应该被实体存档代理收集”成为显式意图，而不是只靠 `has_method("to_save_data")` 猜测。
- 保持教学路径简单：默认教 `Saveable` + `SaveableComponent`，进阶场景再教 duck-typed participant。

## 建议方案

引入“实体存档参与者”的收集规则，但不新增全局基类要求。

实体上的 `Saveable` 代理，例如 `PlayerSaveAgent`，收集两类节点：

1. `node is SaveableComponent`
2. duck-typed 节点，要求：
   - 节点在 `"mkit_entity_save_participant"` group 中
   - 有 `get_save_key()`
   - 有 `to_save_data()`
   - 有 `from_save_data(data)`

`SaveService` 不需要改。它仍然只收集 `Saveable`，例如 `PlayerSaveAgent`、`QuestService`、`WorldService`、`ProgressionService`。

## 推荐 API 形状

实体存档代理可以使用一个小的本地 helper：

```gdscript
class_name PlayerSaveAgent
extends Saveable

const ENTITY_SAVE_PARTICIPANT_GROUP := "mkit_entity_save_participant"


func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	var root := owner if owner != null else get_parent()
	if root == null:
		return data
	for node in _collect_entity_save_participants(root):
		var key := str(node.call("get_save_key"))
		if key == "":
			continue
		data[key] = node.call("to_save_data")
	return data


func from_save_data(data: Dictionary) -> void:
	var root := owner if owner != null else get_parent()
	if root == null:
		return
	for node in _collect_entity_save_participants(root):
		var key := str(node.call("get_save_key"))
		if key != "" and data.has(key) and data[key] is Dictionary:
			node.call("from_save_data", data[key])


func _collect_entity_save_participants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if node == self:
			continue
		if _is_entity_save_participant(node):
			result.append(node)
	return result


func _is_entity_save_participant(node: Node) -> bool:
	if node is SaveableComponent:
		return true
	return (
		node.is_in_group(ENTITY_SAVE_PARTICIPANT_GROUP)
		and node.has_method("get_save_key")
		and node.has_method("to_save_data")
		and node.has_method("from_save_data")
	)
```

game 侧继承冲突组件可以这样写：

```gdscript
class_name WeaponComponent
extends SomeOtherComponent

var ammo: int = 30
var durability: int = 100


func _ready() -> void:
	add_to_group("mkit_entity_save_participant")


func get_save_key() -> String:
	return "weapon"


func to_save_data() -> Dictionary:
	return {
		"ammo": ammo,
		"durability": durability,
	}


func from_save_data(data: Dictionary) -> void:
	ammo = int(data.get("ammo", ammo))
	durability = int(data.get("durability", durability))
```

## 为什么还保留 SaveableComponent

`SaveableComponent` 仍然有价值，不应该删除：

- 它是 mkit 标准组件的明确类型标记。
- 它提供默认 `get_save_key()`，约定 key 来自节点 `name`。
- 它让文档和教学更简单：普通组件直接 `extends SaveableComponent`。
- 它让框架内部组件可以用 `node is SaveableComponent` 做可靠类型判断。
- duck type 是兼容机制，不是主路径。

推荐规则：

| 场景 | 用法 |
|------|------|
| 全局服务、世界状态、账号/局外进度 | `extends Saveable` |
| mkit 标准实体组件，没有继承冲突 | `extends SaveableComponent` |
| game 侧组件已有必需基类 | group + duck type |
| 普通值对象或运行时模型 | 只提供 `to_save_data()`，由所属对象手动调用，不进场景树扫描 |

## Key 规则

`Saveable.get_save_id()` 是全局唯一。`SaveableComponent.get_save_key()` 和 duck participant 的 `get_save_key()` 只要求在所属实体存档代理内部唯一。

例如：

```text
payload["player"] = {
  "HealthComponent": {...},
  "InventoryController": {...},
  "weapon": {...}
}
```

这里 `"player"` 是全局 `save_id`，而 `"HealthComponent"` / `"weapon"` 只是玩家实体内部的 component key。

如果未来实现通用 `EntitySaveAgent`，应该在重复 key 时给出 warning，而不是静默覆盖。

## 不建议的方案

### 不建议：SaveService 全局 duck type 扫描

不要把 `SaveService._collect_saveables()` 改成“所有有 `to_save_data()` 的 Node 都收集”。这会打破 `Saveable` 作为存档根的语义，也容易误收集实体内部组件。

### 不建议：删除 SaveableComponent

完全删除 `SaveableComponent` 会让标准组件也依赖隐式 duck type。短期看更灵活，长期会降低可读性、文档清晰度和类型安全。

### 不建议：为了存档污染组件基类

不要为了让某个组件可存档，就把不相关的父类改成 `SaveableComponent`。如果组件基类的职责不是“可序列化实体组件”，应该用 duck participant 适配。

## 可选后续

如果这个模式在 game 侧频繁出现，可以把 `PlayerSaveAgent` 中的 helper 提炼成 addon 内的复用节点，例如：

```text
addons/mkit/kernel/save/entity_save_agent.gd
```

候选职责：

- `extends Saveable`
- 收集 `SaveableComponent`
- 收集 `"mkit_entity_save_participant"` duck participants
- 检查重复 key 并 `push_warning`
- 支持显式 `root_path`

但当前不需要急着新增这个类。先在 game 侧代理验证模式是否稳定，再决定是否提升到 addon 公共 API。

## 结论

保留三层边界：

1. `SaveService` 只自动收集 `Saveable`。
2. `SaveableComponent` 是 mkit 标准实体组件的主路径。
3. duck-typed participant 是解决单继承冲突的扩展路径，只由实体 `Saveable` 代理收集。

这个设计既保留了当前存档系统的清晰边界，也给 game 侧复杂组件留出了足够灵活性。
