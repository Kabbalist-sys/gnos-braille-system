# Gnos Braille System

A comprehensive, modern, accessible cross-platform Flutter application for Braille translation, OCR, and cloud-based features with advanced user management and analytics.

## 🌟 Features

### 🔤 Advanced Braille Translation
- **Multi-Standard Support**: Grade 1 (Uncontracted), Grade 2 (Contracted), Grade 3 (Shorthand), Computer Braille, Math/Science, and Music Notation
- **Multi-Language Support**: English, Spanish, French, German, Italian, Portuguese, Russian, Chinese, Japanese, Arabic
- **Bidirectional Translation**: Text to Braille and Braille to Text
- **Real-time Translation**: Instant translation with metadata and statistics
- **Custom Formatting**: Advanced output formatting options

### 🔐 User Authentication & Management
- **Multiple Sign-in Options**: Email/Password, Google Sign-in, Anonymous access
- **User Profiles**: Customizable user profiles with display names and photos
- **Account Management**: Password reset, email verification, account deletion
- **Secure Authentication**: Firebase Auth integration with comprehensive error handling

### ☁️ Cloud Storage & Sync
- **Translation History**: Automatic saving of all translations with metadata
- **Cross-Platform Sync**: Access your translations across all devices
- **Data Export**: Export translation history as CSV files
- **Cloud Backup**: Secure Firebase Firestore and Storage integration
- **Search & Filter**: Advanced search through translation history

### 📊 Analytics & Insights
- **Usage Statistics**: Track translation counts, characters translated, languages used
- **Performance Metrics**: Average translation time, success rates, API call statistics
- **Visual Analytics**: Interactive charts and progress indicators
- **Activity Timeline**: Recent translation activity with detailed breakdowns
- **Language & Standard Analysis**: Usage patterns and preferences

### 📱 Modern User Interface
- **Material Design 3**: Clean, accessible interface following Material Design guidelines
- **Responsive Layout**: Optimized for phones, tablets, and desktop
- **Navigation Drawer**: Easy access to all app features
- **Dark/Light Theme**: Customizable theme preferences
- **Accessibility First**: Built with accessibility as a core principle

### 🛠️ Advanced Settings
- **Braille Preferences**: Customize default standards and languages
- **Translation Options**: Configure metadata inclusion, formatting, auto-save
- **App Preferences**: Theme selection, notifications, data management
- **Account Settings**: Profile management, password changes, data export

### 📷 Camera & OCR Integration
- **Text Recognition**: Extract text from images using Google ML Kit
- **Real-time OCR**: Live text recognition from camera feed
- **Multi-language OCR**: Support for multiple languages
- **Direct Translation**: Instant translation of recognized text to Braille

## 🏗️ Architecture

### Backend Services
- **Python REST API**: High-performance Braille translation service
- **Multi-standard Processing**: Support for various Braille standards and languages
- **Metadata Generation**: Comprehensive translation statistics and information
- **Error Handling**: Robust error handling and logging

### Frontend Architecture
- **Flutter Framework**: Cross-platform mobile and web application
- **Service Layer**: Modular service architecture for API, authentication, and storage
- **State Management**: Efficient state management with StatefulWidget pattern
- **Responsive Design**: Adaptive UI components for different screen sizes

### Cloud Infrastructure
- **Firebase Suite**: Complete backend-as-a-service solution
  - **Authentication**: Multi-provider auth with custom user management
  - **Firestore**: NoSQL database for user data and translation history
  - **Storage**: File storage for exports and user assets
  - **Analytics**: App usage and performance monitoring

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Python 3.8+ (for API server)
- Firebase project setup
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/gnos_braille_system.git
   cd gnos_braille_system
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Python API server:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Firebase:**
   - Create a new Firebase project
   - Enable Authentication, Firestore, and Storage
   - Download configuration files
   - Run: `flutterfire configure`

5. **Start the API server:**
   ```bash
   python braille_api.py
   # Or use the provided batch script:
   start_api_server.bat
   ```

6. **Run the Flutter app:**
   ```bash
   flutter run
   ```

## 📚 API Documentation

The Braille translation API provides comprehensive endpoints for text processing:

### Endpoints
- `POST /translate` - Translate text to/from Braille
- `GET /standards` - List supported Braille standards
- `GET /languages` - List supported languages
- `GET /health` - API health check

### Example Usage
```python
import requests

response = requests.post('http://localhost:5000/translate', json={
    'text': 'Hello World',
    'standard': 'grade2',
    'language': 'en',
    'reverse': False,
    'format_output': True,
    'include_metadata': True
})

result = response.json()
print(result['result'])  # Braille output
print(result['metadata'])  # Translation statistics
```

## 🧪 Testing

### Run Flutter Tests
```bash
flutter test
```

### Run API Tests
```bash
python -m pytest tests/
```

### Integration Testing
```bash
flutter drive --target=test_driver/app.dart
```

## 📦 Dependencies

### Flutter Dependencies
- **firebase_core**: Firebase initialization
- **firebase_auth**: User authentication
- **cloud_firestore**: Database operations
- **firebase_storage**: File storage
- **google_sign_in**: Google authentication
- **http**: API communication
- **camera**: Camera access
- **google_ml_kit**: OCR functionality

### Python Dependencies
- **flask**: Web framework
- **flask-cors**: Cross-origin resource sharing
- **pybraille**: Braille translation library
- **louis**: Liblouis Braille translator

## 🛠️ Configuration

### Firebase Setup
1. Create Firebase project
2. Enable required services
3. Download configuration files
4. Configure authentication providers

### API Configuration
- Server runs on `localhost:5000` by default
- Configure endpoint in `lib/services/braille_api_service.dart`
- Adjust timeout and retry settings as needed

## 🔒 Security

- **Data Encryption**: All data encrypted in transit and at rest
- **Authentication**: Secure Firebase Auth with multiple providers
- **Privacy**: User data handled according to privacy best practices
- **Access Control**: Role-based access to features and data

## 🌐 Platform Support

- **Android**: Full feature support
- **iOS**: Full feature support (with iOS-specific configurations)
- **Web**: Core features supported
- **Windows**: Desktop support (beta)
- **macOS**: Desktop support (beta)
- **Linux**: Desktop support (beta)

## 📈 Performance

- **Optimized Translation**: Sub-second response times
- **Efficient Caching**: Smart caching for improved performance
- **Minimal Bundle Size**: Optimized app size and resource usage
- **Battery Optimization**: Efficient resource management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write comprehensive tests
- Update documentation
- Ensure accessibility compliance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Liblouis Project**: Braille translation engine
- **Flutter Team**: Amazing cross-platform framework
- **Firebase**: Comprehensive backend services
- **Google ML Kit**: Advanced OCR capabilities
- **Accessibility Community**: Guidance on inclusive design

## 📞 Support

- **Documentation**: [API Documentation](API_DOCUMENTATION.md)
- **Issues**: [GitHub Issues](https://github.com/yourusername/gnos_braille_system/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/gnos_braille_system/discussions)

## 🗺️ Roadmap

### Upcoming Features
- **Offline Mode**: Full functionality without internet connection
- **Voice Recognition**: Speech-to-Braille translation
- **Advanced OCR**: Handwriting recognition and math equations
- **Collaborative Features**: Share translations with other users
- **Advanced Analytics**: Machine learning insights and recommendations
- **Multi-device Sync**: Real-time synchronization across devices
- **Plugin System**: Extensible architecture for custom features

---

**Built with ❤️ for the accessibility community**
