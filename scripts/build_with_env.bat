@echo off
REM Build script for Gnos Braille System with environment-specific configuration
REM Usage: build_with_env.bat [environment] [platform]
REM Example: build_with_env.bat production android

setlocal enabledelayedexpansion

set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=development

set PLATFORM=%2
if "%PLATFORM%"=="" set PLATFORM=web

echo 🚀 Building Gnos Braille System for environment: %ENVIRONMENT%

REM Check if environment file exists
set ENV_FILE=.env.%ENVIRONMENT%
if not exist "%ENV_FILE%" if not "%ENVIRONMENT%"=="development" (
    echo ❌ Environment file %ENV_FILE% not found!
    echo Available environment files:
    dir /b .env.* 2>nul || echo   No environment files found
    exit /b 1
)

echo 📋 Environment Configuration:
echo    Environment: %ENVIRONMENT%
if "%ENVIRONMENT%"=="development" (
    echo    Debug mode: true
) else (
    echo    Debug mode: false
)

REM Build for different platforms
if "%PLATFORM%"=="android" (
    echo 🤖 Building Android APK...
    flutter build apk --dart-define=ENVIRONMENT=%ENVIRONMENT% --release
    if !errorlevel! equ 0 (
        echo ✅ Android APK built successfully
        echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    ) else (
        echo ❌ Android build failed
        exit /b 1
    )
) else if "%PLATFORM%"=="android-bundle" (
    echo 🤖 Building Android App Bundle...
    flutter build appbundle --dart-define=ENVIRONMENT=%ENVIRONMENT% --release
    if !errorlevel! equ 0 (
        echo ✅ Android App Bundle built successfully
        echo 📱 AAB location: build\app\outputs\bundle\release\app-release.aab
    ) else (
        echo ❌ Android App Bundle build failed
        exit /b 1
    )
) else if "%PLATFORM%"=="web" (
    echo 🌐 Building Web application...
    flutter build web --dart-define=ENVIRONMENT=%ENVIRONMENT% --release
    if !errorlevel! equ 0 (
        echo ✅ Web application built successfully
        echo 🌐 Web build location: build\web\
    ) else (
        echo ❌ Web build failed
        exit /b 1
    )
) else if "%PLATFORM%"=="windows" (
    echo 🪟 Building Windows application...
    flutter build windows --dart-define=ENVIRONMENT=%ENVIRONMENT% --release
    if !errorlevel! equ 0 (
        echo ✅ Windows application built successfully
        echo 🪟 Windows build location: build\windows\runner\Release\
    ) else (
        echo ❌ Windows build failed
        exit /b 1
    )
) else (
    echo ❌ Unsupported platform: %PLATFORM%
    echo Supported platforms: android, android-bundle, web, windows
    exit /b 1
)

echo 🎉 Build completed successfully for %ENVIRONMENT% environment!
endlocal
