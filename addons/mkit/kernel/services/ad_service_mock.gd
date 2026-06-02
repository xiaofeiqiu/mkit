class_name AdServiceMock
extends AdService


func is_rewarded_ad_ready(_placement_id: String) -> bool:
	return true


func show_rewarded_ad(placement_id: String) -> void:
	await get_tree().create_timer(0.5).timeout
	rewarded_ad_completed.emit(placement_id)
