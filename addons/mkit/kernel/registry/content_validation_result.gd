class_name ContentValidationResult
extends RefCounted

## Purpose: Public runtime field `success`.
## Example: `self.success = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var success: bool = true
## Purpose: Public runtime field `errors`.
## Example: `self.errors = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var errors: Array[String] = []
## Purpose: Public runtime field `warnings`.
## Example: `self.warnings = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var warnings: Array[String] = []


## Purpose: Public method `add_error` for external gameplay integration.
## Example: `self.add_error(<message>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func add_error(message: String) -> void:
	success = false
	errors.append(message)


## Purpose: Public method `add_warning` for external gameplay integration.
## Example: `self.add_warning(<message>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func add_warning(message: String) -> void:
	warnings.append(message)
