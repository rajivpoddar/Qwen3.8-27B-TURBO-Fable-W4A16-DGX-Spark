#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONTAINER_NAME="${CONTAINER_NAME:-qwen3.8-27b-turbo-fable-sglang}"
export MTP_CONTAINER_NAME="${MTP_CONTAINER_NAME:-qwen3.8-27b-turbo-fable-sglang-mtp}"
export PID_FILE="${PID_FILE:-.turbo-fable-sglang.pid}"
export MTP_PID_FILE="${MTP_PID_FILE:-.turbo-fable-sglang-mtp.pid}"
export LOG_FILE="${LOG_FILE:-.turbo-fable-sglang.log}"

cd "${SCRIPT_DIR}"
exec "${SCRIPT_DIR}/stop.sh"
