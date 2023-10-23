echo off

IF "%~1" == "" goto :error
set VERSION=%1

set DEBUG_INFO_DIR=.\debug_info\%VERSION%\windows

if not exist %DEBUG_INFO_DIR% mkdir %DEBUG_INFO_DIR%
flutter build windows --obfuscate --split-debug-info=%DEBUG_INFO_DIR%
goto :eof

:error
echo "Version cannot be empty"
