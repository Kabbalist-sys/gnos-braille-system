@echo off
echo Building Flutter app for production (Android)...

REM Set production environment
set PRODUCTION=true

REM Build Android APK (Production)
echo Building Android APK (Production)...
flutter build apk --release ^
  --dart-define=PRODUCTION=true ^
  --dart-define-from-file=.env.production

if %ERRORLEVEL% neq 0 (
    echo Android APK build failed!
    exit /b 1
)

REM Build Android App Bundle (Production)
echo Building Android App Bundle (Production)...
flutter build appbundle --release ^
  --dart-define=PRODUCTION=true ^
  --dart-define-from-file=.env.production

if %ERRORLEVEL% neq 0 (
    echo Android App Bundle build failed!
    exit /b 1
)

echo Android builds completed successfully!
echo.
echo Production build artifacts:
echo - APK: build\app\outputs\flutter-apk\app-release.apk
echo - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo Next steps:
echo 1. Test APK on physical devices
echo 2. Upload App Bundle to Google Play Console
echo 3. Configure Play Console settings and store listing
echo.
pause
