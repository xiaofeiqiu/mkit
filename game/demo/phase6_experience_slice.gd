extends Node2D

# Phase 6 experience slice — validation target:
#   Add XP, level up, save/load level persistence.
#
# Controls: E = +30 XP (enemy)   B = +150 XP (boss)   F = save   L = load

@onready var _level_label: Label = $HUD/StatsPanel/LevelInfo
@onready var _xp_label: Label = $HUD/StatsPanel/XPInfo
@onready var _progress_label: Label = $HUD/StatsPanel/ProgressInfo
@onready var _log_label: Label = $HUD/StatsPanel/EventLog
@onready var _instructions_label: Label = $HUD/Instructions

var _experience: ExperienceComponent = null
var _save_manager: SaveManager = null
var _log_lines: Array[String] = []


func _ready() -> void:
	_save_manager = ServiceRegistry.get_service("save") as SaveManager
	if _save_manager != null:
		_save_manager.save_completed.connect(func(p): _log("[SAVE] saved: %s" % p))
		_save_manager.load_completed.connect(func(p): _log("[SAVE] loaded: %s" % p))
		_save_manager.save_failed.connect(func(p, r): _log("[SAVE] failed: %s" % r))
		_save_manager.load_failed.connect(func(p, r): _log("[SAVE] no save file yet"))

	_setup_experience()

	_instructions_label.text = (
		"E = +30 XP (enemy kill)     B = +150 XP (boss kill)     F = save     L = load"
	)


func _setup_experience() -> void:
	var curve := ExperienceCurve.new()
	curve.base_xp = 50
	curve.growth_factor = 1.4
	curve.max_level = 10

	_experience = ExperienceComponent.new()
	_experience.save_id = "player_experience"
	_experience.curve = curve
	add_child(_experience)

	_experience.level_up.connect(_on_level_up)
	_log("[EXP] ready — lv%d  (max %d, base_xp %d, growth x%.1f)" % [
		_experience.current_level, curve.max_level, curve.base_xp, curve.growth_factor])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E: _add_xp(30)
			KEY_B: _add_xp(150)
			KEY_F: _do_save()
			KEY_L: _do_load()


func _process(_delta: float) -> void:
	if _experience == null or _experience.curve == null:
		return
	var max_lv: int = _experience.curve.max_level
	var lv: int = _experience.current_level
	var xp: int = _experience.current_xp
	var required: int = _experience.curve.get_xp_required(lv)

	_level_label.text = "Level: %d / %d" % [lv, max_lv]

	if lv >= max_lv:
		_xp_label.text = "XP: MAX"
		_progress_label.text = "Progress: [██████████] 100%"
	else:
		_xp_label.text = "XP: %d / %d  (to next: %d)" % [xp, required, _experience.get_xp_to_next_level()]
		var filled: int = int(_experience.get_level_progress() * 10)
		_progress_label.text = "Progress: [%s%s] %d%%" % [
			"█".repeat(filled), "░".repeat(10 - filled),
			int(_experience.get_level_progress() * 100)]


func _on_level_up(old_level: int, new_level: int) -> void:
	_log("[LEVEL UP] %d → %d  (next needs %d XP)" % [
		old_level, new_level, _experience.curve.get_xp_required(new_level)])


func _add_xp(amount: int) -> void:
	if _experience == null:
		return
	if _experience.current_level >= _experience.curve.max_level:
		_log("[XP] already max level")
		return
	_experience.add_xp(amount)
	_log("[XP] +%d  →  %d / %d" % [
		amount, _experience.current_xp,
		_experience.curve.get_xp_required(_experience.current_level)])


func _do_save() -> void:
	if _save_manager == null:
		_log("[SAVE] SaveManager not available")
		return
	_save_manager.save_game(get_tree().root)


func _do_load() -> void:
	if _save_manager == null:
		_log("[SAVE] SaveManager not available")
		return
	_save_manager.load_game(get_tree().root)
	if _experience != null:
		_log("[LOAD] lv=%d  xp=%d" % [_experience.current_level, _experience.current_xp])


func _log(line: String) -> void:
	print(line)
	_log_lines.append(line)
	if _log_lines.size() > 12:
		_log_lines.pop_front()
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)
