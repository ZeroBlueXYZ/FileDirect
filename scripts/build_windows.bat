echo off

if "%~1" == "" goto :error
if "%~2" == "" goto :error
set BUILD_NAME=%1
set BUILD_NUMBER=%2

set DEBUG_INFO_DIR=.\debug_info\%BUILD_NAME%+%BUILD_NUMBER%\windows

if not exist %DEBUG_INFO_DIR% mkdir %DEBUG_INFO_DIR%
flutter build windows --obfuscate --split-debug-info=%DEBUG_INFO_DIR% --build-name=%BUILD_NAME% --build-number=%BUILD_NUMBER%
goto :eof

:error
echo "Both build name and build number must be specified"
