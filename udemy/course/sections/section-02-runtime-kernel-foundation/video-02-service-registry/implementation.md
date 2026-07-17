# ServiceRegistry Implementation

Opening transition:
We now know that `ServiceRegistry` is the central write/read point for shared
services. In this video, we build only that core mechanism.

Step 1. Add the autoload script shell and internal storage.

Code:
```gdscript
extends Node

var _services: Dictionary = {}
```

Script:
The script extends `Node` because Godot loads it as an autoload. The dictionary
is the central table: service id in, service object out. We keep it private so
outside code must go through the guarded functions.

Transition to Step 2:
Now that the table exists, the next step is the write side of the mechanism.

Step 2. Add duplicate-safe service registration.

Code:
```gdscript
func register_service(service_id: String, service: Object) -> bool:
	var id := service_id.strip_edges()
	if id == "":
		push_error("ServiceRegistry.register_service: service_id is empty")
		return false
	if service == null:
		push_error("ServiceRegistry.register_service: service is null for id %s" % service_id)
		return false
	if _services.has(id):
		push_error("Service already registered: %s. Use replace_service() for intentional overrides." % id)
		return false
	_services[id] = service
	return true
```

Script:
This function writes one service into the table. The important boundary is that
bad ids, null objects, and duplicate ids are rejected before the table changes.
That keeps bootstrap mistakes visible instead of silently replacing a service.

Transition to Step 3:
We can write services now. The next step is to let other code check and read
from the same table.

Step 3. Add quiet checks and low-level lookup.

Code:
```gdscript
func has_service(service_id: String) -> bool:
	return _services.has(service_id.strip_edges())


func get_port(service_id: String) -> Object:
	var id := service_id.strip_edges()
	if id == "":
		push_warning("ServiceRegistry.get_port: service_id is empty")
		return null
	var service := _services.get(id, null) as Object
	if service == null:
		push_warning("Missing service: %s" % id)
		return null
	return service
```

Script:
`has_service()` is the quiet check. `get_port()` is the actual read. It warns
when the caller asks for something that is not there, because a missing service
usually means the boot setup is wrong.

Transition to Step 4:
The registry can now write and read one service. For boot verification, we also
want a stable list of the ids currently registered.

Step 4. Add sorted service id listing.

Code:
```gdscript
func get_registered_service_ids() -> Array[String]:
	var ids: Array[String] = []
	for service_id in _services.keys():
		ids.append(str(service_id))
	ids.sort()
	return ids
```

Script:
This function is small, but it matters for teaching and debugging. Sorting the
ids gives a stable result, so the bootstrap log and tests do not depend on
dictionary order.

Transition to Step 5:
The MVP registry is complete. The final step is a tiny check that proves the
same object comes back from the central table.

Step 5. Check one service registration.

Code:
```gdscript
var registry := load("res://addons/mkit/kernel/services/service_registry.gd").new()
var service := Node.new()

assert(registry.register_service("events", service))
assert(registry.has_service("events"))
assert(registry.get_port("events") == service)
assert(registry.get_registered_service_ids() == ["events"])

service.free()
registry.free()
```

Script:
This check uses a plain `Node` because the registry does not need to know the
service's exact class. The key proof is identity: the same object we wrote under
`"events"` is the object we read back.

Next video transition:
Next we build `GameBootstrap`, the class that creates the first services and
writes them into this registry during startup.
