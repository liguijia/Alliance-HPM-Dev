#!/usr/bin/env bash
# ============================================================================
# HPM New Project Creator
# Creates a new project from user_template
#
# Usage:
#   ./tools/scripts/new_project <project_name> [target_dir]
#   ./tools/scripts/new_project.sh <project_name> [target_dir]
#
# Examples:
#   ./tools/scripts/new_project my_motor_control
#   ./tools/scripts/new_project my_project /workspace/projects
# ============================================================================

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEMPLATE_DIR="${WORKSPACE_DIR}/user_template"

# Default target: workspace directory
DEFAULT_TARGET_DIR="/workspace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    echo "Usage: $0 <project_name> [target_dir]"
    echo ""
    echo "Arguments:"
    echo "  project_name   Name of the new project (no spaces, no special chars)"
    echo "  target_dir     Target directory (default: /workspace)"
    echo ""
    echo "Examples:"
    echo "  $0 my_motor_control"
    echo "  $0 my_project /workspace/projects"
    exit 1
}

generate_workspace_file() {
    local project_name="$1"
    local project_dir="$2"
    local workspace_file="${project_dir}/${project_name}.code-workspace"
    local hpm_sdk_rel
    local base_platform_rel

    hpm_sdk_rel="$(python3 - "$project_dir" "${WORKSPACE_DIR}/hpm_sdk" <<'PY'
import os
import sys
print(os.path.relpath(sys.argv[2], sys.argv[1]))
PY
)"

    base_platform_rel="$(python3 - "$project_dir" "${WORKSPACE_DIR}/alliance_hpm_base_platform" <<'PY'
import os
import sys
print(os.path.relpath(sys.argv[2], sys.argv[1]))
PY
)"

    cat > "$workspace_file" <<EOF
{
  "folders": [
    {
      "name": "${project_name}",
      "path": "."
    },
    {
      "name": "hpm_sdk",
      "path": "${hpm_sdk_rel}"
    },
    {
      "name": "alliance_hpm_base_platform",
      "path": "${base_platform_rel}"
    }
  ],
  "settings": {
    "clangd.path": "clangd",
    "clangd.arguments": [
      "--log=error",
      "--background-index",
      "--header-insertion=never"
    ],
    "C_Cpp.intelliSenseEngine": "disabled",
    "cmake.configureOnOpen": false,
    "files.exclude": {
      "**/.git": true,
      "**/.cache": true,
      "**/build": true,
      "**/output": true
    },
    "search.exclude": {
      "**/.cache": true,
      "**/.venv": true,
      "**/build": true,
      "**/output": true
    },
    "files.watcherExclude": {
      "**/.cache/**": true,
      "**/.venv/**": true,
      "**/build/**": true,
      "**/output/**": true
    },
    "cSpell.enabled": true,
    "cSpell.language": "en,zh-CN",
    "cSpell.useGitignore": true,
    "cSpell.maxNumberOfProblems": 2000,
    "editor.formatOnSave": false,
    "terminal.integrated.cwd": "."
  }
}
EOF
}

generate_clangd_file() {
    local project_dir="$1"
    local board_name="$2"

    cat > "${project_dir}/.clangd" <<EOF
---
CompileFlags:
  CompilationDatabase: build
  Add:
    - -I../Interface
    - -I../Board/${board_name}
    - -ferror-limit=0
  Remove:
    - -fno-shrink-wrap
    - -fstrict-volatile-bitfields
    - -fno-tree-switch-conversion
    - -mabi=ilp32d
    - -march=rv32imafdc

Diagnostics:
  UnusedIncludes: None
  MissingIncludes: None
  Suppress:
    - missing-includes
    - pp_file_not_found
    - drv_unknown_argument

Index:
  Background: Build

Hover:
  ShowAKA: true
EOF
}

