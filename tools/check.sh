#!/usr/bin/env sh
# Runs the same checks as CI (.github/workflows/check.yml): format, lint, types, build,
# specs (headless, Lune). Exit code 1 if any fails.
#   tools/check.sh        check
#   tools/check.sh fix    format src/ and tests/ in place first, then check
cd "$(dirname "$0")/.." || exit 1
FAIL=0
DEFS=.luau-lsp/globalTypes.d.luau

if [ ! -f "$DEFS" ]; then
  mkdir -p .luau-lsp
  curl -fsSL -o "$DEFS" https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau || {
    echo "Could not download Roblox type definitions." >&2
    exit 1
  }
fi

# Install only when no package folder exists yet: reinstalling deletes and rebuilds them,
# which can crash a running `rojo serve`. Delete both folders to force a reinstall.
FRESH=0
if [ -f wally.lock ] && [ ! -d Packages ] && [ ! -d ServerPackages ]; then
  wally install || exit 1
  FRESH=1
fi

rojo sourcemap default.project.json -o sourcemap.json || exit 1
if [ "$FRESH" = 1 ]; then
  for d in Packages ServerPackages; do
    if [ -d "$d" ]; then wally-package-types --sourcemap sourcemap.json "$d/"; fi
  done
fi

if [ "$1" = fix ]; then stylua src tests; fi

echo "== format (stylua)"
stylua --check src tests || FAIL=1
echo "== lint (selene)"
selene src tests || FAIL=1
echo "== types (luau-lsp)"
luau-lsp analyze --platform=roblox --definitions=@roblox="$DEFS" --sourcemap=sourcemap.json \
  --ignore="Packages/**" --ignore="ServerPackages/**" --ignore="DevPackages/**" \
  --ignore="src/shared/assets.luau" src tests || FAIL=1
echo "== build (rojo)"
rojo build -o check.rbxl || FAIL=1
echo "== specs (lune)"
lune run tools/lune/specs.luau || FAIL=1

if [ "$FAIL" = 1 ]; then
  echo "CHECKS FAILED" >&2
  exit 1
fi
echo "all checks passed"
