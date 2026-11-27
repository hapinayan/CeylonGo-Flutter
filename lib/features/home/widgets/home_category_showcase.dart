import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../categories/data/category_demo_data.dart';
import '../../categories/models/discovery_models.dart';
import '../../categories/screens/activity_detail_screen.dart';
import '../../categories/screens/rental_detail_screen.dart';
import '../../categories/screens/tour_guide_detail_screen.dart';

class _ShowcaseCardItem {
  final String keyName;
  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData fallbackIcon;
  final String? badge;
  final Color? badgeColor;
  final String? price;
  final VoidCallback onTap;

  const _ShowcaseCardItem({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.price,
  });
}

/// Home Screen Category Showcase Sections
/// Displays live Activities, Local Guides, and Rentals from the backend API
/// (and demo previews only when ArtisanDemoService.isDemoMode is enabled).
class HomeCategoryShowcase extends StatelessWidget {
  final List<ActivityListingModel> activities;
  final List<TourGuideListingModel> guides;
  final List<RentalVehicleModel> rentals;
  final bool isLoading;

  const HomeCategoryShowcase({
    super.key,
    this.activities = const [],
    this.guides = const [],
    this.rentals = const [],
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (ArtisanDemoService.isDemoMode) {
      return _buildDemoShowcase(context);
    }

    if (isLoading && activities.isEmpty && guides.isEmpty && rentals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    final activityItems = activities
        .take(2)
        .map(
          (a) => _ShowcaseCardItem(
            keyName: 'home_activity_${a.id}',
            title: a.title,
            subtitle: '${a.locationLabel} • ${a.durationMinutes} min',
            imageUrl: a.coverImageUrl,
            fallbackIcon: Icons.terrain_rounded,
            badge: a.category,
            badgeColor: const Color(0xFF0284C7),
            price: formatLkrAmount(a.pricePerParticipant),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(
                  listingId: a.id,
                  initialListing: a,
                ),
              ),
            ),
          ),
        )
        .toList();

    final guideItems = guides
        .take(2)
        .map(
          (g) => _ShowcaseCardItem(
            keyName: 'home_guide_${g.id}',
            title: g.title,
            subtitle:
                '${g.locationLabel}${g.yearsOfExperience > 0 ? ' • ${g.yearsOfExperience} yrs exp' : ''}',
            imageUrl: g.coverImageUrl,
            fallbackIcon: Icons.person_outline_rounded,
            badge: g.languages.isNotEmpty
                ? g.languages.join(' • ')
                : '${g.packages.length} package(s)',
            badgeColor: const Color(0xFFEA580C),
            price: g.packages.isNotEmpty
                ? 'From ${formatLkrAmount(g.packages.first.price)}'
                : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TourGuideDetailScreen(
                  listingId: g.id,
                  initialListing: g,
                ),
              ),
            ),
          ),
        )
        .toList();

    final rentalItems = rentals
        .take(2)
        .map(
          (r) => _ShowcaseCardItem(
            keyName: 'home_rental_${r.id}',
            title: r.vehicleName,
            subtitle:
                '${r.locationLabel}${r.transmission != null ? ' • ${r.transmission}' : ''}',
            imageUrl: r.primaryImageUrl,
            fallbackIcon: Icons.directions_bike_outlined,
            badge: r.vehicleType.toUpperCase(),
            badgeColor: const Color(0xFF0A4DF5),
            price: '${formatLkrAmount(r.pricePerDay)} / day',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentalDetailScreen(
                  vehicleId: r.id,
                  initialVehicle: r,
                ),
              ),
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryShowcaseSection(
          title: 'Activities',
          seeAllKey: const Key('see_all_activities'),
          routeName: '/category/activities',
          emptyMessage: 'No activities published yet.',
          items: activityItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Local Guides',
          seeAllKey: const Key('see_all_guides'),
          routeName: '/category/guides',
          emptyMessage: 'No tour guides published yet.',
          items: guideItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Rentals',
          seeAllKey: const Key('see_all_rentals'),
          routeName: '/category/rentals',
          emptyMessage: 'No rental bikes or bicycles published yet.',
          items: rentalItems,
        ),
      ],
    );
  }

  Widget _buildDemoShowcase(BuildContext context) {
    final ecoItems = CategoryDemoData.ecoExperiences
        .take(2)
        .map(
          (e) => _ShowcaseCardItem(
            keyName: 'home_eco_${e.id}',
            title: e.name,
            subtitle: e.location,
            imageUrl: e.imageUrl,
            fallbackIcon: Icons.eco_outlined,
            badge: e.ecoBadge,
            badgeColor: const Color(0xFF16A34A),
            onTap: () => Navigator.pushNamed(context, '/category/eco'),
          ),
        )
        .toList();

    final activityItems = CategoryDemoData.activities
        .take(2)
        .map(
          (a) => _ShowcaseCardItem(
            keyName: 'home_activity_${a.id}',
            title: a.name,
            subtitle: '${a.location} • ${a.duration}',
            imageUrl: a.imageUrl,
            fallbackIcon: Icons.terrain_rounded,
            badge: a.category,
            badgeColor: const Color(0xFF0284C7),
            price: CategoryDemoData.formatLkr(a.priceLkr),
            onTap: () => Navigator.pushNamed(context, '/category/activities'),
          ),
        )
        .toList();

    final guideItems = CategoryDemoData.guides
        .take(2)
        .map(
          (g) => _ShowcaseCardItem(
            keyName: 'home_guide_${g.id}',
            title: g.name,
            subtitle: '${g.region} • ${g.experience}',
            imageUrl: g.imageUrl,
            fallbackIcon: Icons.person_outline_rounded,
            badge: g.languages.join(' • '),
            badgeColor: const Color(0xFFEA580C),
            onTap: () => Navigator.pushNamed(context, '/category/guides'),
          ),
        )
        .toList();

    final rentalItems = CategoryDemoData.rentals
        .take(2)
        .map(
          (r) => _ShowcaseCardItem(
            keyName: 'home_rental_${r.id}',
            title: r.name,
            subtitle: '${r.location} • ${r.transmission}',
            imageUrl: r.imageUrl,
            fallbackIcon: Icons.directions_car_outlined,
            badge: r.category,
            badgeColor: const Color(0xFF0A4DF5),
            price: '${CategoryDemoData.formatLkr(r.pricePerDayLkr)} / day',
            onTap: () => Navigator.pushNamed(context, '/category/rentals'),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryShowcaseSection(
          title: 'Eco Tourism',
          seeAllKey: const Key('see_all_eco'),
          routeName: '/category/eco',
          emptyMessage: '',
          items: ecoItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Activities',
          seeAllKey: const Key('see_all_activities'),
          routeName: '/category/activities',
          emptyMessage: '',
          items: activityItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Local Guides',
          seeAllKey: const Key('see_all_guides'),
          routeName: '/category/guides',
          emptyMessage: '',
          items: guideItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Rentals',
          seeAllKey: const Key('see_all_rentals'),
          routeName: '/category/rentals',
          emptyMessage: '',
          items: rentalItems,
        ),
      ],
    );
  }
}

class _CategoryShowcaseSection extends StatelessWidget {
  final String title;
  final Key seeAllKey;
  final String routeName;
  final String emptyMessage;
  final List<_ShowcaseCardItem> items;

  const _CategoryShowcaseSection({
    required this.title,
    required this.seeAllKey,
    required this.routeName,
    required this.emptyMessage,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: seeAllKey,
                onTap: () => Navigator.pushNamed(context, routeName),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
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
          child: items.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1 ? 0.0 : 10.0,
                      ),
                      child: GestureDetector(
                        key: Key(item.keyName),
                        onTap: item.onTap,
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
                            children: [
                              Container(
                                width: 84,
                                height: 74,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFEFF6FF),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CeylonGoNetworkImage(
                                  imageUrl: item.imageUrl,
                                  fallbackIcon: item.fallbackIcon,
                                  accentColor: item.badgeColor ??
                                      const Color(0xFF0A4DF5),
                                  iconSize: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    if (item.badge != null) ...[
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (item.badgeColor ??
                                                  const Color(0xFF0A4DF5))
                                              .withAlpha(22),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.badge!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: item.badgeColor ??
                                                const Color(0xFF0A4DF5),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (item.price != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.price!,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0A4DF5),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
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
    );
  }
}
