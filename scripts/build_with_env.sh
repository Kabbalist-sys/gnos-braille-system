#!/bin/bash
# Build script for Gnos Braille System with environment-specific configuration
# Usage: ./build_with_env.sh [environment]
# Example: ./build_with_env.sh production

set -e

ENVIRONMENT=${1:-development}

echo "🚀 Building Gnos Braille System for environment: $ENVIRONMENT"

# Check if environment file exists
ENV_FILE=".env.$ENVIRONMENT"
if [ ! -f "$ENV_FILE" ] && [ "$ENVIRONMENT" != "development" ]; then
    echo "❌ Environment file $ENV_FILE not found!"
    echo "Available environment files:"
    ls -1 .env.* 2>/dev/null || echo "  No environment files found"
    exit 1
fi

echo "📋 Environment Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   Debug mode: $([ "$ENVIRONMENT" = "development" ] && echo "true" || echo "false")"

# Set environment variables for build
export ENVIRONMENT="$ENVIRONMENT"

# Build for different platforms
case "${2:-web}" in
    "android")
        echo "🤖 Building Android APK..."
        flutter build apk \
            --dart-define=ENVIRONMENT="$ENVIRONMENT" \
            --release
        echo "✅ Android APK built successfully"
        echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    "android-bundle")
        echo "🤖 Building Android App Bundle..."
        flutter build appbundle \
            --dart-define=ENVIRONMENT="$ENVIRONMENT" \
            --release
        echo "✅ Android App Bundle built successfully"
        echo "📱 AAB location: build/app/outputs/bundle/release/app-release.aab"
        ;;
    "web")
        echo "🌐 Building Web application..."
        flutter build web \
            --dart-define=ENVIRONMENT="$ENVIRONMENT" \
            --release
        echo "✅ Web application built successfully"
        echo "🌐 Web build location: build/web/"
        ;;
    "windows")
        echo "🪟 Building Windows application..."
        flutter build windows \
            --dart-define=ENVIRONMENT="$ENVIRONMENT" \
            --release
        echo "✅ Windows application built successfully"
        echo "🪟 Windows build location: build/windows/runner/Release/"
        ;;
    *)
        echo "❌ Unsupported platform: ${2}"
        echo "Supported platforms: android, android-bundle, web, windows"
        exit 1
        ;;
esac

echo "🎉 Build completed successfully for $ENVIRONMENT environment!"
