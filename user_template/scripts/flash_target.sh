#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/output"
DEFAULT_OCD_SCRIPTS="/workspace/hpm_sdk/boards/openocd"

TOOL=""
ELF_FILE=""
JLINK_DEVICE=""
JLINK_IF="JTAG"
JLINK_SPEED="1000"
OPENOCD_BIN="openocd"
OPENOCD_SCRIPTS="${DEFAULT_OCD_SCRIPTS}"
OPENOCD_PROBE_CFG=""
OPENOCD_SOC_CFG=""
OPENOCD_BOARD_CFG=""
OPENOCD_BIN_ADDR="0x80003000"
OPENOCD_SPEED=""
OPENOCD_RISCV_TIMEOUT=""
DRY_RUN="0"

log() { echo "[flash] $*"; }
err() { echo "[flash] ERROR: $*" >&2; }

usage() {
  cat <<'EOF'
用法:
  flash_target.sh --tool openocd [选项]
  flash_target.sh --tool jlink --device <MCU型号> [选项]

通用选项:
  --tool <openocd|jlink>   选择下载工具(必填)
  --elf <path>             指定 ELF;不指定则自动使用 output/ 下最新的 .elf
  --dry-run                仅打印命令，不执行
  -h, --help               显示帮助

OpenOCD 选项:
  --openocd-bin <path>     openocd 可执行文件(默认: openocd)
  --ocd-scripts <dir>      OpenOCD 脚本根目录(默认: /workspace/hpm_sdk/boards/openocd)
  --probe-cfg <file>       probe cfg(例如 probes/cmsis_dap.cfg)
  --soc-cfg <file>         soc cfg(例如 soc/hpm6750-dual-core.cfg)
  --board-cfg <file>       board cfg(例如 /workspace/user_template/user_board/user_board.cfg)
  --bin-addr <addr>        下载 .bin 时的目标地址(默认: 0x80003000)
  --ocd-speed <kHz>        OpenOCD adapter speed(未设置时,DAPLink默认1000)
  --riscv-timeout <sec>    riscv set_command_timeout_sec(未设置时,DAPLink默认20)

J-Link 选项:
  --device <name>          J-Link 设备名(必填，例如 HPM5301xEGx)
  --if <JTAG|SWD>          接口类型(默认: JTAG)
  --speed <kHz>            下载速率(默认: 1000)

示例:
  ./scripts/flash_target.sh --tool jlink --device HPM5301xEGx --if JTAG
  ./scripts/flash_target.sh --tool openocd \
    --probe-cfg probes/cmsis_dap.cfg \
    --soc-cfg soc/hpm6750-dual-core.cfg \
    --board-cfg /workspace/user_template/user_board/user_board.cfg
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "missing command: $1"
    exit 1
  }
}

find_latest_elf() {
  local f
  f="$(ls -1t "${OUTPUT_DIR}"/*.elf 2>/dev/null | head -n 1 || true)"
  if [[ -z "${f}" ]]; then
    err "no .elf found under ${OUTPUT_DIR}"
    exit 1
  fi
  echo "${f}"
}

find_latest_bin() {
  local f
  f="$(ls -1t "${OUTPUT_DIR}"/*.bin 2>/dev/null | head -n 1 || true)"
  if [[ -z "${f}" ]]; then
    err "no .bin found under ${OUTPUT_DIR}"
    exit 1
  fi
  echo "${f}"
}

