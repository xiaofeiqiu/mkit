class_name DialogueDefinition
extends ContentDefinition
## 说明：`DialogueDefinition` 是 对话系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `DialogueDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册对话定义时使用的稳定 id；DialogueService 和交互点按它启动对话。
@export var dialogue_id: String = ""
## 对话开始时进入的 DialogueNode id；为空时由 DialogueService 选择默认节点。
@export var start_node_id: String = ""
## 对话包含的节点列表；node_id 应在同一个 DialogueDefinition 内唯一。
@export var nodes: Array[DialogueNode] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `DialogueDefinition` 的领域契约一致。
func get_content_id() -> String:
	return dialogue_id


## 返回 `node` 对应的数据或对象，并保持 `DialogueDefinition` 的领域契约一致。
func get_node(node_id: String) -> DialogueNode:
	for node in nodes:
		if node != null and node.node_id == node_id:
			return node
	return null
