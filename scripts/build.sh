#!/bin/bash
set -euo pipefail

IMAGE_NAME="devops-tool"

echo "Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

echo "Smoke test: help"
docker run --rm "$IMAGE_NAME" help

echo "Smoke test: system-info"
docker run --rm "$IMAGE_NAME" system-info

echo "Smoke test: invalid command should return exit code 2"
set +e
docker run --rm "$IMAGE_NAME" invalid-command
status=$?
set -e

if [[ "$status" -ne 2 ]]; then
    echo "Smoke test failed: expected exit code 2, got $status." >&2
    exit 1
fi

echo "Docker build and smoke tests passed."
