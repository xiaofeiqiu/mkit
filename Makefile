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

# Full local gate: dependency layering, runtime contract validation, docs validation, and every test gate.
check: layering contract-check docs-check test

# Run all test gates: unit tests, integration tests, and demo auto-run smoke.
test: ut int demo-test

# Start the current sample game from res://game/bootstrap.tscn.
run:
	$(GODOT) --path . res://game/bootstrap.tscn

# Open this project in the Godot editor.
editor:
	$(GODOT) --path . -e

# Remove generated API docs, temporary integration scenes, and test logs.
clean:
	rm -rf $(DOC_XML_DIR) $(DOC_HTML_DIR)
	rm -f test/integration/tmp_mkit_int_*.tscn
	rm -f $(DOC_XML_LOG) $(KERNEL_LOG) $(MODULE_LOG) $(INT_LOG) $(DEMO_LOG)

# Delete the .godot import cache, then rebuild imports headlessly.
clean-cache:
	rm -rf .godot
	$(GODOT) --headless --import

# Remove temporary integration scenes, then refresh Godot imports.
reimport:
	@rm -f test/integration/tmp_mkit_int_*.tscn
	$(GODOT) --headless --import

# Run addon unit tests after the layering check: kernel first, then modules.
ut: layering ut-kernel ut-modules

# Run GUT unit tests under test/unit/kernel.
ut-kernel: reimport
	$(GODOT) --headless --log-file $(KERNEL_LOG) -s $(GUT) -gdir=res://test/unit/kernel -gexit

# Run GUT unit tests under test/unit/modules.
ut-modules: reimport
	$(GODOT) --headless --log-file $(MODULE_LOG) -s $(GUT) -gdir=res://test/unit/modules -gexit

# Run integration tests under test/integration after layering and reimport.
int: layering reimport
	$(GODOT) --headless --log-file $(INT_LOG) -s $(GUT) -gdir=res://test/integration -gexit

# Run the playable demo headlessly with --demo-auto-run.
demo-test:
	$(GODOT) --headless --log-file $(DEMO_LOG) --path . res://game/bootstrap.tscn --demo-auto-run

# Serve docs/ locally on DOCS_PORT, default 8060.
docs-server:
	@lsof -ti tcp:$(DOCS_PORT) | xargs kill -9 2>/dev/null || true
	python3 -m http.server $(DOCS_PORT) --directory docs

# Regenerate Godot doctool XML for res://addons/mkit.
docs-xml:
	@rm -rf $(DOC_XML_DIR)
	@mkdir -p $(DOC_XML_DIR)
	$(GODOT) --headless --log-file $(DOC_XML_LOG) --path . --doctool $(DOC_XML_DIR) --gdscript-docs res://addons/mkit

# Rebuild static API HTML from generated doctool XML.
docs-html:
	python3 tools/generate_api_html.py --xml-dir $(DOC_XML_DIR) --out-dir $(DOC_HTML_DIR)

# Regenerate both doctool XML and static API HTML.
docs-api: docs-xml docs-html

# Check doc comments, generated API freshness, links, nav, cookbook sections, and stale demo paths.
docs-check:
	python3 tools/check_gd_doc_comments.py
	$(MAKE) docs-api
	python3 tools/check_generated_docs_fresh.py --xml-dir $(DOC_XML_DIR) --html-dir $(DOC_HTML_DIR)
	python3 tools/check_docs_sync.py

# Enforce kernel/modules/game dependency boundaries.
layering:
	python3 tools/check_layering.py

# Check stable runtime ids and entity scene contracts.
contract-check:
	python3 tools/check_runtime_contracts.py

# Audit cookbook field-documentation coverage.
cookbook-fields:
	sh tools/audit_cookbook_fields.sh

.NOTPARALLEL:
.PHONY: check test run editor clean clean-cache reimport ut ut-kernel ut-modules int demo-test docs-server docs-xml docs-html docs-api docs-check layering contract-check cookbook-fields
.PHONY: forest-sample forest-test
forest-sample:
	$(GODOT) --path . --rendering-method gl_compatibility --resolution 1280x720 --scene res://game/whispering_forest/bootstrap.tscn

forest-test:
	GODOT="$(GODOT)" python3 game/whispering_forest/tools/verify.py
