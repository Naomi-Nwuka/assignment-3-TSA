#!/bin/bash
set -euo pipefail

required_files=(
    "README.md"
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    "Dockerfile"
    "compose.yaml"
    ".dockerignore"
    ".github/workflows/ci.yml"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Lint failed: required file missing: $file" >&2
        exit 1
    fi
done

for script in app/*.sh scripts/*.sh tests/*.sh; do
    bash -n "$script"
done

echo "Lint passed: required files exist and Bash syntax is valid."
