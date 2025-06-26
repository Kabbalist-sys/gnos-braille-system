import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test setup utility to initialize Firebase for testing
class TestSetup {
  static Future<void> initializeFirebaseForTesting() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock Firebase Core
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_core'),
            (call) async {
      switch (call.method) {
        case 'Firebase#initializeCore':
          return {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': <String, dynamic>{},
          };
        case 'Firebase#initializeApp':
          return {
            'name': call.arguments['appName'],
            'options': call.arguments['options'],
            'pluginConstants': <String, dynamic>{},
          };
        default:
          return null;
      }
    });

    // Mock Firebase Auth
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_auth'),
            (call) async {
      switch (call.method) {
        case 'Auth#registerIdTokenListener':
          return {'user': null};
        case 'Auth#registerAuthStateListener':
          return {'user': null};
        case 'Auth#signInAnonymously':
          return {
            'user': {
              'uid': 'test-uid',
              'email': null,
              'isAnonymous': true,
            }
          };
        default:
          return null;
      }
    });

    // Mock Firestore
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/cloud_firestore'),
            (call) async {
      return null;
    });

    // Mock Firebase Storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_storage'),
            (call) async {
      return null;
    });

    // Mock Firebase Analytics
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_analytics'),
            (call) async {
      return null;
    });

    // Mock Firebase Crashlytics
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_crashlytics'),
            (call) async {
      return null;
    });

    // Mock Firebase Performance
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_performance'),
            (call) async {
      return null;
    });

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: 'fake-app-id',
          messagingSenderId: 'fake-sender-id',
          projectId: 'fake-project-id',
        ),
      );
    } catch (e) {
      // Firebase might already be initialized
    }
  }
}
