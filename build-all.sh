#!/bin/bash
# build-all.sh — Build and optionally push all Goat image profiles.
#
# Usage:
#   ./build-all.sh              # build all locally (no push)
#   ./build-all.sh --push       # build all + push to ghcr.io/goatcommunity/goat
#   ./build-all.sh light        # build only light locally
#   ./build-all.sh light --push # build light + push

set -e

REGISTRY="ghcr.io/goatcommunity/goat"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION=${VERSION:-"local"}
TAG=${TAG:-"local"}

PUSH=false
PROFILES=()

for arg in "$@"; do
  case "$arg" in
    --push) PUSH=true ;;
    full|light|recon) PROFILES+=("$arg") ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# Default: build all
if [[ ${#PROFILES[@]} -eq 0 ]]; then
  PROFILES=(light recon full)
fi

DOCKERFILE_MAP=(
  "full:Dockerfile"
  "light:light.dockerfile"
  "recon:recon.dockerfile"
)

echo "=== Goat Image Builder ==="
echo "Registry: $REGISTRY"
echo "Profiles: ${PROFILES[*]}"
echo "Push:     $PUSH"
echo ""

for profile in "${PROFILES[@]}"; do
  # Find dockerfile for this profile
  dockerfile=""
  for entry in "${DOCKERFILE_MAP[@]}"; do
    p="${entry%%:*}"
    d="${entry##*:}"
    if [[ "$p" == "$profile" ]]; then
      dockerfile="$d"
      break
    fi
  done

  if [[ -z "$dockerfile" ]]; then
    echo "[!] Unknown profile: $profile" >&2
    exit 1
  fi

  local_tag="goat:${profile}"
  registry_tag="${REGISTRY}:${profile}"

  echo "--- Building $profile ---"
  echo "  Dockerfile: $dockerfile"
  echo "  Local tag:  $local_tag"
  echo "  Registry:   $registry_tag"
  echo ""

  docker build \
    -f "$dockerfile" \
    -t "$local_tag" \
    -t "$registry_tag" \
    --build-arg TAG="$profile" \
    --build-arg VERSION="$VERSION" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg BUILD_PROFILE="$profile" \
    .

  echo ""
  echo "[+] Built: $local_tag"

  if [[ "$PUSH" == "true" ]]; then
    echo "[*] Pushing $registry_tag..."
    docker push "$registry_tag"
    echo "[+] Pushed: $registry_tag"
  fi

  echo ""
done

echo "=== Done ==="
if [[ "$PUSH" == "false" ]]; then
  echo ""
  echo "To push to GHCR:"
  echo "  docker login ghcr.io"
  echo "  ./build-all.sh --push"
fi
