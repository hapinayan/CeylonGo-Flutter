import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../categories/models/discovery_models.dart';
import '../../categories/screens/homestay_detail_screen.dart';

class HomestayItem {
  final int id;
  final String title;
  final String location;
  final double rating;
  final int reviewCount;
  final int pricePerNightLkr;
  final String imageUrl;

  const HomestayItem({
    required this.id,
    required this.title,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNightLkr,
    required this.imageUrl,
  });
}

/// Section E: Featured Homestays
/// Displays vertically stacked homestay cards from the live backend API
/// (or demo fixtures only when ArtisanDemoService.isDemoMode is enabled).
class HomeFeaturedHomestays extends StatefulWidget {
  final Animation<double> animation;
  final VoidCallback? onViewAllTap;
  final List<HomestayListingModel>? homestays;
  final Set<int> favoriteIds;
  final ValueChanged<HomestayListingModel>? onFavoriteTap;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const HomeFeaturedHomestays({
    super.key,
    required this.animation,
    this.onViewAllTap,
    this.homestays,
    this.favoriteIds = const {},
    this.onFavoriteTap,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<HomeFeaturedHomestays> createState() => _HomeFeaturedHomestaysState();
}

class _HomeFeaturedHomestaysState extends State<HomeFeaturedHomestays> {
  final Set<int> _demoFavoriteIds = {};

  static const List<HomestayItem> homestays = [
    HomestayItem(
      id: 1,
      title: 'Traditional Villa with garden',
      location: 'Jaffna',
      rating: 4.8,
      reviewCount: 128,
      pricePerNightLkr: 12500,
      imageUrl:
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
    ),
    HomestayItem(
      id: 2,
      title: 'Ella Mountain Homestay',
      location: 'Ella',
      rating: 4.9,
      reviewCount: 256,
      pricePerNightLkr: 18000,
      imageUrl:
          'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
    ),
  ];

  String _formatPrice(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.55, 0.9, curve: Curves.easeIn),
    );

    final liveItems = widget.homestays;
    final useDemo = ArtisanDemoService.isDemoMode && (liveItems == null || liveItems.isEmpty);

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Featured Homestays',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.onViewAllTap ??
                        () => Navigator.pushNamed(context, '/category/homestays'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A4DF5),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Color(0xFF0A4DF5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildBody(context, liveItems, useDemo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<HomestayListingModel>? liveItems,
    bool useDemo,
  ) {
    if (widget.isLoading && !useDemo) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (widget.errorMessage != null && !useDemo) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Column(
          children: [
            Text(
              widget.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (useDemo) {
      return Column(
        children: List.generate(homestays.length, (index) {
          final item = homestays[index];
          final isFav = _demoFavoriteIds.contains(item.id);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == homestays.length - 1 ? 0.0 : 12.0,
            ),
            child: _buildCard(
              cardKey: Key('homestay_card_${item.id}'),
              favKey: Key('favorite_homestay_${item.id}'),
              title: item.title,
              location: item.location,
              metaLine: '${item.rating} (${item.reviewCount} reviews)',
              priceAmount: _formatPrice(item.pricePerNightLkr),
              imageUrl: item.imageUrl,
              isFav: isFav,
              onTap: () => Navigator.pushNamed(context, '/category/homestays'),
              onFavTap: () {
                setState(() {
                  if (isFav) {
                    _demoFavoriteIds.remove(item.id);
                  } else {
                    _demoFavoriteIds.add(item.id);
                  }
                });
              },
            ),
          );
        }),
      );
    }

    final items = liveItems ?? const <HomestayListingModel>[];
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: const Text(
          'No published homestays available yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      );
    }

    final displayItems = items.take(3).toList();
    return Column(
      children: List.generate(displayItems.length, (index) {
        final item = displayItems[index];
        final isFav = widget.favoriteIds.contains(item.id);
        final parsedPrice = double.tryParse(item.price)?.round() ?? 0;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == displayItems.length - 1 ? 0.0 : 12.0,
          ),
          child: _buildCard(
            cardKey: Key('homestay_card_${item.id}'),
            favKey: Key('favorite_homestay_${item.id}'),
            title: item.title,
            location: item.locationLabel,
            metaLine: item.hostName.isNotEmpty
                ? item.hostName
                : (item.propertyType ?? 'Verified Homestay'),
            priceAmount: parsedPrice > 0
                ? _formatPrice(parsedPrice)
                : formatLkrAmount(item.price).replaceFirst('LKR ', ''),
            imageUrl: item.coverImageUrl,
            isFav: isFav,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomestayDetailScreen(
                    listingId: item.id,
                    initialListing: item,
                  ),
                ),
              );
            },
            onFavTap: widget.onFavoriteTap != null
                ? () => widget.onFavoriteTap!(item)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildCard({
    required Key cardKey,
    required Key favKey,
    required String title,
    required String location,
    required String metaLine,
    required String priceAmount,
    required String imageUrl,
    required bool isFav,
    required VoidCallback onTap,
    VoidCallback? onFavTap,
  }) {
    return GestureDetector(
      key: cardKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFDBEAFE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 118,
              height: 94,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF1F5F9),
              ),
              clipBehavior: Clip.antiAlias,
              child: CeylonGoNetworkImage(
                imageUrl: imageUrl,
                fallbackIcon: Icons.holiday_village_rounded,
                iconSize: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 14,
                                  color: Color(0xFF0A4DF5),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    metaLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'LKR ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  TextSpan(
                                    text: priceAmount,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A4DF5),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' / night',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (onFavTap != null)
                        GestureDetector(
                          key: favKey,
                          onTap: onFavTap,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: isFav
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                    ],
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
