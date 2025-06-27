import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'config/firebase_config.dart';
import 'config/environment_config.dart';
import 'services/braille_api_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/translation_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analytics_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print environment configuration in debug mode
  EnvironmentConfig.printConfig();
  
  // Validate environment configuration
  if (!EnvironmentConfig.validateConfig()) {
    if (EnvironmentConfig.enableDebugLogging) {
      debugPrint('⚠️  Warning: Some environment configurations are missing or invalid');
    }
  }

  // Initialize Firebase with production-ready configuration
  await FirebaseConfig.initialize();

  runApp(DotHullAccessibleApp());
}

class DotHullAccessibleApp extends StatelessWidget {
  const DotHullAccessibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gnos Braille System - ${EnvironmentConfig.environment}',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: !EnvironmentConfig.isProduction,
      initialRoute: '/login',
      routes: {
        '/': (context) => AuthWrapper(child: HomeScreen()),
        '/home': (context) => AuthWrapper(child: HomeScreen()),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/profile': (context) => AuthWrapper(child: UserProfileScreen()),
        '/translation-history': (context) =>
            AuthWrapper(child: TranslationHistoryScreen()),
        '/analytics': (context) => AuthWrapper(child: AnalyticsScreen()),
        '/camera': (context) => AuthWrapper(child: CameraScreen()),
        '/lens': (context) => AuthWrapper(child: LensScreen()),
        '/settings': (context) => AuthWrapper(child: SettingsScreen()),
        '/braille': (context) => AuthWrapper(child: BrailleScreen()),
        '/wireframe': (context) => AuthWrapper(child: WireframeScreen()),
        '/notifications': (context) =>
            AuthWrapper(child: NotificationsScreen()),
        '/cloud': (context) => AuthWrapper(child: CloudScreen()),
        '/blockchain': (context) => AuthWrapper(child: BlockchainScreen()),
        '/about': (context) => AuthWrapper(child: AboutScreen()),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gnos Braille System'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: const Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: const Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Translation History'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'analytics',
                child: const Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sign_out',
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'history':
                  Navigator.pushNamed(context, '/translation-history');
                  break;
                case 'analytics':
                  Navigator.pushNamed(context, '/analytics');
                  break;
                case 'sign_out':
                  final authService = AuthService();
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  }
                  break;
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modern SVG Kabbalah Tree of Life Viewer with enhancements
              AnimatedContainer(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                height: 340,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      Colors.white
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/logo_kabbalah.svg',
                        semanticsLabel: 'Kabbalah Tree of Life',
                        fit: BoxFit.contain,
                        width: 320,
                        height: 320,
                      ),
                    ),
                    // Example: Floating info button for interactive tooltips
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Tooltip(
                        message: 'Tap a Sefira for details',
                        child: Icon(Icons.info_outline, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Modern options row with toggles and feedback
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.color_lens),
                    label: Text('Theme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                    ),
                    onPressed: () {
                      // TODO: Implement theme switcher
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Theme switching coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.remove_red_eye),
                    label: Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                    ),
                    onPressed: () {
                      // TODO: Implement view switcher
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View options coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.download),
                    label: Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                    ),
                    onPressed: () {
                      // TODO: Implement export/download
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Logo
              Image.asset('assets/logo.png', height: 120),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/camera'),
                child: Text('Camera'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/lens'),
                child: Text('Lens'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: Text('Settings'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/braille'),
                child: Text('Braille Translator'),
              ),
              const SizedBox(height: 16),
              // Add a button to access the wireframe
              ElevatedButton.icon(
                icon: Icon(Icons.grid_on),
                label: Text('Show Wireframe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: StadiumBorder(),
                ),
                onPressed: () => Navigator.pushNamed(context, '/wireframe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CameraScreen with camera capture and OCR
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String? _recognizedText;
  bool _isProcessing = false;

  // Voice, TTS, and Translation
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceCommand = '';
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();
  String? _translatedText;
  String _selectedLanguage = 'en';
  final Map<String, String> _languages = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Arabic': 'ar',
    'Chinese': 'zh-cn',
    'Hindi': 'hi',
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
    _speech = stt.SpeechToText();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {});
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isProcessing = true);
    final image = await _controller!.takePicture();

    // Save the captured image path
    final inputPath = image.path;
    final outputPath = inputPath.replaceFirst('.jpg', '_processed.jpg');

    // Call the Python script to preprocess the image (manual step or automate with platform channel)
    // Example command to run manually:
    // python preprocess.py <inputPath> <outputPath>

    // After running the script, use the processed image for OCR
    final inputImage = InputImage.fromFilePath(outputPath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    setState(() {
      _recognizedText = recognizedText.text;
      _isProcessing = false;
    });
    textRecognizer.close();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _voiceCommand = val.recognizedWords;
        });
        if (val.finalResult) {
          _handleVoiceCommand(_voiceCommand);
        }
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String command) async {
    if (command.toLowerCase().contains('capture')) {
      await _captureAndRecognize();
    } else if (command.toLowerCase().contains('read')) {
      if (_recognizedText != null) await _speak(_recognizedText!);
    } else if (command.toLowerCase().contains('translate')) {
      // Try to extract language from command
      String? langCode = _languages.entries
          .firstWhere(
            (entry) => command.toLowerCase().contains(entry.key.toLowerCase()),
            orElse: () => MapEntry('English', 'en'),
          )
          .value;
      setState(() => _selectedLanguage = langCode);
      await _translateText(langCode);
    }
    _stopListening();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _translateText(String targetLang) async {
    if (_recognizedText == null) return;
    var translation =
        await _translator.translate(_recognizedText!, to: targetLang);
    setState(() {
      _translatedText = translation.text;
    });
    await _speak(_translatedText!);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: _controller == null || !_controller!.value.isInitialized
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _captureAndRecognize,
                    child:
                        Text(_isProcessing ? 'Processing...' : 'Capture & OCR'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed:
                            _isListening ? _stopListening : _startListening,
                        child: Text(
                            _isListening ? 'Stop Listening' : 'Voice Command'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _recognizedText == null
                            ? null
                            : () => _speak(_recognizedText!),
                        child: Text('Read Aloud'),
                      ),
                      SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        items: _languages.entries
                            .map((entry) => DropdownMenuItem<String>(
                                  value: entry.value,
                                  child: Text(entry.key),
                                ))
                            .toList(),
                        onChanged: (lang) {
                          if (lang != null) {
                            setState(() => _selectedLanguage = lang);
                          }
                        },
                      ),
                      ElevatedButton(
                        onPressed: _recognizedText == null
                            ? null
                            : () => _translateText(_selectedLanguage),
                        child: Text('Translate'),
                      ),
                    ],
                  ),
                  if (_recognizedText != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Recognized: $_recognizedText'),
                    ),
                  if (_translatedText != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Translated: $_translatedText'),
                    ),
                  if (_voiceCommand.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Voice Command: $_voiceCommand'),
                    ),
                ],
              ),
            ),
    );
  }
}

