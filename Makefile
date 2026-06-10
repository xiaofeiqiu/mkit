GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
GUT  := addons/gut/gut_cmdln.gd
DOCS_PORT ?= 8060
KERNEL_LOG ?= /tmp/mkit_godot_kernel.log
MODULE_LOG ?= /tmp/mkit_godot_modules.log
INT_LOG ?= /tmp/mkit_godot_int.log
DEMO_LOG ?= /tmp/mkit_demo_auto.log

reimport:
	@rm -f test/integration/tmp_mkit_int_*.tscn
	$(GODOT) --headless --import

ut: layering ut-kernel ut-modules

ut-kernel: reimport
	$(GODOT) --headless --log-file $(KERNEL_LOG) -s $(GUT) -gdir=res://test/unit/kernel -gexit

ut-modules: reimport
	$(GODOT) --headless --log-file $(MODULE_LOG) -s $(GUT) -gdir=res://test/unit/modules -gexit

int: layering reimport
	$(GODOT) --headless --log-file $(INT_LOG) -s $(GUT) -gdir=res://test/integration -gexit

demo-test:
	$(GODOT) --headless --log-file $(DEMO_LOG) --path . res://game/bootstrap.tscn --demo-auto-run

docs-server:
	@lsof -ti tcp:$(DOCS_PORT) | xargs kill -9 2>/dev/null || true
	python3 -m http.server $(DOCS_PORT) --directory docs

docs-check:
	python3 tools/check_docs_sync.py

layering:
	python3 tools/check_layering.py

.NOTPARALLEL:
.PHONY: reimport ut ut-kernel ut-modules int demo-test docs-server docs-check layering
