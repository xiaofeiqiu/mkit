class_name PoolService
extends Node
## 说明：`PoolService` 是 基础服务 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(PoolService.SERVICE_ID, PoolService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `PoolService`。
const SERVICE_ID: String = "pool"
var _pools: Dictionary = {}


## 预实例化指定数量的 PackedScene 节点并放入池中；后续 acquire 可直接复用。
func warmup(scene_path: String, count: int, parent: Node = null) -> void:
	for i in range(count):
		var node := _instantiate(scene_path)
		if node == null:
			return
		_deactivate(node)
		if parent != null:
			parent.add_child(node)
		release(scene_path, node)


## 从池中取出节点或实例化新节点；scene 为空时返回 null。
func acquire(scene_path: String, parent: Node = null) -> Node:
	var pool: Array = _pools.get(scene_path, [])
	var node: Node = null
	if not pool.is_empty():
		node = pool.pop_back()
	else:
		node = _instantiate(scene_path)
	_pools[scene_path] = pool
	if node != null:
		if parent != null and node.get_parent() != parent:
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			parent.add_child(node)
		_activate(node)
	return node


## 把节点归还到对应池并从当前父节点移除；无效节点会被忽略。
func release(scene_path: String, node: Node) -> void:
	if node == null:
		return
	_deactivate(node)
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	var pool: Array = _pools[scene_path]
	pool.append(node)
	_pools[scene_path] = pool


## 清空本对象持有的运行时表和缓存；通常在测试或重新 bootstrap 前调用。
func clear_pool(scene_path: String) -> void:
	if not _pools.has(scene_path):
		return
	for node in _pools[scene_path]:
		if node is Node:
			node.queue_free()
	_pools.erase(scene_path)


func _instantiate(scene_path: String) -> Node:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("PoolService missing scene: %s" % scene_path)
		return null
	return scene.instantiate()


func _activate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is CanvasItem:
		(node as CanvasItem).visible = true
	if node.has_method("on_pool_acquired"):
		node.call("on_pool_acquired")


func _deactivate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	if node.has_method("on_pool_released"):
		node.call("on_pool_released")
