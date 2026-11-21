/// Model representing an active promotion/discount for an artisan workshop or product.
class ArtisanPromotionModel {
  final int id;
  final int artisanListingId;
  final int? showcaseItemId;
  final String title;
  final String? description;
  final String promoCode;
  final double? discountPercentage;
  final double? discountFixedAmount;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? listingTitle;
  final String? itemTitle;

  const ArtisanPromotionModel({
    required this.id,
    required this.artisanListingId,
    this.showcaseItemId,
    required this.title,
    this.description,
    required this.promoCode,
    this.discountPercentage,
    this.discountFixedAmount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.listingTitle,
    this.itemTitle,
  });

  factory ArtisanPromotionModel.fromJson(Map<String, dynamic> json) {
    return ArtisanPromotionModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.parse('${json['artisan_listing_id']}'),
      showcaseItemId: json['showcase_item_id'] != null
          ? int.tryParse('${json['showcase_item_id']}')
          : null,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      promoCode: json['promo_code']?.toString() ?? '',
      discountPercentage: json['discount_percentage'] != null
          ? double.tryParse('${json['discount_percentage']}')
          : null,
      discountFixedAmount: json['discount_fixed_amount'] != null
          ? double.tryParse('${json['discount_fixed_amount']}')
          : null,
      currency: json['currency']?.toString() ?? 'LKR',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] != false,
      listingTitle: json['listing_title']?.toString(),
      itemTitle: json['item_title']?.toString(),
    );
  }

  /// Formatted badge text for the discount (e.g., '15% OFF' or 'LKR 500 OFF').
  String get discountBadge {
    if (discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    }
    if (discountFixedAmount != null && discountFixedAmount! > 0) {
      return '$currency ${discountFixedAmount!.toStringAsFixed(0)} OFF';
    }
    return 'Special Offer';
  }
}

/// Paginated promotion collection.
class ArtisanPromotionPaginationModel {
  final List<ArtisanPromotionModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const ArtisanPromotionPaginationModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ArtisanPromotionPaginationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ArtisanPromotionPaginationModel(
      items: rawItems
          .map((e) => ArtisanPromotionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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

