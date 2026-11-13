#!/usr/bin/env bash
# Run the gdUnit4 test suite headless.
# Usage: GODOT_BIN=/path/to/godot ./run_tests.sh [extra gdUnit4 args]
# Default runs everything under res://tests.
set -euo pipefail
cd "$(dirname "$0")"

GODOT_BIN="${GODOT_BIN:-$(command -v godot || command -v godot4 || true)}"
if [ -z "$GODOT_BIN" ]; then
    echo "Set GODOT_BIN to your Godot 4.7 executable." >&2
    exit 1
fi

# Import first so class_name caches and .uid files exist on a fresh clone.
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1 || true

if [ $# -eq 0 ]; then
    set -- -a res://tests
fi
# --continue: report every failing test instead of stopping at the first.
exec ./addons/gdUnit4/runtest.sh --godot_binary "$GODOT_BIN" --headless --ignoreHeadlessMode --continue "$@"
