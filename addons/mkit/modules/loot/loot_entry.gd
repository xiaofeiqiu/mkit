class_name LootEntry
extends Resource
## 说明：`LootEntry` 是 掉落与奖励系统 的条目对象，负责描述列表中的一项可配置记录。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := LootEntry.new()`

## 掉落项引用的内容 id；通常指向 ItemDefinition 或其他可奖励内容。
@export var content_id: String = ""
## 随机选择权重；值越大被选中的概率越高，0 表示不会自然选中。
@export var weight: float = 1.0
## 一次掉落的最小数量；应小于或等于 max_quantity。
@export var min_quantity: int = 1
## 一次掉落的最大数量；应大于或等于 min_quantity。
@export var max_quantity: int = 1
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []
