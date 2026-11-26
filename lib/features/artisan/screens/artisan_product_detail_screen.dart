import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/showcase_item_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_launcher_service.dart';
import '../services/artisan_service.dart';
import '../widgets/stock_badge.dart';
import 'artisan_business_detail_screen.dart';
import 'artisan_reservation_form_screen.dart';

class ArtisanProductDetailScreen extends StatefulWidget {
  final int productId;
  final ArtisanService? artisanService;

  const ArtisanProductDetailScreen({
    super.key,
    required this.productId,
    this.artisanService,
  });

  @override
  State<ArtisanProductDetailScreen> createState() =>
      _ArtisanProductDetailScreenState();
}

class _ArtisanProductDetailScreenState
    extends State<ArtisanProductDetailScreen> {
  late final ArtisanService _artisanService;

  ShowcaseItemResponse? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _artisanService.getShowcaseItemDetails(widget.productId);
      if (mounted) {
        setState(() {
          _product = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Product Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                const Text(
                  'Item Not Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage ?? 'Unable to retrieve showcase product.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProduct,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final images = product.images;
    final currentImageUrl = images.isNotEmpty && _selectedImageIndex < images.length
        ? images[_selectedImageIndex].fullImageUrl
        : product.fullImageUrl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          IconButton(
            key: const Key('product_favorite_btn'),
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Product favorites coming soon (Pending schema approval)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product favorites are coming soon pending system schema update.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              final shareUrl = ArtisanLauncherService.buildPublicShareUrl(
                'products',
                product.id,
              );
              ArtisanLauncherService.showShareModal(
                context,
                title: product.title,
                shareUrl: shareUrl,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            SizedBox(
              height: 260,
              width: double.infinity,
              child: currentImageUrl.isNotEmpty
                  ? Image.network(
                      currentImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),

            // Gallery Thumbnails
            if (images.length > 1) ...[
              Container(
                height: 70,
                color: AppTheme.backgroundWhite,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedImageIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: Container(
                        width: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentOrange
                                : AppTheme.borderSlate,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          images[index].fullImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Product Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isProduct
                              ? const Color(0xFFE0E7FF)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.isProduct ? 'Handcrafted Product' : 'Artisan Workshop / Experience',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: product.isProduct
                                ? const Color(0xFF3730A3)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      StockBadge(
                        stockQuantity: product.stockQuantity,
                        isAvailable: product.isAvailable,
                        isActive: product.isActive,
                        approvalStatus: product.approvalStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  if (product.sku != null && product.sku!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product.sku}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Materials / Duration Attributes Card
                  if ((product.materials != null && product.materials!.isNotEmpty) ||
                      product.durationMinutes != null ||
                      product.isCustomOrderAvailable) ...[
                    Card(
                      elevation: 0,
                      color: AppTheme.backgroundWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppTheme.borderSlate),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            if (product.materials != null && product.materials!.isNotEmpty)
                              _buildAttributeRow(
                                Icons.texture,
                                'Materials & Crafting Tools',
                                product.materials!,
                              ),
                            if (product.durationMinutes != null && product.durationMinutes! > 0)
                              _buildAttributeRow(
                                Icons.schedule,
                                'Workshop Duration',
                                '${product.durationMinutes} minutes',
                              ),
                            if (product.isCustomOrderAvailable)
                              _buildAttributeRow(
                                Icons.check_circle_outline,
                                'Custom Commissions',
                                'Available on request with artisan',
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const Text(
                      'About This Craft',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Parent Business Workshop Card
                  Card(
                    elevation: 0,
                    color: AppTheme.backgroundWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppTheme.borderSlate),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.primarySubtle,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: AppTheme.primaryNavy,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Crafted by Workshop',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    textBaseline: TextBaseline.alphabetic,
                                  ),
                                ),
                                Text(
                                  product.listingTitle ?? 'Artisan Workshop #${product.artisanListingId}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtisanBusinessDetailScreen(
                                    listingId: product.artisanListingId,
                                    artisanService: _artisanService,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Visit Shop'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (product.isProduct && product.stockQuantity > 0 && product.isAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('reserve_for_pickup_btn'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtisanReservationFormScreen(
                                product: product,
                                artisanService: _artisanService,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Reserve for In-Store Pickup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (product.isProduct && (!product.isAvailable || product.stockQuantity == 0)) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('reserve_out_of_stock_btn'),
                        onPressed: null,
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: Text(!product.isAvailable
                            ? 'Item Currently Unavailable'
                            : 'Out of Stock - Reservations Paused'),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFFF1F5F9),
                          disabledForegroundColor: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Inquiry and Contact Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ArtisanLauncherService.showContactModal(
                          context,
                          title: product.title,
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Inquire with Artisan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Direct inquiry with verified local artisans. No middleman markups.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.primarySubtle,
      child: const Center(
        child: Icon(Icons.image, size: 64, color: AppTheme.primaryNavy),
      ),
    );
  }
}
