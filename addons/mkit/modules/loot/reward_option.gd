## What: RewardOption is the runtime choice object shown to the player after reward generation.
## Responsibilities: carry display data, rarity, source, effects, and payload for one selectable reward.
## Upstream: RewardSystem builds options from RewardDefinition resources.
## Downstream: reward UI renders options and RunDirector/RewardSystem applies the chosen option.
## When to use: Use it as the runtime presentation object for reward selection screens.
## Example: render `option.display_name`, `option.rarity`, and call `reward_system.apply_selected(option, ctx)` on click.
class_name RewardOption
extends RefCounted

## Purpose: Public runtime field `reward_id`.
## Example: `self.reward_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var reward_id: String = ""
## Purpose: Public runtime field `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var display_name: String = ""
## Purpose: Public runtime field `description`.
## Example: `self.description = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var description: String = ""
## Purpose: Public runtime field `icon`.
## Example: `self.icon = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var icon: Texture2D = null
## Purpose: Public runtime field `rarity`.
## Example: `self.rarity = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var rarity: String = "common"
## Purpose: Public runtime field `source`.
## Example: `self.source = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source: String = ""
## Purpose: Public runtime field `effects`.
## Example: `self.effects = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var effects: Array[GameEffect] = []
## Purpose: Public runtime field `payload`.
## Example: `self.payload = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var payload: Dictionary = {}
