class_name ShopEntry
extends Resource
## 说明：`ShopEntry` 是 商店系统 的条目对象，负责描述列表中的一项可配置记录。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在商店系统中复用这段契约或状态时使用它。
## 示例：`var instance := ShopEntry.new()`

## 引用的 ItemDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var item_id: String = ""
## 覆盖商品价格；-1 表示使用 ItemDefinition.value 和商店倍率计算。
@export var price_override: int = -1
## 可购买库存数量；-1 表示无限库存。
@export var stock: int = -1
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []
