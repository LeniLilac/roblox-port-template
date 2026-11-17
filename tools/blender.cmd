@echo off
rem Runs the newest installed Blender with online access on (the MCP add-on
rem only opens its socket then), passing on any arguments:
rem   tools\blender.cmd                                   the window, for the MCP server
rem   tools\blender.cmd -b file.blend -P script.py        headless, running a script
setlocal
call "%~dp0find-blender.cmd"
if not defined BLENDER_PATH (
  echo Blender not found. Install it: winget install BlenderFoundation.Blender 1>&2
  exit /b 1
)
"%BLENDER_PATH%" --online-mode %*
