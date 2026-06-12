class_name ShopDefinition
extends ContentDefinition
## 说明：`ShopDefinition` 是 商店系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `ShopDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册商店定义时使用的稳定 id；ShopService 按它打开商品列表。
@export var shop_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 使用的钱包货币 id；需与 Wallet 或 ProgressionState 中的余额 key 一致。
@export var currency_id: String = "gold"
## 商店出售的商品条目列表；每项 ShopEntry 指向一个 ItemDefinition。
@export var entries: Array[ShopEntry] = []
## 购买价格倍率；1 表示使用条目基础价格。
@export var buy_price_multiplier: float = 1.0
## 出售价格倍率；1 表示按物品基础价值全价出售。
@export var sell_price_multiplier: float = 0.5
## 商店是否允许玩家出售物品。
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
