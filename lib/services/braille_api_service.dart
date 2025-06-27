import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment_config.dart';

/// Service class for integrating with the Braille Translation API
/// Provides comprehensive Braille translation functionality with full API integration
class BrailleApiService {
  static String get baseUrl => EnvironmentConfig.brailleApiUrl;
  static int get timeout => EnvironmentConfig.apiTimeout;
  static int get retryAttempts => EnvironmentConfig.apiRetryAttempts;
  static int get retryDelay => EnvironmentConfig.apiRetryDelay;

  /// Health check endpoint with retry logic
  static Future<Map<String, dynamic>> healthCheck() async {
    for (int attempt = 0; attempt < retryAttempts; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/health'))
            .timeout(Duration(milliseconds: timeout));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return {
            'status': 'healthy',
            'connected': true,
            'service': data['service'] ?? 'Braille Translation API',
            'version': data['version'] ?? '1.0.0',
            'pybraille_available': data['pybraille_available'] ?? false,
          };
        } else {
          throw Exception('API server returned status: ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == retryAttempts - 1) {
          return {
            'status': 'error',
            'connected': false,
            'error': 'Connection failed after $retryAttempts attempts: ${e.toString()}',
          };
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return {
      'status': 'error',
      'connected': false,
      'error': 'All retry attempts failed',
    };
  }

  /// Translates text to Braille or Braille to text with retry logic
  static Future<Map<String, dynamic>> translateText({
    required String text,
    String standard = 'grade1',
    String language = 'en',
    bool reverse = false,
    bool formatOutput = true,
    bool includeMetadata = true,
  }) async {
    if (text.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Input text cannot be empty',
        'result': '',
        'character_count': 0,
        'braille_cell_count': 0,
      };
    }

    for (int attempt = 0; attempt < retryAttempts; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/braille/translate'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'text': text,
            'standard': standard,
            'language': language,
            'reverse': reverse,
            'format_output': formatOutput,
            'include_metadata': includeMetadata,
          }),
        ).timeout(Duration(milliseconds: timeout));

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          return {
            'success': true,
            'result': result['result'] ?? '',
            'character_count': result['character_count'] ?? 0,
            'braille_cell_count': result['braille_cell_count'] ?? 0,
            'metadata': result['metadata'] ?? {},
            'standard': standard,
            'language': language,
            'reverse': reverse,
          };
        } else {
          if (attempt == retryAttempts - 1) {
            return {
              'success': false,
              'error': 'API request failed with status: ${response.statusCode}',
              'result': '',
              'character_count': 0,
              'braille_cell_count': 0,
            };
          }
        }
      } catch (e) {
        if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'error': 'Connection error after $retryAttempts attempts: ${e.toString()}',
            'result': '',
            'character_count': 0,
            'braille_cell_count': 0,
          };
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return {
      'success': false,
      'error': 'All retry attempts failed',
      'result': '',
      'character_count': 0,
      'braille_cell_count': 0,
    };
  }



  /// Get supported Braille standards with timeout and retry
  static Future<Map<String, dynamic>> getSupportedStandards() async {
    for (int attempt = 0; attempt < retryAttempts; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/api/braille/standards'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(Duration(milliseconds: timeout));

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          return {
            'success': true,
            'standards': result['standards'] ?? [],
          };
        } else if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'standards': [],
            'error': 'Failed to fetch standards: status ${response.statusCode}',
          };
        }
      } catch (e) {
        if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'standards': [],
            'error': 'Connection error: ${e.toString()}',
          };
        }
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return {
      'success': false,
      'standards': [],
      'error': 'All retry attempts failed',
    };
  }

  /// Get supported languages with timeout and retry
  static Future<Map<String, dynamic>> getSupportedLanguages() async {
    for (int attempt = 0; attempt < retryAttempts; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/api/braille/languages'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(Duration(milliseconds: timeout));

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          return {
            'success': true,
            'languages': result['languages'] ?? [],
          };
        } else if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'languages': [],
            'error': 'Failed to fetch languages: status ${response.statusCode}',
          };
        }
      } catch (e) {
        if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'languages': [],
            'error': 'Connection error: ${e.toString()}',
          };
        }
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return {
      'success': false,
      'languages': [],
      'error': 'All retry attempts failed',
    };
  }

  /// Get demo translations with timeout and retry
  static Future<Map<String, dynamic>> getDemoTranslations() async {
    for (int attempt = 0; attempt < retryAttempts; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/api/braille/demo'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(Duration(milliseconds: timeout));

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          return {
            'success': true,
            'demo_translations': result['demo_translations'] ?? [],
          };
        } else if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'demo_translations': [],
            'error': 'Failed to fetch demo translations: status ${response.statusCode}',
          };
        }
      } catch (e) {
        if (attempt == retryAttempts - 1) {
          return {
            'success': false,
            'demo_translations': [],
            'error': 'Connection error: ${e.toString()}',
          };
        }
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return {
      'success': false,
      'demo_translations': [],
      'error': 'All retry attempts failed',
    };
  }
}
