import '../models/artisan_listing_model.dart';
import '../models/artisan_promotion_model.dart';
import '../models/artisan_reservation_model.dart';
import '../models/artisan_review_model.dart';
import '../models/artisan_wishlist_model.dart';
import '../models/showcase_item_model.dart';
import 'artisan_service.dart';

/// Offline In-Memory Mock Service for CeylonGo Traveler Artisan Demonstration.
/// Strictly executes zero HTTP requests and zero database connections.
/// Maintains mutable state in application memory for interactive presentation flows.
class ArtisanDemoService extends ArtisanService {
  static bool isDemoMode = false;

  static final ArtisanDemoService _instance = ArtisanDemoService._internal();
  static ArtisanDemoService get instance => _instance;

  factory ArtisanDemoService() {
    return _instance;
  }

  ArtisanDemoService._internal() {
    resetToDefaults();
  }

  late List<ArtisanListingResponse> _listings;
  late List<ShowcaseItemResponse> _showcaseItems;
  late List<ArtisanReservationModel> _reservations;
  late List<ArtisanReviewModel> _reviews;
  late Set<int> _wishlistListingIds;

  void resetToDefaults() {
    _listings = [
      ArtisanListingResponse(
        id: 1,
        providerProfileId: 1,
        title: 'Ambalangoda Traditional Masks Studio',
        craftCategory: 'Woodcarving & Masks',
        district: 'Galle',
        city: 'Ambalangoda',
        description:
            'Authentic handcrafted Sri Lankan masks crafted with centuries-old Kaduru wood carving traditions.',
        address: '142 Main Street, Ambalangoda, Southern Province',
        latitude: 6.2359,
        longitude: 80.0543,
        phone: '+94912258900',
        email: 'masks.ambalangoda@ceylongo.demo',
        websiteUrl: 'https://ceylongo.demo/ambalangoda-masks',
        coverImageUrl:
            'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=800',
        isActive: true,
        isVerified: true,
        isFeatured: true,
        approvalStatus: 'approved',
        verificationStatus: 'verified',
        averageRating: 4.8,
        totalReviews: 24,
        images: const [
          ArtisanBusinessImageModel(
            id: 301,
            artisanListingId: 1,
            imageUrl:
                'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=800',
            caption: 'Mask Studio Gallery Main Hall',
            displayOrder: 1,
            isPrimary: true,
          ),
          ArtisanBusinessImageModel(
            id: 302,
            artisanListingId: 1,
            imageUrl:
                'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800',
            caption: 'Live Kaduru Wood Carving Workbench',
            displayOrder: 2,
            isPrimary: false,
          ),
        ],
        businessHours: const [
          ArtisanBusinessHourModel(
            id: 1,
            artisanListingId: 1,
            dayOfWeek: 1,
            openTime: '09:00',
            closeTime: '17:00',
            isClosed: false,
          ),
          ArtisanBusinessHourModel(
            id: 2,
            artisanListingId: 1,
            dayOfWeek: 2,
            openTime: '09:00',
            closeTime: '17:00',
            isClosed: false,
          ),
          ArtisanBusinessHourModel(
            id: 3,
            artisanListingId: 1,
            dayOfWeek: 3,
            openTime: '09:00',
            closeTime: '17:00',
            isClosed: false,
          ),
          ArtisanBusinessHourModel(
            id: 4,
            artisanListingId: 1,
            dayOfWeek: 4,
            openTime: '09:00',
            closeTime: '17:00',
            isClosed: false,
          ),
          ArtisanBusinessHourModel(
            id: 5,
            artisanListingId: 1,
            dayOfWeek: 5,
            openTime: '09:00',
            closeTime: '17:00',
            isClosed: false,
          ),
          ArtisanBusinessHourModel(
            id: 6,
            artisanListingId: 1,
            dayOfWeek: 6,
            openTime: '09:00',
            closeTime: '15:00',
            isClosed: false,
          ),
          ArtisanBusinessHourModel(
            id: 7,
            artisanListingId: 1,
            dayOfWeek: 0,
            openTime: null,
            closeTime: null,
            isClosed: true,
          ),
        ],
      ),
      ArtisanListingResponse(
        id: 2,
        providerProfileId: 1,
        title: 'Kandy Royal Brass Crafts',
        craftCategory: 'Jewelry & Metalcraft',
        district: 'Kandy',
        city: 'Pilimathalawa',
        description:
            'Heritage hand-beaten brass oil lamps, ceremonial trays, and decorative craft ware from Kandy.',
        address: '88 Temple Road, Pilimathalawa, Central Province',
        latitude: 7.2612,
        longitude: 80.5694,
        phone: '+94812384500',
        email: 'kandy.brass@ceylongo.demo',
        coverImageUrl:
            'https://images.unsplash.com/photo-1606857521015-7f9fcf423740?w=800',
        isActive: true,
        isVerified: true,
        isFeatured: false,
        approvalStatus: 'approved',
        verificationStatus: 'verified',
        averageRating: 4.6,
        totalReviews: 18,
        images: const [],
        businessHours: const [],
      ),
      ArtisanListingResponse(
        id: 3,
        providerProfileId: 2,
        title: 'Matara Clay & Terracotta Creations',
        craftCategory: 'Traditional Pottery',
        district: 'Matara',
        city: 'Weligama',
        description:
            'Organic pottery, hand-thrown terracotta cookware, and rustic decorative pottery pots.',
        address: '22 Beach Road, Weligama, Southern Province',
        latitude: 5.9734,
        longitude: 80.4287,
        phone: '+94412255100',
        email: 'matara.clay@ceylongo.demo',
        isActive: true,
        isVerified: false,
        isFeatured: false,
        approvalStatus: 'approved',
        verificationStatus: 'unverified',
        averageRating: 4.2,
        totalReviews: 7,
        images: const [],
        businessHours: const [],
      ),
    ];

    _showcaseItems = [
      ShowcaseItemResponse(
        id: 50,
        artisanListingId: 1,
        title: 'Hand-Carved Peacock Mask (Mayura Raksha)',
        itemType: 'product',
        description:
            'Vibrant ritual mask carved from soft Kaduru wood, featuring intricate peacock feathers and natural pigments.',
        materials: 'Kaduru Wood, Natural Mineral Pigments',
        price: 8500.0,
        currency: 'LKR',
        stockQuantity: 5,
        sku: 'MASK-PEA-001',
        isAvailable: true,
        isActive: true,
        isFeatured: true,
        approvalStatus: 'approved',
        listingTitle: 'Ambalangoda Traditional Masks Studio',
        images: const [
          ArtisanProductImageModel(
            id: 501,
            showcaseItemId: 50,
            imageUrl:
                'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=600',
            caption: 'Mayura Raksha front view',
            displayOrder: 1,
            isPrimary: true,
          ),
        ],
      ),
      ShowcaseItemResponse(
        id: 51,
        artisanListingId: 1,
        title: 'Traditional Gurulu Raksha Mask',
        itemType: 'product',
        description:
            'Mythical bird mask designed to ward off evil spirits. Currently in production.',
        materials: 'Kaduru Wood, Acrylic Pigments',
        price: 12000.0,
        currency: 'LKR',
        stockQuantity: 0,
        sku: 'MASK-GUR-002',
        isAvailable: false,
        isActive: true,
        isFeatured: false,
        approvalStatus: 'approved',
        listingTitle: 'Ambalangoda Traditional Masks Studio',
        images: const [],
      ),
      ShowcaseItemResponse(
        id: 52,
        artisanListingId: 2,
        title: 'Royal Brass Oil Lamp (Pahana)',
        itemType: 'product',
        description:
            'Hand-cast solid brass traditional 5-wick oil lamp engraved with classic Kandyan floral patterns.',
        materials: 'Solid Cast Brass',
        price: 14500.0,
        currency: 'LKR',
        stockQuantity: 8,
        sku: 'BRASS-PAH-001',
        isAvailable: true,
        isActive: true,
        isFeatured: false,
        approvalStatus: 'approved',
        listingTitle: 'Kandy Royal Brass Crafts',
        images: const [],
      ),
      ShowcaseItemResponse(
        id: 53,
        artisanListingId: 3,
        title: 'Terracotta Tea Set (6 Cups)',
        itemType: 'product',
        description: 'Eco-friendly unglazed clay tea set fired in a wood kiln.',
        materials: 'Natural Weligama Clay',
        price: 6200.0,
        currency: 'LKR',
        stockQuantity: 3,
        sku: 'CLAY-TEA-001',
        isAvailable: true,
        isActive: true,
        isFeatured: false,
        approvalStatus: 'approved',
        listingTitle: 'Matara Clay & Terracotta Creations',
        images: const [],
      ),
    ];

    _reservations = [
      ArtisanReservationModel(
        id: 101,
        showcaseItemId: 50,
        artisanListingId: 1,
        travelerId: 11,
        quantity: 1,
        totalPrice: 8500.0,
        currency: 'LKR',
        status: ReservationStatus.pending,
        pickupDate: '2026-11-25T14:00:00Z',
        specialNotes:
            'Counter pickup; please wrap securely for luggage transport.',
        createdAt: DateTime.parse('2026-11-18T10:00:00Z'),
        updatedAt: DateTime.parse('2026-11-18T10:00:00Z'),
        itemTitle: 'Hand-Carved Peacock Mask (Mayura Raksha)',
        listingTitle: 'Ambalangoda Traditional Masks Studio',
        providerBusinessName: 'Ambalangoda Traditional Masks Studio',
        travelerName: 'Alice Traveler',
      ),
      ArtisanReservationModel(
        id: 102,
        showcaseItemId: 52,
        artisanListingId: 2,
        travelerId: 11,
        quantity: 2,
        totalPrice: 29000.0,
        currency: 'LKR',
        status: ReservationStatus.confirmed,
        pickupDate: '2026-11-28T11:00:00Z',
        specialNotes: 'Visiting Kandy on Saturday morning.',
        createdAt: DateTime.parse('2026-11-17T09:00:00Z'),
        updatedAt: DateTime.parse('2026-11-17T12:00:00Z'),
        itemTitle: 'Royal Brass Oil Lamp (Pahana)',
        listingTitle: 'Kandy Royal Brass Crafts',
        providerBusinessName: 'Kandy Royal Brass Crafts',
        travelerName: 'Alice Traveler',
      ),
      ArtisanReservationModel(
        id: 103,
        showcaseItemId: 50,
        artisanListingId: 1,
        travelerId: 11,
        quantity: 1,
        totalPrice: 8500.0,
        currency: 'LKR',
        status: ReservationStatus.readyForPickup,
        pickupDate: '2026-11-20T16:00:00Z',
        createdAt: DateTime.parse('2026-11-16T15:00:00Z'),
        updatedAt: DateTime.parse('2026-11-19T08:00:00Z'),
        itemTitle: 'Hand-Carved Peacock Mask (Mayura Raksha)',
        listingTitle: 'Ambalangoda Traditional Masks Studio',
        providerBusinessName: 'Ambalangoda Traditional Masks Studio',
        travelerName: 'Alice Traveler',
      ),
      ArtisanReservationModel(
        id: 104,
        showcaseItemId: 50,
        artisanListingId: 1,
        travelerId: 11,
        quantity: 1,
        totalPrice: 8500.0,
        currency: 'LKR',
        status: ReservationStatus.completed,
        pickupDate: '2026-11-15T12:00:00Z',
        createdAt: DateTime.parse('2026-11-14T08:00:00Z'),
        updatedAt: DateTime.parse('2026-11-15T12:30:00Z'),
        itemTitle: 'Hand-Carved Peacock Mask (Mayura Raksha)',
        listingTitle: 'Ambalangoda Traditional Masks Studio',
        providerBusinessName: 'Ambalangoda Traditional Masks Studio',
        travelerName: 'Alice Traveler',
      ),
      ArtisanReservationModel(
        id: 105,
        showcaseItemId: 51,
        artisanListingId: 1,
        travelerId: 11,
        quantity: 1,
        totalPrice: 12000.0,
        currency: 'LKR',
        status: ReservationStatus.cancelled,
        cancellationReason: 'Travel itinerary adjusted.',
        cancelledBy: 11,
        pickupDate: '2026-11-19T10:00:00Z',
        createdAt: DateTime.parse('2026-11-15T10:00:00Z'),
        updatedAt: DateTime.parse('2026-11-16T09:00:00Z'),
        itemTitle: 'Traditional Gurulu Raksha Mask',
        listingTitle: 'Ambalangoda Traditional Masks Studio',
        providerBusinessName: 'Ambalangoda Traditional Masks Studio',
        travelerName: 'Alice Traveler',
      ),
    ];

    _reviews = [
      ArtisanReviewModel(
        id: 201,
        listingReferenceId: 1,
        userId: 10,
        userName: 'Elena Rostova',
        rating: 5.0,
        comment:
            'Phenomenal craftsmanship! Master Sunil gave us a live wood carving demonstration. The peacock mask is mesmerizing.',
        isVerifiedBooking: true,
        isPublished: true,
        createdAt: DateTime.parse('2026-11-10T14:00:00Z'),
        artisanListingId: 1,
        artisanListingTitle: 'Ambalangoda Traditional Masks Studio',
      ),
      ArtisanReviewModel(
        id: 202,
        listingReferenceId: 1,
        userId: 11,
        userName: 'Alice Traveler',
        rating: 4.0,
        comment:
            'Very welcoming studio right on Main Street. Seamless pickup reservation experience.',
        isVerifiedBooking: true,
        isPublished: true,
        createdAt: DateTime.parse('2026-11-12T16:30:00Z'),
        artisanListingId: 1,
        artisanListingTitle: 'Ambalangoda Traditional Masks Studio',
      ),
      ArtisanReviewModel(
        id: 203,
        listingReferenceId: 2,
        userId: 12,
        userName: 'Thomas Wright',
        rating: 5.0,
        comment:
            'Heavy, solid brass oil lamp. Worth every rupee for an authentic traditional heirloom.',
        isVerifiedBooking: true,
        isPublished: true,
        createdAt: DateTime.parse('2026-11-14T09:15:00Z'),
        artisanListingId: 2,
        artisanListingTitle: 'Kandy Royal Brass Crafts',
      ),
    ];

    _wishlistListingIds = {1};
  }

