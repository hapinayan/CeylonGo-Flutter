import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';

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
/// Displays two vertically stacked homestay cards matching the approved reference.
class HomeFeaturedHomestays extends StatefulWidget {
  final Animation<double> animation;
  final VoidCallback? onViewAllTap;

  const HomeFeaturedHomestays({
    super.key,
    required this.animation,
    this.onViewAllTap,
  });

  @override
  State<HomeFeaturedHomestays> createState() => _HomeFeaturedHomestaysState();
}

class _HomeFeaturedHomestaysState extends State<HomeFeaturedHomestays> {
  final Set<int> _favoriteIds = {};

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

  void _toggleFavorite(int id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  void _onCardTap(HomestayItem item) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.title} (${item.location}) • LKR ${_formatPrice(item.pricePerNightLkr)} / night',
        ),
        backgroundColor: AppTheme.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
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
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Viewing all certified heritage homestays',
                              ),
                              backgroundColor: AppTheme.primaryNavy,
                            ),
                          );
                        },
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

            // Two Vertically Stacked Homestay Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: List.generate(homestays.length, (index) {
                  final item = homestays[index];
                  final isFav = _favoriteIds.contains(item.id);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == homestays.length - 1 ? 0.0 : 12.0,
                    ),
                    child: GestureDetector(
                      key: Key('homestay_card_${item.id}'),
                      onTap: () => _onCardTap(item),
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
                            // Left Property Image
                            Container(
                              width: 118,
                              height: 94,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFF1F5F9),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CeylonGoNetworkImage(
                                imageUrl: item.imageUrl,
                                fallbackIcon: Icons.holiday_village_rounded,
                                iconSize: 30,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Right Property Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title
                                  Text(
                                    item.title,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Location
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
                                                    item.location,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                            // Rating
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  size: 15,
                                                  color: Color(0xFFF59E0B),
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    '${item.rating} (${item.reviewCount} reviews)',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                            // Price
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: _formatPrice(
                                                      item.pricePerNightLkr,
                                                    ),
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                      // Outline Heart Icon on the right
                                      GestureDetector(
                                        key: Key('favorite_homestay_${item.id}'),
                                        onTap: () => _toggleFavorite(item.id),
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
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
