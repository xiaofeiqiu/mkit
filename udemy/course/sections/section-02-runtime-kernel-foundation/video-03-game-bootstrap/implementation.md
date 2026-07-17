# GameBootstrap Implementation

Opening transition:
`ServiceRegistry` gives us the central table. Now `GameBootstrap` becomes the
class that fills the table and moves the project from boot scene to game scene.

Step 1. Add the class shell and exported boot configuration.

Code:
```gdscript
class_name GameBootstrap
extends Node

@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = ""
```

Script:
These fields are scene configuration. `resource_databases` tells bootstrap what
content to load. `initial_scene_path` tells it where to go after startup. We do
not add `save_path` yet because save/load is not the Section 2 visible result.

Transition to Step 2:
The scene can now hold startup settings. Next, we need one readable entry point
for the startup sequence.

Step 2. Add `_ready()` and the boot checklist.

Code:
```gdscript
func _ready() -> void:
	boot()


func boot() -> void:
	_register_kernel_services()
	_load_content()
	_validate_content()
	_enter_initial_scene.call_deferred()
```

Script:
`_ready()` is the Godot hook, and `boot()` is the course-friendly checklist.
The order is the important idea: services first, content next, validation after
loading, and scene entry last. We defer the scene change so the boot scene has
finished its current frame.

Transition to Step 3:
The checklist names service registration, but we still need the service map
that says which services are ready in this section.

Step 3. Add the staged service map.

Code:
```gdscript
func _build_services() -> Dictionary:
	return {
		EventService.SERVICE_ID: EventService.new(),
		ContentService.SERVICE_ID: ContentService.new(),
		RandomService.SERVICE_ID: RandomService.new(),
		TimeService.SERVICE_ID: TimeService.new(),
		SceneService.SERVICE_ID: SceneService.new(),
	}
```

Script:
This is intentionally smaller than the live production source. We register only
the services the Section 2 result needs or can understand right now. Action,
effect, command, save, audio, and pool services are real, but they become useful
when their systems are taught.

Transition to Step 4:
Now we can describe the services. The next step is to write each service into
`ServiceRegistry` with the guard behavior students already built.

Step 4. Register the staged services.

Code:
```gdscript
func _register_kernel_services() -> void:
	if ServiceRegistry == null:
		push_error("GameBootstrap: ServiceRegistry autoload is missing")
		return
	if ServiceRegistry.has_service(EventService.SERVICE_ID):
		print("[mkit] GameBootstrap: services already registered, skipping")
		return
	var services := _build_services()
	for service_id in services:
		_register_service_entry(service_id, services[service_id])
	print("[mkit] GameBootstrap runtime services: %s" % ", ".join(ServiceRegistry.get_registered_service_ids()))


func _register_service_entry(service_id: String, service: Object) -> bool:
	if service == null:
		push_error("GameBootstrap._register_service_entry: service is null for %s" % service_id)
		return false
	var node := service as Node
	if node != null:
		node.name = service.get_class()
	if not ServiceRegistry.register_service(service_id, service):
		return false
	if node != null:
		ServiceRegistry.add_child(node)
	return true
```

Script:
This step connects `GameBootstrap` to `ServiceRegistry`. The bootstrap builds
the map, then registers each service by id. Node services are added as children
of the autoload so they have a stable place in the scene tree.

Transition to Step 5:
The services are now available. Next, bootstrap uses the content service it just
registered to load and validate configured content.

Step 5. Load and validate configured content.

Code:
```gdscript
func _load_content() -> void:
	var registry := ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService
	if registry == null:
		push_error("GameBootstrap._load_content: missing ContentService service")
		return
	for db in resource_databases:
		if db != null:
			registry.load_database(db)


func _validate_content() -> void:
	var registry := ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService
	if registry == null:
		push_error("GameBootstrap._validate_content: missing ContentService service")
		return
	var result := registry.validate_all()
	if not result.success:
		push_error("Content validation failed: %s" % result.errors)
```

Script:
This is the first real use of a registered service. Bootstrap asks the registry
for `ContentService`, then uses it to load each configured database. Validation
keeps bad content ids visible before the game scene starts.

Transition to Step 6:
At this point, services and content are ready. The last boot step is to leave
the bootstrap scene and enter the configured game scene.

Step 6. Enter the initial scene.

Code:
```gdscript
func _enter_initial_scene() -> void:
	if initial_scene_path == "":
		return
	if not ResourceLoader.exists(initial_scene_path, "PackedScene"):
		push_error("GameBootstrap.initial_scene_path must point to an existing PackedScene resource, but got: %s" % initial_scene_path)
		return
	var scene_router := ServiceRegistry.get_port(SceneService.SERVICE_ID) as SceneService
	if scene_router != null:
		scene_router.change_scene(initial_scene_path)
	else:
		get_tree().change_scene_to_file(initial_scene_path)
```

Script:
This method turns the boot result into visible progress. If `SceneService` is
registered, bootstrap uses it. If not, it still has a simple Godot fallback.
The course check is that the project leaves `game/bootstrap.tscn` and enters
the configured playable scene.

Next video transition:
Next we build `ModuleBootstrap`, which shows how a project can extend this
kernel boot sequence without editing `GameBootstrap` directly.
