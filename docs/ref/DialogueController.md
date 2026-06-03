# DialogueController

## 概念说明

DialogueController 是对话域的运行时 Node，注册为 ServiceRegistry 的 `dialogue` service。它运行当前会话：进入节点（执行 on_enter_effects、发节点信号）、按选项或线性推进、结束会话。同一时刻只运行一段对话。

## 设计目的

成为单一会话协调者。NPC 的 DialogueInteractable 只负责「用哪个 dialogue_id 启动」，节点呈现交给订阅信号的 DialogueUI，选项的判定与副作用复用 Condition / GameEffect / EffectExecutor。把「一段对话怎么走」集中到一处，调用方只用公开方法与信号，互不耦合。

## 文件

`res://addons/mkit/modules/dialogue/dialogue_controller.gd`

## 字段说明

- **dialogue_started**：start() 成功后发出，携带 dialogue_id。
- **node_entered**：每进入一个节点发出，携带该 DialogueNode（UI 据此显示台词）。
- **choices_presented**：进入的节点含 choices 时发出，携带节点与过滤后的可用选项数组。
- **dialogue_ended**：会话结束时发出，携带结束的 dialogue_id。
- **runtime**：当前 DialogueRuntime；无会话时为 null（is_active() 据此判定）。
- **content**：ContentRegistry 引用，为空时从 `content` service 懒加载。

## 接口

```gdscript
class_name DialogueController
extends Node
signal dialogue_started(dialogue_id: String)
signal node_entered(node: DialogueNode)
signal choices_presented(node: DialogueNode, available: Array[DialogueChoice])
signal dialogue_ended(dialogue_id: String)
var runtime: DialogueRuntime = null
var content: ContentRegistry = null
func is_active() -> bool
func start(dialogue_id: String, context: GameplayContext) -> bool
func get_available_choices() -> Array[DialogueChoice]
func choose(choice_index: int) -> void
func advance() -> void
func end() -> void
func get_definition(dialogue_id: String) -> DialogueDefinition
```

## 函数使用场景

- **`is_active()`**：是否有正在进行的会话（runtime 非 null）。
- **`start(dialogue_id, context)`**：启动一段对话。已有会话时拒绝并返回 false；从 ContentRegistry 取 DialogueDefinition（缺失返回 false），建 runtime，发 dialogue_started + EventRouter.emit_dialogue_started，进入 start_node_id。返回值为 `is_active()`：若 start_node_id 指向不存在的节点导致进入即结束（start→end），返回 false，调用方据此识别「配置错误」而不会误判为交互成功。
- **`get_available_choices()`**：返回当前节点中通过 conditions 过滤后的可用 DialogueChoice 列表；choose 的索引以此列表为准。
- **`choose(choice_index)`**：选择当前可用选项中的第 index 个，执行其 effects，按 next_node_id 跳转（为空则结束）；index 越界为安全 no-op。
- **`advance()`**：线性推进。当前节点有 choices 时不动作；next_node_id 为空时结束；否则进入 next_node_id。
- **`end()`**：结束当前会话，清空 runtime，发 dialogue_ended + EventRouter.emit_dialogue_ended。
- **`get_definition(dialogue_id)`**：从 ContentRegistry 读取 DialogueDefinition；id 为空或缺失返回 null。

进入节点时（start / choose / advance 内部）：执行该节点 on_enter_effects（EffectExecutor），发 node_entered；若节点含 choices，再发 choices_presented（携带过滤后的可用项）。

## 使用示例

```gdscript
var dialogue := ServiceRegistry.get_service("dialogue") as DialogueController
if dialogue.start("dlg.elder_intro", GameplayContext.new().with_source(player)):
    for choice in dialogue.get_available_choices():
        print(choice.text)
    dialogue.choose(0)
```
