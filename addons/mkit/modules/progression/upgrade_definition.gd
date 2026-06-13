class_name UpgradeDefinition
extends ContentDefinition
## 说明：`UpgradeDefinition` 是 成长系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `UpgradeDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册升级定义时使用的稳定 id；购买、前置条件和解锁记录按它引用。
@export var upgrade_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
@export_multiline var description: String = ""
## 可达到的最高等级；达到后继续获得经验不再提升等级。
@export var max_level: int = 1
## 使用的钱包货币 id；需与 Wallet 或 ProgressionState 中的余额 key 一致。
@export var currency_id: String = "meta_currency"
## 每一级升级需要的货币数量；索引 0 对应购买第 1 级。
@export var cost_by_level: Array[int] = [100]
## 购买前必须达到要求的升级 id 列表。
@export var prerequisite_upgrade_ids: Array[String] = []
## 购买该升级后解锁的内容 id 列表。
@export var unlock_content_ids: Array[String] = []
## 条件通过后按顺序执行的效果列表；每个元素应为 GameEffect 资源。
@export var effects: Array[GameEffect] = []
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
## 是否属于局外永久升级；关闭时可作为本局内升级处理。
@export var is_meta_upgrade: bool = true


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return upgrade_id


## 读取当前对象中的 `cost_for_level`；未找到时返回 null、空集合或该 API 的默认值。
func get_cost_for_level(next_level: int) -> int:
	var index := max(0, next_level - 1)
	if index >= cost_by_level.size():
		return cost_by_level[-1] if not cost_by_level.is_empty() else 0
	return cost_by_level[index]
