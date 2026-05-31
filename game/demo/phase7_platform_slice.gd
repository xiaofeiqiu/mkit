extends Node2D

# Phase 6 Platform Services slice — validation target:
#   Analytics, rewarded ads, purchases, and cloud-save paths all use mock services.
#
# Controls:
#   A = track analytics event (run_started)
#   D = show rewarded ad (mock: 0.5 s delay then reward)
#   P = purchase product (mock: 0.3 s delay then complete)
#   C = save to cloud      L = load from cloud

@onready var _log_label: Label = $HUD/StatsPanel/EventLog
@onready var _status_label: Label = $HUD/StatsPanel/StatusInfo
@onready var _instructions_label: Label = $HUD/Instructions

var _analytics: AnalyticsService = null
var _ads: AdService = null
var _iap: IAPService = null
var _cloud_save: CloudSaveService = null
var _log_lines: Array[String] = []
var _run_counter: int = 0
var _ad_busy: bool = false
var _iap_busy: bool = false
var _cloud_busy: bool = false


func _ready() -> void:
	_analytics = ServiceRegistry.get_service("analytics") as AnalyticsService
	_ads = ServiceRegistry.get_service("ads") as AdService
	_iap = ServiceRegistry.get_service("iap") as IAPService
	_cloud_save = ServiceRegistry.get_service("cloud_save") as CloudSaveService

	_connect_signals()
	_update_status()

	_instructions_label.text = (
		"A = analytics event     D = rewarded ad     P = IAP purchase     C = cloud save     L = cloud load"
	)
	_log("Platform services ready — all using mock implementations")


func _connect_signals() -> void:
	if _ads != null:
		_ads.rewarded_ad_completed.connect(_on_ad_completed)
		_ads.rewarded_ad_failed.connect(_on_ad_failed)

	if _iap != null:
		_iap.purchase_completed.connect(_on_purchase_completed)
		_iap.purchase_failed.connect(_on_purchase_failed)
		_iap.products_loaded.connect(func(ids): _log("[IAP] products loaded: %s" % str(ids)))
		_iap.restore_completed.connect(func(ids): _log("[IAP] restore: %s" % str(ids)))

	if _cloud_save != null:
		_cloud_save.cloud_save_completed.connect(func(slot): _log("[CloudSave] saved: '%s'" % slot))
		_cloud_save.cloud_save_failed.connect(func(slot, r): _log("[CloudSave] save failed: %s" % r))
		_cloud_save.cloud_load_completed.connect(_on_cloud_loaded)
		_cloud_save.cloud_load_failed.connect(func(slot, r): _log("[CloudSave] load failed: %s" % r))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A: _do_analytics()
			KEY_D: _do_rewarded_ad()
			KEY_P: _do_iap_purchase()
			KEY_C: _do_cloud_save()
			KEY_L: _do_cloud_load()


# --- Analytics ---

func _do_analytics() -> void:
	if _analytics == null:
		_log("[Analytics] service not available")
		return
	_run_counter += 1
	_analytics.track_event("run_started", {
		"run_id": "run_%03d" % _run_counter,
		"seed": randi(),
		"character": "warrior"
	})
	_analytics.set_user_property("total_runs", _run_counter)
	_log("[Analytics] tracked run_started  (run #%d)" % _run_counter)
	_update_status()


# --- Rewarded Ad ---

func _do_rewarded_ad() -> void:
	if _ads == null:
		_log("[Ad] service not available")
		return
	if _ad_busy:
		_log("[Ad] already waiting for ad")
		return
	if not _ads.is_rewarded_ad_ready("revive"):
		_log("[Ad] not ready")
		return
	_ad_busy = true
	_log("[Ad] showing rewarded ad (placement: revive) …")
	_update_status()
	_ads.show_rewarded_ad("revive")


func _on_ad_completed(placement_id: String) -> void:
	_ad_busy = false
	_log("[Ad] completed — placement: %s  → +50 HP granted" % placement_id)
	_update_status()


func _on_ad_failed(placement_id: String, reason: String) -> void:
	_ad_busy = false
	_log("[Ad] failed  placement=%s  reason=%s" % [placement_id, reason])
	_update_status()


# --- IAP ---

func _do_iap_purchase() -> void:
	if _iap == null:
		_log("[IAP] service not available")
		return
	if _iap_busy:
		_log("[IAP] already waiting for purchase")
		return
	_iap_busy = true
	var product := "com.mkit.starter_pack"
	_log("[IAP] purchasing '%s' …" % product)
	_update_status()
	_iap.purchase(product)


func _on_purchase_completed(product_id: String) -> void:
	_iap_busy = false
	_log("[IAP] purchase_completed: %s  (owned: %s)" % [
		product_id, str(_iap.is_purchased(product_id))])
	_update_status()


func _on_purchase_failed(product_id: String, reason: String) -> void:
	_iap_busy = false
	_log("[IAP] purchase_failed  product=%s  reason=%s" % [product_id, reason])
	_update_status()


# --- CloudSave ---

func _do_cloud_save() -> void:
	if _cloud_save == null:
		_log("[CloudSave] service not available")
		return
	if not _cloud_save.is_available():
		_log("[CloudSave] not available")
		return
	if _cloud_busy:
		_log("[CloudSave] busy")
		return
	_cloud_busy = true
	var data := {
		"run_count": _run_counter,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	_log("[CloudSave] saving slot 'profile_01' …")
	_update_status()
	_cloud_save.save_to_cloud("profile_01", data)
	await _cloud_save.cloud_save_completed
	_cloud_busy = false
	_update_status()


func _do_cloud_load() -> void:
	if _cloud_save == null:
		_log("[CloudSave] service not available")
		return
	if not _cloud_save.is_available():
		_log("[CloudSave] not available")
		return
	if _cloud_busy:
		_log("[CloudSave] busy")
		return
	_cloud_busy = true
	_log("[CloudSave] loading slot 'profile_01' …")
	_update_status()
	_cloud_save.load_from_cloud("profile_01")
	var result = await _cloud_save.cloud_load_completed
	_cloud_busy = false
	_update_status()


func _on_cloud_loaded(slot: String, data: Dictionary) -> void:
	_log("[CloudSave] loaded '%s': run_count=%s  ts=%s" % [
		slot,
		str(data.get("run_count", "?")),
		str(data.get("timestamp", "?"))
	])


# --- HUD ---

func _update_status() -> void:
	if _status_label == null:
		return
	var lines: Array[String] = []
	lines.append("Analytics: %s" % ("OK" if _analytics != null else "missing"))
	lines.append("Ads:       %s%s" % [
		("OK" if _ads != null else "missing"),
		"  [waiting…]" if _ad_busy else ""])
	lines.append("IAP:       %s%s" % [
		("OK" if _iap != null else "missing"),
		"  [waiting…]" if _iap_busy else ""])
	lines.append("CloudSave: %s%s  (available=%s)" % [
		("OK" if _cloud_save != null else "missing"),
		"  [busy…]" if _cloud_busy else "",
		str(_cloud_save.is_available()) if _cloud_save != null else "false"])
	lines.append("Runs tracked: %d" % _run_counter)
	_status_label.text = "\n".join(lines)


func _log(line: String) -> void:
	print(line)
	_log_lines.append(line)
	if _log_lines.size() > 10:
		_log_lines.pop_front()
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)
