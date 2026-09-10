#!/usr/bin/env bash
set -euo pipefail

# Serve SeatownSin's ModelOpt mixed-precision W4A16 conversion of the
# Qwen3.8-27B TURBO Fable fine-tune on one DGX Spark. The checkpoint retains
# the stock Qwen3.8 MTP head, so the first qualification uses native EAGLE/MTP
# rather than an external DSpark/DFlash2 drafter trained against base logits.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export MODEL_ID="${MODEL_ID:-SeatownSin/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NM-DAU-NVFP4-W4A16}"
export MODEL_REVISION="${MODEL_REVISION:-8c0067b9f7b909906d51042099907fd0cdf1e82d}"
export QUANT="${QUANT:-mixed-w4a16}"

# Keep the existing Qwen client alias and Spark endpoint. The exact target,
# revision and container name remain visible in the startup receipt and log.
export SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-qwen3.8-27b}"
export CONTAINER_NAME="${CONTAINER_NAME:-qwen3.8-27b-turbo-fable-sglang}"
export PORT="${PORT:-30000}"
export PID_FILE="${PID_FILE:-.turbo-fable-sglang.pid}"
export LOG_FILE="${LOG_FILE:-.turbo-fable-sglang.log}"

# The Spark-specific conversion author measured a global OOM at 0.95 and
# validated 0.75. Four requests match the current S3-S6 experiment lane.
# A 4096-token chunk trades some cold-prefill throughput for shorter decode
# pauses under concurrent, long-lived coding-agent histories.
export MAX_CONCURRENT_REQUESTS="${MAX_CONCURRENT_REQUESTS:-4}"
export MAX_MAMBA_CACHE_SIZE="${MAX_MAMBA_CACHE_SIZE:-64}"
export CONTEXT_LENGTH="${CONTEXT_LENGTH:-262144}"
export YARN="${YARN:-0}"
export CHUNKED_PREFILL="${CHUNKED_PREFILL:-4096}"
export MEM_FRACTION_STATIC="${MEM_FRACTION_STATIC:-0.75}"

# Native MTP parameters shipped by the checkpoint's Spark recipe.
export SPEC_STEPS="${SPEC_STEPS:-3}"
export SPEC_TOPK="${SPEC_TOPK:-1}"
export SPEC_DRAFT="${SPEC_DRAFT:-4}"

cd "${SCRIPT_DIR}"
exec "${SCRIPT_DIR}/start.sh"
