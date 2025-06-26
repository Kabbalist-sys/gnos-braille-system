"""
Flutter/Dart HTTP Client Integration Example
===========================================

This file shows the Dart code patterns you can use in your Flutter app
to integrate with the Python Braille Translation API.

Copy these code snippets into your Flutter project.
"""

# Add this to your pubspec.yaml dependencies:
# http: ^1.1.0

# 1. API Client Class (add to lib/services/braille_api_service.dart)

"""
import 'dart:convert';
import 'package:http/http.dart' as http;

class BrailleApiService {
  static const String baseUrl = 'http://localhost:5000'; // Change for production
  
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> translateText({
    required String text,
    String standard = 'grade1',
    String language = 'en',
    bool reverse = false,
    bool formatOutput = true,
    bool includeMetadata = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/braille/translate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'standard': standard,
          'language': language,
          'reverse': reverse,
          'format_output': formatOutput,
          'include_metadata': includeMetadata,
        }),
      );
      
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  static Future<List<Map<String, dynamic>>> getStandards() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/braille/standards'));
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['standards']);
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getLanguages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/braille/languages'));
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['languages']);
    } catch (e) {
      return [];
    }
  }
}
"""

# 2. Enhanced Braille Screen Widget (update lib/main.dart BrailleScreen)

"""
class _BrailleScreenState extends State<BrailleScreen> {
  final TextEditingController _inputController = TextEditingController();
  String? _brailleResult;
  bool _isLoading = false;
  String _selectedStandard = 'grade1';
  String _selectedLanguage = 'en';
  bool _reverseMode = false;
  List<Map<String, dynamic>> _standards = [];
  List<Map<String, dynamic>> _languages = [];
  Map<String, dynamic>? _metadata;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadApiData() async {
    final standards = await BrailleApiService.getStandards();
    final languages = await BrailleApiService.getLanguages();
    setState(() {
      _standards = standards;
      _languages = languages;
    });
  }

  Future<void> _translateWithAPI() async {
    setState(() => _isLoading = true);
    final input = _inputController.text;
    
    if (input.isEmpty) {
      setState(() {
        _brailleResult = null;
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await BrailleApiService.translateText(
        text: input,
        standard: _selectedStandard,
        language: _selectedLanguage,
        reverse: _reverseMode,
        includeMetadata: true,
      );

      setState(() {
        if (result['success'] == true) {
          _brailleResult = result['result'];
          _metadata = result['metadata'];
        } else {
          _brailleResult = 'Error: ${result['error']}';
          _metadata = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _brailleResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Braille Translator'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input field
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: _reverseMode 
                  ? 'Enter Braille to translate to text'
                  : 'Enter text to translate to Braille',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.translate),
              ),
              minLines: 2,
              maxLines: 4,
              style: TextStyle(
                fontSize: _reverseMode ? 24 : 16,
                fontFamily: _reverseMode ? 'monospace' : null,
              ),
            ),
            const SizedBox(height: 16),
            
            // Controls row
            Row(
              children: [
                // Standard dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStandard,
                    decoration: InputDecoration(
                      labelText: 'Standard',
                      border: OutlineInputBorder(),
                    ),
                    items: _standards.map((standard) {
                      return DropdownMenuItem<String>(
                        value: standard['code'],
                        child: Text(standard['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStandard = value!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Language dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['code'],
                        child: Text(language['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reverse mode toggle
            SwitchListTile(
              title: Text('Reverse Mode (Braille → Text)'),
              subtitle: Text('Toggle to translate Braille back to text'),
              value: _reverseMode,
              onChanged: (value) {
                setState(() {
                  _reverseMode = value;
                  _inputController.clear();
                  _brailleResult = null;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Translate button
            ElevatedButton.icon(
              icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.translate),
              label: Text(_isLoading ? 'Translating...' : 'Translate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _translateWithAPI,
            ),
            const SizedBox(height: 24),
            
            // Result display
            if (_isLoading) 
              Center(child: CircularProgressIndicator()),
            
            if (_brailleResult != null && !_isLoading)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Result:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _brailleResult!,
                        style: TextStyle(
                          fontSize: _reverseMode ? 16 : 28,
                          fontFamily: _reverseMode ? null : 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    // Metadata display
                    if (_metadata != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Translation Info:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Method: ${_metadata!['translation_method']}'),
                            Text('Characters: ${_metadata!.containsKey('character_count') ? _metadata!['character_count'] : 'N/A'}'),
                            Text('Braille Cells: ${_metadata!.containsKey('braille_cell_count') ? _metadata!['braille_cell_count'] : 'N/A'}'),
                            if (_metadata!.containsKey('compression_ratio'))
                              Text('Compression: ${_metadata!['compression_ratio']}x'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
"""

# 3. Add HTTP dependency to pubspec.yaml

"""
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  camera: any
  google_mlkit_text_recognition: ^0.15.0
  speech_to_text: any
  flutter_tts: any
  translator: any
  vibration: any
  flutter_svg: ^2.0.10
  firebase_core: ^2.30.0
  firebase_messaging: ^14.7.10
  cloud_firestore: ^4.15.10
  firebase_storage: ^11.6.10
  http: ^1.1.0  # Add this line for API calls
"""

# 4. Usage in your existing braille_translate.py (legacy support)

"""
# Update your existing braille_translate.py to use the new API as fallback:

import sys
import requests
import json

def translate_with_api(text, standard='grade1'):
    try:
        response = requests.post(
            'http://localhost:5000/api/braille/translate',
            json={'text': text, 'standard': standard},
            timeout=5
        )
        result = response.json()
        if result.get('success'):
            return result['result']
        else:
            return f"API Error: {result.get('error', 'Unknown error')}"
    except:
        # Fallback to basic implementation
        return basic_braille_translation(text)

def basic_braille_translation(text):
    # Your existing basic implementation here
    basic_map = {
        'a': '⠁', 'b': '⠃', 'c': '⠉', 'd': '⠙', 'e': '⠑',
        # ... rest of your mapping
    }
    return ''.join([basic_map.get(c.lower(), '⠀') for c in text])

if __name__ == '__main__':
    if len(sys.argv) > 1:
        text = sys.argv[1]
        result = translate_with_api(text)
        print(result)
    else:
        print("Usage: python braille_translate.py <text>")
"""
