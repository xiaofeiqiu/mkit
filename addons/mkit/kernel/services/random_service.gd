class_name RandomService
extends RefCounted
## 说明：`RandomService` 是 基础服务 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(RandomService.SERVICE_ID, RandomService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `RandomService`。
const SERVICE_ID: String = "random"
## RandomService 当前使用的随机种子；用于可复现的随机流程。
var seed_value: int = 0
## RandomNumberGenerator 实例；所有服务级随机值都应从这里取得。
var rng := RandomNumberGenerator.new()


## 设置 `seed` 对应的数据或对象，并保持 `RandomService` 的领域契约一致。
func set_seed(value: int) -> void:
	seed_value = value
	rng.seed = value


## 执行 `randomize_seed` 对应的公开操作，并保持 `RandomService` 的领域契约一致。
func randomize_seed() -> int:
	rng.randomize()
	seed_value = rng.seed
	return seed_value


## 执行 `randf` 对应的公开操作，并保持 `RandomService` 的领域契约一致。
func randf() -> float:
	return rng.randf()


## 执行 `randi_range` 对应的公开操作，并保持 `RandomService` 的领域契约一致。
func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)


## 执行 `randf_range` 对应的公开操作，并保持 `RandomService` 的领域契约一致。
func randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)


## 执行 `chance` 对应的公开操作，并保持 `RandomService` 的领域契约一致。
func chance(probability: float) -> bool:
	return self.randf() < clamp(probability, 0.0, 1.0)


## 执行 `weighted_pick` 对应的公开操作，并保持 `RandomService` 的领域契约一致。
func weighted_pick(entries: Array, weight_property: String = "weight"):
	var total := 0.0
	for entry in entries:
		if entry == null:
			continue
		var raw_weight: Variant = entry.get(weight_property)
		if raw_weight == null:
			continue
		total += max(0.0, float(raw_weight))
	if total <= 0.0:
		return null
	var roll := self.randf() * total
	var cursor := 0.0
	var fallback = null
	for entry in entries:
		if entry == null:
			continue
		var raw_weight: Variant = entry.get(weight_property)
		if raw_weight == null:
			continue
		var weight := max(0.0, float(raw_weight))
		if weight <= 0.0:
			continue
		fallback = entry
		cursor += weight
		if roll <= cursor:
			return entry
	return fallback
