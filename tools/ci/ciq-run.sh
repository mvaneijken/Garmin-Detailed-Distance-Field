#!/usr/bin/env bash
# Runs a command inside the pinned Connect IQ toolchain image (.ciq-toolchain-image).
#
#   tools/ci/ciq-run.sh [--repo <dir>] [--mount <host-dir>:<container-dir>] -- <command> [args...]
#
# --repo   Repository checkout whose .ciq-toolchain-image / .ciq-sdk-version are used (default: .).
#          It is mounted at /work, which is also the working directory.
# --mount  Extra read-only bind mount (repeatable), e.g. for the signing key directory.
#
# The caller must be logged in to ghcr.io (docker login) with read access to the private package.
set -euo pipefail

repo='.'
mounts=()
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --mount) mounts+=(-v "$2:ro"); shift 2 ;;
    --) shift; break ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ $# -gt 0 ] || { echo "No command given" >&2; exit 2; }

repo="$(cd "$repo" && pwd)"
image="$(grep -v '^[[:space:]]*#' "$repo/.ciq-toolchain-image" | tr -d '[:space:]' || true)"
if ! [[ "$image" =~ ^ghcr\.io/mvaneijken/ciq-toolchain@sha256:[0-9a-f]{64}$ ]]; then
  echo "::error file=.ciq-toolchain-image::No valid toolchain image pinned (expected ghcr.io/mvaneijken/ciq-toolchain@sha256:<digest>). Run tools/toolchain/Publish-CiqToolchainImage.ps1. See docs/CI-CD.md."
  exit 1
fi

docker pull --quiet "$image" >/dev/null

expected_sdk="$(tr -d '[:space:]' < "$repo/.ciq-sdk-version")"
image_sdk="$(docker inspect --format '{{ index .Config.Labels "nl.vaneijken.ciq.sdk-version" }}' "$image")"
if [ "$image_sdk" != "$expected_sdk" ]; then
  echo "::error::Toolchain image has SDK '$image_sdk' but .ciq-sdk-version says '$expected_sdk'. Rebuild the image."
  exit 1
fi

exec docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/home/ciq \
  -e GITHUB_STEP_SUMMARY=/work/.ci-summary.md \
  -v "$repo:/work" \
  "${mounts[@]}" \
  -w /work \
  "$image" "$@"
