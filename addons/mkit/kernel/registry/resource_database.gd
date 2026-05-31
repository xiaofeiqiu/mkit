class_name ResourceDatabase
extends Resource

## Purpose: Inspector-exposed configuration `database_id`.
## Example: `self.database_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var database_id: String = ""
## Purpose: Inspector-exposed configuration `resources`.
## Example: `self.resources = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var resources: Array[Resource] = []
## Purpose: Inspector-exposed configuration `resource_paths`.
## Example: `self.resource_paths = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var resource_paths: Array[String] = []


## Purpose: Public method `get_all_resources` for external gameplay integration.
## Example: `self.get_all_resources()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_all_resources() -> Array[Resource]:
	var result: Array[Resource] = []
	result.append_array(resources)

	for path in resource_paths:
		var res: Resource = load(path)
		if res != null:
			result.append(res)
		else:
			push_warning("Failed to load resource: %s" % path)

	return result
