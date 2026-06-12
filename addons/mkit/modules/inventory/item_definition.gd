class_name ItemDefinition
extends ContentDefinition
## 说明：`ItemDefinition` 是 背包与装备系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `ItemDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册物品定义时使用的稳定 id；背包、掉落和商店按它查找物品。
@export var item_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
@export_multiline var description: String = ""
## 物品类型字符串；例如 material、consumable、equipment，由游戏约定扩展。
@export var item_type: String = "material"
## 稀有度字符串；用于 UI 样式、掉落权重或奖励展示。
@export var rarity: String = "common"
## 物品基础货币价值；商店买卖会在此基础上应用价格倍率或覆盖价。
@export var value: int = 0
## UI 展示用图标资源；为 null 时界面应使用默认图标或隐藏图标位。
@export var icon: Texture2D
## 物品是否可以堆叠；关闭后每个实例独占一个槽位。
@export var stackable: bool = true
## 单槽最大堆叠数量；仅在 stackable 为 true 时生效。
@export var max_stack: int = 99
## 装备物品可放入的槽位 id；为空表示不可装备。
@export var equipment_slot: String = ""
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
## 使用物品前需要通过的条件列表。
@export var use_conditions: Array[Condition] = []
## 物品使用成功后执行的效果列表。
@export var use_effects: Array[GameEffect] = []
## 状态或装备提供的属性修饰列表；应用后由 StatsComponent 参与计算。
@export var stat_modifiers: Array[StatModifierDefinition] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `ItemDefinition` 的领域契约一致。
func get_content_id() -> String:
	return item_id
