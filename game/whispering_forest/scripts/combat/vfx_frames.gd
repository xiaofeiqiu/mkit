extends RefCounted

static var cache: Dictionary = {}
const Tuning = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
const SOLID_MANIFEST := "res://game/whispering_forest/assets/combat-vfx/solid-8/manifest.json"
const ICE_MANIFEST := "res://game/whispering_forest/assets/combat-vfx/ice-16/manifest.json"

static func solid_data(name: String) -> Dictionary:
	if name=="ice":
		if not cache.has("ice_manifest"):
			cache["ice_manifest"]=JSON.parse_string(FileAccess.get_file_as_string(ICE_MANIFEST))
		return cache["ice_manifest"].clips.ice
	if not cache.has("solid_manifest"):
		cache["solid_manifest"]=JSON.parse_string(FileAccess.get_file_as_string(SOLID_MANIFEST))
	return cache["solid_manifest"].clips[name]

static func pivot(name: String) -> Vector2:
	var value: Array=solid_data(name).pivot
	return Vector2(value[0],value[1])

static func clip(name: String, variant: int = 0) -> Array[Texture2D]:
	var key: String="clip:"+name+":"+str(variant)
	if cache.has(key): return cache[key]
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/whispering_forest/assets/combat-vfx/clips.json"))
	var result: Array[Texture2D] = []
	if manifest[name].get("type","") in ["model_frames","aseprite_frames"]:
		var spec:=solid_data(name)
		var sheet: Texture2D=load(spec.file)
		assert(int(spec.frames)==Tuning.frame_count(name) and int(spec.cell*spec.frames)==sheet.get_width(),"Exported clip count/grid differs from the registered animation")
		for i in range(int(spec.frames)):
			var texture:=AtlasTexture.new()
			texture.atlas=sheet
			texture.region=Rect2(i*spec.cell,variant*spec.cell,spec.cell,spec.cell)
			texture.filter_clip=true
			result.append(texture)
		cache[key]=result
		return result
	for page in manifest[name].pages:
		var sheet: Texture2D=load("res://game/whispering_forest/assets/combat-vfx/"+page.file)
		var cell:=sheet.get_size()/Vector2(page.columns,page.rows)
		for i in range(int(page.count)):
			var texture:=AtlasTexture.new()
			texture.atlas=sheet
			texture.region=Rect2(Vector2(i%int(page.columns),int(i/int(page.columns)))*cell,cell)
			if page.has("regions"):
				var box: Array=page.regions[i]
				texture.region=Rect2(box[0],box[1],box[2],box[3])
				var canvas:=Vector2(page.canvas[0],page.canvas[1])
				var size_value:=Vector2(box[2],box[3])
				# Airborne explosion frames have an authored centre; their physical
				# sizes stay intact. Ground-rooted spells use model pivots above.
				var origin: Array=page.pivots[i]
				texture.margin=Rect2(Vector2(canvas.x*0.5-origin[0],canvas.y*0.5-origin[1]),canvas-size_value)
			texture.filter_clip=true
			result.append(texture)
	assert(result.size()==Tuning.frame_count(name),"Elemental clip does not match its authored frame count")
	cache[key]=result
	return result

static func frames(name: String) -> Array[Texture2D]:
	if cache.has(name): return cache[name]
	var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/whispering_forest/assets/combat-vfx/regions.json"))
	var sheet: Texture2D=load("res://game/whispering_forest/assets/combat-vfx/"+name+".png")
	var result: Array[Texture2D] = []
	for region in metadata[name].regions:
		var texture:=AtlasTexture.new()
		texture.atlas=sheet
		texture.region=Rect2(region[0],region[1],region[2],region[3])
		texture.filter_clip=true
		result.append(texture)
	cache[name]=result
	return result
