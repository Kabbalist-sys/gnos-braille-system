import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';

/// Service class for user authentication and management
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Production security: Rate limiting and validation
      if (FirebaseConfig.isProduction) {
        await _validateSignInAttempt(email);
      }
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login time
      await updateLastLogin();
      
      // Log successful sign-in for analytics
      if (FirebaseConfig.enableAnalytics) {
        await _logAuthEvent('sign_in_success', {'method': 'email'});
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Log failed attempts for security monitoring
      if (FirebaseConfig.isProduction) {
        await _logFailedSignInAttempt(email, e.code);
      }
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      // Production security: Validate registration data
      if (FirebaseConfig.isProduction) {
        _validateRegistrationData(email, password, displayName);
      }
      
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile
      await userCredential.user?.updateDisplayName(displayName);
      
      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, displayName);
      
      // Log successful registration
      if (FirebaseConfig.enableAnalytics) {
        await _logAuthEvent('sign_up_success', {'method': 'email'});
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      
      // Create anonymous user document
      await _createUserDocument(userCredential.user!, 'Anonymous User');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Enhanced sign in with Google with production security
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Production security: Check if Google sign-in is enabled
      if (FirebaseConfig.isProduction && !_isGoogleSignInEnabled()) {
        throw Exception('Google sign-in is currently disabled');
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Create user document if it doesn't exist
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocument(
          userCredential.user!, 
          userCredential.user?.displayName ?? 'Google User'
        );
      }
      
      // Update last login time
      await updateLastLogin();
      
      // Log successful Google sign-in
      if (FirebaseConfig.enableAnalytics) {
        await _logAuthEvent('sign_in_success', {'method': 'google'});
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  // Enhanced sign out with cleanup
  Future<void> signOut() async {
    try {
      // Clean up any cached data
      await _cleanupUserSession();
      
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Log sign out event
      if (FirebaseConfig.enableAnalytics) {
        await _logAuthEvent('sign_out', {});
      }
    } catch (e) {
      // Don't throw errors on sign out to avoid blocking user
      if (kDebugMode) {
        print('Sign out error: $e');
      }
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        
        // Update user document in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': displayName ?? user.displayName,
          'photoURL': photoURL ?? user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _deleteUserData(user.uid);
        
        // Delete user account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'isAnonymous': user.isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'settings': {
        'brailleStandard': 'grade1',
        'language': 'en',
        'theme': 'light',
        'notifications': true,
      },
      'usage': {
        'translationsCount': 0,
        'totalCharactersTranslated': 0,
        'favoriteStandard': 'grade1',
      }
    });
  }

  // Delete user data from Firestore
  Future<void> _deleteUserData(String uid) async {
    final batch = _firestore.batch();
    
    // Delete user document
    batch.delete(_firestore.collection('users').doc(uid));
    
    // Delete user's translations
    final translations = await _firestore
        .collection('translations')
        .where('userId', isEqualTo: uid)
        .get();
    
    for (final doc in translations.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Security validation methods
  Future<void> _validateSignInAttempt(String email) async {
    // Check for rate limiting in production
    final now = DateTime.now();
    final attempts = await _getRecentSignInAttempts(email);
    
    if (attempts.length >= 5) {
      final lastAttempt = attempts.last;
      final timeDiff = now.difference(lastAttempt).inMinutes;
      
      if (timeDiff < 15) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many sign-in attempts. Please try again later.',
        );
      }
    }
  }

  void _validateRegistrationData(String email, String password, String displayName) {
    // Email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }
    
    // Password strength validation
    if (password.length < 8) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 8 characters long.',
      );
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must contain at least one uppercase letter, one lowercase letter, and one number.',
      );
    }
    
    // Display name validation
    if (displayName.trim().length < 2) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Display name must be at least 2 characters long.',
      );
    }
    
    if (displayName.length > 50) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Display name must be less than 50 characters.',
      );
    }
  }

  bool _isGoogleSignInEnabled() {
    // Check if Google sign-in is enabled in production
    // This could be controlled by remote config
    return true; // For now, always enabled
  }

  Future<List<DateTime>> _getRecentSignInAttempts(String email) async {
    try {
      final doc = await _firestore
          .collection('security')
          .doc('sign_in_attempts')
          .collection(email.hashCode.toString())
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      return doc.docs
          .map((doc) => (doc.data()['timestamp'] as Timestamp).toDate())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _logFailedSignInAttempt(String email, String errorCode) async {
    try {
      await _firestore
          .collection('security')
          .doc('sign_in_attempts')
          .collection(email.hashCode.toString())
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'errorCode': errorCode,
        'success': false,
      });
    } catch (e) {
      // Don't throw errors for logging failures
      if (kDebugMode) {
        print('Failed to log sign-in attempt: $e');
      }
    }
  }

  Future<void> _logAuthEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      // Log to analytics service
      if (FirebaseConfig.enableAnalytics) {
        // This would integrate with Firebase Analytics
        // await FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
      }
      
      // Log to custom analytics collection for detailed tracking
      await _firestore.collection('analytics').add({
        'event': eventName,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Don't throw errors for analytics logging
      if (kDebugMode) {
        print('Failed to log auth event: $e');
      }
    }
  }

  Future<void> _cleanupUserSession() async {
    try {
      // Clear any cached data, temporary files, etc.
      // This is where you'd clean up user-specific caches
      if (kDebugMode) {
        print('User session cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup user session: $e');
      }
    }
  }
}
