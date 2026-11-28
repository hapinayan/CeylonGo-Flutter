import '../../../core/constants/api_constants.dart';

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString());
}

int _toInt(dynamic val, [int fallback = 0]) {
  if (val is int) return val;
  return int.tryParse('$val') ?? fallback;
}

String formatLkrAmount(dynamic raw) {
  final numVal = _toDouble(raw);
  if (numVal == null) return 'LKR $raw';
  final rounded = numVal.round();
  final str = rounded.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
    buf.write(str[i]);
  }
  return 'LKR ${buf.toString()}';
}

// ============================================================================
// Homestays
// ============================================================================

class HomestayRoomModel {
  final int id;
  final int listingId;
  final String label;
  final int capacity;
  final bool isActive;
  final String? roomType;
  final String? description;
  final String? nightlyPrice;

  const HomestayRoomModel({
    required this.id,
    required this.listingId,
    required this.label,
    required this.capacity,
    this.isActive = true,
    this.roomType,
    this.description,
    this.nightlyPrice,
  });

  factory HomestayRoomModel.fromJson(Map<String, dynamic> json) {
    return HomestayRoomModel(
      id: _toInt(json['id']),
      listingId: _toInt(json['listing_id']),
      label: json['label']?.toString() ?? 'Room',
      capacity: _toInt(json['capacity'], 1),
      isActive: json['is_active'] != false,
      roomType: json['room_type']?.toString(),
      description: json['description']?.toString(),
      nightlyPrice: json['nightly_price']?.toString(),
    );
  }
}

class HomestayListingModel {
  final int id;
  final int providerId;
  final String title;
  final String description;
  final String district;
  final String locality;
  final double? latitude;
  final double? longitude;
  final String price;
  final String currency;
  final String? propertyType;
  final List<String> amenities;
  final String hostName;
  final List<String> imageUrls;
  final List<HomestayRoomModel> rooms;

  const HomestayListingModel({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.district,
    required this.locality,
    this.latitude,
    this.longitude,
    required this.price,
    this.currency = 'LKR',
    this.propertyType,
    this.amenities = const [],
    this.hostName = '',
    this.imageUrls = const [],
    this.rooms = const [],
  });

  String get coverImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get locationLabel =>
      locality.isNotEmpty && locality.toLowerCase() != district.toLowerCase()
          ? '$locality, $district'
          : district;
  bool get hasCoordinates => latitude != null && longitude != null;

