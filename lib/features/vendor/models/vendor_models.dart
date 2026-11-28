import 'dart:typed_data';

enum VendorCategory {
  homestay('Homestay Provider', 'Number of Rooms'),
  ecoTourism('Eco Tourism Provider', 'Duration'),
  activity('Activity Provider', 'Duration'),
  localGuide('Local Guide', 'Languages'),
  rental('Rental Provider', 'Vehicle Type'),
  artisan('Artisan Provider', 'Product Type');

  final String label;
  final String specificFieldLabel;

  const VendorCategory(this.label, this.specificFieldLabel);

  String get titleFieldLabel {
    switch (this) {
      case VendorCategory.homestay:
        return 'Property Name';
      case VendorCategory.ecoTourism:
        return 'Experience Name';
      case VendorCategory.activity:
        return 'Activity Name';
      case VendorCategory.localGuide:
        return 'Service Name';
      case VendorCategory.rental:
        return 'Vehicle Name';
      case VendorCategory.artisan:
        return 'Product or Workshop Name';
    }
  }

  String get priceFieldLabel {
    switch (this) {
      case VendorCategory.homestay:
        return 'Price per Night (LKR)';
      case VendorCategory.activity:
        return 'Price per Person (LKR)';
      case VendorCategory.rental:
        return 'Price per Day (LKR)';
      case VendorCategory.ecoTourism:
      case VendorCategory.localGuide:
      case VendorCategory.artisan:
        return 'Price (LKR)';
    }
  }

  String get priceUnitSuffix {
    switch (this) {
      case VendorCategory.homestay:
        return '/ night';
      case VendorCategory.activity:
        return '/ person';
      case VendorCategory.rental:
        return '/ day';
      case VendorCategory.ecoTourism:
      case VendorCategory.localGuide:
      case VendorCategory.artisan:
        return '';
    }
  }
}

class CategoryFieldSpec {
  final String key;
  final String label;
  final String hint;
  final bool isNumeric;
  final bool isRequired;

  const CategoryFieldSpec({
    required this.key,
    required this.label,
    required this.hint,
    this.isNumeric = false,
    this.isRequired = true,
  });
}

class VendorCategoryFormConfig {
  static const Map<VendorCategory, List<CategoryFieldSpec>> fieldsByCategory = {
    VendorCategory.homestay: [
      CategoryFieldSpec(
        key: 'rooms',
        label: 'Number of Rooms',
        hint: 'e.g. 2',
        isNumeric: true,
      ),
      CategoryFieldSpec(
        key: 'max_guests',
        label: 'Maximum Guests',
        hint: 'e.g. 4',
        isNumeric: true,
      ),
      CategoryFieldSpec(
        key: 'amenities',
        label: 'Amenities',
        hint: 'e.g. Wi-Fi, Breakfast, AC, Garden',
      ),
    ],
    VendorCategory.ecoTourism: [
      CategoryFieldSpec(
        key: 'duration',
        label: 'Duration',
        hint: 'e.g. 4 hours',
      ),
      CategoryFieldSpec(
        key: 'eco_features',
        label: 'Eco-friendly Features',
        hint: 'e.g. Solar powered, Zero single-use plastic',
      ),
    ],
    VendorCategory.activity: [
      CategoryFieldSpec(
        key: 'duration',
        label: 'Duration',
        hint: 'e.g. 3 hours',
      ),
      CategoryFieldSpec(
        key: 'max_participants',
        label: 'Maximum Participants',
        hint: 'e.g. 8',
        isNumeric: true,
      ),
    ],
    VendorCategory.localGuide: [
      CategoryFieldSpec(
        key: 'languages',
        label: 'Languages',
        hint: 'e.g. English, Sinhala, Tamil',
      ),
      CategoryFieldSpec(
        key: 'experience',
        label: 'Experience',
        hint: 'e.g. 6 years certified national guide',
      ),
    ],
    VendorCategory.rental: [
      CategoryFieldSpec(
        key: 'vehicle_type',
        label: 'Vehicle Type',
        hint: 'e.g. Automatic Scooter, Tuk-Tuk, Van',
      ),
      CategoryFieldSpec(
        key: 'availability',
        label: 'Availability',
        hint: 'e.g. Available daily (7 AM – 8 PM)',
      ),
    ],
    VendorCategory.artisan: [
      CategoryFieldSpec(
        key: 'product_type',
        label: 'Product Type',
        hint: 'e.g. Handloom Textile, Wood Carving',
      ),
      CategoryFieldSpec(
        key: 'quantity_or_capacity',
        label: 'Available Quantity or Workshop Capacity',
        hint: 'e.g. 12 pieces / 6 workshop seats',
      ),
    ],
  };

  static List<CategoryFieldSpec> fieldsFor(VendorCategory category) {
    return fieldsByCategory[category] ?? const [];
  }
}

