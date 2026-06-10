class_name Mkit
extends RefCounted
## Typed facade over ServiceRegistry — the single blessed way to reach the
## built-in services from game and module code. Each accessor returns the
## concrete service type (or null, with a warning, when it is not registered),
## so call sites get completion and type checking without `as` casts.
##
## Lives in the modules layer because it references module service types;
## kernel code keeps using ServiceRegistry.get_port directly.


static func events() -> EventService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService


static func content() -> ContentService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService


static func random() -> RandomService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_RANDOM) as RandomService


static func time() -> TimeService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_TIME) as TimeService


static func actions() -> ActionService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_ACTIONS) as ActionService


static func effects() -> EffectService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService


static func commands() -> CommandService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMMANDS) as CommandService


static func scenes() -> SceneService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_SCENES) as SceneService


static func pool() -> PoolService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_POOL) as PoolService


static func save() -> SaveService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService


static func audio() -> AudioService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_AUDIO) as AudioService


static func analytics() -> AnalyticsService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_ANALYTICS) as AnalyticsService


static func ads() -> AdService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_ADS) as AdService


static func iap() -> IAPService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_IAP) as IAPService


static func cloud_save() -> CloudSaveService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_CLOUD_SAVE) as CloudSaveService


static func combat() -> CombatService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService


static func progression() -> ProgressionService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_PROGRESSION) as ProgressionService


static func quest() -> QuestService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_QUEST) as QuestService


static func shop() -> ShopService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_SHOP) as ShopService


static func dialogue() -> DialogueService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService


static func world() -> WorldService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_WORLD) as WorldService


static func loot() -> LootService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_LOOT) as LootService


static func ui() -> UIManager:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_UI) as UIManager
