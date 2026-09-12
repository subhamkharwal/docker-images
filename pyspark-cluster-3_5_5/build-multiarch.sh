#!/usr/bin/env bash
#
# Build and publish the Spark 3.5.5 cluster images as multi-architecture
# (linux/amd64 + linux/arm64) manifests.
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

set -euo pipefail

REGISTRY="easewithdata"
TAG="3.5.5_multi_arch"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="multiarch"

cd "$(dirname "$0")"

PUSH=""
if [[ "${1:-}" == "--push" ]]; then
  PUSH="--push"
  echo ">> Images WILL be pushed to ${REGISTRY} as :${TAG}"
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

# Pushing the larger images (pyspark-jupyter is ~2.5 GB per architecture) can
# fail part way through when the connection drops: buildx retries the blob, the
# registry has already expired the upload session, and it surfaces as
# "blob upload unknown to registry". Retrying the whole build is cheap because
# every layer is cached by then -- only the upload repeats.
RETRIES=3

build() {
  local dir="$1" name="$2" attempt=1
  echo
  echo "=============================================================="
  echo ">> Building ${REGISTRY}/${name}:${TAG}  [${PLATFORMS}]"
  echo "=============================================================="
  while :; do
    if docker buildx build \
         --platform "${PLATFORMS}" \
         --build-arg "BASE_TAG=${TAG}" \
         -t "${REGISTRY}/${name}:${TAG}" \
         ${PUSH} \
         "${dir}"; then
      return 0
    fi
    if (( attempt >= RETRIES )); then
      echo ">> ${name}: failed after ${attempt} attempts" >&2
      return 1
    fi
    echo ">> ${name}: attempt ${attempt} failed, retrying..." >&2
    (( attempt++ ))
  done
}

# spark-base must be built and pushed first: master and worker use it as their
# FROM, and buildx resolves that from the registry, not the local cache.
build ./base   spark-base

if [[ -z "${PUSH}" ]]; then
  echo
  echo ">> Stopping after spark-base."
  echo "   master/worker inherit FROM ${REGISTRY}/spark-base:${TAG}, which must"
  echo "   exist in the registry before they can build. Re-run with --push to"
  echo "   build the full set."
  exit 0
fi

build ./master spark-master
build ./worker spark-worker
build ./jupyter pyspark-jupyter

# Verify rather than trust: confirm each published manifest really advertises
# both architectures, so a partial publish cannot pass silently.
echo
echo ">> Verifying published manifests"
rc=0
for n in spark-base spark-master spark-worker pyspark-jupyter; do
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

if (( rc != 0 )); then
  echo >&2
  echo ">> One or more images did not publish both architectures." >&2
  exit 1
fi

echo
echo ">> All images published as ${TAG} for ${PLATFORMS}"
