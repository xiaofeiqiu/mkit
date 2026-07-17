class_name Mkit
extends RefCounted
## 说明：`Mkit` 是 ServiceRegistry 的类型化门面，是游戏和模块代码访问内置服务的推荐入口。
## 上游：通常由 game、module、controller 或测试代码调用。
## 下游：会通过 ServiceRegistry 取回具体服务实例，并让调用点获得类型提示和检查。
## 使用：当调用方需要访问 mkit 内置服务时，优先使用这里的静态 accessor。
## 示例：`var combat := Mkit.combat()`


## 返回 ServiceRegistry 中注册的 EventService；bootstrap 尚未注册 `events` 时返回 null。
static func events() -> EventService:
	return ServiceRegistry.get_port(EventService.SERVICE_ID) as EventService


## 返回 ContentService，用于按 content id 或类型读取 ResourceDatabase 已加载的定义资源。
static func content() -> ContentService:
	return ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService


## 返回 RandomService，供 gameplay 代码使用同一个可设 seed 的随机源。
static func random() -> RandomService:
	return ServiceRegistry.get_port(RandomService.SERVICE_ID) as RandomService


## 返回 TimeService，供系统读取缩放 delta、暂停状态和时间戳。
static func time() -> TimeService:
	return ServiceRegistry.get_port(TimeService.SERVICE_ID) as TimeService


## 返回 ActionService，用于启动、更新和取消 GameAction 流程。
static func actions() -> ActionService:
	return ServiceRegistry.get_port(ActionService.SERVICE_ID) as ActionService


## 返回 EffectService，用于统一执行 GameEffect 并取得 EffectResult。
static func effects() -> EffectService:
	return ServiceRegistry.get_port(EffectService.SERVICE_ID) as EffectService


## 返回 CommandService；调用方只有 `target_id` 时可用它路由 GameCommand。
static func commands() -> CommandService:
	return ServiceRegistry.get_port(CommandService.SERVICE_ID) as CommandService


## 返回 SceneService，用于切换或重载当前 Godot 场景。
static func scenes() -> SceneService:
	return ServiceRegistry.get_port(SceneService.SERVICE_ID) as SceneService


## 返回 PoolService，用于复用 PackedScene 实例和临时节点。
static func pool() -> PoolService:
	return ServiceRegistry.get_port(PoolService.SERVICE_ID) as PoolService


## 返回 SaveService；实际保存与读取由返回的服务执行。
static func save() -> SaveService:
	return ServiceRegistry.get_port(SaveService.SERVICE_ID) as SaveService


## 返回 AudioService，用于播放 AudioDefinition 注册的音效和音乐。
static func audio() -> AudioService:
	return ServiceRegistry.get_port(AudioService.SERVICE_ID) as AudioService


## 返回 CombatService，用于统一解析 DamageRequest；缺失时返回 null。
static func combat() -> CombatService:
	return ServiceRegistry.get_port(CombatService.SERVICE_ID) as CombatService


## 返回 ProgressionService，用于经验、等级、货币和升级相关流程。
static func progression() -> ProgressionService:
	return ServiceRegistry.get_port(ProgressionService.SERVICE_ID) as ProgressionService


## 返回 QuestService，用于接受、推进、完成和保存任务状态。
static func quest() -> QuestService:
	return ServiceRegistry.get_port(QuestService.SERVICE_ID) as QuestService


## 返回 ShopService，用于检查价格、购买、出售和发出商店事件。
static func shop() -> ShopService:
	return ServiceRegistry.get_port(ShopService.SERVICE_ID) as ShopService


## 返回 DialogueService，用于启动 dialogue、选择分支并联动任务事件。
static func dialogue() -> DialogueService:
	return ServiceRegistry.get_port(DialogueService.SERVICE_ID) as DialogueService


## 返回 WorldService，用于按 ZoneDefinition 切换区域并保存当前 zone。
static func world() -> WorldService:
	return ServiceRegistry.get_port(WorldService.SERVICE_ID) as WorldService


## 返回 LootService，用于按 loot table 掷出掉落并生成奖励结果。
static func loot() -> LootService:
	return ServiceRegistry.get_port(LootService.SERVICE_ID) as LootService


## 返回 DeathLootService，用于根据实体死亡事件查找并投放死亡掉落规则。
static func death_loot() -> DeathLootService:
	return ServiceRegistry.get_port(DeathLootService.SERVICE_ID) as DeathLootService


## 返回可选 UIManager；UI 服务未进入场景树或未注册时返回 null 且不输出 warning。
static func ui() -> UIManager:
	return _get_optional_port(UIManager.SERVICE_ID) as UIManager


static func _get_optional_port(service_id: String) -> Object:
	if not ServiceRegistry.has_service(service_id):
		return null
	return ServiceRegistry.get_port(service_id)
