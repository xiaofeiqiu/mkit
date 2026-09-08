extends RefCounted

const ROOT := "res://game/whispering_forest/assets/combat-vfx/"
const Count = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
const Config = preload("res://game/whispering_forest/art/city/render_config.gd")

static func failures() -> Array[String]:
	var errors: Array[String]=[]
	var manifests: Array=[]
	for path in ["solid-8/manifest.json","ice-16/manifest.json"]:
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+path))
		manifests.append(manifest)
		if manifest.profile.sha256!=Config.digest(): errors.append(path+": stale shared camera/light profile; re-export it")
		for source in manifest.sources:
			if FileAccess.get_sha256(source)!=manifest.sources[source]: errors.append("Spell source changed without re-export: "+source)
	var active: Dictionary=manifests[0].clips.duplicate(true)
	active.ice=manifests[1].clips.ice
	for kind in active:
		var spec: Dictionary=active[kind]
		if int(spec.frames)!=Count.frame_count(kind): errors.append(kind+": authored frame count mismatch")
		if FileAccess.get_sha256(spec.file)!=spec.sha256: errors.append(kind+": atlas changed without metadata")
		var sheet:=Image.load_from_file(spec.file)
		if sheet.get_format()!=Image.FORMAT_RGBA8: errors.append(kind+": atlas has no real RGBA channel")
		if sheet.get_width()!=int(spec.cell*spec.frames) or sheet.get_height()!=int(spec.cell*spec.variants): errors.append(kind+": atlas dimensions do not match the frame grid")
		# Compute the root from the fixed projection, independently of the export
		# metadata and visible bounds. Asymmetric tips must not change this pivot.
		var expected:=Vector2(spec.cell/2.0,spec.cell/2.0)
		if kind!="earth": expected.y+=1.35*Config.DATA.logical_units_per_metre*sqrt(2.0)*Config.DATA.supersample*cos(PI/6)
		if expected.distance_to(Vector2(spec.pivot[0],spec.pivot[1]))>0.01: errors.append(kind+": pivot differs from the projected model root")
		for variant in range(int(spec.variants)):
			for frame in range(int(spec.frames)):
				var cell:=sheet.get_region(Rect2i(frame*spec.cell,variant*spec.cell,spec.cell,spec.cell))
				var box:=cell.get_used_rect()
				if box.size==Vector2i.ZERO or box.position.x<2 or box.position.y<2 or box.end.x>spec.cell-2 or box.end.y>spec.cell-2:
					errors.append("%s %d/%d: clipped, touching or empty frame" % [kind,variant,frame])
				if kind=="ice":
					var hash:=HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(cell.get_data())
					if hash.finish().hex_encode()!=spec.frame_sha256[frame]: errors.append("Ice cel changed without Aseprite export metadata")
	var ice: Dictionary=active.ice
	var ase: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ice.aseprite_data))
	if ase.frames.size()!=16 or ase.meta.layers.size()!=4: errors.append("Ice Aseprite timeline must contain sixteen cels and four editable layers")
	var elapsed:=0
	var unique: Dictionary={}
	for i in range(int(ice.frames)):
		if not is_equal_approx(float(ice.times[i]),elapsed/1000.0): errors.append("Ice runtime time differs from the Aseprite timeline")
		elapsed+=int(ase.frames[i].duration)
		unique[ice.frame_sha256[i]]=true
		if i>=int(ice.peak_frame) and ice.heights_metres[i]!=ice.heights_metres[ice.peak_frame]: errors.append("Ice contracts after the eruption")
	if elapsed!=roundi(Count.ICE_LIFE*1000) or unique.size()!=16: errors.append("Ice must contain sixteen distinct cels across its complete registered lifetime")
	if not is_equal_approx(float(ice.times[ice.peak_frame]),Count.ICE_PEAK): errors.append("Ice hit time differs from the authored eruption peak")
	var clips: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"clips.json"))
	for kind in clips:
		if int(clips[kind].frame_count)!=Count.frame_count(kind): errors.append(kind+": animation count differs from its migration status")
	for page in clips.fire.pages:
		if FileAccess.get_sha256(ROOT+page.file)!=page.source_sha256: errors.append("Fire source changed; re-register the eight reviewed poses")
		for i in range(int(page.count)):
			var box: Array=page.regions[i]
			var pivot: Array=page.pivots[i]
			if Vector2(pivot[0],pivot[1]).distance_to(Vector2(box[2],box[3])*0.5)>0.01: errors.append("Fire explosion centre drifted")
	return errors
