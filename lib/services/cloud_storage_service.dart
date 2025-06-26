import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Model for translation history
class TranslationRecord {
  final String id;
  final String originalText;
  final String translatedText;
  final String standard;
  final String language;
  final bool isReverse;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String userId;

  TranslationRecord({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.standard,
    required this.language,
    required this.isReverse,
    required this.timestamp,
    this.metadata,
    required this.userId,
  });

  factory TranslationRecord.fromMap(Map<String, dynamic> map, String id) {
    return TranslationRecord(
      id: id,
      originalText: map['originalText'] ?? '',
      translatedText: map['translatedText'] ?? '',
      standard: map['standard'] ?? 'grade1',
      language: map['language'] ?? 'en',
      isReverse: map['isReverse'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'],
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'standard': standard,
      'language': language,
      'isReverse': isReverse,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'userId': userId,
    };
  }
}

/// Service for cloud storage and translation history management
class CloudStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save translation to cloud
  Future<String> saveTranslation(TranslationRecord translation) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc =
        await _firestore.collection('translations').add(translation.toMap());

    // Update user statistics
    await _updateUserStats(translation);

    return doc.id;
  }

  // Get user's translation history
  Stream<List<TranslationRecord>> getTranslationHistory({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('translations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TranslationRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete translation
  Future<void> deleteTranslation(String translationId) async {
    await _firestore.collection('translations').doc(translationId).delete();
  }

  // Export translation history to JSON
  Future<String> exportTranslationHistory() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final translations = await _firestore
        .collection('translations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    final data = {
      'user': user.uid,
      'exportDate': DateTime.now().toIso8601String(),
      'totalTranslations': translations.docs.length,
      'translations': translations.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
                'timestamp': (doc.data()['timestamp'] as Timestamp)
                    .toDate()
                    .toIso8601String(),
              })
          .toList(),
    };

    return jsonEncode(data);
  }

  // Upload exported data to Firebase Storage
  Future<String> uploadExportedData(String jsonData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileName =
        'translations_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final ref = _storage.ref().child('exports/${user.uid}/$fileName');

    final uploadTask = ref.putData(
      Uint8List.fromList(utf8.encode(jsonData)),
      SettableMetadata(contentType: 'application/json'),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final translationsSnapshot = await _firestore
        .collection('translations')
        .where('userId', isEqualTo: user.uid)
        .get();

    // Calculate additional statistics
    final translations = translationsSnapshot.docs;
    final standardCounts = <String, int>{};
    final languageCounts = <String, int>{};
    int totalCharacters = 0;

    for (final doc in translations) {
      final data = doc.data();
      final standard = data['standard'] ?? 'grade1';
      final language = data['language'] ?? 'en';
      final originalText = data['originalText'] ?? '';

      standardCounts[standard] = (standardCounts[standard] ?? 0) + 1;
      languageCounts[language] = (languageCounts[language] ?? 0) + 1;
      totalCharacters += originalText.length as int;
    }

    return {
      'totalTranslations': translations.length,
      'totalCharacters': totalCharacters,
      'mostUsedStandard': standardCounts.isNotEmpty
          ? standardCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : 'grade1',
      'mostUsedLanguage': languageCounts.isNotEmpty
          ? languageCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : 'en',
      'standardBreakdown': standardCounts,
      'languageBreakdown': languageCounts,
      'averageCharactersPerTranslation':
          translations.isNotEmpty ? totalCharacters / translations.length : 0,
      'memberSince': userData['createdAt'],
      'lastActivity': userData['lastLoginAt'],
    };
  }

  // Search translations
  Future<List<TranslationRecord>> searchTranslations(String query) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Note: Firestore doesn't support full-text search natively
    // This is a basic implementation that searches by exact matches
    final results = await _firestore
        .collection('translations')
        .where('userId', isEqualTo: user.uid)
        .where('originalText', isGreaterThanOrEqualTo: query)
        .where('originalText', isLessThan: '$query\uf8ff')
        .orderBy('originalText')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return results.docs
        .map((doc) => TranslationRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get favorite translations (most recently accessed)
  Future<List<TranslationRecord>> getFavoriteTranslations(
      {int limit = 10}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final results = await _firestore
        .collection('translations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return results.docs
        .map((doc) => TranslationRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Update user statistics
  Future<void> _updateUserStats(TranslationRecord translation) async {
    final userDoc = _firestore.collection('users').doc(translation.userId);

    await userDoc.update({
      'usage.translationsCount': FieldValue.increment(1),
      'usage.totalCharactersTranslated':
          FieldValue.increment(translation.originalText.length),
      'usage.favoriteStandard': translation.standard,
      'lastTranslationAt': FieldValue.serverTimestamp(),
    });
  }

  // Sync offline translations (for future offline support)
  Future<void> syncOfflineTranslations(
      List<TranslationRecord> offlineTranslations) async {
    final batch = _firestore.batch();

    for (final translation in offlineTranslations) {
      final doc = _firestore.collection('translations').doc();
      batch.set(doc, translation.toMap());
    }

    await batch.commit();
  }

  // Clear all user data (for account deletion)
  Future<void> clearAllUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // Delete translations
    final translations = await _firestore
        .collection('translations')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final doc in translations.docs) {
      batch.delete(doc.reference);
    }

    // Delete user document
    batch.delete(_firestore.collection('users').doc(user.uid));

    await batch.commit();

    // Delete storage files
    try {
      final storageRef = _storage.ref().child('exports/${user.uid}');
      final listResult = await storageRef.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Storage files might not exist, that's okay
      debugPrint('No storage files to delete or error deleting: $e');
    }
  }
}