run_openocd() {
  [[ -n "${OPENOCD_PROBE_CFG}" ]] || { err "--probe-cfg is required for openocd"; exit 1; }
  [[ -n "${OPENOCD_SOC_CFG}" ]] || { err "--soc-cfg is required for openocd"; exit 1; }
  [[ -n "${OPENOCD_BOARD_CFG}" ]] || { err "--board-cfg is required for openocd"; exit 1; }

  local is_daplink="0"
  if [[ "${OPENOCD_PROBE_CFG}" == *"cmsis_dap"* || "${OPENOCD_PROBE_CFG}" == *"daplink"* ]]; then
    is_daplink="1"
  fi
  if [[ -z "${OPENOCD_RISCV_TIMEOUT}" && "${is_daplink}" == "1" ]]; then
    OPENOCD_RISCV_TIMEOUT="40"
  fi

  local program_cmd
  if [[ "${ELF_FILE}" == *.bin ]]; then
    program_cmd="program ${ELF_FILE} ${OPENOCD_BIN_ADDR} verify reset exit"
  else
    program_cmd="program ${ELF_FILE} verify reset exit"
  fi

  local setup_cmd=""
  if [[ -n "${OPENOCD_SPEED}" ]]; then
    setup_cmd+="adapter speed ${OPENOCD_SPEED}; "
  fi
  if [[ -n "${OPENOCD_RISCV_TIMEOUT}" ]]; then
    setup_cmd+="riscv set_command_timeout_sec ${OPENOCD_RISCV_TIMEOUT}; "
  fi
  setup_cmd+="init; reset halt; "

  local run_once
  run_once() {
    local speed_arg="$1"
    local setup_local=""
    if [[ -n "${speed_arg}" ]]; then
      setup_local+="adapter speed ${speed_arg}; "
    fi
    if [[ -n "${OPENOCD_RISCV_TIMEOUT}" ]]; then
      setup_local+="riscv set_command_timeout_sec ${OPENOCD_RISCV_TIMEOUT}; "
    fi
    setup_local+="init; reset halt; "

    local cmd=(
      "${OPENOCD_BIN}"
      -s "${OPENOCD_SCRIPTS}"
      -f "${OPENOCD_PROBE_CFG}"
      -f "${OPENOCD_SOC_CFG}"
      -f "${OPENOCD_BOARD_CFG}"
      -c "${setup_local}${program_cmd}"
    )

    log "tool=openocd"
    log "elf=${ELF_FILE}"
    log "cmd: ${cmd[*]}"
    if [[ "${DRY_RUN}" == "1" ]]; then
      return 0
    fi
    "${cmd[@]}"
  }

  if [[ "${is_daplink}" == "1" && -z "${OPENOCD_SPEED}" ]]; then
    local speeds=("1000" "800" "600" "400" "200")
    local max_attempts="${#speeds[@]}"
    local i
    for ((i=1; i<=max_attempts; i++)); do
      local s="${speeds[$((i-1))]}"
      log "DAPLink try ${i}/${max_attempts} at ${s} kHz"
      if run_once "${s}"; then
        return 0
      fi
      log "Attempt failed at ${s} kHz"
      sleep 1
    done
    return 1
  fi

  run_once "${OPENOCD_SPEED}"
}

run_jlink() {
  [[ -n "${JLINK_DEVICE}" ]] || { err "--device is required for jlink"; exit 1; }

  local jlink_bin="${JLINK_ROOT:-}/JLinkExe"
  if [[ ! -x "${jlink_bin}" ]]; then
    jlink_bin="JLinkExe"
  fi
  need_cmd "${jlink_bin}"

  local tmp_script
  tmp_script="$(mktemp)"
  trap 'rm -f "${tmp_script}"' EXIT

  cat > "${tmp_script}" <<EOF
si ${JLINK_IF}
speed ${JLINK_SPEED}
connect
r
h
loadfile ${ELF_FILE}
r
g
qc
EOF

  local cmd=(
    "${jlink_bin}"
    -device "${JLINK_DEVICE}"
    -if "${JLINK_IF}"
    -speed "${JLINK_SPEED}"
    -autoconnect 1
    -CommanderScript "${tmp_script}"
  )

  log "tool=jlink"
  log "elf=${ELF_FILE}"
  log "cmd: ${cmd[*]}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    return 0
  fi
  "${cmd[@]}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOL="${2:-}"; shift 2 ;;
    --elf) ELF_FILE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="1"; shift ;;
    --openocd-bin) OPENOCD_BIN="${2:-}"; shift 2 ;;
    --ocd-scripts) OPENOCD_SCRIPTS="${2:-}"; shift 2 ;;
    --probe-cfg) OPENOCD_PROBE_CFG="${2:-}"; shift 2 ;;
    --soc-cfg) OPENOCD_SOC_CFG="${2:-}"; shift 2 ;;
    --board-cfg) OPENOCD_BOARD_CFG="${2:-}"; shift 2 ;;
    --bin-addr) OPENOCD_BIN_ADDR="${2:-}"; shift 2 ;;
    --ocd-speed) OPENOCD_SPEED="${2:-}"; shift 2 ;;
    --riscv-timeout) OPENOCD_RISCV_TIMEOUT="${2:-}"; shift 2 ;;
    --device) JLINK_DEVICE="${2:-}"; shift 2 ;;
    --if) JLINK_IF="${2:-}"; shift 2 ;;
    --speed) JLINK_SPEED="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown arg: $1"; usage; exit 1 ;;
  esac
done

[[ -n "${TOOL}" ]] || { err "--tool is required"; usage; exit 1; }

if [[ -z "${ELF_FILE}" ]]; then
  if [[ "${TOOL}" == "openocd" ]] && [[ "${OPENOCD_PROBE_CFG}" == *"cmsis_dap"* || "${OPENOCD_PROBE_CFG}" == *"daplink"* ]]; then
    ELF_FILE="$(find_latest_bin)"
  else
    ELF_FILE="$(find_latest_elf)"
  fi
fi
[[ -f "${ELF_FILE}" ]] || { err "ELF not found: ${ELF_FILE}"; exit 1; }

case "${TOOL}" in
  openocd) run_openocd ;;
  jlink) run_jlink ;;
  *)
    err "unsupported --tool: ${TOOL}"
    usage
    exit 1
    ;;
esac
