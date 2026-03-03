SHELL := /bin/bash

# Paths
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
APP_DIR := $(ROOT_DIR)/user_app
BUILD_DIR := $(ROOT_DIR)/build
OUTPUT_DIR := $(ROOT_DIR)/output
PROJECT_NAME ?= $(notdir $(ROOT_DIR))
AUTO_BOARD_DIR := $(firstword $(wildcard $(ROOT_DIR)/*_board))
AUTO_BOARD := $(notdir $(AUTO_BOARD_DIR))

# Build options (can be overridden: make BOARD=...)
BOARD ?= $(AUTO_BOARD)
BOARD_SEARCH_PATH ?= $(ROOT_DIR)
RV_ARCH ?= rv32imafdc
RV_ABI ?= ilp32d
CMAKE_BUILD_TYPE ?= Debug
HPM_BUILD_TYPE ?= flash_xip
GENERATOR ?= Ninja
LAST_BUILD_LOG := $(BUILD_DIR)/last_build.log
BUILD_UI_SCRIPT := /workspace/tools/scripts/build_ui.sh

CMAKE_ARGS := \
	-G$(GENERATOR) \
	-DBOARD=$(BOARD) \
	-DBOARD_SEARCH_PATH=$(BOARD_SEARCH_PATH) \
	-DRV_ARCH=$(RV_ARCH) \
	-DRV_ABI=$(RV_ABI) \
	-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
	-DHPM_BUILD_TYPE=$(HPM_BUILD_TYPE)

.PHONY: all configure build build-core artifacts artifacts-core clean distclean rebuild help banner

all: artifacts

configure:
	@if [ -z "$(BOARD)" ]; then \
		echo "Error: no '*_board' directory found under $(ROOT_DIR), and BOARD is not set."; \
		echo "Use: make BOARD=<board_name> BOARD_SEARCH_PATH=<parent_dir> configure"; \
		exit 1; \
	fi
	cmake -S $(APP_DIR) -B $(BUILD_DIR) $(CMAKE_ARGS)

build-core: configure
	@echo ""
	@echo "============================================================"
	@echo "[BUILD] Start compiling target"
	@echo "============================================================"
	cmake --build $(BUILD_DIR) -j

build:
	@mkdir -p $(BUILD_DIR); \
	status=0; \
	set -o pipefail; \
	$(MAKE) --no-print-directory build-core 2>&1 | tee $(LAST_BUILD_LOG); \
	status=$$?; \
	$(MAKE) --no-print-directory banner BUILD_STATUS=$$status BUILD_ACTION=build BUILD_LOG="$(LAST_BUILD_LOG)"; \
	exit $$status

artifacts-core: build-core
	@echo ""
	@echo "============================================================"
	@echo "[ARTIFACTS] Export compiled files"
	@echo "  OUTPUT_DIR: $(OUTPUT_DIR)"
	@echo "============================================================"
	mkdir -p $(OUTPUT_DIR)
	cp -f $(BUILD_DIR)/output/demo.elf $(OUTPUT_DIR)/$(PROJECT_NAME).elf
	cp -f $(BUILD_DIR)/output/demo.bin $(OUTPUT_DIR)/$(PROJECT_NAME).bin
	cp -f $(BUILD_DIR)/output/demo.map $(OUTPUT_DIR)/$(PROJECT_NAME).map
	cp -f $(BUILD_DIR)/output/demo.asm $(OUTPUT_DIR)/$(PROJECT_NAME).asm

artifacts:
	@mkdir -p $(BUILD_DIR); \
	status=0; \
	set -o pipefail; \
	$(MAKE) --no-print-directory artifacts-core 2>&1 | tee $(LAST_BUILD_LOG); \
	status=$$?; \
	$(MAKE) --no-print-directory banner BUILD_STATUS=$$status BUILD_ACTION=artifacts BUILD_LOG="$(LAST_BUILD_LOG)"; \
	exit $$status

banner:
	@$(BUILD_UI_SCRIPT) \
		--project "$(PROJECT_NAME)" \
		--action "$${BUILD_ACTION:-manual}" \
		--status "$${BUILD_STATUS:-0}" \
		--output-dir "$(OUTPUT_DIR)" \
		--log-file "$${BUILD_LOG:-}" \
		--app-dir "$(APP_DIR)" \
		--build-dir "$(BUILD_DIR)" \
		--board "$(BOARD)" \
		--board-search-path "$(BOARD_SEARCH_PATH)" \
		--rv-arch "$(RV_ARCH)" \
		--rv-abi "$(RV_ABI)" \
		--cmake-build-type "$(CMAKE_BUILD_TYPE)" \
		--hpm-build-type "$(HPM_BUILD_TYPE)"

clean:
	@echo "[CLEAN] Remove .cache, build, output"
	rm -rf $(ROOT_DIR)/.cache $(BUILD_DIR) $(OUTPUT_DIR)

distclean:
	@echo "[DISTCLEAN] Remove .cache, build, output"
	rm -rf $(ROOT_DIR)/.cache $(BUILD_DIR) $(OUTPUT_DIR)

rebuild: clean build

help:
	@echo "Targets:"
	@echo "  make configure   - configure CMake in $(BUILD_DIR)"
	@echo "  make build       - configure + build, then print banner/result"
	@echo "  make artifacts   - build + copy outputs, then print banner/result"
	@echo "  make clean       - remove .cache/build/output"
	@echo "  make distclean   - remove .cache/build/output"
	@echo "  make rebuild     - clean then build"
	@echo ""
	@echo "Overridable vars: BOARD BOARD_SEARCH_PATH RV_ARCH RV_ABI CMAKE_BUILD_TYPE HPM_BUILD_TYPE GENERATOR PROJECT_NAME"
