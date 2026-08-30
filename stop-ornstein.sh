#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONTAINER_NAME="${CONTAINER_NAME:-ornstein3.8-27b-sglang}"
export MTP_CONTAINER_NAME="${MTP_CONTAINER_NAME:-ornstein3.8-27b-sglang-mtp}"
export PID_FILE="${PID_FILE:-.ornstein-sglang.pid}"
export MTP_PID_FILE="${MTP_PID_FILE:-.ornstein-sglang-mtp.pid}"
export LOG_FILE="${LOG_FILE:-.ornstein-sglang.log}"

cd "${SCRIPT_DIR}"
exec "${SCRIPT_DIR}/stop.sh"
