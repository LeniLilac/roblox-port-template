@echo off
rem Sets BLENDER_PATH to the newest Blender installed: by its installer (Program
rem Files) or unpacked from the portable zip under
rem %LOCALAPPDATA%\Programs\Blender Foundation\. Called by tools\blender.cmd
rem and tools\blender-mcp.cmd.
set "BLENDER_PATH="
for /f "delims=" %%D in ('dir /b /ad /o-n "%ProgramFiles%\Blender Foundation\Blender *" 2^>nul') do (
  if exist "%ProgramFiles%\Blender Foundation\%%D\blender.exe" (
    set "BLENDER_PATH=%ProgramFiles%\Blender Foundation\%%D\blender.exe"
    exit /b 0
  )
)
for /f "delims=" %%D in ('dir /b /ad /o-n "%LOCALAPPDATA%\Programs\Blender Foundation\blender-*" 2^>nul') do (
  if exist "%LOCALAPPDATA%\Programs\Blender Foundation\%%D\blender.exe" (
    set "BLENDER_PATH=%LOCALAPPDATA%\Programs\Blender Foundation\%%D\blender.exe"
    exit /b 0
  )
)
exit /b 1
