int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  return int.tryParse('$v') ?? fallback;
}

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
      verified: json['verified'] == true,
      nextAction: json['next_action']?.toString(),
      authorizationToken: json['authorization_token']?.toString(),
      expiresIn: json['expires_in'] is int ? json['expires_in'] as int : null,
      message: json['message']?.toString(),
    );
  }
}

class ProviderRegistrationDraft {
  final String email;
  final String? fullName;
  final String? phone;
  final String? nicNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? permanentProvince;
  final String? permanentDistrict;
  final String? permanentCity;
  final String? permanentLandmark;
  final String? permanentPostalCode;
  final String? businessName;
  final String? providerType;
  final String? businessDistrict;
  final String? businessCity;
  final String? description;
  final bool selfieUploaded;
  final bool nicFrontUploaded;
  final bool nicBackUploaded;
  final bool personalCompleted;
  final bool businessCompleted;
  final bool identityCompleted;
  final String currentStep;

  const ProviderRegistrationDraft({
    required this.email,
    this.fullName,
    this.phone,
    this.nicNumber,
    this.dateOfBirth,
    this.gender,
    this.permanentProvince,
    this.permanentDistrict,
    this.permanentCity,
    this.permanentLandmark,
    this.permanentPostalCode,
    this.businessName,
    this.providerType,
    this.businessDistrict,
    this.businessCity,
    this.description,
    this.selfieUploaded = false,
    this.nicFrontUploaded = false,
    this.nicBackUploaded = false,
    this.personalCompleted = false,
    this.businessCompleted = false,
    this.identityCompleted = false,
    this.currentStep = 'personal',
  });

  factory ProviderRegistrationDraft.fromJson(Map<String, dynamic> json) {
    return ProviderRegistrationDraft(
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      nicNumber: json['nic_number']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      gender: json['gender']?.toString(),
      permanentProvince: json['permanent_province']?.toString(),
      permanentDistrict: json['permanent_district']?.toString(),
      permanentCity: json['permanent_city']?.toString(),
      permanentLandmark: json['permanent_landmark']?.toString(),
      permanentPostalCode: json['permanent_postal_code']?.toString(),
      businessName: json['business_name']?.toString(),
      providerType: json['provider_type']?.toString(),
      businessDistrict: json['business_district']?.toString(),
      businessCity: json['business_city']?.toString(),
      description: json['description']?.toString(),
      selfieUploaded: json['selfie_uploaded'] == true,
      nicFrontUploaded: json['nic_front_uploaded'] == true,
      nicBackUploaded: json['nic_back_uploaded'] == true,
      personalCompleted: json['personal_completed'] == true,
      businessCompleted: json['business_completed'] == true,
      identityCompleted: json['identity_completed'] == true,
      currentStep: json['current_step']?.toString() ?? 'personal',
    );
  }
}

class ProviderProfileModel {
  final int id;
  final int userId;
  final String businessName;
  final String phone;
  final String district;
  final String verificationStatus; // 'pending' | 'approved' | 'rejected' | 'suspended'
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final String? decisionReason;

  const ProviderProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.phone,
    required this.district,
    required this.verificationStatus,
    this.submittedAt,
    this.decidedAt,
    this.decisionReason,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      businessName: json['business_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      decidedAt: json['decided_at'] != null
          ? DateTime.tryParse(json['decided_at'].toString())
          : null,
      decisionReason: json['decision_reason']?.toString(),
    );
  }
}

class ProviderUnitModel {
  final int id;
  final int listingId;
  final String label;
  final int capacity;
  final bool isActive;
  final String? roomType;
  final String? nightlyPrice;

  const ProviderUnitModel({
    required this.id,
    required this.listingId,
    required this.label,
    required this.capacity,
    this.isActive = true,
    this.roomType,
    this.nightlyPrice,
  });

  factory ProviderUnitModel.fromJson(Map<String, dynamic> json) {
    return ProviderUnitModel(
      id: _toInt(json['id']),
      listingId: _toInt(json['listing_id']),
      label: json['label']?.toString() ?? '',
      capacity: _toInt(json['capacity'], 1),
      isActive: json['is_active'] != false,
      roomType: json['room_type']?.toString(),
      nightlyPrice: json['nightly_price']?.toString(),
    );
  }
}

class ProviderListingModel {
  final int id;
  final int providerId;
  final String category;
  final String title;
  final String description;
  final String district;
  final String locality;
  final String price;
  final String currency;
  final String approvalStatus;
  final bool isActive;
  final String verificationStatus;
  final String? decisionReason;
  final List<ProviderUnitModel> units;
  final List<ProviderUnitModel> rooms;

  const ProviderListingModel({
    required this.id,
    required this.providerId,
    required this.category,
    required this.title,
    required this.description,
    required this.district,
    required this.locality,
    required this.price,
    this.currency = 'LKR',
    this.approvalStatus = 'draft',
    this.isActive = false,
    this.verificationStatus = 'draft',
    this.decisionReason,
    this.units = const [],
    this.rooms = const [],
  });

  factory ProviderListingModel.fromJson(Map<String, dynamic> json) {
    // Handles both ReviewListing ({listing: ..., verification_status: ..., rooms: ...})
    // and flat ListingResponse ({id, category, ...}).
    final rawListing = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : json;

    final units = <ProviderUnitModel>[];
    if (rawListing['units'] is List) {
      for (final u in rawListing['units'] as List) {
        if (u is Map<String, dynamic>) {
          units.add(ProviderUnitModel.fromJson(u));
        }
      }
    }

    final rooms = <ProviderUnitModel>[];
    if (json['rooms'] is List) {
      for (final r in json['rooms'] as List) {
        if (r is Map<String, dynamic>) {
          rooms.add(ProviderUnitModel.fromJson(r));
        }
      }
    }

    return ProviderListingModel(
      id: _toInt(rawListing['id']),
      providerId: _toInt(rawListing['provider_id']),
      category: rawListing['category']?.toString() ?? 'homestay',
      title: rawListing['title']?.toString() ?? '',
      description: rawListing['description']?.toString() ?? '',
      district: rawListing['district']?.toString() ?? '',
      locality: rawListing['locality']?.toString() ?? '',
      price: rawListing['price']?.toString() ?? '0',
      currency: rawListing['currency']?.toString() ?? 'LKR',
      approvalStatus: rawListing['approval_status']?.toString() ?? 'draft',
      isActive: rawListing['is_active'] == true,
      verificationStatus: json['verification_status']?.toString() ??
          rawListing['approval_status']?.toString() ??
          'draft',
      decisionReason: json['decision_reason']?.toString(),
      units: units,
      rooms: rooms.isNotEmpty ? rooms : units,
    );
  }
}

class ProviderAvailabilitySlot {
  final int id;
  final int unitId;
  final int listingId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final bool isOpen;

  const ProviderAvailabilitySlot({
    required this.id,
    required this.unitId,
    required this.listingId,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.isOpen,
  });

  factory ProviderAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return ProviderAvailabilitySlot(
      id: _toInt(json['id']),
      unitId: _toInt(json['unit_id']),
      listingId: _toInt(json['listing_id']),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ??
          DateTime.now(),
      capacity: _toInt(json['capacity'], 1),
      isOpen: json['is_open'] != false,
    );
  }
}
