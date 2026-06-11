class_name Mkit
extends RefCounted
## 说明：`Mkit` 是 ServiceRegistry 的类型化门面，是游戏和模块代码访问内置服务的推荐入口。
## 上游：通常由 game、module、controller 或测试代码调用。
## 下游：会通过 ServiceRegistry 取回具体服务实例，并让调用点获得类型提示和检查。
## 使用：当调用方需要访问 mkit 内置服务时，优先使用这里的静态 accessor。
## 示例：`var combat := Mkit.combat()`


## 执行 `events` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func events() -> EventService:
	return ServiceRegistry.get_port(EventService.SERVICE_ID) as EventService


## 执行 `content` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func content() -> ContentService:
	return ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService


## 执行 `random` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func random() -> RandomService:
	return ServiceRegistry.get_port(RandomService.SERVICE_ID) as RandomService


## 执行 `time` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func time() -> TimeService:
	return ServiceRegistry.get_port(TimeService.SERVICE_ID) as TimeService


## 执行 `actions` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func actions() -> ActionService:
	return ServiceRegistry.get_port(ActionService.SERVICE_ID) as ActionService


## 执行 `effects` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func effects() -> EffectService:
	return ServiceRegistry.get_port(EffectService.SERVICE_ID) as EffectService


## 执行 `commands` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func commands() -> CommandService:
	return ServiceRegistry.get_port(CommandService.SERVICE_ID) as CommandService


## 执行 `scenes` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func scenes() -> SceneService:
	return ServiceRegistry.get_port(SceneService.SERVICE_ID) as SceneService


## 执行 `pool` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func pool() -> PoolService:
	return ServiceRegistry.get_port(PoolService.SERVICE_ID) as PoolService


## 保存当前运行时状态，并保持 `Mkit` 的领域契约一致。
static func save() -> SaveService:
	return ServiceRegistry.get_port(SaveService.SERVICE_ID) as SaveService


## 执行 `audio` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func audio() -> AudioService:
	return ServiceRegistry.get_port(AudioService.SERVICE_ID) as AudioService


## 执行 `combat` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func combat() -> CombatService:
	return ServiceRegistry.get_port(CombatService.SERVICE_ID) as CombatService


## 执行 `progression` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func progression() -> ProgressionService:
	return ServiceRegistry.get_port(ProgressionService.SERVICE_ID) as ProgressionService


## 执行 `quest` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func quest() -> QuestService:
	return ServiceRegistry.get_port(QuestService.SERVICE_ID) as QuestService


## 执行 `shop` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func shop() -> ShopService:
	return ServiceRegistry.get_port(ShopService.SERVICE_ID) as ShopService


## 执行 `dialogue` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func dialogue() -> DialogueService:
	return ServiceRegistry.get_port(DialogueService.SERVICE_ID) as DialogueService


## 执行 `world` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func world() -> WorldService:
	return ServiceRegistry.get_port(WorldService.SERVICE_ID) as WorldService


## 执行 `loot` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func loot() -> LootService:
	return ServiceRegistry.get_port(LootService.SERVICE_ID) as LootService


## 执行 `ui` 对应的公开操作，并保持 `Mkit` 的领域契约一致。
static func ui() -> UIManager:
	return _get_optional_port(UIManager.SERVICE_ID) as UIManager


static func _get_optional_port(service_id: String) -> Object:
	if not ServiceRegistry.has_service(service_id):
		return null
	return ServiceRegistry.get_port(service_id)
