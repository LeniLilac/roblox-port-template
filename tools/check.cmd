@echo off
rem Runs the same checks as CI (.github/workflows/check.yml): format, lint, types, build,
rem specs (headless, Lune). Exit code 1 if any fails.
rem   tools\check.cmd        check
rem   tools\check.cmd fix    format src\ and tests\ in place first, then check
setlocal
cd /d "%~dp0.."
set "FAIL=0"
set "DEFS=.luau-lsp\globalTypes.d.luau"

if not exist "%DEFS%" (
  if not exist .luau-lsp mkdir .luau-lsp
  curl -fsSL -o "%DEFS%" https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau
  if errorlevel 1 (
    echo Could not download Roblox type definitions. 1>&2
    exit /b 1
  )
)

rem Install only when no package folder exists yet: reinstalling deletes and rebuilds them,
rem which can crash a running `rojo serve`. Delete both folders to force a reinstall.
set "FRESH=0"
if exist wally.lock if not exist Packages if not exist ServerPackages (
  wally install || exit /b 1
  set "FRESH=1"
)

rojo sourcemap default.project.json -o sourcemap.json || exit /b 1
if "%FRESH%"=="1" (
  if exist Packages wally-package-types --sourcemap sourcemap.json Packages/
  if exist ServerPackages wally-package-types --sourcemap sourcemap.json ServerPackages/
)

if /i "%~1"=="fix" stylua src tests

echo == format (stylua)
stylua --check src tests || set "FAIL=1"
echo == lint (selene)
selene src tests || set "FAIL=1"
echo == types (luau-lsp)
luau-lsp analyze --platform=roblox --definitions=@roblox=%DEFS% --sourcemap=sourcemap.json --ignore="Packages/**" --ignore="ServerPackages/**" --ignore="DevPackages/**" --ignore="src/shared/assets.luau" src tests || set "FAIL=1"
echo == build (rojo)
rojo build -o check.rbxl || set "FAIL=1"
echo == specs (lune)
lune run tools/lune/specs.luau || set "FAIL=1"

if "%FAIL%"=="1" (
  echo CHECKS FAILED 1>&2
  exit /b 1
)
echo all checks passed