  // ============================================================================
  // Discovery & Business Methods
  // ============================================================================

  @override
  Future<List<String>> getCategories() async {
    return [
      'Woodcarving & Masks',
      'Jewelry & Metalcraft',
      'Traditional Pottery',
      'Handloom & Batik',
      'Coir & Coconut Crafts',
    ];
  }

  @override
  Future<List<String>> getDistricts() async {
    return ['Galle', 'Kandy', 'Matara', 'Colombo', 'Jaffna'];
  }

  @override
  Future<ArtisanListingPagination> getFeaturedListings({
    String? category,
    String? district,
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    var featured = _listings.where((l) => l.isFeatured).toList();
    if (category != null && category.trim().isNotEmpty) {
      featured =
          featured.where((l) => l.craftCategory == category.trim()).toList();
    }
    if (district != null && district.trim().isNotEmpty) {
      featured =
          featured.where((l) => l.district == district.trim()).toList();
    }
    return ArtisanListingPagination(
      items: featured,
      total: featured.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<ArtisanListingPagination> getListings({
    String? category,
    String? district,
    bool? isFeatured,
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    var items = List<ArtisanListingResponse>.from(_listings);

    if (category != null && category.trim().isNotEmpty) {
      items = items.where((l) => l.craftCategory == category.trim()).toList();
    }
    if (district != null && district.trim().isNotEmpty) {
      items = items.where((l) => l.district == district.trim()).toList();
    }
    if (isFeatured != null) {
      items = items.where((l) => l.isFeatured == isFeatured).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      items = items
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.city.toLowerCase().contains(q) ||
              (l.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return ArtisanListingPagination(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: (items.length / pageSize).ceil().clamp(1, 999),
    );
  }

  @override
  Future<ArtisanNearbyListingPagination> getNearbyListings({
    String? category,
    required double latitude,
    required double longitude,
    int page = 1,
    int pageSize = 10,
    double radiusKm = 50.0,
    String? search,
  }) async {
    var nearbyItems = _listings
        .map((l) => ArtisanListingSummary(
              id: l.id,
              providerProfileId: l.providerProfileId,
              title: l.title,
              craftCategory: l.craftCategory,
              district: l.district,
              city: l.city,
              latitude: l.latitude,
              longitude: l.longitude,
              coverImageUrl: l.coverImageUrl,
              isActive: l.isActive,
              isVerified: l.isVerified,
              isFeatured: l.isFeatured,
              approvalStatus: l.approvalStatus,
              distanceKm: 2.5,
              averageRating: l.averageRating,
              totalReviews: l.totalReviews,
            ))
        .toList();

    if (category != null && category.trim().isNotEmpty) {
      nearbyItems = nearbyItems
          .where((l) => l.craftCategory == category.trim())
          .toList();
    }

    return ArtisanNearbyListingPagination(
      items: nearbyItems,
      total: nearbyItems.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
      originLatitude: latitude,
      originLongitude: longitude,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<ArtisanListingResponse> getListingDetails(int id) async {
    final match = _listings.firstWhere(
      (l) => l.id == id,
      orElse: () => _listings.first,
    );
    return match;
  }

  // ============================================================================
  // Showcase Products
  // ============================================================================

  @override
  Future<ShowcaseItemPagination> getShowcaseItems({
    int? artisanListingId,
    bool? isFeatured,
    String? itemType,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    var items = List<ShowcaseItemResponse>.from(_showcaseItems);
    if (artisanListingId != null) {
      items = items.where((p) => p.artisanListingId == artisanListingId).toList();
    }
    if (isFeatured != null) {
      items = items.where((p) => p.isFeatured == isFeatured).toList();
    }
    if (itemType != null) {
      items = items.where((p) => p.itemType == itemType).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      items = items
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return ShowcaseItemPagination(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: (items.length / pageSize).ceil().clamp(1, 999),
    );
  }

  @override
  Future<ShowcaseItemResponse> getShowcaseItemDetails(int id) async {
    return _showcaseItems.firstWhere(
      (p) => p.id == id,
      orElse: () => _showcaseItems.first,
    );
  }

  @override
  Future<ShowcaseItemPagination> getListingShowcaseItems(
    int listingId, {
    String? itemType,
    int page = 1,
    int pageSize = 20,
  }) async {
    var items = _showcaseItems
        .where((p) => p.artisanListingId == listingId)
        .toList();
    if (itemType != null) {
      items = items.where((p) => p.itemType == itemType).toList();
    }
    return ShowcaseItemPagination(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: (items.length / pageSize).ceil().clamp(1, 999),
    );
  }

  // ============================================================================
  // Product Reservations (Fulfillment & Counter Settlement)
  // ============================================================================

  @override
  Future<ArtisanReservationModel> createReservation(
    ArtisanReservationCreatePayload payload,
  ) async {
    final itemId = payload.showcaseItemId;
    final quantity = payload.quantity;
    final pickupDate = payload.pickupDate;
    final specialNotes = payload.specialNotes;

    final item = await getShowcaseItemDetails(itemId);
    final listing = await getListingDetails(item.artisanListingId);

    // In-memory stock decrement
    final prodIdx = _showcaseItems.indexWhere((p) => p.id == itemId);
    if (prodIdx >= 0) {
      final current = _showcaseItems[prodIdx];
      final newStock = (current.stockQuantity - quantity).clamp(0, 9999);
      _showcaseItems[prodIdx] = ShowcaseItemResponse(
        id: current.id,
        artisanListingId: current.artisanListingId,
        title: current.title,
        itemType: current.itemType,
        description: current.description,
        materials: current.materials,
        price: current.price,
        currency: current.currency,
        stockQuantity: newStock,
        sku: current.sku,
        isAvailable: newStock > 0,
        isActive: current.isActive,
        isFeatured: current.isFeatured,
        approvalStatus: current.approvalStatus,
        listingTitle: current.listingTitle,
        images: current.images,
      );
    }

    final newId = 100 + _reservations.length + 1;
    final unitPrice = item.price ?? 0.0;
    final totalPrice = unitPrice * quantity;

    final newRes = ArtisanReservationModel(
      id: newId,
      showcaseItemId: itemId,
      artisanListingId: item.artisanListingId,
      travelerId: 11,
      quantity: quantity,
      totalPrice: totalPrice,
      currency: item.currency,
      status: ReservationStatus.pending,
      pickupDate: pickupDate,
      specialNotes: specialNotes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemTitle: item.title,
      listingTitle: listing.title,
      providerBusinessName: listing.title,
      travelerName: 'Demo Traveler',
    );

    _reservations.insert(0, newRes);
    return newRes;
  }

  @override
  Future<List<ArtisanReservationModel>> getMyReservations({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    if (status != null && status.trim().isNotEmpty && status != 'all') {
      return _reservations
          .where((r) => r.status.code.toLowerCase() == status.trim().toLowerCase())
          .toList();
    }
    return _reservations;
  }

  @override
  Future<ArtisanReservationModel> getReservation(int id) async {
    return _reservations.firstWhere(
      (r) => r.id == id,
      orElse: () => _reservations.first,
    );
  }

  @override
  Future<ArtisanReservationModel> cancelReservation(
    int id, {
    String? reason,
  }) async {
    final idx = _reservations.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      final old = _reservations[idx];
      final updated = ArtisanReservationModel(
        id: old.id,
        showcaseItemId: old.showcaseItemId,
        artisanListingId: old.artisanListingId,
        travelerId: old.travelerId,
        quantity: old.quantity,
        totalPrice: old.totalPrice,
        currency: old.currency,
        status: ReservationStatus.cancelled,
        pickupDate: old.pickupDate,
        specialNotes: old.specialNotes,
        cancelledBy: old.travelerId,
        cancellationReason: reason ?? 'Cancelled by traveler',
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        itemTitle: old.itemTitle,
        listingTitle: old.listingTitle,
        providerBusinessName: old.providerBusinessName,
        travelerName: old.travelerName,
      );
      _reservations[idx] = updated;

      // Restore stock quantity
      final prodIdx =
          _showcaseItems.indexWhere((p) => p.id == old.showcaseItemId);
      if (prodIdx >= 0) {
        final cur = _showcaseItems[prodIdx];
        final restoredStock = cur.stockQuantity + old.quantity;
        _showcaseItems[prodIdx] = ShowcaseItemResponse(
          id: cur.id,
          artisanListingId: cur.artisanListingId,
          title: cur.title,
          itemType: cur.itemType,
          description: cur.description,
          materials: cur.materials,
          price: cur.price,
          currency: cur.currency,
          stockQuantity: restoredStock,
          sku: cur.sku,
          isAvailable: true,
          isActive: cur.isActive,
          isFeatured: cur.isFeatured,
          approvalStatus: cur.approvalStatus,
          listingTitle: cur.listingTitle,
          images: cur.images,
        );
      }
      return updated;
    }
    throw Exception('Reservation not found');
  }

  // ============================================================================
  // Reviews & Ratings
  // ============================================================================

  @override
  Future<ArtisanReviewPaginationModel> getListingReviews(
    int listingId, {
    int page = 1,
    int pageSize = 10,
    double? rating,
    String sortBy = 'newest',
  }) async {
    var items = _reviews
        .where((r) => r.listingReferenceId == listingId && r.isPublished)
        .toList();
    if (rating != null) {
      items = items.where((r) => r.rating == rating).toList();
    }
    final summary = await getListingReviewSummary(listingId);
    return ArtisanReviewPaginationModel(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: (items.length / pageSize).ceil().clamp(1, 999),
      averageRating: summary.averageRating,
      totalReviews: summary.totalReviews,
    );
  }

  @override
  Future<ArtisanReviewSummaryModel> getListingReviewSummary(
    int listingId,
  ) async {
    final items = _reviews
        .where((r) => r.listingReferenceId == listingId && r.isPublished)
        .toList();
    if (items.isEmpty) {
      return ArtisanReviewSummaryModel(
        listingId: listingId,
        listingTitle: 'Craft Studio',
        averageRating: 0.0,
        totalReviews: 0,
        ratingBreakdown: {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
        verifiedReviewsCount: 0,
      );
    }

    final sum = items.fold(0.0, (acc, r) => acc + r.rating);
    final avg = double.parse((sum / items.length).toStringAsFixed(1));
    final breakdown = {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0};
    for (final r in items) {
      final key = r.rating.round().clamp(1, 5).toString();
      breakdown[key] = (breakdown[key] ?? 0) + 1;
    }

    return ArtisanReviewSummaryModel(
      listingId: listingId,
      listingTitle: items.first.artisanListingTitle ?? 'Craft Studio',
      averageRating: avg,
      totalReviews: items.length,
      ratingBreakdown: breakdown,
      verifiedReviewsCount: items.where((r) => r.isVerifiedBooking).length,
    );
  }

  @override
  Future<ArtisanReviewModel> createReview(
    int listingId,
    ArtisanReviewCreatePayload payload,
  ) async {
    final newRev = ArtisanReviewModel(
      id: 200 + _reviews.length + 1,
      listingReferenceId: listingId,
      bookingReferenceId: payload.reservationId,
      userId: 11,
      userName: 'Demo Traveler',
      rating: payload.rating,
      title: payload.title,
      comment: payload.comment,
      isVerifiedBooking: true,
      isPublished: true,
      createdAt: DateTime.now(),
      artisanListingId: listingId,
      artisanListingTitle: (await getListingDetails(listingId)).title,
    );
    _reviews.insert(0, newRev);
    return newRev;
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    _reviews.removeWhere((r) => r.id == reviewId);
  }

  // ============================================================================
  // Business Wishlist
  // ============================================================================

  @override
  Future<ArtisanWishlistCheckModel> checkWishlistStatus(int listingId) async {
    return ArtisanWishlistCheckModel(
      listingId: listingId,
      isSaved: _wishlistListingIds.contains(listingId),
      wishlistId: _wishlistListingIds.contains(listingId) ? listingId : null,
    );
  }

  @override
  Future<ArtisanWishlistItemModel> addToWishlist(
    int listingId, {
    String? notes,
  }) async {
    _wishlistListingIds.add(listingId);
    final listing = await getListingDetails(listingId);
    return ArtisanWishlistItemModel(
      id: listingId,
      userId: 11,
      listingReferenceId: listingId,
      artisanListingId: listingId,
      notes: notes,
      createdAt: DateTime.now(),
      isAvailable: true,
      listing: ArtisanWishlistSavedListingSummary(
        id: listing.id,
        providerProfileId: listing.providerProfileId,
        title: listing.title,
        craftCategory: listing.craftCategory,
        district: listing.district,
        city: listing.city,
        coverImageUrl: listing.coverImageUrl,
        approvalStatus: listing.approvalStatus,
        isActive: listing.isActive,
        averageRating: listing.averageRating,
        totalReviews: listing.totalReviews,
      ),
    );
  }

  @override
  Future<void> removeFromWishlist(int listingId) async {
    _wishlistListingIds.remove(listingId);
  }

  @override
  Future<ArtisanWishlistPaginationModel> getMyWishlist({
    bool availableOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = <ArtisanWishlistItemModel>[];
    for (final id in _wishlistListingIds) {
      final listing = await getListingDetails(id);
      items.add(ArtisanWishlistItemModel(
        id: id,
        userId: 11,
        listingReferenceId: id,
        artisanListingId: id,
        createdAt: DateTime.now(),
        isAvailable: true,
        listing: ArtisanWishlistSavedListingSummary(
          id: listing.id,
          providerProfileId: listing.providerProfileId,
          title: listing.title,
          craftCategory: listing.craftCategory,
          district: listing.district,
          city: listing.city,
          coverImageUrl: listing.coverImageUrl,
          approvalStatus: listing.approvalStatus,
          isActive: listing.isActive,
          averageRating: listing.averageRating,
          totalReviews: listing.totalReviews,
        ),
      ));
    }
    return ArtisanWishlistPaginationModel(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<ArtisanPromotionPaginationModel> getActivePromotions({
    int? listingId,
    int page = 1,
    int pageSize = 10,
    int? showcaseItemId,
  }) async {
    return const ArtisanPromotionPaginationModel(
      items: [],
      total: 0,
      page: 1,
      pageSize: 10,
      totalPages: 1,
    );
  }
}
