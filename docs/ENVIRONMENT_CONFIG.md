# Environment Configuration Guide

This guide explains how to use the environment configuration system in the Gnos Braille System.

## Overview

The environment configuration system allows you to manage different settings for different environments (development, staging, production) through environment variables and configuration files.

## Environment Files

The project includes several environment configuration files:

- `.env.template` - Template with all available environment variables
- `.env.staging` - Staging environment configuration
- `.env.production` - Production environment configuration

## Environment Variables

### Firebase Configuration
- `FIREBASE_API_KEY_PROD` - Firebase API key for production
- `FIREBASE_AUTH_DOMAIN_PROD` - Firebase auth domain
- `FIREBASE_PROJECT_ID_PROD` - Firebase project ID
- `FIREBASE_STORAGE_BUCKET_PROD` - Firebase storage bucket
- `FIREBASE_MESSAGING_SENDER_ID_PROD` - Firebase messaging sender ID
- `FIREBASE_APP_ID_PROD` - Firebase app ID
- `FIREBASE_MEASUREMENT_ID_PROD` - Firebase measurement ID (Analytics)

### API Configuration
- `BRAILLE_API_URL_PROD` - Braille translation API URL
- `API_TIMEOUT_PROD` - API request timeout in milliseconds
- `API_RETRY_ATTEMPTS_PROD` - Number of retry attempts for failed API calls
- `API_RETRY_DELAY_PROD` - Delay between retry attempts in milliseconds

### Feature Flags
- `ENABLE_ANALYTICS` - Enable Google Analytics (true/false)
- `ENABLE_CRASHLYTICS` - Enable Firebase Crashlytics (true/false)
- `ENABLE_PERFORMANCE_MONITORING` - Enable Firebase Performance Monitoring (true/false)
- `ENABLE_DEBUG_LOGGING` - Enable debug logging (true/false)
- `ENABLE_OFFLINE_MODE` - Enable offline functionality (true/false)
- `ENABLE_VOICE_FEEDBACK` - Enable voice feedback (true/false)
- `ENABLE_HAPTIC_FEEDBACK` - Enable haptic feedback (true/false)

### Security Settings
- `MAX_TRANSLATION_LENGTH` - Maximum length for text translation
- `MAX_EXPORT_SIZE` - Maximum size for export operations in bytes
- `SESSION_TIMEOUT` - User session timeout in milliseconds
- `MAX_LOGIN_ATTEMPTS` - Maximum failed login attempts before lockout
- `PASSWORD_MIN_LENGTH` - Minimum password length
- `ENFORCE_2FA` - Enforce two-factor authentication (true/false)

### Rate Limiting
- `MAX_REQUESTS_PER_MINUTE` - Maximum API requests per minute
- `MAX_TRANSLATIONS_PER_HOUR` - Maximum translations per hour
- `MAX_EXPORTS_PER_DAY` - Maximum exports per day

### Cache Settings
- `CACHE_TTL` - Cache time-to-live in milliseconds
- `MAX_CACHE_SIZE` - Maximum cache size in bytes
- `ENABLE_DISK_CACHE` - Enable disk caching (true/false)

### Accessibility Settings
- `DEFAULT_FONT_SIZE` - Default font size
- `MAX_FONT_SIZE` - Maximum font size
- `MIN_FONT_SIZE` - Minimum font size
- `DEFAULT_CONTRAST_RATIO` - Default contrast ratio
- `SCREEN_READER_TIMEOUT` - Screen reader timeout in milliseconds

### Braille Translation Settings
- `DEFAULT_BRAILLE_GRADE` - Default Braille grade (1, 2, or 3)
- `SUPPORT_GRADE_1` - Support Braille Grade 1 (true/false)
- `SUPPORT_GRADE_2` - Support Braille Grade 2 (true/false)
- `SUPPORT_GRADE_3` - Support Braille Grade 3 (true/false)
- `MAX_BRAILLE_CELLS_PER_LINE` - Maximum Braille cells per line

### OCR Settings
- `OCR_CONFIDENCE_THRESHOLD` - OCR confidence threshold (0.0 to 1.0)
- `OCR_MAX_IMAGE_SIZE` - Maximum image size for OCR in bytes
- `SUPPORTED_IMAGE_FORMATS` - Supported image formats (comma-separated)

