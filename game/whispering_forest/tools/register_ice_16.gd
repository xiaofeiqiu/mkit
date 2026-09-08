extends SceneTree

const ROOT := "res://game/whispering_forest/"
const ART := ROOT+"art/combat/ice-16/"
const OUT := ROOT+"assets/combat-vfx/ice-16/"
const Motion = preload("res://game/whispering_forest/art/combat/ice_motion.gd")

func _initialize() -> void:
	var projection: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ART+"base/projection.json"))
	var authored: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"aseprite.json"))
	assert(authored.frames.size()==16)
	var spec: Dictionary=projection.duplicate(true)
	spec.erase("profile"); spec.erase("sources")
	spec.file=OUT+"ice.png"; spec.variants=1
	spec.sha256=FileAccess.get_sha256(spec.file)
	spec.anchor="shared projected ground origin; constant canvas; no per-frame trim, scale or centre"
	spec.authoring=ART+"ice-spear-16.aseprite"
	spec.aseprite_data=OUT+"aseprite.json"
	spec.durations_ms=[]; spec.bounds=[[]]; spec.frame_sha256=[]
	var sheet:=Image.load_from_file(spec.file)
	assert(sheet.get_width()==384*16 and sheet.get_height()==384)
	var times: Array=[]
	var elapsed:=0
	for i in range(16):
		var frame: Dictionary=authored.frames[i]
		assert(not frame.trimmed and not frame.rotated and frame.frame.x==i*384 and frame.frame.w==384)
		times.append(elapsed/1000.0)
		spec.durations_ms.append(frame.duration); elapsed+=int(frame.duration)
		var img:=sheet.get_region(Rect2i(i*384,0,384,384))
		var box:=img.get_used_rect()
		assert(box.has_area() and box.position.x>2 and box.position.y>2 and box.end.x<382 and box.end.y<382)
		spec.bounds[0].append([box.position.x,box.position.y,box.size.x,box.size.y])
		var hash:=HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(img.get_data())
		var digest:=hash.finish().hex_encode()
		assert(not spec.frame_sha256.has(digest),"Duplicate cel does not count as a newly authored pose")
		spec.frame_sha256.append(digest)
	assert(elapsed==roundi(Motion.LIFE*1000) and is_equal_approx(times[Motion.PEAK_FRAME],Motion.TIMES[Motion.PEAK_FRAME]))
	spec.times=times
	var manifest: Dictionary={"profile":projection.profile,"sources":projection.sources,"clips":{"ice":spec},"tool":"Aseprite 1.3.18.3-dev"}
	for path in [ART+"author_ice.lua",ART+"ice-spear-16.aseprite",OUT+"aseprite.json",ROOT+"tools/register_ice_16.gd"]:
		manifest.sources[path]=FileAccess.get_sha256(path)
	var file:=FileAccess.open(OUT+"manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n"); file.close()
	print("WF_ICE_REGISTERED_OK: 16 distinct Aseprite cels, full RGBA, fixed pivot, %.2fs / hit %.2fs" % [Motion.LIFE,Motion.TIMES[Motion.PEAK_FRAME]])
	quit()
