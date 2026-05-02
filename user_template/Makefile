SHELL := /bin/bash

# Paths
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
APP_DIR := $(ROOT_DIR)/user_app
BUILD_DIR := $(ROOT_DIR)/build
OUTPUT_DIR := $(ROOT_DIR)/output
PROJECT_NAME ?= $(notdir $(ROOT_DIR))

# ---- Board selection ----
# Change default here, or override on command line:
#   make BOARD_SEARCH_PATH=user_board
#   make BOARD_SEARCH_PATH=hpm5301evklite_board
#   make BOARD_SEARCH_PATH=/some/external/path/custom_board
BOARD_SEARCH_PATH ?= hpm5301evklite_board

# Auto-derive BOARD name and CMake search parent from BOARD_SEARCH_PATH
_BOARD_ABS := $(abspath $(BOARD_SEARCH_PATH))
BOARD := $(notdir $(_BOARD_ABS))
_CMAKE_BOARD_SEARCH_PATH := $(patsubst %/,%,$(dir $(_BOARD_ABS)))
RV_ARCH ?= rv32imafdc
RV_ABI ?= ilp32d
CMAKE_BUILD_TYPE ?= Debug
HPM_BUILD_TYPE ?= flash_xip
GENERATOR ?= Ninja
LAST_BUILD_LOG := $(BUILD_DIR)/last_build.log
BUILD_UI_SCRIPT := /workspace/tools/scripts/build_ui.sh
FLASH_SCRIPT := /workspace/tools/scripts/flash_target.sh

# Flash options (can be overridden: make FLASH_TOOL=jlink flash)
FLASH_TOOL ?= openocd
OPENOCD_BIN ?= $(if $(HPM_OPENOCD_PREFIX),$(HPM_OPENOCD_PREFIX)/bin/openocd,openocd)
OCD_SCRIPTS ?= $(if $(HPM_OCD_SCRIPTS),$(HPM_OCD_SCRIPTS),/workspace/hpm_sdk/boards/openocd)
PROBE_CFG ?= probes/cmsis_dap.cfg
SOC_CFG ?= soc/hpm5300.cfg
BOARD_CFG ?= boards/hpm5301evklite.cfg
JLINK_DEVICE ?= HPM5301xEGx
JLINK_IF ?= JTAG
JLINK_SPEED ?= 1000

CMAKE_ARGS := \
	-G$(GENERATOR) \
	-DBOARD=$(BOARD) \
	-DBOARD_SEARCH_PATH=$(_CMAKE_BOARD_SEARCH_PATH) \
	-DRV_ARCH=$(RV_ARCH) \
	-DRV_ABI=$(RV_ABI) \
	-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
	-DHPM_BUILD_TYPE=$(HPM_BUILD_TYPE)

.PHONY: all configure build build-core artifacts artifacts-core flash flash-openocd flash-jlink clean distclean rebuild help banner

all: artifacts

configure:
	@if [ ! -d "$(_BOARD_ABS)" ]; then \
		echo "Error: board directory not found: $(_BOARD_ABS)"; \
		echo "Use: make BOARD_SEARCH_PATH=<board_dir>"; \
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
		--board-search-path "$(_CMAKE_BOARD_SEARCH_PATH)" \
		--rv-arch "$(RV_ARCH)" \
		--rv-abi "$(RV_ABI)" \
		--cmake-build-type "$(CMAKE_BUILD_TYPE)" \
		--hpm-build-type "$(HPM_BUILD_TYPE)"

flash: build
	@echo ""
	@echo "============================================================"
	@echo "[FLASH] Programming target (tool=$(FLASH_TOOL))"
	@echo "============================================================"
ifeq ($(FLASH_TOOL),jlink)
	$(FLASH_SCRIPT) --tool jlink \
		--device $(JLINK_DEVICE) \
		--if $(JLINK_IF) \
		--speed $(JLINK_SPEED) \
		--elf $(BUILD_DIR)/output/demo.elf
else
	$(FLASH_SCRIPT) --tool openocd \
		--openocd-bin $(OPENOCD_BIN) \
		--ocd-scripts $(OCD_SCRIPTS) \
		--probe-cfg $(PROBE_CFG) \
		--soc-cfg $(SOC_CFG) \
		--board-cfg $(BOARD_CFG) \
		--elf $(BUILD_DIR)/output/demo.elf
endif

flash-openocd: build
	@echo ""
	@echo "============================================================"
	@echo "[FLASH] Programming target (OpenOCD)"
	@echo "============================================================"
	$(FLASH_SCRIPT) --tool openocd \
		--openocd-bin $(OPENOCD_BIN) \
		--ocd-scripts $(OCD_SCRIPTS) \
		--probe-cfg $(PROBE_CFG) \
		--soc-cfg $(SOC_CFG) \
		--board-cfg $(BOARD_CFG) \
		--elf $(BUILD_DIR)/output/demo.elf

flash-jlink: build
	@echo ""
	@echo "============================================================"
	@echo "[FLASH] Programming target (J-Link)"
	@echo "============================================================"
	$(FLASH_SCRIPT) --tool jlink \
		--device $(JLINK_DEVICE) \
		--if $(JLINK_IF) \
		--speed $(JLINK_SPEED) \
		--elf $(BUILD_DIR)/output/demo.elf

clean:
	@echo "[CLEAN] Remove .cache, build, output"
	rm -rf $(ROOT_DIR)/.cache $(BUILD_DIR) $(OUTPUT_DIR)

distclean:
	@echo "[DISTCLEAN] Remove .cache, build, output"
	rm -rf $(ROOT_DIR)/.cache $(BUILD_DIR) $(OUTPUT_DIR)

rebuild: clean build

help:
	@echo "Targets:"
	@echo "  make configure      - configure CMake in $(BUILD_DIR)"
	@echo "  make build          - configure + build, then print banner/result"
	@echo "  make artifacts      - build + copy outputs, then print banner/result"
	@echo "  make flash          - build + flash (default: openocd, set FLASH_TOOL=jlink to switch)"
	@echo "  make flash-openocd  - build + flash via OpenOCD (DAPLink)"
	@echo "  make flash-jlink    - build + flash via J-Link"
	@echo "  make clean          - remove .cache/build/output"
	@echo "  make distclean      - remove .cache/build/output"
	@echo "  make rebuild        - clean then build"
	@echo ""
	@echo ""
	@echo "Board selection:"
	@echo "  make BOARD_SEARCH_PATH=hpm5301evklite_board"
	@echo "  make BOARD_SEARCH_PATH=user_board"
	@echo ""
	@echo "Build vars:  BOARD_SEARCH_PATH RV_ARCH RV_ABI CMAKE_BUILD_TYPE HPM_BUILD_TYPE GENERATOR PROJECT_NAME"
	@echo "Flash vars:  FLASH_TOOL OPENOCD_BIN OCD_SCRIPTS PROBE_CFG SOC_CFG BOARD_CFG JLINK_DEVICE JLINK_IF JLINK_SPEED"
