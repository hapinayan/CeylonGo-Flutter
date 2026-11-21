library;

import 'artisan_listing_model.dart';

class ArtisanProductImageModel {
  final int id;
  final int showcaseItemId;
  final String imageUrl;
  final String? caption;
  final int displayOrder;
  final bool isPrimary;

  const ArtisanProductImageModel({
    required this.id,
    required this.showcaseItemId,
    required this.imageUrl,
    this.caption,
    this.displayOrder = 0,
    this.isPrimary = false,
  });

  String get fullImageUrl => resolveImageUrl(imageUrl);

  factory ArtisanProductImageModel.fromJson(Map<String, dynamic> json) {
    return ArtisanProductImageModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      showcaseItemId: json['showcase_item_id'] is int
          ? json['showcase_item_id'] as int
          : int.tryParse('${json['showcase_item_id']}') ?? 0,
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
    'showcase_item_id': showcaseItemId,
    'image_url': imageUrl,
    'caption': caption,
    'display_order': displayOrder,
    'is_primary': isPrimary,
  };
}

class ShowcaseItemSummary {
  final int id;
  final int artisanListingId;
  final String title;
  final String itemType; // 'product' or 'service'
  final double? price;
  final String currency;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFeatured;
  final bool isActive;
  final int stockQuantity;
  final String? sku;
  final bool isCustomOrderAvailable;
  final String approvalStatus;

  const ShowcaseItemSummary({
    required this.id,
    required this.artisanListingId,
    required this.title,
    this.itemType = 'product',
    this.price,
    this.currency = 'LKR',
    this.imageUrl,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isActive = true,
    this.stockQuantity = 0,
    this.sku,
    this.isCustomOrderAvailable = false,
    this.approvalStatus = 'approved',
  });

  String get fullImageUrl => resolveImageUrl(imageUrl);

  bool get isProduct => itemType.toLowerCase() == 'product';
  bool get isService => itemType.toLowerCase() == 'service';

  bool get isPurchasable =>
      isActive && approvalStatus == 'approved' && isAvailable && stockQuantity > 0;

  String get formattedPrice {
    if (price == null) return 'Inquire Price';
    final pStr = price!.toStringAsFixed(price!.truncateToDouble() == price! ? 0 : 2);
    return '$currency $pStr';
  }

  factory ShowcaseItemSummary.fromJson(Map<String, dynamic> json) {
    return ShowcaseItemSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.tryParse('${json['artisan_listing_id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      itemType: (json['item_type'] ?? 'product').toString(),
      price: json['price'] != null ? double.tryParse('${json['price']}') : null,
      currency: (json['currency'] ?? 'LKR').toString(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] == true,
      isFeatured: json['is_featured'] == true,
      isActive: json['is_active'] == true,
      stockQuantity: json['stock_quantity'] is int
          ? json['stock_quantity'] as int
          : int.tryParse('${json['stock_quantity']}') ?? 0,
      sku: json['sku'] as String?,
      isCustomOrderAvailable: json['is_custom_order_available'] == true,
      approvalStatus: (json['approval_status'] ?? 'approved').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artisan_listing_id': artisanListingId,
    'title': title,
    'item_type': itemType,
    'price': price,
    'currency': currency,
    'image_url': imageUrl,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'is_active': isActive,
    'stock_quantity': stockQuantity,
    'sku': sku,
    'is_custom_order_available': isCustomOrderAvailable,
    'approval_status': approvalStatus,
  };
}

class ShowcaseItemResponse extends ShowcaseItemSummary {
  final String? description;
  final String? materials;
  final int? durationMinutes;
  final String? listingTitle;
  final List<ArtisanProductImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShowcaseItemResponse({
    required super.id,
    required super.artisanListingId,
    required super.title,
    super.itemType = 'product',
    super.price,
    super.currency = 'LKR',
    super.imageUrl,
    super.isAvailable = true,
    super.isFeatured = false,
    super.isActive = true,
    super.stockQuantity = 0,
    super.sku,
    super.isCustomOrderAvailable = false,
    super.approvalStatus = 'approved',
    this.description,
    this.materials,
    this.durationMinutes,
    this.listingTitle,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ShowcaseItemResponse.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] ?? json['product_images'];
    final imageList = <ArtisanProductImageModel>[];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is Map<String, dynamic>) {
          imageList.add(ArtisanProductImageModel.fromJson(img));
        }
      }
    }

    return ShowcaseItemResponse(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.tryParse('${json['artisan_listing_id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      itemType: (json['item_type'] ?? 'product').toString(),
      price: json['price'] != null ? double.tryParse('${json['price']}') : null,
      currency: (json['currency'] ?? 'LKR').toString(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] == true,
      isFeatured: json['is_featured'] == true,
      isActive: json['is_active'] == true,
      stockQuantity: json['stock_quantity'] is int
          ? json['stock_quantity'] as int
          : int.tryParse('${json['stock_quantity']}') ?? 0,
      sku: json['sku'] as String?,
      isCustomOrderAvailable: json['is_custom_order_available'] == true,
      approvalStatus: (json['approval_status'] ?? 'approved').toString(),
      description: json['description'] as String?,
      materials: json['materials'] as String?,
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse('${json['duration_minutes']}'),
      listingTitle: json['listing_title'] as String?,
      images: imageList,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse('${json['updated_at']}') : null,
    );
  }
}

class ShowcaseItemPagination {
  final List<ShowcaseItemSummary> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const ShowcaseItemPagination({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ShowcaseItemPagination.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemList = <ShowcaseItemSummary>[];
    if (rawItems is List) {
      for (final itm in rawItems) {
        if (itm is Map<String, dynamic>) {
          itemList.add(ShowcaseItemSummary.fromJson(itm));
        }
      }
    }
    return ShowcaseItemPagination(
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
