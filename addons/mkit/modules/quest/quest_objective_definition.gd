class_name QuestObjectiveDefinition
extends Resource
## 说明：`QuestObjectiveDefinition` 是 任务系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `QuestObjectiveDefinition` 资源，再通过 ContentService 按 id 查询。

## 任务内部引用该目标的稳定 id；同一 QuestDefinition 的 objectives 中应保持唯一。
@export var objective_id: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
@export_multiline var description: String = ""
## 事件类型字符串；发布或匹配 DomainEvent 时必须与订阅方约定一致。
@export var event_type: String = ""
## 匹配 DomainEvent.payload 时读取的 key；为空表示不检查 payload key。
@export var match_key: String = ""
## payload 对应 key 需要匹配的字符串值；为空表示只检查 key 是否存在或跳过值检查。
@export var match_value: String = ""
## 从 DomainEvent.payload 读取进度增量的 key；为空时使用固定 amount 或 1。
@export var count_payload_key: String = ""
## 目标完成所需累计数量；达到或超过该值即完成。
@export var required_count: int = 1
## 是否为可选目标；可选目标不阻止任务完成。
@export var optional: bool = false
