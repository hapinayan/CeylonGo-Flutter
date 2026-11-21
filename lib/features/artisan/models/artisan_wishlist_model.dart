import 'artisan_listing_model.dart';

/// Detailed summary of a saved artisan business in the traveler's wishlist.
class ArtisanWishlistSavedListingSummary {
  final int id;
  final int providerProfileId;
  final String title;
  final String craftCategory;
  final String district;
  final String city;
  final String? coverImageUrl;
  final String approvalStatus;
  final bool isActive;
  final double? averageRating;
  final int totalReviews;

  const ArtisanWishlistSavedListingSummary({
    required this.id,
    required this.providerProfileId,
    required this.title,
    required this.craftCategory,
    required this.district,
    required this.city,
    this.coverImageUrl,
    required this.approvalStatus,
    required this.isActive,
    this.averageRating,
    required this.totalReviews,
  });

  factory ArtisanWishlistSavedListingSummary.fromJson(Map<String, dynamic> json) {
    return ArtisanWishlistSavedListingSummary(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      providerProfileId: json['provider_profile_id'] is int
          ? json['provider_profile_id'] as int
          : int.parse('${json['provider_profile_id']}'),
      title: json['title']?.toString() ?? '',
      craftCategory: json['craft_category']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      coverImageUrl: json['cover_image_url']?.toString(),
      approvalStatus: json['approval_status']?.toString() ?? 'approved',
      isActive: json['is_active'] != false,
      averageRating: json['average_rating'] != null
          ? double.tryParse('${json['average_rating']}')
          : null,
      totalReviews: json['total_reviews'] is int
          ? json['total_reviews'] as int
          : int.tryParse('${json['total_reviews']}') ?? 0,
    );
  }

  String get fullCoverImageUrl => resolveImageUrl(coverImageUrl);
}

/// Single item inside traveler's wishlist response.
class ArtisanWishlistItemModel {
  final int id;
  final int userId;
  final int listingReferenceId;
  final int artisanListingId;
  final String? notes;
  final DateTime createdAt;
  final bool isAvailable;
  final ArtisanWishlistSavedListingSummary? listing;

  const ArtisanWishlistItemModel({
    required this.id,
    required this.userId,
    required this.listingReferenceId,
    required this.artisanListingId,
    this.notes,
    required this.createdAt,
    required this.isAvailable,
    this.listing,
  });

  factory ArtisanWishlistItemModel.fromJson(Map<String, dynamic> json) {
    return ArtisanWishlistItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.parse('${json['user_id']}'),
      listingReferenceId: json['listing_reference_id'] is int
          ? json['listing_reference_id'] as int
          : int.parse('${json['listing_reference_id']}'),
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.parse('${json['artisan_listing_id']}'),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isAvailable: json['is_available'] != false,
      listing: json['listing'] != null && json['listing'] is Map<String, dynamic>
          ? ArtisanWishlistSavedListingSummary.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Paginated collection of traveler's saved artisan businesses.
class ArtisanWishlistPaginationModel {
  final List<ArtisanWishlistItemModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const ArtisanWishlistPaginationModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ArtisanWishlistPaginationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ArtisanWishlistPaginationModel(
      items: rawItems
          .map((e) => ArtisanWishlistItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
      page: json['page'] is int ? json['page'] as int : int.tryParse('${json['page']}') ?? 1,
      pageSize: json['page_size'] is int
          ? json['page_size'] as int
          : int.tryParse('${json['page_size']}') ?? 20,
      totalPages: json['total_pages'] is int
          ? json['total_pages'] as int
          : int.tryParse('${json['total_pages']}') ?? 0,
    );
  }
}

/// Status check indicating whether a given artisan listing is in traveler's wishlist.
class ArtisanWishlistCheckModel {
  final int listingId;
  final bool isSaved;
  final int? wishlistId;

  const ArtisanWishlistCheckModel({
    required this.listingId,
    required this.isSaved,
    this.wishlistId,
  });

  factory ArtisanWishlistCheckModel.fromJson(Map<String, dynamic> json) {
    return ArtisanWishlistCheckModel(
      listingId: json['listing_id'] is int
          ? json['listing_id'] as int
          : int.parse('${json['listing_id']}'),
      isSaved: json['is_saved'] == true,
      wishlistId: json['wishlist_id'] != null
          ? int.tryParse('${json['wishlist_id']}')
          : null,
    );
  }
}
