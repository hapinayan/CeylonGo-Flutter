import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/artisan_wishlist_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_service.dart';

/// Screen displaying the traveler's saved artisan workshops and studios.
/// Grounded in GET /api/v1/artisan-wishlists/me and DELETE /api/v1/artisan-listings/{id}/wishlist.
class ArtisanWishlistScreen extends StatefulWidget {
  final ArtisanService? artisanService;
  final SecureStorageService? storageService;

  const ArtisanWishlistScreen({
    super.key,
    this.artisanService,
    this.storageService,
  });

  @override
  State<ArtisanWishlistScreen> createState() => _ArtisanWishlistScreenState();
}

class _ArtisanWishlistScreenState extends State<ArtisanWishlistScreen> {
  late final ArtisanService _artisanService;
  late final SecureStorageService _storageService;

  List<ArtisanWishlistItemModel> _wishlistItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _storageService = widget.storageService ?? SecureStorageService();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please sign in to view your saved workshops.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final res = await _artisanService.getMyWishlist(page: 1, pageSize: 50);
      if (mounted) {
        setState(() {
          _wishlistItems = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiError ? e.message : 'Unable to load saved workshops';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRemove(ArtisanWishlistItemModel item) async {
    try {
      await _artisanService.removeFromWishlist(item.artisanListingId);
      if (mounted) {
        setState(() {
          _wishlistItems.removeWhere((w) => w.id == item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed workshop from your wishlist.'),
            backgroundColor: AppTheme.primaryNavy,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiError ? e.message : 'Failed to remove.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Saved Artisan Workshops'),
      ),
      body: Column(
        children: [
          // Informational Notice on Schema Constraints
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFEFF6FF), // Light blue
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wishlists save your favorite verified workshops and master studios. Product-level favorites will be enabled in a future database schema update.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E40AF),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Wishlist Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentOrange),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppTheme.errorRed),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _loadWishlist,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _wishlistItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_border,
                                      size: 54, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Saved Workshops Yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Save traditional artisan studios, woodcarvers, and potters to plan your visits across Sri Lanka.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/artisan');
                                    },
                                    child: const Text('Discover Workshops'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadWishlist,
                            color: AppTheme.accentOrange,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _wishlistItems.length,
                              itemBuilder: (context, index) {
                                return _buildWishlistCard(_wishlistItems[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(ArtisanWishlistItemModel item) {
    final listing = item.listing;

    return Card(
      elevation: 0,
      color: AppTheme.backgroundWhite,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSlate),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workshop Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 76,
                child: listing != null && listing.fullCoverImageUrl.isNotEmpty
                    ? Image.network(
                        listing.fullCoverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: AppTheme.primarySubtle),
                      )
                    : Container(
                        color: AppTheme.primarySubtle,
                        child: const Icon(Icons.palette_outlined,
                            color: AppTheme.primaryNavy),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing?.title ?? 'Artisan Workshop #${item.artisanListingId}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: AppTheme.errorRed, size: 20),
                        tooltip: 'Remove from wishlist',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _handleRemove(item),
                      ),
                    ],
                  ),
                  if (listing != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      listing.craftCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${listing.city}, ${listing.district}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/artisan/business?id=${item.artisanListingId}',
                          arguments: {'id': item.artisanListingId},
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('View Workshop'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
