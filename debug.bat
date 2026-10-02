@echo off
cd /d %~dp0
if exist ja_translate.exe (
    start "" "ja_translate.exe" -debug
    exit
)
for %%i in (*.exe) do (
    start "" "%%i" -debug
    exit
)
