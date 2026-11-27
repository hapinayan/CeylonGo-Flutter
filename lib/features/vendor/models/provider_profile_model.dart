import '../../auth/models/user_model.dart';

/// Strongly-typed user summary returned by `POST /api/v1/providers/login`.
class ProviderUser {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String businessName;
  final String providerType;
  final String district;
  final String approvalStatus;

  const ProviderUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.businessName,
    required this.providerType,
    required this.district,
    required this.approvalStatus,
  });

  factory ProviderUser.fromJson(Map<String, dynamic> json) {
    return ProviderUser(
      id: _parseInt(json['id']),
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'provider',
      isActive: json['is_active'] as bool? ?? false,
      businessName: (json['business_name'] as String?) ?? '',
      providerType: (json['provider_type'] as String?) ?? '',
      district: (json['district'] as String?) ?? '',
      approvalStatus: (json['approval_status'] as String?) ?? '',
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: id.toString(),
      fullName: businessName.trim().isNotEmpty ? businessName : fullName,
      email: email,
      role: role,
    );
  }
}

/// Response from `POST /api/v1/providers/login`.
class ProviderLoginResult {
  final String accessToken;
  final String tokenType;
  final ProviderUser user;

  const ProviderLoginResult({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory ProviderLoginResult.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'] as String?;
    if (token == null || token.trim().isEmpty) {
      throw const FormatException(
        'Invalid provider login response: missing access_token.',
      );
    }
    final tokenType = (json['token_type'] as String?) ?? '';
    if (tokenType.toLowerCase() != 'bearer') {
      throw FormatException(
        'Invalid token_type: expected "bearer", received "$tokenType".',
      );
    }
    final rawUser = json['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid provider login response: missing user object.',
      );
    }
    return ProviderLoginResult(
      accessToken: token,
      tokenType: tokenType,
      user: ProviderUser.fromJson(rawUser),
    );
  }
}

/// Strongly-typed profile returned by `GET /api/v1/providers/me` and
/// `PATCH /api/v1/providers/me` (`ProviderMeResponse`).
class ProviderProfile {
  final int id;
  final int userId;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String businessName;
  final String providerType;
  final String phone;
  final String? secondaryPhone;
  final String district;
  final String? description;
  final String? businessRegistrationNumber;
  final String approvalStatus;
  final String? businessProvince;
  final String? businessDistrict;
  final String? businessCity;
  final String? businessLandmark;
  final String? businessPostalCode;
  final DateTime? createdAt;

