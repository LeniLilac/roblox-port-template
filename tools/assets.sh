#!/usr/bin/env sh
# Uploads new or changed files in assets/ to Roblox and regenerates src/shared/assets.luau.
# The Open Cloud key comes from ASPHALT_API_KEY (your environment or .env).
#   tools/assets.sh                    upload (asphalt sync cloud)
#   tools/assets.sh cloud --dry-run    list what would upload, upload nothing
set -e
cd "$(dirname "$0")/.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
if grep -q '^id = 0[[:space:]]*$' asphalt.toml; then
  echo "Set the [creator] type and id in asphalt.toml first." >&2
  exit 1
fi
if [ -z "$ASPHALT_API_KEY" ]; then
  echo "ASPHALT_API_KEY is not set. Copy .env.example to .env and add your Open Cloud key." >&2
  exit 1
fi
if [ $# -eq 0 ]; then
  exec asphalt sync cloud
else
  exec asphalt sync "$@"
fi
