import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DestinationItem {
  final String name;
  final String imageUrl;
  final String province;
  final String subtitle;

  const DestinationItem({
    required this.name,
    required this.imageUrl,
    required this.province,
    required this.subtitle,
  });
}

/// Section F: Popular Destinations
/// Displays horizontal destination cards (Jaffna, Ella, Kandy)
/// with smooth physics, image fallbacks, and micro tap feedback.
class HomePopularDestinations extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback? onViewAllTap;
  final ValueChanged<DestinationItem>? onDestinationTap;

  const HomePopularDestinations({
    super.key,
    required this.animation,
    this.onViewAllTap,
    this.onDestinationTap,
  });

  static const List<DestinationItem> destinations = [
    DestinationItem(
      name: 'Jaffna',
      province: 'Northern Province',
      subtitle: 'Nallur Kovil & Heritage',
      imageUrl: 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=600',
    ),
    DestinationItem(
      name: 'Ella',
      province: 'Uva Province',
      subtitle: 'Nine Arch Bridge & Tea',
      imageUrl: 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
    ),
    DestinationItem(
      name: 'Kandy',
      province: 'Central Province',
      subtitle: 'Temple of the Tooth & Lake',
      imageUrl: 'https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?w=600',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
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
              padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Popular Destinations',
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
                    onTap: onViewAllTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exploring all 25 Sri Lankan travel districts!'),
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

            // Horizontal Scrollable Cards List
            SizedBox(
              height: 146,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: destinations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  return _DestinationCard(
                    destination: destination,
                    onTap: () => onDestinationTap != null
                        ? onDestinationTap!(destination)
                        : Navigator.pushNamed(context, '/artisan'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  final DestinationItem destination;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.destination,
    required this.onTap,
  });

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  double _scale = 1.0;

  Widget _buildPlaceholder() {
    return Container(
      width: 122,
      height: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF082B5C).withAlpha(160),
            const Color(0xFF2563EB).withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.location_city_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        key: Key('destination_${widget.destination.name.toLowerCase()}'),
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 122,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                widget.destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildPlaceholder();
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.destination.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

