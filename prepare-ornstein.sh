#!/usr/bin/env bash
set -euo pipefail

# Pull the serving image and cache one immutable Ornstein snapshot without
# starting SGLang or taking GPU memory away from the live service.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_ID="${MODEL_ID:-GestaltLabs/Ornstein3.8-27B}"
MODEL_REVISION="${MODEL_REVISION:-f4fa57a13de0c14fae62aacac721faa73f2a1345}"
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
  -c 'from huggingface_hub import snapshot_download; print(snapshot_download(repo_id=__import__("os").environ["MODEL_ID"], revision=__import__("os").environ["MODEL_REVISION"], cache_dir=__import__("os").environ["HF_HOME"]))'

snapshot_dir="${HF_HOME}/hub/models--GestaltLabs--Ornstein3.8-27B/snapshots/${MODEL_REVISION}"
[[ -r "${snapshot_dir}/model.safetensors.index.json" ]] || {
  echo "Downloaded snapshot is missing model.safetensors.index.json"; exit 1;
}
shard_count="$(find -L "${snapshot_dir}" -maxdepth 1 -name 'model-*-of-*.safetensors' -type f | wc -l | tr -d ' ')"
[[ "${shard_count}" == "11" ]] || {
  echo "Expected 11 readable safetensor shards, found ${shard_count}"; exit 1;
}

echo "ORNSTEIN_PREPARED model=${MODEL_ID} revision=${MODEL_REVISION} shards=${shard_count} image=${IMAGE}"
