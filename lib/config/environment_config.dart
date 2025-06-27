import 'package:flutter/foundation.dart';

/// Environment Configuration Manager
/// Manages environment-specific settings for the Gnos Braille System
class EnvironmentConfig {
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  // Environment detection
  static bool get isProduction => _environment == 'production';
  static bool get isStaging => _environment == 'staging';
  static bool get isDevelopment => _environment == 'development';
  static String get environment => _environment;
  
  // Firebase Configuration
  static String get firebaseApiKey => const String.fromEnvironment(
    'FIREBASE_API_KEY_PROD',
    defaultValue: 'your_api_key_here',
  );
  
  static String get firebaseAuthDomain => const String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN_PROD',
    defaultValue: 'your-project.firebaseapp.com',
  );
  
  static String get firebaseProjectId => const String.fromEnvironment(
    'FIREBASE_PROJECT_ID_PROD',
    defaultValue: 'your-project-id',
  );
  
  static String get firebaseStorageBucket => const String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET_PROD',
    defaultValue: 'your-project.appspot.com',
  );
  
  static String get firebaseMessagingSenderId => const String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID_PROD',
    defaultValue: '123456789',
  );
  
  static String get firebaseAppId => const String.fromEnvironment(
    'FIREBASE_APP_ID_PROD',
    defaultValue: '1:123456789:web:abcdef123456',
  );
  
  static String get firebaseMeasurementId => const String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID_PROD',
    defaultValue: 'G-ABCDEF1234',
  );
  
  // API Configuration
  static String get brailleApiUrl => const String.fromEnvironment(
    'BRAILLE_API_URL_PROD',
    defaultValue: 'https://api.gnos-braille.com',
  );
  
  static int get apiTimeout => const int.fromEnvironment(
    'API_TIMEOUT_PROD',
    defaultValue: 30000,
  );
  
  static int get apiRetryAttempts => const int.fromEnvironment(
    'API_RETRY_ATTEMPTS_PROD',
    defaultValue: 3,
  );
  
  static int get apiRetryDelay => const int.fromEnvironment(
    'API_RETRY_DELAY_PROD',
    defaultValue: 1000,
  );
  
  // Feature Flags
  static bool get enableAnalytics => const bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
  
  static bool get enableCrashlytics => const bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );
  
  static bool get enablePerformanceMonitoring => const bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );
  
  static bool get enableDebugLogging => const bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: kDebugMode,
  );
  
  static bool get enableOfflineMode => const bool.fromEnvironment(
    'ENABLE_OFFLINE_MODE',
    defaultValue: true,
  );
  
  static bool get enableVoiceFeedback => const bool.fromEnvironment(
    'ENABLE_VOICE_FEEDBACK',
    defaultValue: true,
  );
  
  static bool get enableHapticFeedback => const bool.fromEnvironment(
    'ENABLE_HAPTIC_FEEDBACK',
    defaultValue: true,
  );
  
  // Security Settings
  static int get maxTranslationLength => const int.fromEnvironment(
    'MAX_TRANSLATION_LENGTH',
    defaultValue: 10000,
  );
  
  static int get maxExportSize => const int.fromEnvironment(
    'MAX_EXPORT_SIZE',
    defaultValue: 50000000,
  );
  
  static int get sessionTimeout => const int.fromEnvironment(
    'SESSION_TIMEOUT',
    defaultValue: 3600000,
  );
  
  static int get maxLoginAttempts => const int.fromEnvironment(
    'MAX_LOGIN_ATTEMPTS',
    defaultValue: 5,
  );
  
  static int get passwordMinLength => const int.fromEnvironment(
    'PASSWORD_MIN_LENGTH',
    defaultValue: 8,
  );
  
  static bool get enforce2FA => const bool.fromEnvironment(
    'ENFORCE_2FA',
    defaultValue: false,
  ) || isProduction; // Always enforce 2FA in production
  
  // Rate Limiting
  static int get maxRequestsPerMinute => const int.fromEnvironment(
    'MAX_REQUESTS_PER_MINUTE',
    defaultValue: 100,
  );
  
  static int get maxTranslationsPerHour => const int.fromEnvironment(
    'MAX_TRANSLATIONS_PER_HOUR',
    defaultValue: 1000,
  );
  
  static int get maxExportsPerDay => const int.fromEnvironment(
    'MAX_EXPORTS_PER_DAY',
    defaultValue: 50,
  );
  
  // Cache Settings
  static int get cacheTTL => const int.fromEnvironment(
    'CACHE_TTL',
    defaultValue: 300000,
  );
  
  static int get maxCacheSize => const int.fromEnvironment(
    'MAX_CACHE_SIZE',
    defaultValue: 100000000,
  );
  
  static bool get enableDiskCache => const bool.fromEnvironment(
    'ENABLE_DISK_CACHE',
    defaultValue: true,
  );
  
  // Accessibility Settings
  static int get defaultFontSize => const int.fromEnvironment(
    'DEFAULT_FONT_SIZE',
    defaultValue: 16,
  );
  
  static int get maxFontSize => const int.fromEnvironment(
    'MAX_FONT_SIZE',
    defaultValue: 32,
  );
  
  static int get minFontSize => const int.fromEnvironment(
    'MIN_FONT_SIZE',
    defaultValue: 12,
  );
  
  static int get defaultContrastRatio => const int.fromEnvironment(
    'DEFAULT_CONTRAST_RATIO',
    defaultValue: 7,
  );
  
  static int get screenReaderTimeout => const int.fromEnvironment(
    'SCREEN_READER_TIMEOUT',
    defaultValue: 5000,
  );
  
  // Braille Translation Settings
  static int get defaultBrailleGrade => const int.fromEnvironment(
    'DEFAULT_BRAILLE_GRADE',
    defaultValue: 2,
  );
  
  static bool get supportGrade1 => const bool.fromEnvironment(
    'SUPPORT_GRADE_1',
    defaultValue: true,
  );
  
  static bool get supportGrade2 => const bool.fromEnvironment(
    'SUPPORT_GRADE_2',
    defaultValue: true,
  );
  
  static bool get supportGrade3 => const bool.fromEnvironment(
    'SUPPORT_GRADE_3',
    defaultValue: false,
  );
  
  static int get maxBrailleCellsPerLine => const int.fromEnvironment(
    'MAX_BRAILLE_CELLS_PER_LINE',
    defaultValue: 40,
  );
  
  // OCR Settings
  static double get ocrConfidenceThreshold {
    const String value = String.fromEnvironment(
      'OCR_CONFIDENCE_THRESHOLD',
      defaultValue: '0.85',
    );
    return double.tryParse(value) ?? 0.85;
  }
  
  static int get ocrMaxImageSize => const int.fromEnvironment(
    'OCR_MAX_IMAGE_SIZE',
    defaultValue: 10000000,
  );
  
  static String get supportedImageFormats => const String.fromEnvironment(
    'SUPPORTED_IMAGE_FORMATS',
    defaultValue: 'jpg,jpeg,png,pdf,tiff',
  );
  
  // Storage Settings
  static int get maxUserStorage => const int.fromEnvironment(
    'MAX_USER_STORAGE',
    defaultValue: 1000000000,
  );
  
  static bool get autoBackupEnabled => const bool.fromEnvironment(
    'AUTO_BACKUP_ENABLED',
    defaultValue: true,
  );
  
  static int get backupRetentionDays => const int.fromEnvironment(
    'BACKUP_RETENTION_DAYS',
    defaultValue: 30,
  );
  
  // Notifications
  static bool get enablePushNotifications => const bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );
  
  static bool get enableEmailNotifications => const bool.fromEnvironment(
    'ENABLE_EMAIL_NOTIFICATIONS',
    defaultValue: true,
  );
  
  static bool get notificationSoundEnabled => const bool.fromEnvironment(
    'NOTIFICATION_SOUND_ENABLED',
    defaultValue: true,
  );
  
  // Application URLs
  static String get cdnUrl => const String.fromEnvironment(
    'CDN_URL',
    defaultValue: 'https://cdn.gnos-braille.com',
  );
  
  static String get supportEmail => const String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@gnos-braille.com',
  );
  
  static String get privacyPolicyUrl => const String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://gnos-braille.com/privacy',
  );
  
  static String get termsOfServiceUrl => const String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
    defaultValue: 'https://gnos-braille.com/terms',
  );
  
  // Debug Settings (development/staging only)
  static bool get enableDebugPanel => const bool.fromEnvironment(
    'ENABLE_DEBUG_PANEL',
    defaultValue: false,
  );
  
  static bool get showPerformanceOverlay => const bool.fromEnvironment(
    'SHOW_PERFORMANCE_OVERLAY',
    defaultValue: false,
  );
  
  static bool get enableInspector => const bool.fromEnvironment(
    'ENABLE_INSPECTOR',
    defaultValue: kDebugMode,
  );
  
  // Logging
  static String get logLevel => const String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: kDebugMode ? 'debug' : 'error',
  );
  
  // Sentry/Error Reporting
  static String get sentryDsn => const String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  
  /// Print current configuration (for debugging)
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('🔧 Environment Configuration:');
      debugPrint('   Environment: $environment');
      debugPrint('   Debug Mode: $kDebugMode');
      debugPrint('   Firebase Project: $firebaseProjectId');
      debugPrint('   API URL: $brailleApiUrl');
      debugPrint('   Analytics: $enableAnalytics');
      debugPrint('   Debug Logging: $enableDebugLogging');
      debugPrint('   2FA Enforced: $enforce2FA');
      debugPrint('   Max Translation Length: $maxTranslationLength');
      debugPrint('   Support Email: $supportEmail');
    }
  }
  
  /// Validate configuration
  static bool validateConfig() {
    final requiredFields = <String, String>{
      'Firebase API Key': firebaseApiKey,
      'Firebase Project ID': firebaseProjectId,
      'Braille API URL': brailleApiUrl,
      'Support Email': supportEmail,
    };
    
    bool isValid = true;
    for (final entry in requiredFields.entries) {
      if (entry.value.isEmpty || entry.value.contains('your_') || entry.value.contains('here')) {
        if (kDebugMode) {
          debugPrint('❌ Missing or invalid configuration: ${entry.key}');
        }
        isValid = false;
      }
    }
    
    return isValid;
  }
}
