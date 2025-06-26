import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'test_app.dart';
import 'test_setup.dart';

void main() {
  // Set up Firebase mock before running tests
  setUpAll(() async {
    await TestSetup.initializeFirebaseForTesting();
  });

  group('Firebase Initialization Tests', () {
    testWidgets('App loads without Firebase errors',
        (WidgetTester tester) async {
      // This test verifies that the app can load without Firebase initialization issues
      await tester.pumpWidget(const TestDotHullAccessibleApp());

      // Verify theme configuration
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.visualDensity,
          equals(VisualDensity.adaptivePlatformDensity));

      // Check app title and initial route
      expect(app.title, equals('Dot Hull Accessible App'));
      expect(app.initialRoute, equals('/login'));

      // Verify routes are configured
      expect(app.routes, isNotNull);
      expect(app.routes?.length, greaterThan(5));
    });

    testWidgets('Home screen displays without Firebase dependencies',
        (WidgetTester tester) async {
      // Test the home screen directly without Firebase
      await tester.pumpWidget(MaterialApp(home: MockHomeScreen()));
      await tester.pumpAndSettle();

      // Verify app title in AppBar
      expect(find.text('Dot Hull Accessible App'), findsOneWidget);

      // Check for modern UI components
      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify SVG logo presence and semantic labeling
      expect(find.byType(SvgPicture), findsOneWidget);
      final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgWidget.semanticsLabel, equals('Kabbalah Tree of Life'));
    });

    testWidgets('Login screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: MockLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('Navigation structure is properly set up',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestDotHullAccessibleApp());
      await tester.pumpAndSettle();

      // The app should start on login screen as per initialRoute
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });

  group('Theme & Layout Tests', () {
    testWidgets('App uses correct theme configuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestDotHullAccessibleApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      // Check that theme is properly configured
      expect(app.theme, isNotNull);
      expect(app.theme?.visualDensity,
          equals(VisualDensity.adaptivePlatformDensity));
      expect(app.theme?.colorScheme, isNotNull);
    });

    testWidgets('Drawer navigation works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: MockHomeScreen()));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer content
      expect(find.text('App Menu'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
