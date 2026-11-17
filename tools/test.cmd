@echo off
rem Runs the specs in tests\ headless with Lune (tools\lune\specs.luau), no Studio needed.
rem   tools\test.cmd              every spec
rem   tools\test.cmd Save Shop    only specs whose name contains one of the words
rem Exit code 1 if a spec fails or errors.
setlocal
cd /d "%~dp0.."
lune run tools/lune/specs.luau %*
