import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Test version of the app that doesn't require Firebase initialization
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  
  const TestAppWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dot Hull Accessible App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: child,
    );
  }
}

/// Simplified home screen for testing
class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dot Hull Accessible App'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.blue[100]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo section
              Container(
                height: 200,
                child: SvgPicture.asset(
                  'assets/logo_kabbalah.svg',
                  semanticsLabel: 'Kabbalah Tree of Life',
                  height: 150,
                ),
              ),
              const SizedBox(height: 20),
              
              // Alternative PNG logo
              Image.asset(
                'assets/logo.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 30),
              
              // Control buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(
                    message: 'Switch between light and dark themes',
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Theme'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('View'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Export'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Navigation grid
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavButton('Camera', Icons.camera_alt, () {
                        Navigator.pushNamed(context, '/camera');
                      }),
                      _buildNavButton('Lens', Icons.center_focus_strong, () {
                        Navigator.pushNamed(context, '/lens');
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavButton('Settings', Icons.settings, () {
                        Navigator.pushNamed(context, '/settings');
                      }),
                      _buildNavButton('Braille Translator', Icons.translate, () {
                        Navigator.pushNamed(context, '/braille');
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
