#!/usr/bin/env bash
set -euo pipefail

# Cache the immutable TURBO Fable W4A16 snapshot without starting SGLang or
# consuming GPU memory from the live inference service.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_ID="${MODEL_ID:-SeatownSin/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NM-DAU-NVFP4-W4A16}"
MODEL_REVISION="${MODEL_REVISION:-8c0067b9f7b909906d51042099907fd0cdf1e82d}"
IMAGE="${IMAGE:-lmsysorg/sglang:qwen38-27b}"
HF_HOME="${HF_HOME:-${SCRIPT_DIR}/.cache/huggingface}"

command -v docker >/dev/null 2>&1 || { echo "docker is not on PATH"; exit 1; }
mkdir -p "${HF_HOME}"

if [[ -z "${HF_TOKEN:-}" && -f "${HOME}/.bashrc" ]]; then
  token_line="$(sed -n -E '/^[[:space:]]*(export[[:space:]]+)?HF_TOKEN=/ {p;q;}' "${HOME}/.bashrc")"
  HF_TOKEN="${token_line#*=}"
  HF_TOKEN="${HF_TOKEN#\"}"; HF_TOKEN="${HF_TOKEN%\"}"
  HF_TOKEN="${HF_TOKEN#\'}"; HF_TOKEN="${HF_TOKEN%\'}"
fi
export HF_TOKEN

echo "Pulling ${IMAGE}"
docker pull "${IMAGE}"

echo "Caching ${MODEL_ID} at ${MODEL_REVISION}"
docker run --rm \
  -e HF_HOME=/root/.cache/huggingface \
  -e HF_TOKEN="${HF_TOKEN:-}" \
  -e MODEL_ID="${MODEL_ID}" \
  -e MODEL_REVISION="${MODEL_REVISION}" \
  -v "${HF_HOME}:/root/.cache/huggingface" \
  --entrypoint python3 \
  "${IMAGE}" \
  -c 'from huggingface_hub import snapshot_download; import os; print(snapshot_download(repo_id=os.environ["MODEL_ID"], revision=os.environ["MODEL_REVISION"], cache_dir=os.path.join(os.environ["HF_HOME"], "hub")))'

repo_cache_name="models--${MODEL_ID//\//--}"
snapshot_dir="${HF_HOME}/hub/${repo_cache_name}/snapshots/${MODEL_REVISION}"

for required in config.json model.safetensors.index.json hf_quant_config.json chat_template.jinja; do
  [[ -r "${snapshot_dir}/${required}" ]] || {
    echo "Downloaded snapshot is missing ${required}"; exit 1;
  }
done

grep -Eq '"quant_algo"[[:space:]]*:[[:space:]]*"MIXED_PRECISION"' \
  "${snapshot_dir}/hf_quant_config.json" || {
    echo "Checkpoint is not the expected servable MIXED_PRECISION export"; exit 1;
  }

shard_count="$(find -L "${snapshot_dir}" -maxdepth 1 -name 'model-*-of-*.safetensors' -type f | wc -l | tr -d ' ')"
[[ "${shard_count}" == "11" ]] || {
  echo "Expected 11 readable safetensor shards, found ${shard_count}"; exit 1;
}

grep -q '"mtp\.' "${snapshot_dir}/model.safetensors.index.json" || {
  echo "Checkpoint index does not expose the required MTP tensors"; exit 1;
}

echo "TURBO_FABLE_PREPARED model=${MODEL_ID} revision=${MODEL_REVISION} shards=${shard_count} quant=MIXED_PRECISION image=${IMAGE}"
