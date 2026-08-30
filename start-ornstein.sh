#!/usr/bin/env bash
set -euo pipefail

# Ornstein3.8 is a BF16 Qwen3.8 fine-tune with its original MTP head intact.
# Keep the first evaluation on the checkpoint's own MTP path: external
# DSpark/DFlash drafters were trained against the base model's logits.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export MODEL_ID="${MODEL_ID:-GestaltLabs/Ornstein3.8-27B}"
export MODEL_REVISION="${MODEL_REVISION:-f4fa57a13de0c14fae62aacac721faa73f2a1345}"
export QUANT="${QUANT:-bf16}"
export SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-ornstein3.8-27b}"
export CONTAINER_NAME="${CONTAINER_NAME:-ornstein3.8-27b-sglang}"
export PID_FILE="${PID_FILE:-.ornstein-sglang.pid}"
export LOG_FILE="${LOG_FILE:-.ornstein-sglang.log}"

# Six agent slots, native 262K context, and smaller prefill chunks avoid a
# six-way prefill spike. 0.82 leaves host/unified-memory headroom for Docker,
# Claude clients, and transient graph compilation on a 128 GB Spark.
export MAX_CONCURRENT_REQUESTS="${MAX_CONCURRENT_REQUESTS:-6}"
export CONTEXT_LENGTH="${CONTEXT_LENGTH:-262144}"
export YARN="${YARN:-0}"
export CHUNKED_PREFILL="${CHUNKED_PREFILL:-2048}"
export MEM_FRACTION_STATIC="${MEM_FRACTION_STATIC:-0.82}"
export SPEC_STEPS="${SPEC_STEPS:-3}"
export SPEC_TOPK="${SPEC_TOPK:-1}"
export SPEC_DRAFT="${SPEC_DRAFT:-4}"

cd "${SCRIPT_DIR}"
exec "${SCRIPT_DIR}/start.sh"
