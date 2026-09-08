extends Node3D

# One locked camera and one density for all world assets. Larger canvases may
# change SIZE, never the pixels/metre ratio. Cropping records the exact origin.
const Config = preload("res://game/whispering_forest/art/city/render_config.gd")
const SETTINGS = Config.DATA
const LOGICAL_UNITS_PER_METRE: float = SETTINGS.logical_units_per_metre
const SUPERSAMPLE: float = SETTINGS.supersample
const PIXELS_PER_METRE := LOGICAL_UNITS_PER_METRE*sqrt(2.0)*SUPERSAMPLE
const CANVAS: int = SETTINGS.canvas
const TARGET: Vector3 = SETTINGS.camera_target
const PROFILE_VERSION := Config.VERSION
const PROFILE_SOURCE := "res://game/whispering_forest/art/city/render_config.gd"
var camera: Camera3D

func build() -> void:
	name="BellwakeAssetStage"
	var environment := WorldEnvironment.new()
	environment.name="SharedDaylight"
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0,0,0,0)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color(SETTINGS.ambient_color)
	environment.environment.ambient_light_energy=SETTINGS.ambient_energy
	environment.environment.ssao_enabled=true
	environment.environment.ssao_radius=SETTINGS.ssao_radius
	environment.environment.ssao_intensity=SETTINGS.ssao_intensity
	environment.environment.ssao_power=SETTINGS.ssao_power
	environment.environment.tonemap_exposure=SETTINGS.exposure
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name="SharedUpperLeftSun"
	sun.rotation_degrees=SETTINGS.key_rotation
	sun.light_color=Color(SETTINGS.key_color)
	sun.light_energy=SETTINGS.key_energy
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=SETTINGS.shadow_distance
	sun.shadow_bias=SETTINGS.shadow_bias
	sun.shadow_normal_bias=SETTINGS.shadow_normal_bias
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name="CoolSkyFill"
	fill.rotation_degrees=SETTINGS.fill_rotation
	fill.light_color=Color(SETTINGS.fill_color)
	fill.light_energy=SETTINGS.fill_energy
	add_child(fill)
	camera=Camera3D.new()
	camera.name="Locked_2_to_1_Orthographic"
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=CANVAS/PIXELS_PER_METRE
	camera.near=SETTINGS.near
	camera.far=SETTINGS.far
	camera.position=TARGET+SETTINGS.camera_offset
	add_child(camera)
	camera.look_at(TARGET)
	camera.current=true
	for child in get_children(): child.owner=self

func frame_canvas(canvas: Vector2i, target: Vector3) -> void:
	# Framing may change; projection, density, azimuth and lights may not.
	camera.size=float(canvas.y)/PIXELS_PER_METRE
	camera.position=target+SETTINGS.camera_offset
	camera.look_at(target)

static func profile_record() -> Dictionary:
	var result := {"version":Config.VERSION,"sha256":Config.digest(),
		"source":PROFILE_SOURCE,"elevation_degrees":30,"azimuth_degrees":45,
		"pixels_per_metre":PIXELS_PER_METRE,"runtime_scale":1.0/SUPERSAMPLE}
	for key in SETTINGS:
		var value = SETTINGS[key]
		result[key]=[value.x,value.y,value.z] if value is Vector3 else value
	return result

func verify_projection() -> bool:
	var p := camera.unproject_position(Vector3.ZERO)
	var u := camera.unproject_position(Vector3.RIGHT)-p
	var v := camera.unproject_position(Vector3.BACK)-p
	var up := camera.unproject_position(Vector3.UP)-p
	return u.distance_to(Vector2(32,16)*SUPERSAMPLE)<0.01 and v.distance_to(Vector2(-32,16)*SUPERSAMPLE)<0.01 and absf(up.x)<0.001
