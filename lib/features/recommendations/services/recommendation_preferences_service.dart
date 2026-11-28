import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/recommendation_models.dart';

/// Abstraction for storing traveler interest & district preferences locally
/// (kept separate from JWT/auth credentials).
abstract class RecommendationPreferencesStore {
  Future<TravelerPreferences> load();
  Future<void> save(TravelerPreferences preferences);
  Future<void> clear();
}

class SecureRecommendationPreferencesStore
    implements RecommendationPreferencesStore {
  static const String _storageKey = 'ceylongo_traveler_interests_v1';
  final FlutterSecureStorage _storage;

  SecureRecommendationPreferencesStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<TravelerPreferences> load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const TravelerPreferences();
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return TravelerPreferences.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
      return const TravelerPreferences();
    } catch (_) {
      return const TravelerPreferences();
    }
  }

  @override
  Future<void> save(TravelerPreferences preferences) async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(preferences.toJson()),
      );
    } catch (_) {
      // Ignore storage write errors gracefully without crashing UI.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {
      // Ignore storage delete errors gracefully.
    }
  }
}

/// In-memory preferences store for unit/widget tests.
class InMemoryRecommendationPreferencesStore
    implements RecommendationPreferencesStore {
  TravelerPreferences _current;

  InMemoryRecommendationPreferencesStore([
    TravelerPreferences initial = const TravelerPreferences(),
  ]) : _current = initial;

  @override
  Future<TravelerPreferences> load() async => _current;

  @override
  Future<void> save(TravelerPreferences preferences) async {
    _current = preferences;
  }

  @override
  Future<void> clear() async {
    _current = const TravelerPreferences();
  }
}

