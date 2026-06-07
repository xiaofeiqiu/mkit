# DialogueRuntime

**层：** Module  
**文件：** `addons/mkit/modules/dialogue/dialogue_runtime.gd`  
**继承：** `extends RefCounted`

## 职责

一段进行中对话的运行时状态：当前对话 id、当前节点、历史、上下文。`DialogueService.runtime` 持有它，对话结束时置空。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `dialogue_id` | `String` | `""` | 当前对话 |
| `current_node_id` | `String` | `""` | 当前节点 |
| `history` | `Array[String]` | `[]` | 已访问节点 |
| `context` | `GameplayContext` | `null` | 对话上下文（选项/节点 effect 用）|

## 相关

- → [DialogueService](DialogueService.md)（持有它）
