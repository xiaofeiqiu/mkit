# DialogueInteractable

## 概念说明

DialogueInteractable 把「交互」绑定到「启动一段对话」，继承自 Interactable。它是房间里 NPC 给信息/给任务的入口：玩家走到 NPC 前按交互键即开始对话。

## 设计目的

复用统一的互动协议接入对话：InteractionComponent → Interactable.interact() → DialogueInteractable._interact_impl() → DialogueController.start()，无需为 NPC 写专用输入或对话启动代码。对话内容（dialogue_id）与 NPC 身份（npc_id）是数据，启动机制是通用的。同时在启动时发 npc_talked 事件，供任务「与 X 对话」目标计数。

## 文件

`res://addons/mkit/modules/dialogue/dialogue_interactable.gd`

## 字段说明

- **dialogue_id**：要启动的对话 ID，对应一个 DialogueDefinition。为空时互动失败。
- **npc_id**：NPC 身份标识。非空时，对话成功启动后发 EventRouter.emit_npc_talked(npc_id)（同时发出 npc_talked typed signal 与 npc_talked DomainEvent），供 QuestSystem 推进「与 X 对话」目标。

（另继承 Interactable 的 interaction_id / display_text / conditions 字段。）

## 接口

```gdscript
class_name DialogueInteractable
extends Interactable
@export var dialogue_id: String = ""
@export var npc_id: String = ""
func _interact_impl(context: GameplayContext) -> bool
```

## 函数使用场景

- **`_interact_impl(context)`**：由基类 Interactable.interact()（通过 can_interact 校验后）调用。它检查 dialogue_id 非空、从 ServiceRegistry 取 `dialogue` service、调用 DialogueController.start(dialogue_id, context)；启动成功且 npc_id 非空时发 npc_talked 事件。缺 service 或启动失败（例如已有会话进行中）时返回 false。

## 使用示例

```gdscript
var npc := Node2D.new()
var talk := DialogueInteractable.new()
talk.name = "Interactable"
talk.display_text = "Talk"
talk.dialogue_id = "dlg.elder_intro"
talk.npc_id = "npc.elder"
npc.add_child(talk)
```
