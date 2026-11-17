@echo off
rem Launches the Roblox Studio MCP server (StudioMCP.exe) from the newest
rem installed Studio version. Studio's own %LOCALAPPDATA%\Roblox\mcp.bat
rem hardcodes a version folder and goes stale when Studio auto-updates.
setlocal
set "VERSIONS=%LOCALAPPDATA%\Roblox\Versions"
for /f "delims=" %%D in ('dir /b /ad /o-d "%VERSIONS%\version-*" 2^>nul') do (
  if exist "%VERSIONS%\%%D\StudioMCP.exe" (
    "%VERSIONS%\%%D\StudioMCP.exe" %*
    exit /b
  )
)
echo StudioMCP.exe not found under %VERSIONS%. Install or update Roblox Studio. 1>&2
exit /b 1
