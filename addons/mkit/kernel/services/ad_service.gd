## What: AdService is the platform abstraction for rewarded ads.
## Responsibilities: report ad readiness, request rewarded ads, and emit completion or failure signals.
## Upstream: revive, bonus reward, or monetization flows call it through ServiceRegistry.
## Downstream: platform-specific SDK adapters or AdServiceMock complete the request and emit results.
## When to use: Use it when gameplay wants an ad reward without depending on a concrete ad SDK.
## Example: `var ads := ServiceRegistry.get_service("ads") as AdService; ads.show_rewarded_ad("revive_after_death")`.
class_name AdService
extends Node

## Rewarded-ad platform abstraction. Run/death flows depend on this, never on a real ad SDK.

## Purpose: Emits the `rewarded_ad_completed` signal so external listeners can react to this runtime event.
## Example: `self.rewarded_ad_completed.connect(_on_rewarded_ad_completed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal rewarded_ad_completed(placement_id: String)
## Purpose: Emits the `rewarded_ad_failed` signal so external listeners can react to this runtime event.
## Example: `self.rewarded_ad_failed.connect(_on_rewarded_ad_failed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal rewarded_ad_failed(placement_id: String, reason: String)


## Purpose: Public method `is_rewarded_ad_ready` used by external systems to invoke this class behavior.
## Example: `self.is_rewarded_ad_ready("placement_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func is_rewarded_ad_ready(placement_id: String) -> bool:
	return false


## Purpose: Public method `show_rewarded_ad` used by external systems to invoke this class behavior.
## Example: `self.show_rewarded_ad("placement_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func show_rewarded_ad(placement_id: String) -> void:
	rewarded_ad_failed.emit(placement_id, "not_implemented")
