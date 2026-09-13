#!/usr/bin/env bash
#
# Build the Spark 4.2.0 cluster images (defined in docker-bake.hcl).
#
#   ./build-multiarch.sh           # build linux/amd64 + linux/arm64, no push
#   ./build-multiarch.sh --load    # build for THIS machine's arch and load the
#                                  # images into local docker (for testing
#                                  # with docker compose)
#   ./build-multiarch.sh --push    # build both arches and push to Docker Hub,
#                                  # then verify the published manifests
#
# Requires a buildx builder with the docker-container driver (created below if
# missing) and, for --push, `docker login`.

set -euo pipefail

REGISTRY="easewithdata"
TAG="4.2.0"
BUILDER="multiarch"
IMAGES=(spark-base spark-master spark-worker pyspark-jupyter)

cd "$(dirname "$0")"

MODE="${1:-}"
case "${MODE}" in
  "")      echo ">> Multi-arch build only (no push, no load)." ;;
  --load)  echo ">> Single-arch build, loading into local docker." ;;
  --push)  echo ">> Images WILL be pushed to ${REGISTRY} as :${TAG}" ;;
  *)       echo "Unknown option: ${MODE}" >&2; exit 2 ;;
esac

if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  echo ">> Creating buildx builder '${BUILDER}'"
  docker buildx create --name "${BUILDER}" --driver docker-container
fi
docker buildx inspect "${BUILDER}" --bootstrap >/dev/null

BAKE=(docker buildx bake --builder "${BUILDER}" --file docker-bake.hcl)

if [[ "${MODE}" == "--load" ]]; then
  case "$(uname -m)" in
    arm64|aarch64) PLATFORM="linux/arm64" ;;
    *)             PLATFORM="linux/amd64" ;;
  esac
  "${BAKE[@]}" --set "*.platform=${PLATFORM}" --load
  echo ">> Loaded ${PLATFORM} images:"
  for n in "${IMAGES[@]}"; do echo "   ${REGISTRY}/${n}:${TAG}"; done
  exit 0
fi

if [[ "${MODE}" == "" ]]; then
  "${BAKE[@]}"
  echo ">> Build finished (result kept in the build cache)."
  exit 0
fi

# --push. Large uploads (the Jupyter image is several GB per architecture) can
# fail when the connection drops mid-upload ("blob upload unknown to registry").
# Retrying is cheap because every layer is cached by then.
RETRIES=3
attempt=1
until "${BAKE[@]}" --push; do
  if (( attempt >= RETRIES )); then
    echo ">> Push failed after ${attempt} attempts" >&2
    exit 1
  fi
  echo ">> Push attempt ${attempt} failed, retrying..." >&2
  (( attempt++ ))
done

# Verify rather than trust exit codes: every manifest must advertise both
# architectures.
echo
echo ">> Verifying published manifests"
rc=0
for n in "${IMAGES[@]}"; do
  out="$(docker buildx imagetools inspect "${REGISTRY}/${n}:${TAG}" 2>&1 || true)"
  missing=""
  for p in linux/amd64 linux/arm64; do
    grep -q "Platform:  *${p}\$" <<<"${out}" || missing="${missing} ${p}"
  done
  if [[ -n "${missing}" ]]; then
    echo "   FAIL ${n}: missing${missing}" >&2
    rc=1
  else
    echo "   OK   ${n}: linux/amd64 + linux/arm64"
  fi
done
exit "${rc}"
