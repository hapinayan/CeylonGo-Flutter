library;

import '../../../core/constants/api_constants.dart';

/// Resolves relative backend image paths to full URLs.
String resolveImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return '';
  final trimmed = path.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = ApiConstants.baseUrl;
  if (trimmed.startsWith('/')) {
    return '$base$trimmed';
  }
  return '$base/$trimmed';
}

/// Helper converting day numbers (0-6) into standard day names.
String dayOfWeekToString(int day) {
  switch (day) {
    case 0:
      return 'Monday';
    case 1:
      return 'Tuesday';
    case 2:
      return 'Wednesday';
    case 3:
      return 'Thursday';
    case 4:
      return 'Friday';
    case 5:
      return 'Saturday';
    case 6:
      return 'Sunday';
    default:
      return 'Day $day';
  }
}

class ArtisanBusinessImageModel {
  final int id;
  final int artisanListingId;
  final String imageUrl;
  final String? caption;
  final int displayOrder;
  final bool isPrimary;

  const ArtisanBusinessImageModel({
    required this.id,
    required this.artisanListingId,
    required this.imageUrl,
    this.caption,
    this.displayOrder = 0,
    this.isPrimary = false,
  });

  String get fullImageUrl => resolveImageUrl(imageUrl);

  factory ArtisanBusinessImageModel.fromJson(Map<String, dynamic> json) {
    return ArtisanBusinessImageModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.tryParse('${json['artisan_listing_id']}') ?? 0,
      imageUrl: (json['image_url'] ?? '').toString(),
      caption: json['caption'] as String?,
      displayOrder: json['display_order'] is int
          ? json['display_order'] as int
          : int.tryParse('${json['display_order']}') ?? 0,
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artisan_listing_id': artisanListingId,
    'image_url': imageUrl,
    'caption': caption,
    'display_order': displayOrder,
    'is_primary': isPrimary,
  };
}