// LensScreen with overlay and accessibility placeholder
class LensScreen extends StatelessWidget {
  const LensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lens')),
      body: Stack(
        children: [
          Center(child: Text('Lens Screen Placeholder')),
          // Example overlay for detected region
          Positioned(
            left: 50,
            top: 100,
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                color: Colors.red.withValues(alpha: 0.1),
              ),
              child: Center(
                  child: Text('Detected Dot Hull Text',
                      style: TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}

// BrailleScreen for Braille translation
class BrailleScreen extends StatefulWidget {
  const BrailleScreen({super.key});

  @override
  State<BrailleScreen> createState() => _BrailleScreenState();
}

class _BrailleScreenState extends State<BrailleScreen> {
  final TextEditingController _inputController = TextEditingController();
  final CloudStorageService _cloudStorageService = CloudStorageService();
  String? _brailleResult;
  bool _isLoading = false;
  bool _isReverse = false;
  String _selectedStandard = 'grade1';
  String _selectedLanguage = 'en';
  Map<String, dynamic>? _metadata;
  List<dynamic> _standards = [];
  List<dynamic> _languages = [];
  String? _apiStatus;
  List<TranslationRecord> _translationHistory = [];
  bool _realTimeTranslation = false;
  String? _connectionError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
    _loadSupportedOptions();
    _loadTranslationHistory();
    _inputController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_realTimeTranslation && _inputController.text.isNotEmpty) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _translateText();
      });
    }
  }

  Future<void> _checkApiHealth() async {
    setState(() {
      _connectionError = null;
    });

    final health = await BrailleApiService.healthCheck();
    setState(() {
      if (health['connected'] == true) {
        _apiStatus = 'Connected';
        _connectionError = null;
      } else {
        _apiStatus = 'Disconnected';
        _connectionError = health['error'];
      }
    });
  }

  Future<void> _loadSupportedOptions() async {
    final standardsResponse = await BrailleApiService.getSupportedStandards();
    final languagesResponse = await BrailleApiService.getSupportedLanguages();

    setState(() {
      if (standardsResponse['success'] == true) {
        _standards = standardsResponse['standards'];
      } else {
        _standards = [
          {'code': 'grade1', 'name': 'Grade 1 (Uncontracted)'},
          {'code': 'grade2', 'name': 'Grade 2 (Contracted)'},
        ];
      }

      if (languagesResponse['success'] == true) {
        _languages = languagesResponse['languages'];
      } else {
        _languages = [
          {'code': 'en', 'name': 'English'},
          {'code': 'es', 'name': 'Spanish'},
          {'code': 'fr', 'name': 'French'},
        ];
      }
    });
  }

  Future<void> _loadTranslationHistory() async {
    try {
      // Listen to the stream and get the first value
      _cloudStorageService.getTranslationHistory(limit: 10).listen((history) {
        setState(() {
          _translationHistory = history;
        });
      });
    } catch (e) {
      debugPrint('Failed to load translation history: $e');
    }
  }

  Future<void> _saveTranslation(
      String originalText, String translatedText) async {
    try {
      final translationRecord = TranslationRecord(
        id: '', // Will be generated by Firestore
        originalText: originalText,
        translatedText: translatedText,
        standard: _selectedStandard,
        language: _selectedLanguage,
        isReverse: _isReverse,
        timestamp: DateTime.now(),
        metadata: _metadata,
        userId: '', // Will be set by the service
      );

      await _cloudStorageService.saveTranslation(translationRecord);
      _loadTranslationHistory(); // Refresh history
    } catch (e) {
      debugPrint('Failed to save translation: $e');
    }
  }

  Future<void> _translateText() async {
    final input = _inputController.text.trim();
    
    if (input.isEmpty) {
      setState(() {
        _brailleResult = null;
        _isLoading = false;
        _metadata = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await BrailleApiService.translateText(
        text: input,
        standard: _selectedStandard,
        language: _selectedLanguage,
        reverse: _isReverse,
        formatOutput: true,
        includeMetadata: true,
      );

      setState(() {
        if (result['success'] == true) {
          _brailleResult = result['result'];
          _metadata = result['metadata'];
          _connectionError = null;

          // Save translation to cloud storage
          _saveTranslation(input, _brailleResult!);
        } else {
          _brailleResult = null;
          _connectionError = result['error'];
          _metadata = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _brailleResult = null;
        _connectionError = 'Unexpected error: $e';
        _isLoading = false;
        _metadata = null;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareResult() {
    if (_brailleResult != null) {
      final shareText = 'Original: ${_inputController.text}\nBraille: $_brailleResult';
      // For now, just copy to clipboard since share_plus isn't available
      _copyToClipboard(shareText);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation copied to clipboard!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _brailleResult = null;
      _metadata = null;
      _connectionError = null;
    });
  }

  void _loadHistoryItem(TranslationRecord record) {
    setState(() {
      _inputController.text = record.originalText;
      _brailleResult = record.translatedText;
      _isReverse = record.isReverse;
      _selectedStandard = record.standard;
      _selectedLanguage = record.language;
      _metadata = record.metadata;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Braille Translator'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkApiHealth,
            tooltip: 'Refresh connection',
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Status Card
            Card(
              color: _apiStatus == 'Connected' ? Colors.green[50] : Colors.red[50],
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _apiStatus == 'Connected' ? Icons.check_circle : Icons.error,
                          color: _apiStatus == 'Connected' ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('API Status: ${_apiStatus ?? "Checking..."}'),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: _checkApiHealth,
                          tooltip: 'Refresh connection',
                        ),
                      ],
                    ),
                    if (_connectionError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _connectionError!,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Real-time translation toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Real-time Translation', style: TextStyle(fontWeight: FontWeight.bold)),
                    Spacer(),
                    Switch(
                      value: _realTimeTranslation,
                      onChanged: (value) {
                        setState(() {
                          _realTimeTranslation = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Translation Direction Switch
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('Translation Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text('Text → Braille'),
                    Switch(
                      value: _isReverse,
                      onChanged: (value) {
                        setState(() {
                          _isReverse = value;
                          _inputController.clear();
                          _brailleResult = null;
                          _metadata = null;
                          _connectionError = null;
                        });
                      },
                    ),
                    Text('Braille → Text'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Standard', style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: _selectedStandard,
                            isExpanded: true,
                            items: _standards.map<DropdownMenuItem<String>>((standard) {
                              return DropdownMenuItem<String>(
                                value: standard['code'],
                                child: Text(standard['name']),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStandard = newValue ?? 'grade1';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            items: _languages.map<DropdownMenuItem<String>>((language) {
                              return DropdownMenuItem<String>(
                                value: language['code'],
                                child: Text(language['name']),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLanguage = newValue ?? 'en';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input Field with enhanced features
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: _isReverse
                    ? 'Enter Braille to translate to text'
                    : 'Enter text to translate to Braille',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _inputController.clear();
                          setState(() {
                            _brailleResult = null;
                            _metadata = null;
                            _connectionError = null;
                          });
                        },
                      )
                    : null,
              ),
              minLines: 2,
              maxLines: 4,
              style: TextStyle(
                fontSize: _isReverse ? 24 : 16,
                fontFamily: _isReverse ? 'monospace' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Translate Button
            ElevatedButton.icon(
              icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.translate),
              label: Text(_isLoading ? 'Translating...' : 'Translate'),
              onPressed: _isLoading ? null : _translateText,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading) Center(child: CircularProgressIndicator()),

            // Error Display
            if (_connectionError != null && !_isLoading)
              Card(
                color: Colors.red[50],
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Translation Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(_connectionError!, style: TextStyle(color: Colors.red[800])),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                        onPressed: _translateText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Result Display
            if (_brailleResult != null && !_isLoading)
              Card(
                color: Colors.blue[50],
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Translation Result:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo[700],
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(_brailleResult!),
                            tooltip: 'Copy result',
                          ),
                          IconButton(
                            icon: Icon(Icons.share),
                            onPressed: _shareResult,
                            tooltip: 'Share translation',
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SelectableText(
                        _brailleResult!,
                        style: TextStyle(
                          fontSize: _isReverse ? 16 : 28,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                      if (_metadata != null) ...[
                        SizedBox(height: 16),
                        Divider(),
                        Text(
                          'Translation Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildMetadataRow('Method', _metadata!['translation_method'] ?? 'Unknown'),
                        _buildMetadataRow('Characters', '${_inputController.text.length}'),
                        if (_metadata!['compression_ratio'] != null)
                          _buildMetadataRow('Compression', '${_metadata!['compression_ratio']}x'),
                        if (_metadata!['contractions_used'] == true)
                          _buildMetadataRow('Contractions', 'Used'),
                      ],
                    ],
                  ),
                ),
              ),

            // Translation History
            if (_translationHistory.isNotEmpty) ...[
              SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Translations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 12),
                      ...(_translationHistory.take(3).map((record) => ListTile(
                        title: Text(
                          record.originalText.length > 30
                              ? '${record.originalText.substring(0, 30)}...'
                              : record.originalText,
                        ),
                        subtitle: Text(
                          '${record.isReverse ? "Braille → Text" : "Text → Braille"} • ${record.timestamp.toString().substring(0, 16)}',
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _loadHistoryItem(record),
                      ))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// WireframeScreen to visually mock up the main app layout using simple boxes and labels
class WireframeScreen extends StatelessWidget {
  const WireframeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wireframe Mockup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_tree, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Header / Logo',
                        style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _WireframeBox(
                    label: 'Camera',
                    icon: Icons.camera_alt,
                    onTap: () => Navigator.pushNamed(context, '/camera'),
                  ),
                  _WireframeBox(
                    label: 'Braille Translator',
                    icon: Icons.blur_circular,
                    onTap: () => Navigator.pushNamed(context, '/braille'),
                  ),
                  _WireframeBox(
                    label: 'Lens',
                    icon: Icons.remove_red_eye,
                    onTap: () => Navigator.pushNamed(context, '/lens'),
                  ),
                  _WireframeBox(
                    label: 'Settings',
                    icon: Icons.settings,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _WireframeBox(
                    label: 'Notifications',
                    icon: Icons.notifications,
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  _WireframeBox(
                    label: 'Cloud',
                    icon: Icons.cloud,
                    onTap: () => Navigator.pushNamed(context, '/cloud'),
                  ),
                  _WireframeBox(
                    label: 'Blockchain',
                    icon: Icons.lock,
                    onTap: () => Navigator.pushNamed(context, '/blockchain'),
                  ),
                  _WireframeBox(
                    label: 'About',
                    icon: Icons.info_outline,
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.home, color: Colors.grey),
                  Icon(Icons.camera_alt, color: Colors.grey),
                  Icon(Icons.blur_circular, color: Colors.grey),
                  Icon(Icons.settings, color: Colors.grey),
                ],
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.blueGrey,
                tooltip: 'Action',
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WireframeBox extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const _WireframeBox({required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 36, color: Colors.blueGrey),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}

// New screens for Notifications, Cloud, Blockchain, and About
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: ListView(
        children: [
          ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Welcome to the app!')),
          ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Your scan is complete.')),
          ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Cloud sync successful.')),
        ],
      ),
    );
  }
}

class CloudScreen extends StatelessWidget {
  const CloudScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cloud')),
      body: Center(
          child: Text('Cloud status: Connected\nFiles: 3 uploaded',
              textAlign: TextAlign.center)),
    );
  }
}

class BlockchainScreen extends StatelessWidget {
  const BlockchainScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blockchain')),
      body: Center(child: Text('Blockchain integration coming soon!')),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
            'Dot Hull Accessible App\nVersion 1.0.0\nAccessible, cross-platform, and feature-rich.',
            textAlign: TextAlign.center),
      ),
    );
  }
}
