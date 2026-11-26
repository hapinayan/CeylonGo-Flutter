/// Model representing a traveler review for an Artisan Business.
/// Conforms to dbo.reviews contract and app/schemas/artisan_review.py.
class ArtisanReviewModel {
  final int id;
  final int listingReferenceId;
  final int? bookingReferenceId;
  final int userId;
  final String? userName;
  final double rating;
  final String? title;
  final String? comment;
  final bool isVerifiedBooking;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? artisanListingId;
  final String? artisanListingTitle;
  final String? bookingReferenceCode;

  const ArtisanReviewModel({
    required this.id,
    required this.listingReferenceId,
    this.bookingReferenceId,
    required this.userId,
    this.userName,
    required this.rating,
    this.title,
    this.comment,
    required this.isVerifiedBooking,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
    this.artisanListingId,
    this.artisanListingTitle,
    this.bookingReferenceCode,
  });

  factory ArtisanReviewModel.fromJson(Map<String, dynamic> json) {
    return ArtisanReviewModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      listingReferenceId: json['listing_reference_id'] is int
          ? json['listing_reference_id'] as int
          : int.parse('${json['listing_reference_id']}'),
      bookingReferenceId: json['booking_reference_id'] != null
          ? int.tryParse('${json['booking_reference_id']}')
          : null,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.parse('${json['user_id']}'),
      userName: json['user_name']?.toString(),
      rating: json['rating'] != null
          ? double.tryParse('${json['rating']}') ?? 5.0
          : 5.0,
      title: json['title']?.toString(),
      comment: json['comment']?.toString(),
      isVerifiedBooking: json['is_verified_booking'] == true,
      isPublished: json['is_published'] != false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      artisanListingId: json['artisan_listing_id'] != null
          ? int.tryParse('${json['artisan_listing_id']}')
          : null,
      artisanListingTitle: json['artisan_listing_title']?.toString(),
      bookingReferenceCode: json['booking_reference_code']?.toString(),
    );
  }
}

/// Aggregated metrics and star breakdown for an artisan listing.
class ArtisanReviewSummaryModel {
  final int listingId;
  final String listingTitle;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingBreakdown;
  final int verifiedReviewsCount;

  const ArtisanReviewSummaryModel({
    required this.listingId,
    required this.listingTitle,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    required this.verifiedReviewsCount,
  });

  factory ArtisanReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdownRaw = json['rating_breakdown'];
    final Map<String, int> breakdown = {
      '5': 0,
      '4': 0,
      '3': 0,
      '2': 0,
      '1': 0,
    };
    if (breakdownRaw is Map) {
      breakdownRaw.forEach((k, v) {
        breakdown[k.toString()] = int.tryParse('$v') ?? 0;
      });
    }

    return ArtisanReviewSummaryModel(
      listingId: json['listing_id'] is int
          ? json['listing_id'] as int
          : int.tryParse('${json['listing_id']}') ?? 0,
      listingTitle: json['listing_title']?.toString() ?? '',
      averageRating: json['average_rating'] != null
          ? double.tryParse('${json['average_rating']}') ?? 0.0
          : 0.0,
      totalReviews: json['total_reviews'] is int
          ? json['total_reviews'] as int
          : int.tryParse('${json['total_reviews']}') ?? 0,
      ratingBreakdown: breakdown,
      verifiedReviewsCount: json['verified_reviews_count'] is int
          ? json['verified_reviews_count'] as int
          : int.tryParse('${json['verified_reviews_count']}') ?? 0,
    );
  }
}

/// Paginated review list response.
class ArtisanReviewPaginationModel {
  final List<ArtisanReviewModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final double averageRating;
  final int totalReviews;

  const ArtisanReviewPaginationModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.averageRating,
    required this.totalReviews,
  });

  factory ArtisanReviewPaginationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ArtisanReviewPaginationModel(
      items: rawItems
          .map((e) => ArtisanReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
      page: json['page'] is int ? json['page'] as int : int.tryParse('${json['page']}') ?? 1,
      pageSize: json['page_size'] is int
          ? json['page_size'] as int
          : int.tryParse('${json['page_size']}') ?? 10,
      totalPages: json['total_pages'] is int
          ? json['total_pages'] as int
          : int.tryParse('${json['total_pages']}') ?? 0,
      averageRating: json['average_rating'] != null
          ? double.tryParse('${json['average_rating']}') ?? 0.0
          : 0.0,
      totalReviews: json['total_reviews'] is int
          ? json['total_reviews'] as int
          : int.tryParse('${json['total_reviews']}') ?? 0,
    );
  }
}

/// Payload for submitting a review after a completed reservation.
class ArtisanReviewCreatePayload {
  final int reservationId;
  final double rating;
  final String? title;
  final String? comment;

  const ArtisanReviewCreatePayload({
    required this.reservationId,
    required this.rating,
    this.title,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'reservation_id': reservationId,
      'rating': rating,
    };
    if (title != null && title!.trim().isNotEmpty) {
      map['title'] = title!.trim();
    }
    if (comment != null && comment!.trim().isNotEmpty) {
      map['comment'] = comment!.trim();
    }
    return map;
  }
}

/// Payload for updating an existing review.
class ArtisanReviewUpdatePayload {
  final double? rating;
  final String? title;
  final String? comment;

  const ArtisanReviewUpdatePayload({
    this.rating,
    this.title,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rating != null) {
      map['rating'] = rating;
    }
    if (title != null) {
      map['title'] = title!.trim().isEmpty ? null : title!.trim();
    }
    if (comment != null) {
      map['comment'] = comment!.trim().isEmpty ? null : comment!.trim();
    }
    return map;
  }
}

