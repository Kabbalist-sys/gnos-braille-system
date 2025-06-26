import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for integrating with the Braille Translation API
class BrailleApiService {
  static const String baseUrl = 'http://localhost:5000';
  
  /// Translates text to Braille or Braille to text
  static Future<Map<String, dynamic>> translateText({
    required String text,
    String standard = 'grade1',
    String language = 'en',
    bool reverse = false,
    bool formatOutput = true,
    bool includeMetadata = true,
  }) async {
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
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'error': 'API request failed with status: ${response.statusCode}',
          'result': '',
          'character_count': 0,
          'braille_cell_count': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}',
        'result': '',
        'character_count': 0,
        'braille_cell_count': 0,
      };
    }
  }
  
  /// Get health status of the API
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'API health check failed',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  /// Get supported Braille standards
  static Future<Map<String, dynamic>> getSupportedStandards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/braille/standards'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'standards': [],
          'error': 'Failed to fetch standards',
        };
      }
    } catch (e) {
      return {
        'standards': [],
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  /// Get supported languages
  static Future<Map<String, dynamic>> getSupportedLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/braille/languages'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'languages': [],
          'error': 'Failed to fetch languages',
        };
      }
    } catch (e) {
      return {
        'languages': [],
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  /// Get demo translations
  static Future<Map<String, dynamic>> getDemoTranslations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/braille/demo'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'demo_translations': [],
          'error': 'Failed to fetch demo translations',
        };
      }
    } catch (e) {
      return {
        'demo_translations': [],
        'error': 'Connection error: ${e.toString()}',
      };
    }
  }
}
