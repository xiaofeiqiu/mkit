class_name LootEntry
extends Resource
## 说明：`LootEntry` 是 掉落与奖励系统 的条目对象，负责描述列表中的一项可配置记录。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := LootEntry.new()`

## 编辑器配置：`content_id` 表示稳定 id，由 `LootEntry` 的公开 API 读取或维护。
@export var content_id: String = ""
## 编辑器配置：`weight` 表示 `LootEntry` 的字段值，由 `LootEntry` 的公开 API 读取或维护。
@export var weight: float = 1.0
## 编辑器配置：`min_quantity` 表示最小值，由 `LootEntry` 的公开 API 读取或维护。
@export var min_quantity: int = 1
## 编辑器配置：`max_quantity` 表示最大值，由 `LootEntry` 的公开 API 读取或维护。
@export var max_quantity: int = 1
## 编辑器配置：`conditions` 表示执行条件列表，由 `LootEntry` 的公开 API 读取或维护。
@export var conditions: Array[Condition] = []
