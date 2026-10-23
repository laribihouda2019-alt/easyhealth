@echo off
cd /d "%~dp0"
echo Start AI API in another terminal: python app.py
echo.
echo Then run: ngrok http 5000
echo.
echo Update fronten\lib\config\api_config.dart with the ngrok URL (aiBaseUrl)
