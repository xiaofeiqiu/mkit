GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
GUT  := addons/gut/gut_cmdln.gd

ut: ut-kernel ut-modules

ut-kernel:
	$(GODOT) --headless -s $(GUT) -gdir=res://test/unit/kernel -gexit

ut-modules:
	$(GODOT) --headless -s $(GUT) -gdir=res://test/unit/modules -gexit

.PHONY: ut ut-kernel ut-modules
