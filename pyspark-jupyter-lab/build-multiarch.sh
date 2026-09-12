#!/usr/bin/env bash
#
# Build and publish the PySpark 3.3.0 Jupyter Lab image as a multi-architecture
# (linux/amd64 + linux/arm64) manifest.
#
# One tag serves every host: Docker picks the matching architecture at pull
# time. amd64 covers Intel/AMD Windows and Intel Macs; arm64 covers Apple
# Silicon and Windows on ARM. Apple Silicon users stop running the JVM under
# emulation, which is the main reason for doing this.
#
# Usage:
#   ./build-multiarch.sh            # build both arches locally, no push
#   ./build-multiarch.sh --push     # build and push to Docker Hub
#
# Requires: docker login, and a buildx builder with a docker-container driver.
#
# NOTE: this script never touches the ":latest" tag.

set -euo pipefail

REGISTRY="easewithdata"
NAME="pyspark-jupyter-lab"
TAG="3.3.0_multi_arch"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="multiarch"

cd "$(dirname "$0")"

PUSH=""
if [[ "${1:-}" == "--push" ]]; then
  PUSH="--push"
  echo ">> Image WILL be pushed to ${REGISTRY}/${NAME}:${TAG}"
else
  echo ">> Dry build only (no push). Pass --push to publish."
  echo ">> Note: multi-platform builds cannot be loaded into the local docker"
  echo "         image store; without --push the result stays in the build cache."
fi

# A docker-container driver is required for multi-platform output; the default
# "docker" driver can only produce single-arch images.
if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  echo ">> Creating buildx builder '${BUILDER}'"
  docker buildx create --name "${BUILDER}" --driver docker-container
fi
docker buildx use "${BUILDER}"
docker buildx inspect --bootstrap >/dev/null

# Pushing an image this size can fail part way through when the connection
# drops: buildx retries the blob, the registry has already expired the upload
# session, and it surfaces as "blob upload unknown to registry". Retrying the
# whole build is cheap because every layer is cached by then -- only the upload
# repeats.
RETRIES=3
attempt=1
while :; do
  echo ">> Building ${REGISTRY}/${NAME}:${TAG}  [${PLATFORMS}]  attempt ${attempt}"
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

# Verify rather than trust: buildx can report success even when the push did
# not land, so confirm the published manifest really advertises both arches.
echo ">> Verifying published manifest"
out="$(docker buildx imagetools inspect "${REGISTRY}/${NAME}:${TAG}" 2>&1 || true)"
rc=0
for p in linux/amd64 linux/arm64; do
  grep -q "Platform:  *${p}\$" <<<"${out}" || { echo "   FAIL missing ${p}" >&2; rc=1; }
done
(( rc == 0 )) || { echo ">> manifest incomplete" >&2; exit 1; }
echo ">> OK: ${REGISTRY}/${NAME}:${TAG} published for ${PLATFORMS}"
