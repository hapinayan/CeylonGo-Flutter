import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/user_model.dart';

/// Exception thrown when secure storage operations fail.
/// Sanitized to ensure no sensitive tokens or data are leaked.
class SecureStorageException implements Exception {
  final String message;

  const SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}

/// CeylonGo Platform Secure JWT & Session Storage
/// Backed by Android Keystore / EncryptedSharedPreferences
/// Strictly conforms to Section 7 of Specification v1.0
class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Keys used for secure storage
  static const String _keyAccessToken = 'ceylongo_access_token';
  static const String _keyUserProfile = 'ceylongo_user_profile';
  static const String _keyVendorDemoSession = 'ceylongo_vendor_demo_session';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Securely persist the JWT access token.
  /// Tokens and passwords are never logged or exposed.
  Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) {
      throw const SecureStorageException('Cannot save an empty access token.');
    }
    try {
      await _storage.write(key: _keyAccessToken, value: token);
    } catch (_) {
      throw const SecureStorageException(
        'Failed to securely save access token.',
      );
    }
  }

  /// Retrieve the stored JWT access token.
  /// Returns null if no token exists.
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (_) {
      throw const SecureStorageException(
        'Failed to retrieve access token from secure storage.',
      );
    }
  }

  /// Check whether an access token currently exists.
  Future<bool> hasToken() async {
    try {
      final token = await _storage.read(key: _keyAccessToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Delete the access token from secure storage.
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _keyAccessToken);
    } catch (_) {
      throw const SecureStorageException('Failed to delete access token.');
    }
  }

  /// Persist traveler user profile (id, full_name, email, role).
  /// Note: Passwords are NEVER stored.
  Future<void> saveUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _keyUserProfile, value: userJson);
    } catch (_) {
      throw const SecureStorageException('Failed to save user profile.');
    }
  }

  /// Retrieve stored traveler user profile.
  Future<UserModel?> getUser() async {
    try {
      final userJson = await _storage.read(key: _keyUserProfile);
      if (userJson == null || userJson.isEmpty) {
        return null;
      }
      final Map<String, dynamic> data = jsonDecode(userJson);
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Persist clearly labeled offline demo vendor session metadata.
  /// Never stored in [_keyAccessToken] or [_keyUserProfile] so it is never
  /// confused with real backend authentication.
  Future<void> saveVendorDemoSession(Map<String, dynamic> demoData) async {
    try {
      final sanitized = <String, dynamic>{
        ...demoData,
        'is_demo_session': true,
      };
      await _storage.write(
        key: _keyVendorDemoSession,
        value: jsonEncode(sanitized),
      );
    } catch (_) {
      throw const SecureStorageException(
        'Failed to save demo vendor session.',
      );
    }
  }

  /// Retrieve clearly labeled offline demo vendor session metadata, if present.
  Future<Map<String, dynamic>?> getVendorDemoSession() async {
    try {
      final raw = await _storage.read(key: _keyVendorDemoSession);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final Map<String, dynamic> data = jsonDecode(raw);
      if (data['is_demo_session'] != true) {
        return null;
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Delete the offline demo vendor session from secure storage.
  Future<void> clearVendorDemoSession() async {
    try {
      await _storage.delete(key: _keyVendorDemoSession);
    } catch (_) {
      throw const SecureStorageException(
        'Failed to clear demo vendor session.',
      );
    }
  }

  /// Clear all stored authentication data (token, profile, and demo session) during logout.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyUserProfile);
      await _storage.delete(key: _keyVendorDemoSession);
    } catch (_) {
      throw const SecureStorageException(
        'Failed to clear authentication data.',
      );
    }
  }
}
