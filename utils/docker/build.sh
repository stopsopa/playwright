#!/usr/bin/env bash
set -e
set +x

if [[ ($1 == '--help') || ($1 == '-h') || ($1 == '') || ($2 == '') ]]; then
  echo "usage: $(basename $0) {--arm64,--amd64} {jammy,noble} playwright:localbuild-noble"
  echo
  echo "Build Playwright docker image and tag it as 'playwright:localbuild-noble'."
  echo "Once image is built, you can run it with"
  echo ""
  echo "  docker run --rm -it playwright:localbuild-noble /bin/bash"
  echo ""
  echo "NOTE: this requires on Playwright dependencies to be installed with 'npm install'"
  echo "      and Playwright itself being built with 'npm run build'"
  echo ""
  exit 0
fi

function cleanup() {
  rm -f "playwright-core.tar.gz"
}

trap "cleanup; cd $(pwd -P)" EXIT
cd "$(dirname "$0")"

# We rely on `./playwright-core.tar.gz` to download browsers into the docker
# image.
node ../../utils/pack_package.js playwright-core ./playwright-core.tar.gz

PLATFORM=""
if [[ "$1" == "--arm64" ]]; then
  PLATFORM="linux/arm64";
elif [[ "$1" == "--amd64" ]]; then
  PLATFORM="linux/amd64"
else
  echo "ERROR: unknown platform specifier - $1. Only --arm64 or --amd64 is supported"
  exit 1
fi

# force two platforms
PLATFORM="linux/amd64,linux/arm64"

# from: https://unix.stackexchange.com/a/748634
if docker buildx ls | grep -q "multi-platform-builder"; then
  echo "Builder multi-platform-builder already exists."
else
  # Create the builder if it does not exist
  docker buildx create --use --platform="${PLATFORM}" --name multi-platform-builder
  echo "Builder multi-platform-builder created."
fi
docker buildx inspect --bootstrap
docker buildx build --platform="${PLATFORM}" --push --tag "${3}" -f "Dockerfile.${2}" .

# 2. Build and LOAD only the native architecture into your local Docker
# (Docker Desktop will automatically pick the platform matching your Mac)
docker buildx build --load --tag "${3}" -f "Dockerfile.${2}" .
# this way we don't have to do

# docker pull monstersmart/playwright:v1.59.1-noble-just-chromium
# to run locally
# docker image ls
