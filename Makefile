GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
GUT  := addons/gut/gut_cmdln.gd
DOCS_PORT ?= 8060

ut: ut-kernel ut-modules

ut-kernel:
	$(GODOT) --headless -s $(GUT) -gdir=res://test/unit/kernel -gexit

ut-modules:
	$(GODOT) --headless -s $(GUT) -gdir=res://test/unit/modules -gexit

docs-server:
	python3 -m http.server $(DOCS_PORT) --directory docs

.PHONY: ut ut-kernel ut-modules docs-server
