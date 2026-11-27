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

/// Response from `POST /api/v1/providers/registration/identity`,
/// `PUT /personal`, `PUT /business`, and `GET /draft` (`DraftResponse`).
class ProviderDraftStatus {
  final String email;
  final String? fullName;
  final String? phone;
  final String identityDocumentType;
  final String? nicNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? permanentProvince;
  final String? permanentDistrict;
  final String? permanentCity;
  final String? permanentLandmark;
  final String? permanentPostalCode;
  final String? businessName;
  final String? providerType;
  final String? secondaryPhone;
  final String? businessProvince;
  final String? businessDistrict;
  final String? businessCity;
  final String? businessLandmark;
  final String? businessPostalCode;
  final String? businessRegistrationNumber;
  final String? description;
  final bool selfieUploaded;
  final bool nicFrontUploaded;
  final bool nicBackUploaded;
  final bool personalCompleted;
  final bool businessCompleted;
  final bool identityCompleted;
  final String currentStep;

  const ProviderDraftStatus({
    required this.email,
    this.fullName,
    this.phone,
    this.identityDocumentType = 'nic',
    this.nicNumber,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.permanentProvince,
    this.permanentDistrict,
    this.permanentCity,
    this.permanentLandmark,
    this.permanentPostalCode,
    this.businessName,
    this.providerType,
    this.secondaryPhone,
    this.businessProvince,
    this.businessDistrict,
    this.businessCity,
    this.businessLandmark,
    this.businessPostalCode,
    this.businessRegistrationNumber,
    this.description,
    this.selfieUploaded = false,
    this.nicFrontUploaded = false,
    this.nicBackUploaded = false,
    this.personalCompleted = false,
    this.businessCompleted = false,
    this.identityCompleted = false,
    this.currentStep = 'personal',
  });

  bool get readyToSubmit =>
      personalCompleted && businessCompleted && identityCompleted;

