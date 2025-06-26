import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// Import Crashlytics and Performance Monitoring for production
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseConfig {
  // Environment-specific configurations
  static const bool kIsProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool kIsDevelopment = !kIsProduction;

  // Firebase services instances
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;
  static FirebasePerformance? _performance;

  // Getters for Firebase services
  static FirebaseAnalytics get analytics =>
      _analytics ??= FirebaseAnalytics.instance;
  static FirebaseCrashlytics get crashlytics =>
      _crashlytics ??= FirebaseCrashlytics.instance;
  static FirebasePerformance get performance =>
      _performance ??= FirebasePerformance.instance;

  // Production Firebase options
  static const FirebaseOptions productionOptions = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_PROD'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN_PROD'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID_PROD'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET_PROD'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_PROD'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_PROD'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID_PROD'),
  );

  // Development Firebase options
  static const FirebaseOptions developmentOptions = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_DEV'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN_DEV'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID_DEV'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET_DEV'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_DEV'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_DEV'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID_DEV'),
  );

  // Get current environment options
  static FirebaseOptions get currentOptions {
    if (kIsProduction) {
      return productionOptions;
    } else {
      return developmentOptions;
    }
  }

  // Initialize Firebase with proper configuration
  static Future<void> initialize() async {
    try {
      // Check if we're in a test environment
      if (_isTestEnvironment()) {
        if (kDebugMode) {
          print('Skipping Firebase initialization in test environment');
        }
        return;
      }

      await Firebase.initializeApp(
        options: currentOptions,
      );

      if (kDebugMode) {
        print(
            'Firebase initialized for ${kIsProduction ? "PRODUCTION" : "DEVELOPMENT"} environment');
      }

      // Configure Firebase settings for production
      if (kIsProduction) {
        await _configureProductionSettings();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  // Check if we're in test environment
  static bool _isTestEnvironment() {
    // Check if we're running in Flutter test environment
    try {
      return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  // Production-specific configurations
  static Future<void> _configureProductionSettings() async {
    // Enable Firebase Analytics in production
    if (enableAnalytics) {
      await analytics.setAnalyticsCollectionEnabled(true);
    }

    // Configure Crashlytics
    if (enableCrashlytics) {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      // Set up Flutter error handling
      FlutterError.onError = (errorDetails) {
        crashlytics.recordFlutterFatalError(errorDetails);
      };
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        crashlytics.recordError(error, stackTrace, fatal: true);
        return true;
      };
    }

    // Configure Performance Monitoring
    if (enablePerformanceMonitoring) {
      await performance.setPerformanceCollectionEnabled(true);
    }

    if (kDebugMode) {
      print('Production Firebase settings configured');
      print('- Analytics: $enableAnalytics');
      print('- Crashlytics: $enableCrashlytics');
      print('- Performance: $enablePerformanceMonitoring');
    }
  }

  // Utility methods for environment detection
  static bool get isProduction => kIsProduction;
  static bool get isDevelopment => kIsDevelopment;
  static String get environment => kIsProduction ? 'production' : 'development';

  // API endpoints based on environment
  static String get brailleApiBaseUrl {
    if (kIsProduction) {
      return const String.fromEnvironment('BRAILLE_API_URL_PROD',
          defaultValue: 'https://api.gnos-braille.com');
    } else {
      return const String.fromEnvironment('BRAILLE_API_URL_DEV',
          defaultValue: 'http://localhost:5000');
    }
  }

  // Feature flags for production
  static bool get enableAnalytics => kIsProduction;
  static bool get enableCrashlytics => kIsProduction;
  static bool get enablePerformanceMonitoring => kIsProduction;
  static bool get enableDebugLogging => kIsDevelopment;
}
