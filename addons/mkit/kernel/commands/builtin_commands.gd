## What: BuiltinCommands is the central list of command type string constants used by the command system.
## Responsibilities: prevent typo-prone command ids and document the command vocabulary shipped with MKit.
## Upstream: input readers, AI brains, UI buttons, and tests create GameCommand objects using these constants.
## Downstream: CommandRouter, CommandReceiver, StateMachine, and State subclasses switch on command types.
## When to use: Use it whenever code creates or compares a built-in gameplay command.
## Example: `CommandRouter.dispatch(GameCommand.create(BuiltinCommands.CAST_ABILITY, "player", "enemy", {"ability_id":"fireball"}))`.
class_name BuiltinCommands
extends Object

const MOVE := "move"
const STOP_MOVE := "stop_move"
const ATTACK := "attack"
const CAST_ABILITY := "cast_ability"
const DASH := "dash"
const INTERACT := "interact"
const SELECT_REWARD := "select_reward"
const OPEN_INVENTORY := "open_inventory"
const CLOSE_INVENTORY := "close_inventory"
const EQUIP_ITEM := "equip_item"
const UNEQUIP_ITEM := "unequip_item"
const PAUSE := "pause"
const RESUME := "resume"
