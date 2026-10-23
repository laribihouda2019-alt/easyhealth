@echo off
echo Killing all Chrome processes...
taskkill /F /IM chrome.exe >nul 2>&1

echo Cleaning Flutter cache...
flutter clean >nul 2>&1

echo Removing build directories...
if exist build rmdir /s /q build >nul 2>&1
if exist .dart_tool rmdir /s /q .dart_tool >nul 2>&1

echo Getting dependencies...
flutter pub get

echo Starting Flutter app on Chrome...
flutter run -d chrome --web-port=8080

pause
