@echo off
echo Setting up Production Environment for Gnos Braille System...
echo.

REM Check if .env.production exists
if not exist ".env.production" (
    echo Creating .env.production from template...
    copy ".env.production.example" ".env.production"
    echo.
    echo IMPORTANT: Please edit .env.production and fill in your actual production values!
    echo Press any key to open the file for editing...
    pause >nul
    notepad .env.production
) else (
    echo .env.production already exists.
)

echo.
echo Checking Flutter dependencies...
flutter pub get

echo.
echo Running static analysis...
flutter analyze

echo.
echo Checking Firebase CLI...
firebase --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo WARNING: Firebase CLI not found!
    echo Please install it with: npm install -g firebase-tools
    echo Then run: firebase login
) else (
    echo Firebase CLI is installed.
    echo.
    echo Checking Firebase authentication...
    firebase projects:list >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo.
        echo Please login to Firebase: firebase login
    ) else (
        echo Firebase authentication OK.
    )
)

echo.
echo Production Environment Setup Complete!
echo.
echo Next steps:
echo 1. Edit .env.production with your Firebase production credentials
echo 2. Create/configure your Firebase production project
echo 3. Deploy security rules: firebase deploy --only firestore:rules,storage
echo 4. Build for production: build_production_web.bat or build_production_android.bat
echo 5. Deploy to hosting: deploy_firebase_production.bat
echo.
echo For detailed instructions, see PRODUCTION_DEPLOYMENT.md
echo.
pause
