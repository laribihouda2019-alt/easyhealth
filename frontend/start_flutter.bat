@echo off
echo Starting EasyHealth Flutter App...

REM Kill any existing Chrome processes
echo Killing Chrome processes...
taskkill /F /IM chrome.exe >nul 2>&1

REM Clean Flutter
echo Cleaning Flutter...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Remove problematic directories
echo Removing problematic directories...
if exist linux rmdir /s /q linux >nul 2>&1
if exist build rmdir /s /q build >nul 2>&1
if exist .dart_tool rmdir /s /q .dart_tool >nul 2>&1

REM Start Flutter with specific port
echo Starting Flutter on port 8080...
flutter run -d chrome --web-port=8080 --web-hostname=localhost

pause
