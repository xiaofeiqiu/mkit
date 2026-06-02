@tool
extends EditorPlugin
const AUTOLOADS := {
	"ServiceRegistry": "res://addons/mkit/kernel/services/service_registry.gd",
}


func _enter_tree() -> void:
	for autoload_name in AUTOLOADS:
		if not ProjectSettings.has_setting("autoload/%s" % autoload_name):
			add_autoload_singleton(autoload_name, AUTOLOADS[autoload_name])


func _exit_tree() -> void:
	for autoload_name in AUTOLOADS:
		if ProjectSettings.has_setting("autoload/%s" % autoload_name):
			remove_autoload_singleton(autoload_name)
