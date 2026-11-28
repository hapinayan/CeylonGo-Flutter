import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/traveler_profile_photo_models.dart';

class TravelerPhotoStorageException implements Exception {
  final String message;
  const TravelerPhotoStorageException(this.message);

  @override
  String toString() => message;
}

/// Account-isolated local-only storage for Traveler profile photos.
/// Never stores bytes in JWT/auth storage keys and never shares across accounts.
abstract class TravelerProfilePhotoStore {
  Future<TravelerProfilePhotoData?> loadForAccount(String accountKey);
  Future<TravelerProfilePhotoData> saveForAccount({
    required String accountKey,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  });
  Future<void> removeForAccount(String accountKey);
}

/// Derives a safe, deterministic, non-sensitive local file slug for an account.
String deriveSafeAccountSlug(String accountKey) {
  final clean = accountKey.trim().toLowerCase();
  if (clean.isEmpty) return 'anonymous';
  var hash = 2166136261;
  for (final code in utf8.encode(clean)) {
    hash ^= code;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return 'acct_${hash.toRadixString(16).padLeft(8, '0')}';
}

class FileTravelerProfilePhotoStore implements TravelerProfilePhotoStore {
  final Future<Directory> Function() _directoryProvider;

  FileTravelerProfilePhotoStore({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  Future<Directory> _avatarDir() async {
    final base = await _directoryProvider();
    final dir = Directory('${base.path}${Platform.pathSeparator}traveler_avatars');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _metaFile(Directory dir, String slug) =>
      File('${dir.path}${Platform.pathSeparator}$slug.json');

  @override
  Future<TravelerProfilePhotoData?> loadForAccount(String accountKey) async {
    final slug = deriveSafeAccountSlug(accountKey);
    try {
      final dir = await _avatarDir();
      final metaFile = _metaFile(dir, slug);
      if (!await metaFile.exists()) return null;

      final decoded = jsonDecode(await metaFile.readAsString());
      if (decoded is! Map) {
        await _deleteQuietly(metaFile);
        return null;
      }

      final ext = decoded['extension'] as String?;
      final mime = decoded['mime_type'] as String?;
      final filename = decoded['file_name'] as String?;
      final updatedRaw = decoded['updated_at'] as String?;
      if (ext == null || mime == null || filename == null) {
        await _deleteQuietly(metaFile);
        return null;
      }

      final imgFile = File('${dir.path}${Platform.pathSeparator}$filename');
      if (!await imgFile.exists()) {
        await _deleteQuietly(metaFile);
        return null;
      }

      final bytes = await imgFile.readAsBytes();
      if (bytes.isEmpty ||
          TravelerProfilePhotoValidator.detectImageSignature(bytes) == null) {
        await _deleteQuietly(imgFile);
        await _deleteQuietly(metaFile);
        return null;
      }

      return TravelerProfilePhotoData(
        bytes: bytes,
        extension: ext,
        mimeType: mime,
        accountKey: accountKey,
        updatedAt: DateTime.tryParse(updatedRaw ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TravelerProfilePhotoData> saveForAccount({
    required String accountKey,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  }) async {
    final slug = deriveSafeAccountSlug(accountKey);
    try {
      final dir = await _avatarDir();
      final metaFile = _metaFile(dir, slug);

      String? oldFilename;
      if (await metaFile.exists()) {
        try {
          final oldDecoded = jsonDecode(await metaFile.readAsString());
          if (oldDecoded is Map) {
            oldFilename = oldDecoded['file_name'] as String?;
          }
        } catch (_) {}
      }

      final now = DateTime.now();
      final newFilename = '${slug}_${now.microsecondsSinceEpoch}$extension';
      final newFile = File('${dir.path}${Platform.pathSeparator}$newFilename');
      await newFile.writeAsBytes(bytes, flush: true);

      await metaFile.writeAsString(
        jsonEncode({
          'file_name': newFilename,
          'extension': extension,
          'mime_type': mimeType,
          'updated_at': now.toIso8601String(),
        }),
        flush: true,
      );

      if (oldFilename != null && oldFilename != newFilename) {
        await _deleteQuietly(
          File('${dir.path}${Platform.pathSeparator}$oldFilename'),
        );
      }

      return TravelerProfilePhotoData(
        bytes: bytes,
        extension: extension,
        mimeType: mimeType,
        accountKey: accountKey,
        updatedAt: now,
      );
    } catch (_) {
      throw const TravelerPhotoStorageException(
        'Could not save profile photo to this device.',
      );
    }
  }

  @override
  Future<void> removeForAccount(String accountKey) async {
    final slug = deriveSafeAccountSlug(accountKey);
    try {
      final dir = await _avatarDir();
      final metaFile = _metaFile(dir, slug);
      if (await metaFile.exists()) {
        try {
          final decoded = jsonDecode(await metaFile.readAsString());
          if (decoded is Map && decoded['file_name'] is String) {
            await _deleteQuietly(
              File('${dir.path}${Platform.pathSeparator}${decoded['file_name']}'),
            );
          }
        } catch (_) {}
        await _deleteQuietly(metaFile);
      }
    } catch (_) {
      throw const TravelerPhotoStorageException(
        'Could not remove stored profile photo.',
      );
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class InMemoryTravelerProfilePhotoStore implements TravelerProfilePhotoStore {
  final Map<String, TravelerProfilePhotoData> _items = {};
  bool failOnSave = false;
  bool failOnRemove = false;

  @override
  Future<TravelerProfilePhotoData?> loadForAccount(String accountKey) async {
    return _items[deriveSafeAccountSlug(accountKey)];
  }

  @override
  Future<TravelerProfilePhotoData> saveForAccount({
    required String accountKey,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  }) async {
    if (failOnSave) {
      throw const TravelerPhotoStorageException(
        'Simulated storage write failure.',
      );
    }
    final data = TravelerProfilePhotoData(
      bytes: bytes,
      extension: extension,
      mimeType: mimeType,
      accountKey: accountKey,
      updatedAt: DateTime.now(),
    );
    _items[deriveSafeAccountSlug(accountKey)] = data;
    return data;
  }

  @override
  Future<void> removeForAccount(String accountKey) async {
    if (failOnRemove) {
      throw const TravelerPhotoStorageException(
        'Simulated storage delete failure.',
      );
    }
    _items.remove(deriveSafeAccountSlug(accountKey));
  }
}

