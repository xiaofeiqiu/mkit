class_name ShopDefinition
extends ContentDefinition
## 说明：`ShopDefinition` 是 商店系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `ShopDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`shop_id` 表示稳定 id，由 `ShopDefinition` 的公开 API 读取或维护。
@export var shop_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `ShopDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`currency_id` 表示稳定 id，由 `ShopDefinition` 的公开 API 读取或维护。
@export var currency_id: String = "gold"
## 编辑器配置：`entries` 表示 `ShopDefinition` 的字段值，由 `ShopDefinition` 的公开 API 读取或维护。
@export var entries: Array[ShopEntry] = []
## 编辑器配置：`buy_price_multiplier` 表示价格配置，由 `ShopDefinition` 的公开 API 读取或维护。
@export var buy_price_multiplier: float = 1.0
## 编辑器配置：`sell_price_multiplier` 表示价格配置，由 `ShopDefinition` 的公开 API 读取或维护。
@export var sell_price_multiplier: float = 0.5
## 编辑器配置：`allow_sell` 表示 `ShopDefinition` 的字段值，由 `ShopDefinition` 的公开 API 读取或维护。
@export var allow_sell: bool = true


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `ShopDefinition` 的领域契约一致。
func get_content_id() -> String:
	return shop_id


## 返回 `entry` 对应的数据或对象，并保持 `ShopDefinition` 的领域契约一致。
func get_entry(item_id: String) -> ShopEntry:
	for entry in entries:
		if entry != null and entry.item_id == item_id:
			return entry
	return null
