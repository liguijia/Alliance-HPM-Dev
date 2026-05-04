#!/usr/bin/env bash

set -euo pipefail

project_name="${PROJECT_NAME:-unknown}"
action="${BUILD_ACTION:-unknown}"
build_status="${BUILD_STATUS:-0}"
output_dir="${OUTPUT_DIR:-}"
build_log="${BUILD_LOG:-}"
app_dir="${APP_DIR:-}"
build_dir="${BUILD_DIR:-}"
board="${BOARD:-}"
board_search_path="${BOARD_SEARCH_PATH:-}"
hpm_sdk_version="${HPM_SDK_VERSION:-}"
riscv_toolchain_version="${RISCV_TOOLCHAIN_VERSION:-}"
rv_arch="${RV_ARCH:-}"
rv_abi="${RV_ABI:-}"
cmake_build_type="${CMAKE_BUILD_TYPE:-}"
hpm_build_type="${HPM_BUILD_TYPE:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      project_name="${2:-}"
      shift 2
      ;;
    --action)
      action="${2:-}"
      shift 2
      ;;
    --status)
      build_status="${2:-0}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --log-file)
      build_log="${2:-}"
      shift 2
      ;;
    --app-dir)
      app_dir="${2:-}"
      shift 2
      ;;
    --build-dir)
      build_dir="${2:-}"
      shift 2
      ;;
    --board)
      board="${2:-}"
      shift 2
      ;;
    --board-search-path)
      board_search_path="${2:-}"
      shift 2
      ;;
    --hpm-sdk-version)
      hpm_sdk_version="${2:-}"
      shift 2
      ;;
    --riscv-toolchain-version)
      riscv_toolchain_version="${2:-}"
      shift 2
      ;;
    --rv-arch)
      rv_arch="${2:-}"
      shift 2
      ;;
    --rv-abi)
      rv_abi="${2:-}"
      shift 2
      ;;
    --cmake-build-type)
      cmake_build_type="${2:-}"
      shift 2
      ;;
    --hpm-build-type)
      hpm_build_type="${2:-}"
      shift 2
      ;;
    *)
      echo "[build_ui] Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$hpm_sdk_version" ]]; then
  sdk_base="${HPM_SDK_BASE:-/workspace/hpm_sdk}"
  version_file="${sdk_base}/VERSION"
  if [[ -f "$version_file" ]]; then
    major="$(awk -F '=' '/VERSION_MAJOR/ {gsub(/[[:space:]]/, "", $2); print $2}' "$version_file")"
    minor="$(awk -F '=' '/VERSION_MINOR/ {gsub(/[[:space:]]/, "", $2); print $2}' "$version_file")"
    patch="$(awk -F '=' '/PATCHLEVEL/ {gsub(/[[:space:]]/, "", $2); print $2}' "$version_file")"
    if [[ -n "$major" && -n "$minor" && -n "$patch" ]]; then
      hpm_sdk_version="${major}.${minor}.${patch}"
    fi
  fi
  hpm_sdk_version="${hpm_sdk_version:-unknown}"
fi

if [[ -z "$riscv_toolchain_version" ]]; then
  if command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
    riscv_toolchain_version="$(riscv32-unknown-elf-gcc --version | head -n 1)"
  elif command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    riscv_toolchain_version="$(riscv64-unknown-elf-gcc --version | head -n 1)"
  else
    riscv_toolchain_version="unknown"
  fi
fi

