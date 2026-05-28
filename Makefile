.SILENT:

INSTALL_DIR := /
INSTALL_TARGETS := $(patsubst %,$(INSTALL_DIR)%,/usr/bin/check_mirrors /usr/share/mirava/mirrors_list.yaml)

.DEFAULT_GOAL := build
.PHONY: build
build: build

.PHONY: install
install: $(INSTALL_TARGETS)

$(INSTALL_DIR)/usr/bin/check_mirrors: check_mirrors.sh
	install -Dm755 $< $@

$(INSTALL_DIR)/usr/share/mirava/mirrors_list.yaml: mirrors_list.yaml
	install -Dm644 $< $@

