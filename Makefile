GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
GUT  := addons/gut/gut_cmdln.gd
DOCS_PORT ?= 8060
DOC_XML_DIR ?= docs/generated/xml
DOC_HTML_DIR ?= docs/generated/html
DOC_XML_LOG ?= /tmp/mkit_docs_xml.log
KERNEL_LOG ?= /tmp/mkit_godot_kernel.log
MODULE_LOG ?= /tmp/mkit_godot_modules.log
INT_LOG ?= /tmp/mkit_godot_int.log
DEMO_LOG ?= /tmp/mkit_demo_auto.log

check: layering docs-check ut int

run:
	$(GODOT) --path . res://game/bootstrap.tscn

editor:
	$(GODOT) --path . -e

clean:
	rm -rf $(DOC_XML_DIR) $(DOC_HTML_DIR)
	rm -f test/integration/tmp_mkit_int_*.tscn
	rm -f $(DOC_XML_LOG) $(KERNEL_LOG) $(MODULE_LOG) $(INT_LOG) $(DEMO_LOG)

clean-cache:
	rm -rf .godot
	$(GODOT) --headless --import

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

docs-xml:
	@rm -rf $(DOC_XML_DIR)
	@mkdir -p $(DOC_XML_DIR)
	$(GODOT) --headless --log-file $(DOC_XML_LOG) --path . --doctool $(DOC_XML_DIR) --gdscript-docs res://addons/mkit

docs-html:
	python3 tools/generate_api_html.py --xml-dir $(DOC_XML_DIR) --out-dir $(DOC_HTML_DIR)

docs-api: docs-xml docs-html

docs-check:
	python3 tools/check_gd_doc_comments.py
	$(MAKE) docs-api
	python3 tools/check_generated_docs_fresh.py --xml-dir $(DOC_XML_DIR) --html-dir $(DOC_HTML_DIR)
	python3 tools/check_docs_sync.py

layering:
	python3 tools/check_layering.py

cookbook-fields:
	sh tools/audit_cookbook_fields.sh

.NOTPARALLEL:
.PHONY: check run editor clean clean-cache reimport ut ut-kernel ut-modules int demo-test docs-server docs-xml docs-html docs-api docs-check layering cookbook-fields
