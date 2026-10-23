@echo off
echo ============================================
echo Application des Modifications EasyHealth
echo ============================================

echo.
echo 1. Verification des fichiers Backend...
cd backend

echo Verification du controller auth...
if not exist controllers\correctedAuthController.js (
    echo Creation du controller auth corrige...
    copy nul controllers\correctedAuthController.js
) else (
    echo Controller auth existe deja
)

echo Verification du script SQL...
if not exist fix_existing_tables.sql (
    echo Le script SQL n'existe pas!
    pause
    exit /b 1
) else (
    echo Script SQL trouve
)

echo.
echo 2. Verification des fichiers Frontend...
cd ..\fronten

echo Verification de la config API...
if exist lib\config\api_config.dart (
    echo Mise a jour de la configuration API...
    powershell -Command "(Get-Content lib\config\api_config.dart) -replace 'localhost:4000', 'localhost:4001' | Set-Content lib\config\api_config.dart"
)

echo Verification du service auth...
if exist lib\services\auth_service.dart (
    echo Le service auth existe
)

echo Verification du service API...
if exist lib\services\api_service.dart (
    echo Le service API existe
)

echo.
echo 3. Nettoyage et preparation...
echo Nettoyage des anciens builds...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool

echo.
echo 4. Instructions pour l'utilisateur:
echo.
echo ============================================
echo ETAPES SUIVANTES MANUELLES:
echo ============================================
echo.
echo 1. BASE DE DONNEES:
echo    - Ouvrir pgAdmin
echo    - Se connecter a easyhealth_f
echo    - Executer le script: fix_existing_tables.sql
echo.
echo 2. BACKEND:
echo    - cd backend
echo    - node server.js
echo.
echo 3. FRONTEND:
echo    - cd fronten
echo    - flutter run -d chrome --web-port=8080
echo.
echo ============================================
echo MODIFICATIONS PRETES!
echo ============================================

pause
