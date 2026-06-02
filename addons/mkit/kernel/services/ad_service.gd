class_name AdService
extends Node
signal rewarded_ad_completed(placement_id: String)
signal rewarded_ad_failed(placement_id: String, reason: String)


func is_rewarded_ad_ready(placement_id: String) -> bool:
	return false


func show_rewarded_ad(placement_id: String) -> void:
	rewarded_ad_failed.emit(placement_id, "not_implemented")
