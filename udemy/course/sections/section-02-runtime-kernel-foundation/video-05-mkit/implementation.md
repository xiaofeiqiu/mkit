# Mkit Implementation

Opening transition:
The services are now registered, and `ModuleBootstrap` gives us the extension
point. `Mkit` is the small facade that makes reading those services clearer.

Step 1. Add the static facade class shell.

Code:
```gdscript
class_name Mkit
extends RefCounted
```

Script:
`Mkit` does not need to be a node because it does not live in a scene. It is a
static helper class. The word facade means this class gives a cleaner front door
to the registry.

Transition to Step 2:
The class exists now. Next, we add typed accessors for the services that are
ready in this section.

Step 2. Add typed accessors for ready services.

Code:
```gdscript
static func events() -> EventService:
	return ServiceRegistry.get_port(EventService.SERVICE_ID) as EventService


static func content() -> ContentService:
	return ServiceRegistry.get_port(ContentService.SERVICE_ID) as ContentService


static func random() -> RandomService:
	return ServiceRegistry.get_port(RandomService.SERVICE_ID) as RandomService


static func time() -> TimeService:
	return ServiceRegistry.get_port(TimeService.SERVICE_ID) as TimeService


static func scenes() -> SceneService:
	return ServiceRegistry.get_port(SceneService.SERVICE_ID) as SceneService
```

Script:
Each function reads from the same central registry, but the return type is now
clear. `Mkit.content()` tells the reader that the result should be a
`ContentService`. This is easier to use than scattering raw string lookups
through gameplay code.

Transition to Step 3:
The facade has enough accessors for the Section 2 boot flow. The final step is
to check that a registered service comes back through the typed helper.

Step 3. Check one typed service read after boot.

Code:
```gdscript
var content := Mkit.content()
assert(content != null)
assert(content == ServiceRegistry.get_port(ContentService.SERVICE_ID))
```

Script:
This check proves that `Mkit` is not a second registry. It returns the same
object that `ServiceRegistry` holds, but with a clearer function name and return
type.

Next video transition:
This completes the Section 2 runtime foundation. The next section can build
player movement on top of a project that already has a clean boot path and
shared service access.
