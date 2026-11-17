@echo off
rem Launches Blender Lab's official MCP server (blender-mcp; install it as in
rem docs/workflows.md). It talks to the MCP add-on inside a running Blender
rem (start one with tools\blender.cmd) and runs background Blenders itself
rem for the *_for_cli tools, from the newest Blender installed.
setlocal
call "%~dp0find-blender.cmd"
where blender-mcp >nul 2>nul
if not errorlevel 1 (
  blender-mcp %*
  exit /b
)
if exist "%USERPROFILE%\.local\bin\blender-mcp.exe" (
  "%USERPROFILE%\.local\bin\blender-mcp.exe" %*
  exit /b
)
echo blender-mcp not found. See docs/workflows.md to install it. 1>&2
exit /b 1
