@tool
## What: MKit editor plugin installs the minimal autoload required by the addon.
## Responsibilities: add ServiceRegistry when the addon is enabled and remove it when disabled.
## Upstream: Godot editor plugin lifecycle calls _enter_tree and _exit_tree.
## Downstream: project runtime code can access the global ServiceRegistry singleton after the plugin is enabled.
## When to use: Enable the addon in Project Settings so MKit services can be registered by GameBootstrap.
## Example: after enabling the addon, runtime code can call `ServiceRegistry.register_service("events", EventRouter.new())`.
extends EditorPlugin

# Mkit registers only a single global service locator autoload when the addon is
# enabled, and removes it when disabled. Every other system is constructed by the
# host game's GameBootstrap node and registered into ServiceRegistry, so the
# addon never injects game-specific autoloads.
const AUTOLOADS := {
	"ServiceRegistry": "res://addons/mkit/kernel/services/service_registry.gd",
}


func _enter_tree() -> void:
	for autoload_name in AUTOLOADS:
		# Guard against double-registration: the autoload may already be present
		# in project.godot (so the kit also works at runtime without the editor).
		if not ProjectSettings.has_setting("autoload/%s" % autoload_name):
			add_autoload_singleton(autoload_name, AUTOLOADS[autoload_name])


func _exit_tree() -> void:
	for autoload_name in AUTOLOADS:
		if ProjectSettings.has_setting("autoload/%s" % autoload_name):
			remove_autoload_singleton(autoload_name)
