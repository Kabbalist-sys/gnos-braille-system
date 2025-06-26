@echo off
echo Deploying to Firebase (Production)...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    exit /b 1
)

REM Login check
echo Checking Firebase authentication...
firebase projects:list >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Please login to Firebase first:
    firebase login
    exit /b 1
)

REM Deploy Firestore rules
echo Deploying Firestore security rules...
firebase deploy --only firestore:rules
if %ERRORLEVEL% neq 0 (
    echo Firestore rules deployment failed!
    exit /b 1
)

REM Deploy Storage rules
echo Deploying Storage security rules...
firebase deploy --only storage
if %ERRORLEVEL% neq 0 (
    echo Storage rules deployment failed!
    exit /b 1
)

REM Deploy Web app (if build exists)
if exist "build\web\" (
    echo Deploying Web app to Firebase Hosting...
    firebase deploy --only hosting
    if %ERRORLEVEL% neq 0 (
        echo Hosting deployment failed!
        exit /b 1
    )
) else (
    echo Web build not found. Run build_production_web.bat first.
)

echo.
echo Firebase deployment completed successfully!
echo.
echo Deployed components:
echo - Firestore security rules
echo - Storage security rules
echo - Web app (if available)
echo.
echo Next steps:
echo 1. Verify deployment in Firebase Console
echo 2. Test all functionality in production
echo 3. Monitor Firebase Console for errors
echo 4. Update DNS settings if using custom domain
echo.
pause
