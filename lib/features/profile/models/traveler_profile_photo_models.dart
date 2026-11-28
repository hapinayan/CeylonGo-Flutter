// Models and client-side image validation for Local Traveler Profile Photo.
// Backend audit confirmed no Traveler avatar upload/sync API exists.

import 'dart:typed_data';

class TravelerPhotoValidationException implements Exception {
  final String message;
  const TravelerPhotoValidationException(this.message);

  @override
  String toString() => message;
}

class TravelerProfilePhotoValidator {
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxDimensionPx = 10000;
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const Set<String> allowedMimeTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  /// Validates bytes, extension/MIME, magic-byte signature, and basic dimensions.
  static ({String extension, String mimeType}) validate({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      throw const TravelerPhotoValidationException(
        'Selected image file is empty.',
      );
    }
    if (bytes.length > maxFileBytes) {
      throw const TravelerPhotoValidationException(
        'Profile photo exceeds the 5 MB maximum size.',
      );
    }

    final detected = detectImageSignature(bytes);
    if (detected == null) {
      throw const TravelerPhotoValidationException(
        'Unsupported or corrupted image. Use a valid JPEG, PNG, or WEBP photo.',
      );
    }

    // Sanity check PNG IHDR dimensions without full pixel decompression.
    if (detected.mimeType == 'image/png' && bytes.length >= 24) {
      final width = _readUint32BE(bytes, 16);
      final height = _readUint32BE(bytes, 20);
      if (width <= 0 ||
          height <= 0 ||
          width > maxDimensionPx ||
          height > maxDimensionPx) {
        throw const TravelerPhotoValidationException(
          'PNG image dimensions are invalid or exceed 10000x10000.',
        );
      }
    }

    final cleanName = filename.trim().toLowerCase();
    final dotIndex = cleanName.lastIndexOf('.');
    if (dotIndex != -1) {
      final ext = cleanName.substring(dotIndex);
      if (!allowedExtensions.contains(ext)) {
        throw const TravelerPhotoValidationException(
          'Unsupported file format. Use JPG, PNG, or WEBP.',
        );
      }
    }

    if (mimeType != null && mimeType.trim().isNotEmpty) {
      final normMime = mimeType.trim().toLowerCase();
      if (!allowedMimeTypes.contains(normMime)) {
        throw const TravelerPhotoValidationException(
          'Unsupported image MIME type. Use JPEG, PNG, or WEBP.',
        );
      }
    }

    return detected;
  }

  static ({String extension, String mimeType})? detectImageSignature(
    Uint8List bytes,
  ) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return (extension: '.jpg', mimeType: 'image/jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return (extension: '.png', mimeType: 'image/png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (extension: '.webp', mimeType: 'image/webp');
    }
    return null;
  }

  static int _readUint32BE(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}

class TravelerProfilePhotoData {
  final Uint8List bytes;
  final String extension;
  final String mimeType;
  final String accountKey;
  final DateTime updatedAt;

  const TravelerProfilePhotoData({
    required this.bytes,
    required this.extension,
    required this.mimeType,
    required this.accountKey,
    required this.updatedAt,
  });
}