# ============================================================================
# Validate Project Name
# ============================================================================
validate_name() {
    local name="$1"

    # Check empty
    if [[ -z "$name" ]]; then
        log_error "Project name cannot be empty"
        usage
    fi

    # Check for invalid characters
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        log_error "Invalid project name: $name"
        log_error "Name must start with letter, contain only: a-z A-Z 0-9 _ -"
        exit 1
    fi

    # Check length
    if [[ ${#name} -gt 64 ]]; then
        log_error "Project name too long (max 64 chars)"
        exit 1
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    # Parse arguments
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local project_name="$1"
    local target_dir="${2:-$DEFAULT_TARGET_DIR}"

    # Validate
    validate_name "$project_name"

    local project_dir="${target_dir}/${project_name}"

    # Check template exists
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
        log_error "Template not found: $TEMPLATE_DIR"
        exit 1
    fi

    # Check target exists
    if [[ -d "$project_dir" ]]; then
        # Check if we're inside the target directory
        local current_dir="$(pwd -P)"
        local target_abs="$(cd "$project_dir" && pwd -P)"
        if [[ "$current_dir" == "$target_abs" || "$current_dir" == "$target_abs"/* ]]; then
            log_error "You are inside the target directory: $project_dir"
            log_error "Please cd to another directory first (e.g., cd /workspace)"
            exit 1
        fi
        log_error "Project directory already exists: $project_dir"
        log_error "Remove it first or choose a different name"
        exit 1
    fi

    # Ensure target parent exists
    if [[ ! -d "$target_dir" ]]; then
        log_info "Creating target directory: $target_dir"
        mkdir -p "$target_dir"
    fi

    # ========================================================================
    # Create Project
    # ========================================================================
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}  Creating New HPM Project${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    echo -e "  Project Name : ${GREEN}${project_name}${NC}"
    echo -e "  Location     : ${GREEN}${project_dir}${NC}"
    echo -e "  Template     : ${GREEN}${TEMPLATE_DIR}${NC}"
    echo ""

    # Copy template
    log_info "Copying template..."
    cp -a "$TEMPLATE_DIR" "$project_dir"

    # Rename user_board to <project_name>_board
    local board_name="${project_name}_board"
    if [[ -d "${project_dir}/Board/user_board" ]]; then
        log_info "Renaming user_board -> ${board_name}..."
        mv "${project_dir}/Board/user_board" "${project_dir}/Board/${board_name}"

        # Update board name in yaml file
        if [[ -f "${project_dir}/Board/${board_name}/user_board.yaml" ]]; then
            mv "${project_dir}/Board/${board_name}/user_board.yaml" \
               "${project_dir}/Board/${board_name}/${board_name}.yaml"
            sed -i "s/name: user_board/name: ${board_name}/" \
                "${project_dir}/Board/${board_name}/${board_name}.yaml"
        fi

        # Update board name in cfg file
        if [[ -f "${project_dir}/Board/${board_name}/user_board.cfg" ]]; then
            mv "${project_dir}/Board/${board_name}/user_board.cfg" \
               "${project_dir}/Board/${board_name}/${board_name}.cfg"
        fi

        # Update BOARD_NAME in board.h
        if [[ -f "${project_dir}/Board/${board_name}/board.h" ]]; then
            sed -i "s/user_board/${board_name}/" \
                "${project_dir}/Board/${board_name}/board.h"
        fi
    fi

    # Remove build artifacts (shouldn't exist but just in case)
    log_info "Cleaning build artifacts..."
    rm -rf "${project_dir}/build"
    rm -rf "${project_dir}/output"
    rm -rf "${project_dir}/.cache"

    # Generate project-local development configs
    log_info "Generating .clangd for ${project_name}..."
    generate_clangd_file "${project_dir}" "${board_name}"

    log_info "Generating VS Code workspace file..."
    generate_workspace_file "${project_name}" "${project_dir}"

    # Update PROJECT_NAME in Makefile (optional, already uses directory name)
    # The Makefile uses $(notdir $(ROOT_DIR)) so it auto-adapts

    # ========================================================================
    # Summary
    # ========================================================================
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}  Project Created Successfully!${NC}"
    echo -e "${GREEN}============================================================${NC}"
    echo ""
    echo -e "  Next steps:"
    echo ""
    echo -e "    ${CYAN}cd ${project_dir}${NC}"
    echo -e "    ${CYAN}make build${NC}"
    echo ""
    echo -e "  Customize your project:"
    echo -e "    1. Edit ${CYAN}Board/${board_name}/board.h${NC} for board config"
    echo -e "    2. Edit ${CYAN}Board/${board_name}/pinmux.c${NC} for pin mux"
    echo -e "    3. Add drivers in ${CYAN}Driver/hpm_impl/${NC}"
    echo -e "    4. Write business logic in ${CYAN}App/Logic/${NC}"
    echo ""
    echo -e "  Available boards:"
    echo -e "    make list-boards"
    echo ""
    echo -e "  Open workspace:"
    echo -e "    ${CYAN}${project_dir}/${project_name}.code-workspace${NC}"
    echo ""
}

main "$@"