class VendorListingPhoto {
  final String id;
  final String path;
  final Uint8List? bytes;
  final bool isLocalFile;

  const VendorListingPhoto({
    required this.id,
    required this.path,
    this.bytes,
    this.isLocalFile = true,
  });

  bool get isNetworkUrl {
    final lower = path.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }
}

enum VendorBookingStatus {
  pending('Pending'),
  accepted('Accepted'),
  rejected('Rejected'),
  completed('Completed');

  final String label;

  const VendorBookingStatus(this.label);
}

class VendorAccountDemo {
  final String id;
  final String businessName;
  final String email;
  final String phone;
  final VendorCategory category;
  final String location;
  final bool isDemoSession;

  const VendorAccountDemo({
    required this.id,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.category,
    required this.location,
    this.isDemoSession = true,
  });
}

class VendorListing {
  final String id;
  final String ownerVendorId;
  final String title;
  final VendorCategory category;
  final String location;
  final int priceLkr;
  final String description;
  final String categorySpecificValue;
  final Map<String, String> categoryDetails;
  final String imageUrl;
  final List<VendorListingPhoto> photos;
  final int coverPhotoIndex;
  final bool isActive;

  const VendorListing({
    required this.id,
    this.ownerVendorId = 'vnd-demo-001',
    required this.title,
    required this.category,
    required this.location,
    required this.priceLkr,
    required this.description,
    required this.categorySpecificValue,
    this.categoryDetails = const {},
    required this.imageUrl,
    this.photos = const [],
    this.coverPhotoIndex = 0,
    this.isActive = true,
  });

  VendorListingPhoto? get coverPhoto {
    if (photos.isEmpty) return null;
    if (coverPhotoIndex >= 0 && coverPhotoIndex < photos.length) {
      return photos[coverPhotoIndex];
    }
    return photos.first;
  }

  String get coverImagePath => coverPhoto?.path ?? imageUrl;

  VendorListing copyWith({
    String? ownerVendorId,
    String? title,
    VendorCategory? category,
    String? location,
    int? priceLkr,
    String? description,
    String? categorySpecificValue,
    Map<String, String>? categoryDetails,
    String? imageUrl,
    List<VendorListingPhoto>? photos,
    int? coverPhotoIndex,
    bool? isActive,
  }) {
    return VendorListing(
      id: id,
      ownerVendorId: ownerVendorId ?? this.ownerVendorId,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      priceLkr: priceLkr ?? this.priceLkr,
      description: description ?? this.description,
      categorySpecificValue:
          categorySpecificValue ?? this.categorySpecificValue,
      categoryDetails: categoryDetails ?? this.categoryDetails,
      imageUrl: imageUrl ?? this.imageUrl,
      photos: photos ?? this.photos,
      coverPhotoIndex: coverPhotoIndex ?? this.coverPhotoIndex,
      isActive: isActive ?? this.isActive,
    );
  }
}

class VendorBookingRequest {
  final String id;
  final String listingTitle;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String dateRange;
  final String unitsLabel;
  final int totalLkr;
  final VendorBookingStatus status;
  final String notes;

  const VendorBookingRequest({
    required this.id,
    required this.listingTitle,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.dateRange,
    required this.unitsLabel,
    required this.totalLkr,
    required this.status,
    required this.notes,
  });

  VendorBookingRequest copyWith({VendorBookingStatus? status}) {
    return VendorBookingRequest(
      id: id,
      listingTitle: listingTitle,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      dateRange: dateRange,
      unitsLabel: unitsLabel,
      totalLkr: totalLkr,
      status: status ?? this.status,
      notes: notes,
    );
  }
}

class VendorReview {
  final String id;
  final String ownerVendorId;
  final String listingId;
  final String listingTitle;
  final String customerName;
  final int rating;
  final String dateLabel;
  final String comment;

  const VendorReview({
    required this.id,
    this.ownerVendorId = 'vnd-demo-001',
    required this.listingId,
    required this.listingTitle,
    required this.customerName,
    required this.rating,
    required this.dateLabel,
    required this.comment,
  });
}

enum VendorNotificationType {
  bookingRequest('Booking Request'),
  bookingStatus('Booking Update'),
  listingUpdate('Listing Update'),
  availabilityReminder('Availability'),
  announcement('Announcement');

  final String label;

  const VendorNotificationType(this.label);
}

class VendorNotificationItem {
  final String id;
  final String ownerVendorId;
  final VendorNotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final bool isRead;

  const VendorNotificationItem({
    required this.id,
    this.ownerVendorId = 'vnd-demo-001',
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isRead = false,
  });

  VendorNotificationItem copyWith({bool? isRead}) {
    return VendorNotificationItem(
      id: id,
      ownerVendorId: ownerVendorId,
      type: type,
      title: title,
      message: message,
      timeLabel: timeLabel,
      isRead: isRead ?? this.isRead,
    );
  }
}

