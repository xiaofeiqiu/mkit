## What: AnalyticsServiceMock is the console-printing development implementation of AnalyticsService.
## Responsibilities: log tracked events and user properties without contacting a backend.
## Upstream: GameBootstrap or tests register it for local builds.
## Downstream: developers inspect printed analytics payloads in the Godot output console.
## When to use: Use it before integrating a real analytics provider or when running offline tests.
## Example: `ServiceRegistry.register_service("analytics", AnalyticsServiceMock.new(), "AnalyticsService")`.
class_name AnalyticsServiceMock
extends AnalyticsService

## Development-time analytics: prints to console instead of sending to a real platform.

## Purpose: Public method `track_event` used by external systems to invoke this class behavior.
## Example: `self.track_event(event_name, {})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func track_event(event_name: String, properties: Dictionary = {}) -> void:
	print("[Analytics] %s %s" % [event_name, properties])


## Purpose: Public method `set_user_property` used by external systems to invoke this class behavior.
## Example: `self.set_user_property("difficulty", "normal")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func set_user_property(key: String, value: Variant) -> void:
	print("[Analytics] user_property %s = %s" % [key, str(value)])
