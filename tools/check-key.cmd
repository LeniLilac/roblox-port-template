@echo off
rem Checks that the Open Cloud key works and shows its owner and permissions, never the key.
setlocal
cd /d "%~dp0.."
if exist .env for /f "usebackq eol=# tokens=1,* delims==" %%A in (".env") do set "%%A=%%B"
lune run tools/lune/check-key.luau
