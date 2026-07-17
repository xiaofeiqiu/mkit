# ModuleBootstrap Implementation

Opening transition:
`GameBootstrap` gives us the kernel boot sequence. `ModuleBootstrap` shows how
the modules layer can extend that sequence without changing the kernel class.

Step 1. Add the module bootstrap class shell.

Code:
```gdscript
class_name ModuleBootstrap
extends GameBootstrap
```

Script:
This class is intentionally small. By extending `GameBootstrap`, it inherits
the full boot checklist: service registration, content loading, validation, and
scene entry. The class exists because module services should be added from the
modules layer, not hardcoded into unrelated game scripts.

Transition to Step 2:
The class now inherits the boot flow. Next, we add the hook that lets it extend
the service map.

Step 2. Override `_build_services()` and keep the map staged.

Code:
```gdscript
func _build_services() -> Dictionary:
	var services := super()
	return services
```

Script:
This is the minimum module boundary. `super()` keeps the kernel services from
`GameBootstrap`. We return the same map now because the course has not built
combat, quests, loot, or world systems yet.

Transition to Step 3:
The code is small, so the useful check is not a new service yet. The useful
check is that the boot scene can use this subclass as its script.

Step 3. Check the boot scene script and inherited configuration.

Script:
Open `res://game/bootstrap.tscn` and confirm the root script points at
`res://addons/mkit/modules/module_bootstrap.gd`. The same node can still expose
`resource_databases` and `initial_scene_path` because those fields are inherited
from `GameBootstrap`.

Next video transition:
Next we build `Mkit`, the typed facade that gives game code a cleaner way to
read the services registered during boot.
