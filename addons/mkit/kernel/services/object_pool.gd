class_name ObjectPool
extends Node

var _pools: Dictionary = {} # scene_path -> Array[Node]


## Purpose: Public method `warmup` for external gameplay integration.
## Example: `self.warmup(<scene_path>, <count>, <parent>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func warmup(scene_path: String, count: int, parent: Node = null) -> void:
	for i in range(count):
		var node := _instantiate(scene_path)
		if node == null:
			return
		_deactivate(node)
		if parent != null:
			parent.add_child(node)
		release(scene_path, node)


## Purpose: Public method `acquire` for external gameplay integration.
## Example: `self.acquire(<scene_path>, <parent>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
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


## Purpose: Public method `release` for external gameplay integration.
## Example: `self.release(<scene_path>, <node>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func release(scene_path: String, node: Node) -> void:
	if node == null:
		return
	_deactivate(node)
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	var pool: Array = _pools[scene_path]
	pool.append(node)
	_pools[scene_path] = pool


## Purpose: Public method `clear_pool` for external gameplay integration.
## Example: `self.clear_pool(<scene_path>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
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
		push_error("ObjectPool missing scene: %s" % scene_path)
		return null
	return scene.instantiate()


func _activate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node.has_method("on_pool_acquired"):
		node.call("on_pool_acquired")


func _deactivate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node.has_method("on_pool_released"):
		node.call("on_pool_released")
