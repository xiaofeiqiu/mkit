GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
GUT  := addons/gut/gut_cmdln.gd
DOCS_PORT ?= 8060
KERNEL_LOG ?= /tmp/mkit_godot_kernel.log
MODULE_LOG ?= /tmp/mkit_godot_modules.log
INT_LOG ?= /tmp/mkit_godot_int.log

ut: ut-kernel ut-modules

ut-kernel:
	$(GODOT) --headless --log-file $(KERNEL_LOG) -s $(GUT) -gdir=res://test/unit/kernel -gexit

ut-modules:
	$(GODOT) --headless --log-file $(MODULE_LOG) -s $(GUT) -gdir=res://test/unit/modules -gexit

int:
	$(GODOT) --headless --log-file $(INT_LOG) -s $(GUT) -gdir=res://test/integration -gexit

docs-server:
	python3 -m http.server $(DOCS_PORT) --directory docs

.PHONY: ut ut-kernel ut-modules int docs-server
