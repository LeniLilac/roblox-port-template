#!/usr/bin/env sh
# Checks that the Open Cloud key works and shows its owner and permissions, never the key.
set -e
cd "$(dirname "$0")/.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
exec lune run tools/lune/check-key.luau