  factory ProviderDraftStatus.fromJson(Map<String, dynamic> json) {
    return ProviderDraftStatus(
      email: (json['email'] as String?) ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      identityDocumentType:
          (json['identity_document_type'] as String?) ?? 'nic',
      nicNumber: json['nic_number'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      permanentProvince: json['permanent_province'] as String?,
      permanentDistrict: json['permanent_district'] as String?,
      permanentCity: json['permanent_city'] as String?,
      permanentLandmark: json['permanent_landmark'] as String?,
      permanentPostalCode: json['permanent_postal_code'] as String?,
      businessName: json['business_name'] as String?,
      providerType: json['provider_type'] as String?,
      secondaryPhone: json['secondary_phone'] as String?,
      businessProvince: json['business_province'] as String?,
      businessDistrict: json['business_district'] as String?,
      businessCity: json['business_city'] as String?,
      businessLandmark: json['business_landmark'] as String?,
      businessPostalCode: json['business_postal_code'] as String?,
      businessRegistrationNumber:
          json['business_registration_number'] as String?,
      description: json['description'] as String?,
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

/// Request payload for `PUT /api/v1/providers/registration/personal`.
class PersonalDetailsPayload {
  final String fullName;
  final String phone;
  final String dateOfBirth; // YYYY-MM-DD
  final String gender; // Male | Female | Other
  final String nationality;
  final String identityDocumentType; // nic | passport
  final String nicNumber;
  final String permanentProvince;
  final String permanentDistrict;
  final String permanentCity;
  final String permanentLandmark;
  final String permanentPostalCode;

  const PersonalDetailsPayload({
    required this.fullName,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.nationality,
    required this.identityDocumentType,
    required this.nicNumber,
    required this.permanentProvince,
    required this.permanentDistrict,
    required this.permanentCity,
    required this.permanentLandmark,
    required this.permanentPostalCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'date_of_birth': dateOfBirth.trim(),
      'gender': gender.trim(),
      'nationality': nationality.trim(),
      'identity_document_type': identityDocumentType.trim().toLowerCase(),
      'nic_number': nicNumber.trim().toUpperCase(),
      'permanent_province': permanentProvince.trim(),
      'permanent_district': permanentDistrict.trim(),
      'permanent_city': permanentCity.trim(),
      'permanent_landmark': permanentLandmark.trim(),
      'permanent_postal_code': permanentPostalCode.trim(),
    };
  }
}

/// Request payload for `PUT /api/v1/providers/registration/business`.
class BusinessDetailsPayload {
  final String businessName;
  final String providerType;
  final String? secondaryPhone;
  final String? businessProvince;
  final String? businessDistrict;
  final String? businessCity;
  final String? businessLandmark;
  final String? businessPostalCode;
  final String? businessRegistrationNumber;
  final String description;
  final bool sameAsPermanent;

  const BusinessDetailsPayload({
    required this.businessName,
    required this.providerType,
    this.secondaryPhone,
    this.businessProvince,
    this.businessDistrict,
    this.businessCity,
    this.businessLandmark,
    this.businessPostalCode,
    this.businessRegistrationNumber,
    required this.description,
    this.sameAsPermanent = false,
  });

  Map<String, dynamic> toJson() {
    String? cleanOpt(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return {
      'business_name': businessName.trim(),
      'provider_type': providerType.trim().toLowerCase(),
      'secondary_phone': cleanOpt(secondaryPhone),
      'business_province': cleanOpt(businessProvince),
      'business_district': cleanOpt(businessDistrict),
      'business_city': cleanOpt(businessCity),
      'business_landmark': cleanOpt(businessLandmark),
      'business_postal_code': cleanOpt(businessPostalCode),
      'business_registration_number': cleanOpt(businessRegistrationNumber),
      'description': description.trim(),
      'same_as_permanent': sameAsPermanent,
    };
  }
}

/// Response from `POST /api/v1/providers/registration/submit`.
class ProviderRegistrationSubmitResult {
  final bool submitted;
  final String approvalStatus;
  final String nextAction;
  final String message;

  const ProviderRegistrationSubmitResult({
    required this.submitted,
    required this.approvalStatus,
    required this.nextAction,
    required this.message,
  });

  factory ProviderRegistrationSubmitResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProviderRegistrationSubmitResult(
      submitted: json['submitted'] as bool? ?? false,
      approvalStatus: (json['approval_status'] as String?) ?? 'pending',
      nextAction: (json['next_action'] as String?) ?? 'await_admin_review',
      message: (json['message'] as String?) ??
          'Your application has been submitted for review.',
    );
  }
}

enum BackendProviderType {
  homestay('homestay', 'Homestay Provider'),
  tourGuide('tour_guide', 'Local Tour Guide'),
  activity('activity', 'Activity Provider'),
  ecoTourism('eco_tourism', 'Eco Tourism Provider'),
  artisan('artisan', 'Artisan Provider'),
  rental('rental', 'Rental Provider');

  final String apiValue;
  final String displayLabel;

  const BackendProviderType(this.apiValue, this.displayLabel);
}

/// Validators aligned with `PersonalDetailsRequest` and `BusinessDetailsRequest`
/// in `CeylonGo-Backend/app/schemas/provider_registration.py`.
class ProviderOnboardingValidators {
  static final RegExp _oldNicRegex = RegExp(r'^[0-9]{9}[VX]$');
  static final RegExp _newNicRegex = RegExp(r'^[0-9]{12}$');
  static final RegExp _passportRegex = RegExp(r'^[A-Z0-9]{6,12}$');
  static final RegExp _dobRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String? validateRequiredLength(
    String? value, {
    required String label,
    required int minLength,
    required int maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.length < minLength) {
      return '$label must be at least $minLength characters.';
    }
    if (text.length > maxLength) {
      return '$label cannot exceed $maxLength characters.';
    }
    return null;
  }

  static String? validateDateOfBirth(String? value, {DateTime? now}) {
    final text = value?.trim() ?? '';
    if (!_dobRegex.hasMatch(text)) {
      return 'Enter date of birth in YYYY-MM-DD format.';
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid calendar date (YYYY-MM-DD).';
    }
    final today = now ?? DateTime.now().toUtc();
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    if (!parsed.isBefore(todayDate)) {
      return 'Date of birth must be in the past.';
    }
    var age = todayDate.year - parsed.year;
    if (todayDate.month < parsed.month ||
        (todayDate.month == parsed.month && todayDate.day < parsed.day)) {
      age -= 1;
    }
    if (age < 18) {
      return 'Primary contact must be at least 18 years old.';
    }
    return null;
  }

  static String? validateIdentityNumber(
    String? value, {
    required String docType,
  }) {
    final cleaned = (value ?? '').trim().toUpperCase();
    if (docType == 'passport') {
      if (!_passportRegex.hasMatch(cleaned)) {
        return 'Passport must be 6–12 alphanumeric characters.';
      }
      return null;
    }
    if (!(_oldNicRegex.hasMatch(cleaned) || _newNicRegex.hasMatch(cleaned))) {
      return 'Enter a valid NIC (e.g. 123456789V or 200012345678).';
    }
    return null;
  }
}

