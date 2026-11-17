#!/usr/bin/env sh
# Runs the specs in tests/ headless with Lune (tools/lune/specs.luau), no Studio needed.
#   tools/test.sh              every spec
#   tools/test.sh Save Shop    only specs whose name contains one of the words
# Exit code 1 if a spec fails or errors.
set -e
cd "$(dirname "$0")/.."
exec lune run tools/lune/specs.luau "$@"