## Usage in Code

### Accessing Configuration Values

```dart
import 'package:gnos_braille_system/config/environment_config.dart';

// Check current environment
bool isProduction = EnvironmentConfig.isProduction;
bool isStaging = EnvironmentConfig.isStaging;
bool isDevelopment = EnvironmentConfig.isDevelopment;

// Access configuration values
String apiUrl = EnvironmentConfig.brailleApiUrl;
int timeout = EnvironmentConfig.apiTimeout;
bool analyticsEnabled = EnvironmentConfig.enableAnalytics;

// Firebase configuration
String firebaseProjectId = EnvironmentConfig.firebaseProjectId;
String firebaseApiKey = EnvironmentConfig.firebaseApiKey;
```

### Configuration Validation

```dart
// Validate configuration at app startup
if (!EnvironmentConfig.validateConfig()) {
    // Handle invalid configuration
    print('Configuration validation failed');
}

// Print configuration for debugging
EnvironmentConfig.printConfig();
```

## Building with Environment Variables

### Using Dart Define

```bash
# Build for production
flutter build web --dart-define=ENVIRONMENT=production

# Build for staging
flutter build android --dart-define=ENVIRONMENT=staging

# Build for development (default)
flutter build apk
```

### Using Build Scripts

We provide convenient build scripts for different platforms:

**Linux/macOS:**
```bash
# Build web for production
./scripts/build_with_env.sh production web

# Build Android for staging
./scripts/build_with_env.sh staging android

# Build Windows for development
./scripts/build_with_env.sh development windows
```

**Windows:**
```batch
REM Build web for production
scripts\build_with_env.bat production web

REM Build Android for staging
scripts\build_with_env.bat staging android

REM Build Windows for development
scripts\build_with_env.bat development windows
```

## CI/CD Integration

The environment configuration is integrated with GitHub Actions workflows:

### Secrets Management

Set the following secrets in your GitHub repository:

1. **Firebase Configuration:**
   - `FIREBASE_API_KEY_PROD`
   - `FIREBASE_AUTH_DOMAIN_PROD`
   - `FIREBASE_PROJECT_ID_PROD`
   - `FIREBASE_STORAGE_BUCKET_PROD`
   - `FIREBASE_MESSAGING_SENDER_ID_PROD`
   - `FIREBASE_APP_ID_PROD`
   - `FIREBASE_MEASUREMENT_ID_PROD`

2. **API Configuration:**
   - `BRAILLE_API_URL_PROD`

3. **Other production-specific secrets as needed**

### Workflow Configuration

The CI/CD workflows automatically use environment variables for builds:

```yaml
- name: Build production Android
  run: |
    flutter build appbundle \
      --dart-define=ENVIRONMENT=production \
      --dart-define=FIREBASE_API_KEY_PROD=${{ secrets.FIREBASE_API_KEY_PROD }} \
      --dart-define=FIREBASE_PROJECT_ID_PROD=${{ secrets.FIREBASE_PROJECT_ID_PROD }}
```

## Environment Detection

The app automatically detects the environment and adjusts behavior:

- **Development:** Debug logging enabled, debug banner shown, relaxed security
- **Staging:** Some debug features enabled, testing configurations
- **Production:** Full security, analytics enabled, debug features disabled

## Best Practices

1. **Never commit sensitive values** to environment files in the repository
2. **Use GitHub Secrets** for production configuration in CI/CD
3. **Validate configuration** at app startup
4. **Use appropriate logging levels** for each environment
5. **Test configuration changes** in staging before production
6. **Keep environment files in sync** with available configuration options

## Troubleshooting

### Configuration Validation Errors

If you see validation errors:

1. Check that all required environment variables are set
2. Ensure values don't contain placeholder text like "your_api_key_here"
3. Verify environment files exist and have correct format
4. Check GitHub Secrets are properly configured for CI/CD

### Build Issues

If builds fail with environment-related errors:

1. Verify the `ENVIRONMENT` dart-define parameter is set correctly
2. Check that environment files exist for the specified environment
3. Ensure all required environment variables are properly substituted
4. Review build logs for specific missing variables

For more detailed information, see the main [README.md](../README.md) and [PUBLISHING.md](../PUBLISHING.md) documentation.
