@echo off
rem Uploads new or changed files in assets\ to Roblox and regenerates src\shared\assets.luau.
rem The Open Cloud key comes from ASPHALT_API_KEY (your environment or .env); nothing secret
rem is stored in this repo.
rem   tools\assets.cmd                    upload (asphalt sync cloud)
rem   tools\assets.cmd cloud --dry-run    list what would upload, upload nothing
setlocal
cd /d "%~dp0.."
if exist .env for /f "usebackq eol=# tokens=1,* delims==" %%A in (".env") do set "%%A=%%B"
for /f "usebackq eol=# tokens=1,2 delims== " %%A in ("asphalt.toml") do (
  if "%%A"=="id" if "%%B"=="0" (
    echo Set the [creator] type and id in asphalt.toml first. 1>&2
    exit /b 1
  )
)
if "%ASPHALT_API_KEY%"=="" (
  echo ASPHALT_API_KEY is not set. Copy .env.example to .env and add your Open Cloud key. 1>&2
  exit /b 1
)
if "%~1"=="" (
  asphalt sync cloud
) else (
  asphalt sync %*
)
