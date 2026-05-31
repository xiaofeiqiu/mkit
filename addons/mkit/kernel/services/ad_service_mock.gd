## What: AdServiceMock is the development implementation of AdService.
## Responsibilities: always report rewarded ads as ready and complete them after a short simulated delay.
## Upstream: GameBootstrap or tests register this mock for local/demo builds.
## Downstream: gameplay reward flows receive the same rewarded_ad_completed signal as a real ad adapter.
## When to use: Use it in editor, CI, or offline demos where no ad SDK is available.
## Example: `ServiceRegistry.register_service("ads", AdServiceMock.new(), "AdService")`.
class_name AdServiceMock
extends AdService

## Development-time ad service: always ready, completes after a short simulated delay.

## Purpose: Public method `is_rewarded_ad_ready` used by external systems to invoke this class behavior.
## Example: `self.is_rewarded_ad_ready("_placement_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func is_rewarded_ad_ready(_placement_id: String) -> bool:
	return true


## Purpose: Public method `show_rewarded_ad` used by external systems to invoke this class behavior.
## Example: `self.show_rewarded_ad("placement_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func show_rewarded_ad(placement_id: String) -> void:
	await get_tree().create_timer(0.5).timeout
	rewarded_ad_completed.emit(placement_id)