  const ProviderProfile({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.businessName,
    required this.providerType,
    required this.phone,
    this.secondaryPhone,
    required this.district,
    this.description,
    this.businessRegistrationNumber,
    required this.approvalStatus,
    this.businessProvince,
    this.businessDistrict,
    this.businessCity,
    this.businessLandmark,
    this.businessPostalCode,
    this.createdAt,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'] as String?;
    return ProviderProfile(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'provider',
      isActive: json['is_active'] as bool? ?? true,
      businessName: (json['business_name'] as String?) ?? '',
      providerType: (json['provider_type'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      secondaryPhone: _nullableTrimmed(json['secondary_phone']),
      district: (json['district'] as String?) ?? '',
      description: _nullableTrimmed(json['description']),
      businessRegistrationNumber:
          _nullableTrimmed(json['business_registration_number']),
      approvalStatus: (json['approval_status'] as String?) ?? '',
      businessProvince: _nullableTrimmed(json['business_province']),
      businessDistrict: _nullableTrimmed(json['business_district']),
      businessCity: _nullableTrimmed(json['business_city']),
      businessLandmark: _nullableTrimmed(json['business_landmark']),
      businessPostalCode: _nullableTrimmed(json['business_postal_code']),
      createdAt:
          rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: userId.toString(),
      fullName: businessName.trim().isNotEmpty ? businessName : fullName,
      email: email,
      role: role,
    );
  }
}

/// Generates a partial PATCH payload matching `ProviderProfileUpdateRequest`
/// containing only fields modified compared to [original].
class ProviderProfilePatch {
  final String businessName;
  final String phone;
  final String secondaryPhone;
  final String district;
  final String description;
  final String businessProvince;
  final String businessDistrict;
  final String businessCity;
  final String businessLandmark;
  final String businessPostalCode;

  const ProviderProfilePatch({
    required this.businessName,
    required this.phone,
    required this.secondaryPhone,
    required this.district,
    required this.description,
    required this.businessProvince,
    required this.businessDistrict,
    required this.businessCity,
    required this.businessLandmark,
    required this.businessPostalCode,
  });

  Map<String, dynamic> diffAgainst(ProviderProfile original) {
    final patch = <String, dynamic>{};

    void addIfChanged(String key, String nextVal, String? prevVal) {
      final cleanNext = nextVal.trim();
      final cleanPrev = (prevVal ?? '').trim();
      if (cleanNext != cleanPrev) {
        patch[key] = cleanNext.isEmpty ? null : cleanNext;
      }
    }

    if (businessName.trim() != original.businessName.trim()) {
      patch['business_name'] = businessName.trim();
    }
    if (phone.trim() != original.phone.trim()) {
      patch['phone'] = phone.trim();
    }
    addIfChanged('secondary_phone', secondaryPhone, original.secondaryPhone);
    if (district.trim() != original.district.trim()) {
      patch['district'] = district.trim();
    }
    addIfChanged('description', description, original.description);
    addIfChanged(
      'business_province',
      businessProvince,
      original.businessProvince,
    );
    addIfChanged(
      'business_district',
      businessDistrict,
      original.businessDistrict,
    );
    addIfChanged('business_city', businessCity, original.businessCity);
    addIfChanged(
      'business_landmark',
      businessLandmark,
      original.businessLandmark,
    );
    addIfChanged(
      'business_postal_code',
      businessPostalCode,
      original.businessPostalCode,
    );

    return patch;
  }
}

/// Client-side validators aligned with `ProviderProfileUpdateRequest` and
/// `ProviderPasswordChangeRequest` in CeylonGo-Backend.
class ProviderValidators {
  static final RegExp _sriLankanPhoneRegex = RegExp(
    r'^(?:\+94|0094|94)?(0?[1-9]\d{8})$',
  );

  static String? validateBusinessName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) {
      return 'Business name must be at least 2 characters.';
    }
    if (text.length > 150) {
      return 'Business name cannot exceed 150 characters.';
    }
    return null;
  }

  static String? validatePhone(String? value, {required bool requiredField}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return requiredField ? 'Primary phone number is required.' : null;
    }
    if (text.length < 9 && requiredField) {
      return 'Phone number must be at least 9 characters.';
    }
    if (text.length > 25) {
      return 'Phone number cannot exceed 25 characters.';
    }
    final cleaned = text.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_sriLankanPhoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid Sri Lankan phone number (e.g. 0771234567 or +94771234567).';
    }
    return null;
  }

  static String? validateDistrict(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) {
      return 'District must be at least 2 characters.';
    }
    if (text.length > 100) {
      return 'District cannot exceed 100 characters.';
    }
    return null;
  }

  static String? validateMaxLength(
    String? value, {
    required String fieldLabel,
    required int maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.length > maxLength) {
      return '$fieldLabel cannot exceed $maxLength characters.';
    }
    return null;
  }

  static String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required.';
    }
    return null;
  }

  static String? validateNewPassword(
    String? value, {
    required String currentPassword,
  }) {
    if (value == null || value.isEmpty) {
      return 'New password is required.';
    }
    if (value.length < 8) {
      return 'New password must be at least 8 characters.';
    }
    if (value.length > 128) {
      return 'New password cannot exceed 128 characters.';
    }
    if (currentPassword.isNotEmpty && value == currentPassword) {
      return 'New password must be different from your current password.';
    }
    return null;
  }

  static String? validateConfirmNewPassword(
    String? value, {
    required String newPassword,
  }) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password.';
    }
    if (value != newPassword) {
      return 'Confirmation password does not match.';
    }
    return null;
  }
}

int _parseInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? 0;
  return 0;
}

String? _nullableTrimmed(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