class ArtisanBusinessHourModel {
  final int id;
  final int artisanListingId;
  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  const ArtisanBusinessHourModel({
    required this.id,
    required this.artisanListingId,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  String get dayName => dayOfWeekToString(dayOfWeek);

  String get formattedHours {
    if (isClosed) return 'Closed';
    if (openTime != null && closeTime != null) {
      return '$openTime - $closeTime';
    }
    return 'Open';
  }

  factory ArtisanBusinessHourModel.fromJson(Map<String, dynamic> json) {
    return ArtisanBusinessHourModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.tryParse('${json['artisan_listing_id']}') ?? 0,
      dayOfWeek: json['day_of_week'] is int
          ? json['day_of_week'] as int
          : int.tryParse('${json['day_of_week']}') ?? 0,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      isClosed: json['is_closed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artisan_listing_id': artisanListingId,
    'day_of_week': dayOfWeek,
    'open_time': openTime,
    'close_time': closeTime,
    'is_closed': isClosed,
  };
}

class ArtisanListingSummary {
  final int id;
  final int providerProfileId;
  final String title;
  final String craftCategory;
  final String district;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? coverImageUrl;
  final bool isActive;
  final bool isVerified;
  final bool isFeatured;
  final String approvalStatus;
  final double? averageRating;
  final int totalReviews;
  final double? distanceKm;

  const ArtisanListingSummary({
    required this.id,
    required this.providerProfileId,
    required this.title,
    required this.craftCategory,
    required this.district,
    required this.city,
    this.latitude,
    this.longitude,
    this.coverImageUrl,
    this.isActive = true,
    this.isVerified = false,
    this.isFeatured = false,
    this.approvalStatus = 'approved',
    this.averageRating,
    this.totalReviews = 0,
    this.distanceKm,
  });

  String get fullCoverImageUrl => resolveImageUrl(coverImageUrl);

  bool get hasCoordinates => latitude != null && longitude != null;

  factory ArtisanListingSummary.fromJson(Map<String, dynamic> json) {
    return ArtisanListingSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      providerProfileId: json['provider_profile_id'] is int
          ? json['provider_profile_id'] as int
          : int.tryParse('${json['provider_profile_id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      craftCategory: (json['craft_category'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      latitude: json['latitude'] != null ? double.tryParse('${json['latitude']}') : null,
      longitude: json['longitude'] != null ? double.tryParse('${json['longitude']}') : null,
      coverImageUrl: json['cover_image_url'] as String?,
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      isFeatured: json['is_featured'] == true,
      approvalStatus: (json['approval_status'] ?? 'approved').toString(),
      averageRating: json['average_rating'] != null ? double.tryParse('${json['average_rating']}') : null,
      totalReviews: json['total_reviews'] is int
          ? json['total_reviews'] as int
          : int.tryParse('${json['total_reviews']}') ?? 0,
      distanceKm: json['distance_km'] != null ? double.tryParse('${json['distance_km']}') : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_profile_id': providerProfileId,
    'title': title,
    'craft_category': craftCategory,
    'district': district,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'cover_image_url': coverImageUrl,
    'is_active': isActive,
    'is_verified': isVerified,
    'is_featured': isFeatured,
    'approval_status': approvalStatus,
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'distance_km': distanceKm,
  };
}

class ArtisanListingResponse extends ArtisanListingSummary {
  final String? description;
  final String? address;
  final String? phone;
  final String? whatsappNumber;
  final String? whatsappLink;
  final String? email;
  final String? websiteUrl;
  final String? openingHours;
  final String verificationStatus;
  final String? providerBusinessName;
  final List<ArtisanBusinessImageModel> images;
  final List<ArtisanBusinessHourModel> businessHours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ArtisanListingResponse({
    required super.id,
    required super.providerProfileId,
    required super.title,
    required super.craftCategory,
    required super.district,
    required super.city,
    super.latitude,
    super.longitude,
    super.coverImageUrl,
    super.isActive = true,
    super.isVerified = false,
    super.isFeatured = false,
    super.approvalStatus = 'approved',
    super.averageRating,
    super.totalReviews = 0,
    super.distanceKm,
    this.description,
    this.address,
    this.phone,
    this.whatsappNumber,
    this.whatsappLink,
    this.email,
    this.websiteUrl,
    this.openingHours,
    this.verificationStatus = 'unverified',
    this.providerBusinessName,
    this.images = const [],
    this.businessHours = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ArtisanListingResponse.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] ?? json['business_images'];
    final imageList = <ArtisanBusinessImageModel>[];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is Map<String, dynamic>) {
          imageList.add(ArtisanBusinessImageModel.fromJson(img));
        }
      }
    }

    final rawHours = json['business_hours'];
    final hourList = <ArtisanBusinessHourModel>[];
    if (rawHours is List) {
      for (final h in rawHours) {
        if (h is Map<String, dynamic>) {
          hourList.add(ArtisanBusinessHourModel.fromJson(h));
        }
      }
      hourList.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    }

    return ArtisanListingResponse(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      providerProfileId: json['provider_profile_id'] is int
          ? json['provider_profile_id'] as int
          : int.tryParse('${json['provider_profile_id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      craftCategory: (json['craft_category'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      latitude: json['latitude'] != null ? double.tryParse('${json['latitude']}') : null,
      longitude: json['longitude'] != null ? double.tryParse('${json['longitude']}') : null,
      coverImageUrl: json['cover_image_url'] as String?,
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      isFeatured: json['is_featured'] == true,
      approvalStatus: (json['approval_status'] ?? 'approved').toString(),
      averageRating: json['average_rating'] != null ? double.tryParse('${json['average_rating']}') : null,
      totalReviews: json['total_reviews'] is int
          ? json['total_reviews'] as int
          : int.tryParse('${json['total_reviews']}') ?? 0,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      whatsappLink: json['whatsapp_link'] as String?,
      email: json['email'] as String?,
      websiteUrl: json['website_url'] as String?,
      openingHours: json['opening_hours'] as String?,
      verificationStatus: (json['verification_status'] ?? 'unverified').toString(),
      providerBusinessName: json['provider_business_name'] as String?,
      images: imageList,
      businessHours: hourList,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse('${json['updated_at']}') : null,
    );
  }
}

class ArtisanListingPagination {
  final List<ArtisanListingSummary> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const ArtisanListingPagination({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ArtisanListingPagination.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemList = <ArtisanListingSummary>[];
    if (rawItems is List) {
      for (final itm in rawItems) {
        if (itm is Map<String, dynamic>) {
          itemList.add(ArtisanListingSummary.fromJson(itm));
        }
      }
    }
    return ArtisanListingPagination(
      items: itemList,
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
      page: json['page'] is int ? json['page'] as int : int.tryParse('${json['page']}') ?? 1,
      pageSize: json['page_size'] is int
          ? json['page_size'] as int
          : int.tryParse('${json['page_size']}') ?? 12,
      totalPages: json['total_pages'] is int
          ? json['total_pages'] as int
          : int.tryParse('${json['total_pages']}') ?? 0,
    );
  }
}

class ArtisanNearbyListingPagination {
  final List<ArtisanListingSummary> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final double originLatitude;
  final double originLongitude;
  final double radiusKm;

  const ArtisanNearbyListingPagination({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.originLatitude,
    required this.originLongitude,
    required this.radiusKm,
  });

  factory ArtisanNearbyListingPagination.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemList = <ArtisanListingSummary>[];
    if (rawItems is List) {
      for (final itm in rawItems) {
        if (itm is Map<String, dynamic>) {
          itemList.add(ArtisanListingSummary.fromJson(itm));
        }
      }
    }
    return ArtisanNearbyListingPagination(
      items: itemList,
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
      page: json['page'] is int ? json['page'] as int : int.tryParse('${json['page']}') ?? 1,
      pageSize: json['page_size'] is int
          ? json['page_size'] as int
          : int.tryParse('${json['page_size']}') ?? 12,
      totalPages: json['total_pages'] is int
          ? json['total_pages'] as int
          : int.tryParse('${json['total_pages']}') ?? 0,
      originLatitude: json['origin_latitude'] != null
          ? double.tryParse('${json['origin_latitude']}') ?? 0.0
          : 0.0,
      originLongitude: json['origin_longitude'] != null
          ? double.tryParse('${json['origin_longitude']}') ?? 0.0
          : 0.0,
      radiusKm: json['radius_km'] != null
          ? double.tryParse('${json['radius_km']}') ?? 50.0
          : 50.0,
    );
  }
}

