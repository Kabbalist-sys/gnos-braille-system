@echo off
REM Local secrets validation script - shows what will be checked

echo.
echo 🔍 Gnos Braille System - Expected GitHub Secrets
echo =================================================
echo.

echo 🔥 Firebase Development Secrets:
echo   - FIREBASE_API_KEY_DEV
echo   - FIREBASE_AUTH_DOMAIN_DEV
echo   - FIREBASE_PROJECT_ID_DEV
echo   - FIREBASE_STORAGE_BUCKET_DEV
echo   - FIREBASE_MESSAGING_SENDER_ID_DEV
echo   - FIREBASE_APP_ID_DEV
echo   - FIREBASE_MEASUREMENT_ID_DEV
echo.

echo 🚀 Firebase Production Secrets:
echo   - FIREBASE_API_KEY_PROD
echo   - FIREBASE_AUTH_DOMAIN_PROD
echo   - FIREBASE_PROJECT_ID_PROD
echo   - FIREBASE_STORAGE_BUCKET_PROD
echo   - FIREBASE_MESSAGING_SENDER_ID_PROD
echo   - FIREBASE_APP_ID_PROD
echo   - FIREBASE_MEASUREMENT_ID_PROD
echo.

echo 🔐 Firebase Service Account:
echo   - FIREBASE_SERVICE_ACCOUNT_DEV (Base64 encoded JSON)
echo   - FIREBASE_SERVICE_ACCOUNT_PROD (Base64 encoded JSON)
echo.

echo 🤖 Android Build Secrets:
echo   - ANDROID_KEYSTORE_BASE64 (Base64 encoded .jks file)
echo   - ANDROID_KEYSTORE_PROPERTIES (key.properties content)
echo   - ANDROID_KEY_ALIAS
echo   - ANDROID_KEY_PASSWORD
echo   - ANDROID_STORE_PASSWORD
echo.

echo 🔑 API Keys:
echo   - BRAILLE_API_KEY
echo   - ENCRYPTION_KEY
echo.

echo 📱 Optional Notification Webhooks:
echo   - SLACK_WEBHOOK_URL
echo   - TEAMS_WEBHOOK_URL
echo.

echo ⚠️  STATUS: Repository not connected to GitHub yet
echo    Please follow the instructions in github_setup_instructions.md
echo.

echo 🚀 Next Steps:
echo 1. Create GitHub repository
echo 2. Push code to GitHub  
echo 3. Run: setup-github-secrets.bat
echo 4. Trigger 'Validate Secrets' workflow in GitHub Actions
echo.

pause
