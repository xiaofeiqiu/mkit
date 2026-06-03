# DialogueRuntime

## 概念说明

DialogueRuntime 是单次对话会话的运行时状态：当前对话 ID、当前节点 ID、已访问节点历史，以及该会话的 GameplayContext。

## 设计目的

把静态 DialogueDefinition 与一次具体会话的可变状态分离，避免把进度写回共享 Resource。DialogueController 同一时刻只持有一个 DialogueRuntime（单活动会话）；会话结束即丢弃。

## 文件

`res://addons/mkit/modules/dialogue/dialogue_runtime.gd`

## 字段说明

- **dialogue_id**：本次会话对应的 DialogueDefinition.dialogue_id。
- **current_node_id**：当前所在节点 ID。
- **history**：已进入节点的 node_id 顺序列表，每进入一个节点追加一项。
- **context**：本次会话的 GameplayContext，由 start() 传入；节点 on_enter_effects 与选项 effects 都以此为上下文执行（source/target 由发起交互方填入）。

## 接口

```gdscript
class_name DialogueRuntime
extends RefCounted
var dialogue_id: String = ""
var current_node_id: String = ""
var history: Array[String] = []
var context: GameplayContext = null
```

## 函数使用场景

DialogueRuntime 是 DialogueController 内部持有的纯状态对象，无公开方法。`is_active()` 即「runtime 是否非 null」；测试或 UI 可读取 `current_node_id` / `dialogue_id` 查询当前进度。

## 使用示例

```gdscript
var dialogue := ServiceRegistry.get_service("dialogue") as DialogueController
dialogue.start("dlg.elder_intro", GameplayContext.new())
print(dialogue.runtime.current_node_id)
```
