import 'dart:typed_data';

enum IdentityDocKind {
  selfie('selfie', 'Provider Selfie'),
  nicFront('nic_front', 'NIC Front'),
  nicBack('nic_back', 'NIC Back');

  final String fieldName;
  final String label;

  const IdentityDocKind(this.fieldName, this.label);
}

class IdentityValidationException implements Exception {
  final String message;

  const IdentityValidationException(this.message);

  @override
  String toString() => message;
}

/// In-memory representation of a validated identity document image.
/// Bytes stay strictly in memory and are never persisted to local app storage
/// or logged.
class IdentityDocumentFile {
  final IdentityDocKind kind;
  final String safeFilename;
  final String mimeType;
  final Uint8List bytes;

  const IdentityDocumentFile({
    required this.kind,
    required this.safeFilename,
    required this.mimeType,
    required this.bytes,
  });

  int get sizeBytes => bytes.length;
}

/// Validates identity document images against CeylonGo-Backend requirements:
/// - Permitted formats: JPEG, PNG, WEBP (verified via magic-byte signatures,
///   not extension alone)
/// - Maximum size: 5 MB (5 * 1024 * 1024 bytes)
/// - Non-empty content
class IdentityDocumentValidator {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  static const Set<String> allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static const Set<String> allowedMimeTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  /// Validates [bytes] along with optional [filename] and [mimeType].
  /// Returns the canonical validated MIME type (`image/jpeg`, `image/png`, or
  /// `image/webp`) or throws [IdentityValidationException].
  static String validate({
    required IdentityDocKind kind,
    required Uint8List bytes,
    String? filename,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      throw IdentityValidationException(
        '${kind.label} file is empty or unreadable.',
      );
    }

    if (bytes.length > maxFileSizeBytes) {
      throw IdentityValidationException(
        '${kind.label} exceeds the 5 MB maximum upload size.',
      );
    }

    if (filename != null && filename.trim().isNotEmpty) {
      final lowerName = filename.trim().toLowerCase();
      final hasDot = lowerName.contains('.');
      if (hasDot && !allowedExtensions.any(lowerName.endsWith)) {
        throw IdentityValidationException(
          '${kind.label} must be a JPEG, PNG, or WEBP image.',
        );
      }
    }

    if (mimeType != null && mimeType.trim().isNotEmpty) {
      final lowerMime = mimeType.trim().toLowerCase();
      if (!allowedMimeTypes.contains(lowerMime)) {
        throw IdentityValidationException(
          '${kind.label} has an unsupported media type. Use JPEG, PNG, or WEBP.',
        );
      }
    }

    final detectedMime = detectImageMimeFromBytes(bytes);
    if (detectedMime == null) {
      throw IdentityValidationException(
        '${kind.label} is not a valid JPEG, PNG, or WEBP image file.',
      );
    }

    return detectedMime;
  }

  /// Inspects magic-byte file signatures so spoofed extensions are rejected
  /// before upload.
  static String? detectImageMimeFromBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      // JPEG can theoretically be shorter, check 3-byte SOI marker first
      if (bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF) {
        return 'image/jpeg';
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
        return 'image/png';
      }
      return null;
    }

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    // WEBP: "RIFF" .... "WEBP"
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return null;
  }

  static String extensionForMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/jpeg':
      default:
        return '.jpg';
    }
  }
}

/// Response from `POST /api/v1/providers/otp/verify`.
class ProviderOtpVerifyResult {
  final bool verified;
  final String? nextAction;
  final String? authorizationToken;
  final int? expiresIn;
  final String? message;

  const ProviderOtpVerifyResult({
    required this.verified,
    this.nextAction,
    this.authorizationToken,
    this.expiresIn,
    this.message,
  });

  factory ProviderOtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return ProviderOtpVerifyResult(
      verified: json['verified'] as bool? ?? false,
      nextAction: json['next_action'] as String?,
      authorizationToken: json['authorization_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      message: json['message'] as String?,
    );
  }
}

/// Response from `POST /api/v1/providers/registration/identity` and
/// `GET /api/v1/providers/registration/draft` (`DraftResponse`).
class ProviderDraftStatus {
  final String email;
  final String identityDocumentType;
  final bool selfieUploaded;
  final bool nicFrontUploaded;
  final bool nicBackUploaded;
  final bool personalCompleted;
  final bool businessCompleted;
  final bool identityCompleted;
  final String currentStep;

  const ProviderDraftStatus({
    required this.email,
    this.identityDocumentType = 'nic',
    this.selfieUploaded = false,
    this.nicFrontUploaded = false,
    this.nicBackUploaded = false,
    this.personalCompleted = false,
    this.businessCompleted = false,
    this.identityCompleted = false,
    this.currentStep = 'personal',
  });

  factory ProviderDraftStatus.fromJson(Map<String, dynamic> json) {
    return ProviderDraftStatus(
      email: (json['email'] as String?) ?? '',
      identityDocumentType:
          (json['identity_document_type'] as String?) ?? 'nic',
      selfieUploaded: json['selfie_uploaded'] as bool? ?? false,
      nicFrontUploaded: json['nic_front_uploaded'] as bool? ?? false,
      nicBackUploaded: json['nic_back_uploaded'] as bool? ?? false,
      personalCompleted: json['personal_completed'] as bool? ?? false,
      businessCompleted: json['business_completed'] as bool? ?? false,
      identityCompleted: json['identity_completed'] as bool? ?? false,
      currentStep: (json['current_step'] as String?) ?? 'personal',
    );
  }
}

