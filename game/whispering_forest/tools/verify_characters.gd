extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var count := 0
	for kind in ["mage","mentor","goblin"]:
		for action in ["idle","walk","attack","seal"]:
			var path := "res://game/whispering_forest/assets/characters/%s-%s.png" % [kind,action]
			var sheet := Image.load_from_file(ProjectSettings.globalize_path(path))
			if sheet==null or sheet.get_size()!=Vector2i(2048,2048):
				failures.append(path+": wrong sheet dimensions")
				continue
			for direction in range(8):
				var distinct: Dictionary = {}
				for frame in range(8):
					var cell := sheet.get_region(Rect2i(frame*256,direction*256,256,256))
					var used := cell.get_used_rect()
					if used.size.x<30 or used.size.y<150:
						failures.append("%s %d/%d: missing character" % [path,direction,frame])
					if used.position.x<=0 or used.position.y<=0 or used.end.x>=256 or used.end.y>=256:
						failures.append("%s %d/%d: clipped character" % [path,direction,frame])
					if cell.get_pixel(0,0).a>0 or cell.get_pixel(255,255).a>0:
						failures.append(path+": background is not transparent")
					distinct[cell.get_data().hex_encode().sha256_text()] = true
					count += 1
				if action=="walk" and distinct.size()!=8:
					failures.append("%s direction %d: walk poses repeat" % [path,direction])
	if failures.is_empty():
		print("WF_CHARACTER_ASSETS_OK: %d transparent frames; complete silhouettes; eight distinct walk poses per direction" % count)
		quit()
	else:
		for message in failures:
			push_error(message)
		quit(1)
