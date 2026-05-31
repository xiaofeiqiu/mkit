## What: AnalyticsService is the platform abstraction for gameplay analytics.
## Responsibilities: accept event tracking and user property updates without binding gameplay to a vendor SDK.
## Upstream: run flow, economy, progression, UI, or tests call analytics methods through ServiceRegistry.
## Downstream: concrete SDK adapters or AnalyticsServiceMock send or print analytics events.
## When to use: Use it when gameplay wants to record behavior while remaining platform-agnostic.
## Example: `analytics.track_event("room_cleared", {"room_id": "combat_01", "time": 42.5})`.
class_name AnalyticsService
extends Node

## Gameplay analytics abstraction. Gameplay code calls this; never a concrete SDK directly.

## Purpose: Public method `track_event` used by external systems to invoke this class behavior.
## Example: `self.track_event(event_name, {})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func track_event(event_name: String, properties: Dictionary = {}) -> void:
	pass


## Purpose: Public method `set_user_property` used by external systems to invoke this class behavior.
## Example: `self.set_user_property("difficulty", "normal")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func set_user_property(key: String, value: Variant) -> void:
	pass
