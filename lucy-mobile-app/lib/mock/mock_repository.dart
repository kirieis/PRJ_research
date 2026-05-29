// lib/mock/mock_repository.dart
// ============================================================
// Project LUCY — Mock Repository
// Loads and parses local JSON mock data from assets.
// Used during Mock-Driven Development (Week 1-2) before
// backend APIs are available.
// ============================================================

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Repository that loads mock JSON data from the assets bundle.
///
/// This class simulates async API calls by reading local JSON files.
/// It will be replaced by a real [ApiRepository] once backend
/// endpoints are deployed and validated against [api-docs.yaml].
class MockRepository {
  /// Path to the Level 1 mock data file.
  static const String _level1Path = 'assets/mock/level_1.json';

  /// Loads and parses the Level 1 mock JSON.
  ///
  /// Returns a [Map<String, dynamic>] that matches the
  /// `Level` schema defined in the OpenAPI specification.
  ///
  /// Throws [FlutterError] if the file cannot be loaded or parsed.
  Future<Map<String, dynamic>> loadLevel() async {
    try {
      final jsonString = await rootBundle.loadString(_level1Path);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return data;
    } catch (e) {
      throw Exception('MockRepository: Failed to load level data — $e');
    }
  }
}
