class_name AnalyticsServiceMock
extends AnalyticsService


func track_event(event_name: String, properties: Dictionary = {}) -> void:
	print("[Analytics] %s %s" % [event_name, properties])


func set_user_property(key: String, value: Variant) -> void:
	print("[Analytics] user_property %s = %s" % [key, str(value)])
