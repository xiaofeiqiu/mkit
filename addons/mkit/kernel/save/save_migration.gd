## What: SaveMigration is a resource hook for upgrading saved data from one schema version to another.
## Responsibilities: declare source/target versions, duplicate incoming save data, and let subclasses transform the payload.
## Upstream: SaveManager selects the matching migration while loading older save files.
## Downstream: concrete migration resources override _migrate_impl to rename fields or add defaults.
## When to use: Use it after changing save format while still supporting existing player profiles.
## Example: create `Migration1To2.gd` with `from_version = 1`, `to_version = 2`, and add `data["payload"]["gold"] = 0`.
class_name SaveMigration
extends Resource

## Purpose: Inspector-facing configuration `from_version` for this class.
## Example: `self.from_version = 1`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var from_version: int = 1
## Purpose: Inspector-facing configuration `to_version` for this class.
## Example: `self.to_version = 1`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var to_version: int = 2


## Purpose: Public method `migrate` used by external systems to invoke this class behavior.
## Example: `self.migrate({})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func migrate(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["save_version"] = to_version
	return _migrate_impl(migrated)


func _migrate_impl(data: Dictionary) -> Dictionary:
	return data
