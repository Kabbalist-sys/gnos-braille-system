@echo off
REM Windows batch script version of the GitHub secrets setup helper

echo.
echo 🚀 GitHub Secrets Setup Helper for Gnos Braille System
echo ==================================================
echo.

REM Add GitHub CLI to PATH
set "PATH=%PATH%;C:\Program Files\GitHub CLI"

REM Check if GitHub CLI is installed
gh --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ GitHub CLI is not installed.
    echo Please install it from: https://cli.github.com/
    pause
    exit /b 1
)

REM Check if user is authenticated
gh auth status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ⚠️  You are not authenticated with GitHub CLI.
    echo Please run: gh auth login
    pause
    exit /b 1
)

echo ✅ GitHub CLI is ready!
echo.

REM Get repository information
for /f "tokens=*" %%i in ('gh repo view --json nameWithOwner -q .nameWithOwner') do set REPO=%%i
echo 📁 Repository: %REPO%
echo.

echo 🔥 Firebase Development Configuration
echo ==================================================
call :set_secret "FIREBASE_API_KEY_DEV" "Firebase Web API Key (Development)"
call :set_secret "FIREBASE_AUTH_DOMAIN_DEV" "Firebase Auth Domain (Development)"
call :set_secret "FIREBASE_PROJECT_ID_DEV" "Firebase Project ID (Development)"
call :set_secret "FIREBASE_STORAGE_BUCKET_DEV" "Firebase Storage Bucket (Development)"
call :set_secret "FIREBASE_MESSAGING_SENDER_ID_DEV" "Firebase Messaging Sender ID (Development)"
call :set_secret "FIREBASE_APP_ID_DEV" "Firebase App ID (Development)"
call :set_secret "FIREBASE_MEASUREMENT_ID_DEV" "Firebase Analytics Measurement ID (Development)"

echo.
echo 🔥 Firebase Production Configuration
echo ==================================================
call :set_secret "FIREBASE_API_KEY_PROD" "Firebase Web API Key (Production)"
call :set_secret "FIREBASE_AUTH_DOMAIN_PROD" "Firebase Auth Domain (Production)"
call :set_secret "FIREBASE_PROJECT_ID_PROD" "Firebase Project ID (Production)"
call :set_secret "FIREBASE_STORAGE_BUCKET_PROD" "Firebase Storage Bucket (Production)"
call :set_secret "FIREBASE_MESSAGING_SENDER_ID_PROD" "Firebase Messaging Sender ID (Production)"
call :set_secret "FIREBASE_APP_ID_PROD" "Firebase App ID (Production)"
call :set_secret "FIREBASE_MEASUREMENT_ID_PROD" "Firebase Analytics Measurement ID (Production)"

echo.
echo 🔧 API Configuration
echo ==================================================
call :set_secret "BRAILLE_API_URL_DEV" "Braille API Base URL (Development)"
call :set_secret "BRAILLE_API_URL_PROD" "Braille API Base URL (Production)"

echo.
echo 🔑 Firebase CLI Authentication
echo ==================================================
echo To get Firebase CI token, run: firebase login:ci
call :set_secret "FIREBASE_TOKEN" "Firebase CI Token"

echo.
echo 📱 Android App Signing
echo ==================================================
echo For Android keystore setup, see GITHUB_SECRETS_SETUP.md
call :set_secret "ANDROID_KEYSTORE_BASE64" "Base64 encoded keystore file"
call :set_secret "ANDROID_KEYSTORE_PASSWORD" "Keystore password"
call :set_secret "ANDROID_KEY_ALIAS" "Key alias name"
call :set_secret "ANDROID_KEY_PASSWORD" "Key password"

echo.
echo 🛡️ Optional Security Tools
echo ==================================================
call :set_secret "SEMGREP_APP_TOKEN" "Semgrep security scanning token (optional)"
call :set_secret "CODECOV_TOKEN" "Codecov upload token (optional)"

echo.
echo 🎉 Setup complete!
echo.
echo Next steps:
echo 1. Verify all secrets are set: gh secret list
echo 2. Test the CI/CD pipeline by pushing a commit
echo 3. Check GitHub Actions tab for workflow execution
echo.
echo For detailed setup instructions, see GITHUB_SECRETS_SETUP.md
echo.
pause
exit /b 0

:set_secret
set secret_name=%~1
set description=%~2
echo.
echo 🔐 Setting up: %secret_name%
echo Description: %description%
set /p secret_value=Enter value (or press Enter to skip): 

if not "%secret_value%"=="" (
    echo %secret_value% | gh secret set %secret_name%
    if %ERRORLEVEL% equ 0 (
        echo ✅ %secret_name% set successfully
    ) else (
        echo ❌ Failed to set %secret_name%
    )
) else (
    echo ⏭️  Skipped %secret_name%
)
goto :eof
