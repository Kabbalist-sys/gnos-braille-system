@echo off
echo Building Flutter web app for production...

REM Set production environment
set PRODUCTION=true

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
flutter pub get

REM Build Web app (Production)
echo Building Web app (Production)...
flutter build web --release ^
  --dart-define=PRODUCTION=true ^
  --dart-define-from-file=.env.production ^
  --web-renderer canvaskit

if %ERRORLEVEL% neq 0 (
    echo Web build failed!
    exit /b 1
)

echo Web build completed successfully!
echo.
echo Production build artifacts:
echo - Web app: build\web\
echo.
echo Next steps:
echo 1. Test the web build locally: flutter run -d web-server --web-port 8080
echo 2. Deploy to Firebase Hosting: run deploy_firebase_production.bat
echo 3. Configure custom domain (if needed)
echo.
pause
