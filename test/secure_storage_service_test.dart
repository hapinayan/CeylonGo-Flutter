import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';

/// In-memory mock/fake implementation of FlutterSecureStorage for testing
class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  bool throwErrorOnNextCall = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwErrorOnNextCall) {
      throw Exception('Simulated Keystore Exception');
    }
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwErrorOnNextCall) {
      throw Exception('Simulated Keystore Exception');
    }
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwErrorOnNextCall) {
      throw Exception('Simulated Keystore Exception');
    }
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwErrorOnNextCall) {
      throw Exception('Simulated Keystore Exception');
    }
    _data.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwErrorOnNextCall) {
      throw Exception('Simulated Keystore Exception');
    }
    return _data.containsKey(key);
  }
}

void main() {
  group('SecureStorageService Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStorageService storageService;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      storageService = SecureStorageService(storage: fakeStorage);
    });

    test('saveToken securely writes token and getToken retrieves it', () async {
      const sampleJwt = 'header.payload.signature_jwt_token';

      await storageService.saveToken(sampleJwt);
      final retrievedToken = await storageService.getToken();

      expect(retrievedToken, equals(sampleJwt));
      expect(await storageService.hasToken(), isTrue);
    });

    test('saveToken rejects empty token with SecureStorageException', () async {
      expect(
        () => storageService.saveToken(''),
        throwsA(isA<SecureStorageException>()),
      );
      expect(
        () => storageService.saveToken('   '),
        throwsA(isA<SecureStorageException>()),
      );
    });

    test('deleteToken removes the access token', () async {
      await storageService.saveToken('test.jwt.token');
      expect(await storageService.hasToken(), isTrue);

      await storageService.deleteToken();

      expect(await storageService.getToken(), isNull);
      expect(await storageService.hasToken(), isFalse);
    });

    test(
      'saveUser and getUser persist and restore UserModel without password',
      () async {
        const user = UserModel(
          id: '550e8400-e29b-41d4-a716-446655440000',
          fullName: 'Test Traveler',
          email: 'traveler@example.com',
          role: 'traveler',
        );

        await storageService.saveUser(user);
        final retrievedUser = await storageService.getUser();

        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.id, equals(user.id));
        expect(retrievedUser.fullName, equals('Test Traveler'));
        expect(retrievedUser.email, equals('traveler@example.com'));
        expect(retrievedUser.role, equals('traveler'));
      },
    );

    test(
      'clear removes both JWT access token and user profile during logout',
      () async {
        await storageService.saveToken('logout.test.token');
        await storageService.saveUser(
          const UserModel(
            id: 'user-123',
            fullName: 'Logged User',
            email: 'user@example.com',
            role: 'traveler',
          ),
        );

        expect(await storageService.hasToken(), isTrue);
        expect(await storageService.getUser(), isNotNull);

        // Perform logout clear
        await storageService.clear();

        expect(await storageService.getToken(), isNull);
        expect(await storageService.hasToken(), isFalse);
        expect(await storageService.getUser(), isNull);
      },
    );

    test(
      'handles platform storage errors safely without revealing sensitive data',
      () async {
        fakeStorage.throwErrorOnNextCall = true;

        expect(
          () => storageService.saveToken('sensitive_jwt_token_123'),
          throwsA(
            isA<SecureStorageException>().having(
              (e) => e.message,
              'message',
              equals('Failed to securely save access token.'),
            ),
          ),
        );

        expect(
          () => storageService.getToken(),
          throwsA(
            isA<SecureStorageException>().having(
              (e) => e.message,
              'message',
              equals('Failed to retrieve access token from secure storage.'),
            ),
          ),
        );
      },
    );
  });
}
