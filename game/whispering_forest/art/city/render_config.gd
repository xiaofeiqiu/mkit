extends RefCounted

# Authoritative configuration used by all Bellwake city asset exporters.
const VERSION := "bellwake-daylight-v3"
const DATA := {
	"renderer":"forward_plus", "projection":"orthographic", "canvas":2048,
	"logical_units_per_metre":32.0, "supersample":2.0,
	"camera_target":Vector3(0,3.7,0), "camera_offset":Vector3(12,9.797958971,12),
	"key_rotation":Vector3(-50,-57.5,0), "key_color":"fffaf1", "key_energy":1.20,
	"fill_rotation":Vector3(-30,145,0), "fill_color":"d8e9ff", "fill_energy":0.16,
	"ambient_color":"e5eff8", "ambient_energy":0.42,
	"ssao_radius":1.2, "ssao_intensity":2.0, "ssao_power":1.3,
	"shadow_bias":0.025, "shadow_normal_bias":0.45, "shadow_distance":48.0,
	"near":0.1, "far":100.0, "msaa":4, "transparent":true,
	"tonemap":"linear", "exposure":1.0, "output_color":"sRGB",
	"ground_shadow":"runtime_ground_layer", "model_self_shadow":true,
	"human_metres":1.8371173, "door_metres":2.35, "storey_metres":3.4
}

static func digest() -> String:
	return FileAccess.get_sha256("res://game/whispering_forest/art/city/render_config.gd")
