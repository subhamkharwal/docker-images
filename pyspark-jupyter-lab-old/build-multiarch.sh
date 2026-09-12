#!/usr/bin/env bash
#
# Build and publish easewithdata/pyspark-jupyter-lab-old as a multi-architecture
# (linux/amd64 + linux/arm64) manifest.
#
# One tag serves every host: Docker picks the matching architecture at pull
# time. amd64 covers Intel/AMD Windows/Linux and Intel Macs; arm64 covers Apple
# Silicon and Windows on ARM. Apple Silicon users stop running the JVM under
# emulation, which is the whole point of this.
#
# Usage:
#   ./build-multiarch.sh            # build both arches, no push
#   ./build-multiarch.sh --push     # build and push to Docker Hub
#
# NOTE: this deliberately never touches the :latest tag.

set -euo pipefail

REGISTRY="easewithdata"
NAME="pyspark-jupyter-lab-old"
TAG="3.3.0_multi_arch"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="multiarch"

cd "$(dirname "$0")"

PUSH=""
if [[ "${1:-}" == "--push" ]]; then
  PUSH="--push"
  echo ">> Image WILL be pushed as ${REGISTRY}/${NAME}:${TAG}"
else
  echo ">> Dry build only (no push). Pass --push to publish."
fi

# A docker-container driver is required for multi-platform output; the default
# "docker" driver can only produce single-arch images.
if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  docker buildx create --name "${BUILDER}" --driver docker-container
fi
docker buildx use "${BUILDER}"
docker buildx inspect --bootstrap >/dev/null

# Large pushes intermittently fail with "blob upload unknown to registry" when
# the connection drops. Retrying is cheap: every layer is cached by then, only
# the upload repeats.
RETRIES=3
attempt=1
while :; do
  if docker buildx build \
       --platform "${PLATFORMS}" \
       -t "${REGISTRY}/${NAME}:${TAG}" \
       ${PUSH} \
       .; then
    break
  fi
  if (( attempt >= RETRIES )); then
    echo ">> failed after ${attempt} attempts" >&2
    exit 1
  fi
  echo ">> attempt ${attempt} failed, retrying..." >&2
  (( attempt++ ))
done

[[ -z "${PUSH}" ]] && exit 0

# Verify rather than trust: a wrapper can exit 0 even when the push did not
# land both architectures.
echo
echo ">> Verifying published manifest"
out="$(docker buildx imagetools inspect "${REGISTRY}/${NAME}:${TAG}" 2>&1 || true)"
rc=0
for p in linux/amd64 linux/arm64; do
  grep -q "Platform:  *${p}\$" <<<"${out}" || { echo "   MISSING ${p}" >&2; rc=1; }
done
(( rc == 0 )) && echo "   OK: linux/amd64 + linux/arm64 both published" || exit 1
