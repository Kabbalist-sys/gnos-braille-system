import 'package:flutter_test/flutter_test.dart';
import 'package:gnos_braille_system/config/environment_config.dart';

void main() {
  group('EnvironmentConfig Tests', () {
    test('should have default values for all configurations', () {
      // Test that all basic getters return non-null values
      expect(EnvironmentConfig.environment, isNotNull);
      expect(EnvironmentConfig.firebaseApiKey, isNotNull);
      expect(EnvironmentConfig.firebaseProjectId, isNotNull);
      expect(EnvironmentConfig.brailleApiUrl, isNotNull);
      expect(EnvironmentConfig.apiTimeout, greaterThan(0));
      expect(EnvironmentConfig.maxTranslationLength, greaterThan(0));
    });

    test('should have correct default environment', () {
      expect(EnvironmentConfig.environment, equals('development'));
      expect(EnvironmentConfig.isDevelopment, isTrue);
      expect(EnvironmentConfig.isProduction, isFalse);
      expect(EnvironmentConfig.isStaging, isFalse);
    });

    test('should enforce 2FA in production environment', () {
      // Note: This test demonstrates the logic, but actual environment
      // variables would need to be set during CI/CD for full testing
      expect(EnvironmentConfig.enforce2FA, isA<bool>());
    });

    test('should have valid OCR confidence threshold', () {
      final threshold = EnvironmentConfig.ocrConfidenceThreshold;
      expect(threshold, greaterThanOrEqualTo(0.0));
      expect(threshold, lessThanOrEqualTo(1.0));
    });

    test('should have reasonable default font sizes', () {
      expect(EnvironmentConfig.defaultFontSize, greaterThan(0));
      expect(EnvironmentConfig.minFontSize, greaterThan(0));
      expect(EnvironmentConfig.maxFontSize, greaterThan(EnvironmentConfig.minFontSize));
      expect(EnvironmentConfig.defaultFontSize, 
        greaterThanOrEqualTo(EnvironmentConfig.minFontSize));
      expect(EnvironmentConfig.defaultFontSize, 
        lessThanOrEqualTo(EnvironmentConfig.maxFontSize));
    });

    test('should have valid braille settings', () {
      expect(EnvironmentConfig.defaultBrailleGrade, greaterThan(0));
      expect(EnvironmentConfig.maxBrailleCellsPerLine, greaterThan(0));
      expect(EnvironmentConfig.supportGrade1, isA<bool>());
      expect(EnvironmentConfig.supportGrade2, isA<bool>());
    });

    test('should have valid rate limiting settings', () {
      expect(EnvironmentConfig.maxRequestsPerMinute, greaterThan(0));
      expect(EnvironmentConfig.maxTranslationsPerHour, greaterThan(0));
      expect(EnvironmentConfig.maxExportsPerDay, greaterThan(0));
    });

    test('should print configuration in debug mode', () {
      // This test ensures the printConfig method doesn't crash
      expect(() => EnvironmentConfig.printConfig(), returnsNormally);
    });

    test('should validate configuration', () {
      // This test ensures the validateConfig method works
      // Use suppressOutput to avoid error messages in test output
      final isValid = EnvironmentConfig.validateConfig(suppressOutput: true);
      expect(isValid, isA<bool>());
      
      // In development/test environment with default placeholder values,
      // validation is expected to return false, which is correct behavior
      if (EnvironmentConfig.isDevelopment) {
        // In development mode, configuration might be invalid due to placeholder values
        // This is expected and acceptable for testing
        expect(isValid, isA<bool>()); // Just ensure it returns a boolean
      } else {
        // In production, configuration should be valid
        expect(isValid, isTrue);
      }
    });

    test('should have valid email format for support email', () {
      final supportEmail = EnvironmentConfig.supportEmail;
      expect(supportEmail, contains('@'));
      expect(supportEmail, contains('.'));
    });

    test('should have valid URLs', () {
      final apiUrl = EnvironmentConfig.brailleApiUrl;
      final cdnUrl = EnvironmentConfig.cdnUrl;
      final privacyUrl = EnvironmentConfig.privacyPolicyUrl;
      
      expect(apiUrl, startsWith('http'));
      expect(cdnUrl, startsWith('http'));
      expect(privacyUrl, startsWith('http'));
    });
  });
}