printf '\n'
printf '%b\n' '\033[1;96m+---------------------------------------------------------------+\033[0m'
printf '%b\n' '\033[1;96m|  █████  ██      ██      ██  █████  ███    ██  ██████  ███████ |\033[0m'
printf '%b\n' '\033[1;96m| ██   ██ ██      ██      ██ ██   ██ ████   ██ ██       ██      |\033[0m'
printf '%b\n' '\033[1;96m| ███████ ██      ██      ██ ███████ ██ ██  ██ ██       █████   |\033[0m'
printf '%b\n' '\033[1;96m| ██   ██ ██      ██      ██ ██   ██ ██  ██ ██ ██       ██      |\033[0m'
printf '%b\n' '\033[1;96m| ██   ██ ███████ ███████ ██ ██   ██ ██   ████  ██████  ███████ |\033[0m'
printf '%b\n' '\033[1;96m|                                                               |\033[0m'
printf '%b\n' '\033[1;96m|   ██   ██ ██████  ███    ███     ██████  ███████ ██    ██     |\033[0m'
printf '%b\n' '\033[1;96m|   ██   ██ ██   ██ ████  ████     ██   ██ ██      ██    ██     |\033[0m'
printf '%b\n' '\033[1;96m|   ███████ ██████  ██ ████ ██     ██   ██ █████   ██    ██     |\033[0m'
printf '%b\n' '\033[1;96m|   ██   ██ ██      ██  ██  ██     ██   ██ ██       ██  ██      |\033[0m'
printf '%b\n' '\033[1;96m|   ██   ██ ██      ██      ██     ██████  ███████   ████       |\033[0m'
printf '%b\n' '\033[1;96m+---------------------------------------------------------------+\033[0m'
printf '\n'

printf '%b\n' '\033[1;30;47m >>> CONFIGURE SUMMARY \033[0m'
printf '%b\n' '\033[1;36m     PROJECT_NAME      :\033[0m \033[1;97m'"${project_name}"'\033[0m'
printf '%b\n' '\033[1;36m     APP_DIR           :\033[0m \033[0;97m'"${app_dir}"'\033[0m'
printf '%b\n' '\033[1;36m     BUILD_DIR         :\033[0m \033[0;97m'"${build_dir}"'\033[0m'
printf '%b\n' '\033[1;36m     BOARD             :\033[0m \033[1;93m'"${board}"'\033[0m'
printf '%b\n' '\033[1;36m     BOARD_SEARCH_PATH :\033[0m \033[0;97m'"${board_search_path}"'\033[0m'
printf '%b\n' '\033[1;36m     HPM_SDK_VERSION   :\033[0m \033[1;94m'"${hpm_sdk_version}"'\033[0m'
printf '%b\n' '\033[1;36m     RISCV_TOOLCHAIN   :\033[0m \033[1;94m'"${riscv_toolchain_version}"'\033[0m'
printf '%b\n' '\033[1;36m     RV_ARCH / RV_ABI  :\033[0m \033[1;92m'"${rv_arch} / ${rv_abi}"'\033[0m'
printf '%b\n' '\033[1;36m     BUILD_TYPE        :\033[0m \033[1;95m'"${cmake_build_type}"'\033[0m'
printf '%b\n' '\033[1;36m     HPM_BUILD_TYPE    :\033[0m \033[1;95m'"${hpm_build_type}"'\033[0m'
printf '\n'

if [[ "$build_status" == "0" ]]; then
  printf '%b\n' "\033[1;30;42m >>> BUILD SUCCESS: ${project_name} [ACTION: ${action}] \033[0m"
else
  printf '%b\n' "\033[1;37;41m >>> BUILD FAILED : ${project_name} [ACTION: ${action}] (EXIT=${build_status}) \033[0m"
  printf '%b\n' '\033[1;31m >>> ERROR DETAILS (directly below):\033[0m'
  if [[ -n "$build_log" && -f "$build_log" ]]; then
    printf '%b\n' '\033[1;33m >>> KEY ERRORS:\033[0m'
    err_lines="$(tr -d '\r' < "$build_log" | grep -iE 'error:|cmake error|failed|undefined reference|ninja: build stopped|no board named' | tail -n 20 || true)"
    if [[ -n "$err_lines" ]]; then
      printf '%s\n' "$err_lines"
    else
      printf '%b\n' '\033[1;33m >>> LAST LOG TAIL (tail -n 40):\033[0m'
      tail -n 40 "$build_log" || true
    fi
  fi
fi

if [[ -n "$output_dir" ]]; then
  if [[ "$build_status" == "0" ]]; then
    echo " >>> ARTIFACTS STATUS:"
  else
    echo " >>> ARTIFACTS STATUS (may be from previous successful build):"
  fi
  for ext in elf bin map asm; do
    artifact="${output_dir}/${project_name}.${ext}"
    if [[ -f "$artifact" ]]; then
      echo "     [OK] ${artifact}"
    else
      echo "     [--] ${artifact} (missing)"
    fi
  done
fi

printf '\n'
