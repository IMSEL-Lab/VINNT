#!/usr/bin/env bash
# Regenerate golden baseline images for the regression harness.
set -euo pipefail

cd "$(dirname "$0")/.."
PPI=150
mkdir -p tests/golden

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  files=(examples/*/*.typ tests/cases/*.typ)
fi

for src in "${files[@]}"; do
  name="$(basename "${src%.typ}")"
  typst compile --root . --ppi "$PPI" --format png "$src" "tests/golden/${name}.png"
  echo "blessed ${name}"
done

echo "typst $(typst --version | awk '{print $2}') / ${#files[@]} example(s)"
