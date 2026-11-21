import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HomestayItem {
  final int id;
  final String title;
  final String location;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final int pricePerNightLkr;
  final String imageUrl;

  const HomestayItem({
    required this.id,
    required this.title,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.pricePerNightLkr,
    required this.imageUrl,
  });
}

/// Section G: Featured Homestays
/// Features horizontal carousel with auto-slide, animated page indicator dots,
/// amenity badges, and "Book Now" micro-interactions matching the approved reference screenshot.
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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _isUserInteracting = false;
  final Set<int> _favoriteIds = {};

  static const List<HomestayItem> homestays = [
    HomestayItem(
      id: 1,
      title: 'Traditional Village Homestay',
      location: 'Kandy',
      rating: 4.8,
      reviewCount: 124,
      amenities: ['Private Room', 'Wi-Fi', 'Local Meals'],
      pricePerNightLkr: 5500,
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
    ),
    HomestayItem(
      id: 2,
      title: 'Ella Valley Eco Cottage',
      location: 'Ella',
      rating: 4.9,
      reviewCount: 88,
      amenities: ['Entire Cabin', 'Wi-Fi', 'Mountain View'],
      pricePerNightLkr: 6800,
      imageUrl: 'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
    ),
    HomestayItem(
      id: 3,
      title: 'Galle Heritage Verandah',
      location: 'Galle',
      rating: 4.9,
      reviewCount: 152,
      amenities: ['Suite Room', 'Wi-Fi', 'Breakfast'],
      pricePerNightLkr: 8200,
      imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!_isUserInteracting && _pageController.hasClients && mounted) {
        final nextPage = (_currentPage + 1) % homestays.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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

  void _onBookNowTap(HomestayItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.holiday_village_outlined, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Location: ${item.location} • LKR ${item.pricePerNightLkr.toString()} / night',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verified homestay hosting will be connected to real booking contracts in upcoming release. In the meantime, discover master Sri Lankan artisan craft studios!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/artisan');
                },
                child: const Text('Explore Traditional Artisans'),
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        fontWeight: FontWeight.bold,
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
                              content: Text('Viewing all certified heritage homestays'),
                              backgroundColor: AppTheme.primaryNavy,
                            ),
                          );
                        },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Homestay Cards Carousel
            Listener(
              onPointerDown: (_) => _isUserInteracting = true,
              onPointerUp: (_) => _isUserInteracting = false,
              onPointerCancel: (_) => _isUserInteracting = false,
              child: SizedBox(
                height: 168,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: homestays.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final item = homestays[index];
                    final isFav = _favoriteIds.contains(item.id);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Left Property Image with Favorite Button
                            Stack(
                              children: [
                                Container(
                                  width: 125,
                                  height: 148,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFFE2E8F0),
                                        child: const Center(
                                          child: Icon(
                                            Icons.holiday_village_rounded,
                                            size: 32,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: GestureDetector(
                                    onTap: () => _toggleFavorite(item.id),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(25),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 16,
                                        color: isFav
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 12),

                            // Right Property Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Title
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),

                                  // Location & Rating Row
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          item.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 15,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        item.rating.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          ' (${item.reviewCount})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Amenities Micro Badges Row
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: item.amenities.take(3).map((amenity) {
                                      IconData icon = Icons.check_circle_outline;
                                      if (amenity.contains('Room') || amenity.contains('Cabin') || amenity.contains('Suite')) {
                                        icon = Icons.single_bed_outlined;
                                      } else if (amenity.contains('Wi-Fi')) {
                                        icon = Icons.wifi;
                                      } else if (amenity.contains('Meals') || amenity.contains('Breakfast')) {
                                        icon = Icons.restaurant_outlined;
                                      } else if (amenity.contains('Mountain')) {
                                        icon = Icons.landscape_outlined;
                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(icon, size: 10, color: const Color(0xFF475569)),
                                            const SizedBox(width: 3),
                                            Flexible(
                                              child: Text(
                                                amenity,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  // Price & Book Now Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: RichText(
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'LKR ${item.pricePerNightLkr.toString()}',
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const TextSpan(
                                                text: ' / night',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10.5,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          key: Key('book_homestay_${item.id}'),
                                          onPressed: () => _onBookNowTap(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 30),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            'Book Now',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
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
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Carousel Page Indicator Dots
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(homestays.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
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

