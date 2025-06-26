import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../lib/screens/login_screen.dart';
import '../lib/screens/register_screen.dart';
import '../lib/screens/forgot_password_screen.dart';
import '../lib/screens/user_profile_screen.dart';
import '../lib/screens/translation_history_screen.dart';
import '../lib/screens/settings_screen.dart';
import '../lib/screens/analytics_screen.dart';  
import '../lib/widgets/auth_wrapper.dart';
import '../lib/widgets/app_drawer.dart';

/// Test-only version of the main app that doesn't initialize Firebase
class TestDotHullAccessibleApp extends StatelessWidget {
  const TestDotHullAccessibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dot Hull Accessible App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => MockHomeScreen(),
        '/home': (context) => MockHomeScreen(),
        '/login': (context) => MockLoginScreen(),
        '/register': (context) => MockRegisterScreen(),
        '/forgot-password': (context) => MockForgotPasswordScreen(),
        '/profile': (context) => MockProfileScreen(),
        '/translation-history': (context) => MockTranslationHistoryScreen(),
        '/settings': (context) => MockSettingsScreen(),
        '/analytics': (context) => MockAnalyticsScreen(),
      },
    );
  }
}

/// Mock home screen for testing
class MockHomeScreen extends StatelessWidget {
  const MockHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dot Hull Accessible App'),
      ),
      drawer: const MockAppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with logo
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/logo_kabbalah.svg',
                    height: 120,
                    semanticsLabel: 'Kabbalah Tree of Life',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Dot Hull',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Your Accessible Braille & OCR Companion',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mock implementations for testing
class MockLoginScreen extends StatelessWidget {
  const MockLoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Login Screen'));
}

class MockRegisterScreen extends StatelessWidget {
  const MockRegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Register Screen'));
}

class MockForgotPasswordScreen extends StatelessWidget {
  const MockForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Forgot Password Screen'));
}

class MockProfileScreen extends StatelessWidget {
  const MockProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Profile Screen'));
}

class MockTranslationHistoryScreen extends StatelessWidget {
  const MockTranslationHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Translation History Screen'));
}

class MockSettingsScreen extends StatelessWidget {
  const MockSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Settings Screen'));
}

class MockAnalyticsScreen extends StatelessWidget {
  const MockAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Analytics Screen'));
}

class MockAppDrawer extends StatelessWidget {
  const MockAppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(child: Text('App Menu')),
          ListTile(title: Text('Home')),
          ListTile(title: Text('Profile')),
          ListTile(title: Text('Settings')),
        ],
      ),
    );
  }
}
