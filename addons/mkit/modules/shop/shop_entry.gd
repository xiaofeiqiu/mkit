class_name ShopEntry
extends Resource
## 说明：`ShopEntry` 是 商店系统 的条目对象，负责描述列表中的一项可配置记录。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在商店系统中复用这段契约或状态时使用它。
## 示例：`var instance := ShopEntry.new()`

## 编辑器配置：`item_id` 表示稳定 id，由 `ShopEntry` 的公开 API 读取或维护。
@export var item_id: String = ""
## 编辑器配置：`price_override` 表示价格配置，由 `ShopEntry` 的公开 API 读取或维护。
@export var price_override: int = -1
## 编辑器配置：`stock` 表示 `ShopEntry` 的字段值，由 `ShopEntry` 的公开 API 读取或维护。
@export var stock: int = -1
## 编辑器配置：`conditions` 表示执行条件列表，由 `ShopEntry` 的公开 API 读取或维护。
@export var conditions: Array[Condition] = []