  factory HomestayListingModel.fromJson(Map<String, dynamic> json) {
    final media = <String>[];
    if (json['media'] is List) {
      for (final item in json['media'] as List) {
        if (item is Map<String, dynamic>) {
          final url = ApiConstants.resolveMediaUrl(item['image_url']?.toString());
          if (url.isNotEmpty) media.add(url);
        }
      }
    }

    final units = <HomestayRoomModel>[];
    if (json['units'] is List) {
      for (final item in json['units'] as List) {
        if (item is Map<String, dynamic>) {
          units.add(HomestayRoomModel.fromJson(item));
        }
      }
    }

    final host = json['host'];
    final hostName = host is Map<String, dynamic>
        ? (host['business_name']?.toString() ?? '')
        : '';

    return HomestayListingModel(
      id: _toInt(json['id']),
      providerId: _toInt(json['provider_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      price: json['price']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      propertyType: json['property_type']?.toString(),
      amenities: (json['amenities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hostName: hostName,
      imageUrls: media,
      rooms: units,
    );
  }
}

class HomestayQuoteModel {
  final String checkIn;
  final String checkOut;
  final int guests;
  final int listingId;
  final int nights;
  final String nightlyRate;
  final String totalAmount;
  final String currency;
  final List<HomestayRoomModel> availableRooms;

  const HomestayQuoteModel({
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.listingId,
    required this.nights,
    required this.nightlyRate,
    required this.totalAmount,
    this.currency = 'LKR',
    this.availableRooms = const [],
  });

  factory HomestayQuoteModel.fromJson(Map<String, dynamic> json) {
    final rooms = <HomestayRoomModel>[];
    if (json['available_rooms'] is List) {
      for (final item in json['available_rooms'] as List) {
        if (item is Map<String, dynamic>) {
          rooms.add(HomestayRoomModel.fromJson(item));
        }
      }
    }
    return HomestayQuoteModel(
      checkIn: json['check_in']?.toString() ?? '',
      checkOut: json['check_out']?.toString() ?? '',
      guests: _toInt(json['guests'], 1),
      listingId: _toInt(json['listing_id']),
      nights: _toInt(json['nights'], 1),
      nightlyRate: json['nightly_rate']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      availableRooms: rooms,
    );
  }
}

// ============================================================================
// Adventure Activities
// ============================================================================

class ActivityListingModel {
  final int id;
  final String title;
  final String description;
  final String district;
  final String locality;
  final double? latitude;
  final double? longitude;
  final String pricePerParticipant;
  final String currency;
  final String providerName;
  final String category;
  final String meetingPoint;
  final int durationMinutes;
  final int minParticipants;
  final int maxParticipants;
  final int? minimumAge;
  final List<String> highlights;
  final List<String> included;
  final List<String> excluded;
  final String? safetyInstructions;
  final String? cancellationPolicy;
  final List<String> imageUrls;

  const ActivityListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.district,
    required this.locality,
    this.latitude,
    this.longitude,
    required this.pricePerParticipant,
    this.currency = 'LKR',
    required this.providerName,
    this.category = 'Adventure',
    this.meetingPoint = '',
    this.durationMinutes = 60,
    this.minParticipants = 1,
    this.maxParticipants = 10,
    this.minimumAge,
    this.highlights = const [],
    this.included = const [],
    this.excluded = const [],
    this.safetyInstructions,
    this.cancellationPolicy,
    this.imageUrls = const [],
  });

  String get coverImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get locationLabel =>
      locality.isNotEmpty && locality.toLowerCase() != district.toLowerCase()
          ? '$locality, $district'
          : district;
  bool get hasCoordinates => latitude != null && longitude != null;

  factory ActivityListingModel.fromJson(Map<String, dynamic> json) {
    final photos = <String>[];
    if (json['photos'] is List) {
      for (final p in json['photos'] as List) {
        if (p is Map<String, dynamic>) {
          final url = ApiConstants.resolveMediaUrl(p['image_url']?.toString());
          if (url.isNotEmpty) photos.add(url);
        }
      }
    }

    final meta = json['activity'] is Map<String, dynamic>
        ? json['activity'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ActivityListingModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      pricePerParticipant: json['price_per_participant']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      providerName: json['provider_name']?.toString() ?? '',
      category: meta['category']?.toString() ?? 'adventure',
      meetingPoint: meta['meeting_point']?.toString() ?? '',
      durationMinutes: _toInt(meta['duration_minutes'], 60),
      minParticipants: _toInt(meta['min_participants'], 1),
      maxParticipants: _toInt(meta['max_participants'], 10),
      minimumAge: meta['minimum_age'] is int ? meta['minimum_age'] as int : null,
      highlights: (meta['highlights'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      included: (meta['included'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      excluded: (meta['excluded'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      safetyInstructions: meta['safety_instructions']?.toString(),
      cancellationPolicy: meta['cancellation_policy']?.toString(),
      imageUrls: photos,
    );
  }
}

class ActivitySlotModel {
  final int id;
  final String date;
  final DateTime startsAt;
  final DateTime endsAt;
  final int remainingCapacity;
  final bool available;
  final String totalAmount;
  final String currency;

  const ActivitySlotModel({
    required this.id,
    required this.date,
    required this.startsAt,
    required this.endsAt,
    required this.remainingCapacity,
    required this.available,
    required this.totalAmount,
    this.currency = 'LKR',
  });

  factory ActivitySlotModel.fromJson(Map<String, dynamic> json) {
    return ActivitySlotModel(
      id: _toInt(json['id']),
      date: json['date']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ??
          DateTime.now(),
      remainingCapacity: _toInt(json['remaining_capacity']),
      available: json['available'] == true,
      totalAmount: json['total_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
    );
  }
}

// ============================================================================
// Tour Guides
// ============================================================================

class GuidePackageModel {
  final int id;
  final String title;
  final String description;
  final String? itinerary;
  final String durationHours;
  final String pricingType;
  final String price;
  final String currency;
  final int maxPeople;
  final String? includedServices;
  final String? excludedServices;
  final String meetingPoint;
  final double? meetingLatitude;
  final double? meetingLongitude;
  final bool isActive;

  const GuidePackageModel({
    required this.id,
    required this.title,
    required this.description,
    this.itinerary,
    required this.durationHours,
    this.pricingType = 'per_person',
    required this.price,
    this.currency = 'LKR',
    this.maxPeople = 10,
    this.includedServices,
    this.excludedServices,
    this.meetingPoint = '',
    this.meetingLatitude,
    this.meetingLongitude,
    this.isActive = true,
  });

  factory GuidePackageModel.fromJson(Map<String, dynamic> json) {
    return GuidePackageModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      itinerary: json['itinerary']?.toString(),
      durationHours: json['duration_hours']?.toString() ?? '1',
      pricingType: json['pricing_type']?.toString() ?? 'per_person',
      price: json['price']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      maxPeople: _toInt(json['max_people'], 10),
      includedServices: json['included_services']?.toString(),
      excludedServices: json['excluded_services']?.toString(),
      meetingPoint: json['meeting_point']?.toString() ?? '',
      meetingLatitude: _toDouble(json['meeting_latitude']),
      meetingLongitude: _toDouble(json['meeting_longitude']),
      isActive: json['is_active'] != false,
    );
  }
}

class GuideSlotModel {
  final int id;
  final int packageId;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool available;
  final int capacity;
  final String totalAmount;
  final String currency;

  const GuideSlotModel({
    required this.id,
    required this.packageId,
    required this.startsAt,
    required this.endsAt,
    required this.available,
    required this.capacity,
    required this.totalAmount,
    this.currency = 'LKR',
  });

  factory GuideSlotModel.fromJson(Map<String, dynamic> json) {
    return GuideSlotModel(
      id: _toInt(json['id']),
      packageId: _toInt(json['package_id']),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ??
          DateTime.now(),
      available: json['available'] == true,
      capacity: _toInt(json['capacity'], 1),
      totalAmount: json['total_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
    );
  }
}

class TourGuideListingModel {
  final int id;
  final String title;
  final String description;
  final String district;
  final String locality;
  final double? latitude;
  final double? longitude;
  final String price;
  final String currency;
  final String providerName;
  final int yearsOfExperience;
  final List<String> categories;
  final List<String> languages;
  final List<String> serviceAreas;
  final String? cancellationPolicy;
  final List<String> imageUrls;
  final List<GuidePackageModel> packages;

  const TourGuideListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.district,
    required this.locality,
    this.latitude,
    this.longitude,
    required this.price,
    this.currency = 'LKR',
    required this.providerName,
    this.yearsOfExperience = 0,
    this.categories = const [],
    this.languages = const [],
    this.serviceAreas = const [],
    this.cancellationPolicy,
    this.imageUrls = const [],
    this.packages = const [],
  });

  String get coverImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get locationLabel =>
      locality.isNotEmpty && locality.toLowerCase() != district.toLowerCase()
          ? '$locality, $district'
          : district;
  bool get hasCoordinates => latitude != null && longitude != null;

  factory TourGuideListingModel.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : json;
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final media = <String>[];
    if (listing['media'] is List) {
      for (final item in listing['media'] as List) {
        if (item is Map<String, dynamic>) {
          final url = ApiConstants.resolveMediaUrl(item['image_url']?.toString());
          if (url.isNotEmpty) media.add(url);
        }
      }
    }

    final langs = <String>[];
    if (profile['languages'] is List) {
      for (final l in profile['languages'] as List) {
        if (l is Map<String, dynamic>) {
          final name = l['language_name']?.toString();
          if (name != null && name.isNotEmpty) langs.add(name);
        } else if (l != null) {
          langs.add(l.toString());
        }
      }
    }

    final areas = <String>[];
    if (profile['service_areas'] is List) {
      for (final a in profile['service_areas'] as List) {
        if (a is Map<String, dynamic>) {
          final d = a['district']?.toString() ?? '';
          final c = a['city']?.toString() ?? '';
          if (c.isNotEmpty && d.isNotEmpty) {
            areas.add('$c, $d');
          } else if (d.isNotEmpty) {
            areas.add(d);
          }
        }
      }
    }

    final pkgs = <GuidePackageModel>[];
    if (json['packages'] is List) {
      for (final p in json['packages'] as List) {
        if (p is Map<String, dynamic>) {
          pkgs.add(GuidePackageModel.fromJson(p));
        }
      }
    }

    return TourGuideListingModel(
      id: _toInt(listing['id']),
      title: listing['title']?.toString() ?? '',
      description: listing['description']?.toString() ?? '',
      district: listing['district']?.toString() ?? '',
      locality: listing['locality']?.toString() ?? '',
      latitude: _toDouble(listing['latitude']),
      longitude: _toDouble(listing['longitude']),
      price: listing['price']?.toString() ?? '0',
      currency: listing['currency']?.toString() ?? 'LKR',
      providerName: json['provider_name']?.toString() ?? '',
      yearsOfExperience: _toInt(profile['years_of_experience']),
      categories: (profile['categories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      languages: langs,
      serviceAreas: areas,
      cancellationPolicy: profile['cancellation_policy']?.toString(),
      imageUrls: media,
      packages: pkgs,
    );
  }
}

// ============================================================================
// Bike & Bicycle Rentals
// ============================================================================

class RentalVehicleModel {
  final int id;
  final int providerId;
  final String? providerBusinessName;
  final String vehicleType; // 'bike' | 'bicycle'
  final String category;
  final String? vehicleSubtype;
  final String vehicleName;
  final String? description;
  final String pricePerDay;
  final String currency;
  final int? modelYear;
  final int? seatingCapacity;
  final String? transmission;
  final String? fuelType;
  final String? district;
  final String? city;
  final String? locationName;
  final String? pickupAddress;
  final double? latitude;
  final double? longitude;
  final String primaryImageUrl;
  final List<String> imageUrls;
  final String? cancellationPolicy;
  final String? rentalTerms;
  final String? requirements;
  final bool requiresDrivingLicense;

  const RentalVehicleModel({
    required this.id,
    required this.providerId,
    this.providerBusinessName,
    required this.vehicleType,
    required this.category,
    this.vehicleSubtype,
    required this.vehicleName,
    this.description,
    required this.pricePerDay,
    this.currency = 'LKR',
    this.modelYear,
    this.seatingCapacity,
    this.transmission,
    this.fuelType,
    this.district,
    this.city,
    this.locationName,
    this.pickupAddress,
    this.latitude,
    this.longitude,
    this.primaryImageUrl = '',
    this.imageUrls = const [],
    this.cancellationPolicy,
    this.rentalTerms,
    this.requirements,
    this.requiresDrivingLicense = false,
  });

  String get locationLabel {
    final parts = [
      if (city != null && city!.isNotEmpty) city!,
      if (district != null &&
          district!.isNotEmpty &&
          district!.toLowerCase() != (city ?? '').toLowerCase())
        district!,
    ];
    return parts.isEmpty ? (locationName ?? 'Sri Lanka') : parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  factory RentalVehicleModel.fromJson(Map<String, dynamic> json) {
    final images = <String>[];
    if (json['images'] is List) {
      for (final item in json['images'] as List) {
        if (item is Map<String, dynamic>) {
          final url = ApiConstants.resolveMediaUrl(item['image_url']?.toString());
          if (url.isNotEmpty) images.add(url);
        }
      }
    }
    final primary =
        ApiConstants.resolveMediaUrl(json['primary_image_url']?.toString());
    if (images.isEmpty && primary.isNotEmpty) {
      images.add(primary);
    }

    final loc = json['location'] is Map<String, dynamic>
        ? json['location'] as Map<String, dynamic>
        : null;
    final rental = json['rental'] is Map<String, dynamic>
        ? json['rental'] as Map<String, dynamic>
        : null;

    return RentalVehicleModel(
      id: _toInt(json['id']),
      providerId: _toInt(json['provider_id']),
      providerBusinessName: json['provider_business_name']?.toString(),
      vehicleType: json['vehicle_type']?.toString() ?? 'bike',
      category: json['category']?.toString() ?? 'bike',
      vehicleSubtype: json['vehicle_subtype']?.toString(),
      vehicleName: json['vehicle_name']?.toString() ?? '',
      description: json['description']?.toString(),
      pricePerDay: json['price_per_day']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      modelYear: json['model_year'] is int ? json['model_year'] as int : null,
      seatingCapacity: json['seating_capacity'] is int
          ? json['seating_capacity'] as int
          : null,
      transmission: json['transmission']?.toString(),
      fuelType: json['fuel_type']?.toString(),
      district: (loc?['district'] ?? json['district'])?.toString(),
      city: (loc?['city'] ?? json['city'])?.toString(),
      locationName: (loc?['location_name'] ?? json['location_name'])?.toString(),
      pickupAddress:
          (loc?['address'] ?? rental?['pickup_address'])?.toString(),
      latitude: _toDouble(loc?['latitude']),
      longitude: _toDouble(loc?['longitude']),
      primaryImageUrl: primary.isNotEmpty
          ? primary
          : (images.isNotEmpty ? images.first : ''),
      imageUrls: images,
      cancellationPolicy:
          (rental?['cancellation_policy'] ?? json['cancellation_policy'])
              ?.toString(),
      rentalTerms: rental?['rental_terms']?.toString(),
      requirements: rental?['requirements']?.toString(),
      requiresDrivingLicense: json['requires_driving_license'] == true ||
          json['vehicle_type']?.toString() == 'bike',
    );
  }
}

class RentalQuoteModel {
  final int vehicleId;
  final DateTime pickupAt;
  final DateTime returnAt;
  final int quantity;
  final bool isAvailable;
  final int availableQuantity;
  final int durationDays;
  final double durationHours;
  final String rate;
  final String totalPrice;
  final String currency;
  final bool requiresDrivingLicense;

  const RentalQuoteModel({
    required this.vehicleId,
    required this.pickupAt,
    required this.returnAt,
    required this.quantity,
    required this.isAvailable,
    required this.availableQuantity,
    required this.durationDays,
    required this.durationHours,
    required this.rate,
    required this.totalPrice,
    this.currency = 'LKR',
    this.requiresDrivingLicense = false,
  });

  factory RentalQuoteModel.fromJson(Map<String, dynamic> json) {
    return RentalQuoteModel(
      vehicleId: _toInt(json['vehicle_id']),
      pickupAt: DateTime.tryParse(json['pickup_at']?.toString() ?? '') ??
          DateTime.now(),
      returnAt: DateTime.tryParse(json['return_at']?.toString() ?? '') ??
          DateTime.now(),
      quantity: _toInt(json['quantity'], 1),
      isAvailable: json['is_available'] == true,
      availableQuantity: _toInt(json['available_quantity']),
      durationDays: _toInt(json['duration_days'], 1),
      durationHours: _toDouble(json['duration_hours']) ?? 24,
      rate: json['rate']?.toString() ?? '0',
      totalPrice: json['total_price']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      requiresDrivingLicense: json['requires_driving_license'] == true,
    );
  }
}
