# Changelog

All notable public changes to Mkit are recorded here.

The format follows Keep a Changelog, and this project uses `0.x` versions while the public API is still settling.

## [Unreleased]

### Added

- Added GitHub Actions CI for layering, module dependency validation, unit tests, integration tests, and docs checks on Godot 4.6.3 stable.
- Added `docs/compatibility.md` with the current Godot, addon, and save schema compatibility contract.
- Added `game_template/` as a minimal starter slice separate from the full village RPG showcase.
- Added a service-ready wiring hook from `GameBootstrap` so services can cache dependencies after the registry is populated.

### Changed

- `ContentService.get_all_by_type()` now registers `class_name` keys such as `AbilityDefinition` first, while keeping legacy file-name keys such as `ability_definition` as aliases.
- `CommandService.dispatch()` now rejects commands that are already marked `consumed`.
- Quest statuses now use `QuestState.STATUS_*` string constants.
- Project docs and plugin metadata now target Godot 4.6.3 stable instead of 4.7-dev.

### Removed

- Removed the unused `GameCommand.priority` field.
