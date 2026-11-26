import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../../categories/data/category_demo_data.dart';

class _ShowcaseCardItem {
  final String keyName;
  final String title;
  final String subtitle;
  final String detailSubtitle;
  final String description;
  final String imageUrl;
  final IconData fallbackIcon;
  final String? badge;
  final Color? badgeColor;
  final String? price;

  const _ShowcaseCardItem({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.detailSubtitle,
    required this.description,
    required this.imageUrl,
    required this.fallbackIcon,
    this.badge,
    this.badgeColor,
    this.price,
  });
}

/// Reusable Home Screen Category Showcase Sections
/// Displays Eco Tourism, Activities, Local Guides, and Rentals
/// using existing CategoryDemoData when "All" is selected on Home.
class HomeCategoryShowcase extends StatelessWidget {
  const HomeCategoryShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final ecoItems = CategoryDemoData.ecoExperiences
        .take(2)
        .map(
          (e) => _ShowcaseCardItem(
            keyName: 'home_eco_${e.id}',
            title: e.name,
            subtitle: e.location,
            detailSubtitle: '${e.category} • ${e.location}',
            description: '${e.ecoBadge}\n\n${e.description}',
            imageUrl: e.imageUrl,
            fallbackIcon: Icons.eco_outlined,
            badge: e.ecoBadge,
            badgeColor: const Color(0xFF16A34A),
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
            detailSubtitle:
                '${a.location} • ${a.duration} • ${CategoryDemoData.formatLkr(a.priceLkr)}',
            description: a.description,
            imageUrl: a.imageUrl,
            fallbackIcon: Icons.terrain_rounded,
            badge: a.category,
            badgeColor: const Color(0xFF0284C7),
            price: CategoryDemoData.formatLkr(a.priceLkr),
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
            detailSubtitle: '${g.region} • ★ ${g.rating}',
            description:
                'Languages: ${g.languages.join(', ')}\n\n${g.bio}',
            imageUrl: g.imageUrl,
            fallbackIcon: Icons.person_outline_rounded,
            badge: g.languages.join(' • '),
            badgeColor: const Color(0xFFEA580C),
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
            detailSubtitle:
                '${r.location} • ${CategoryDemoData.formatLkr(r.pricePerDayLkr)} / day',
            description: r.description,
            imageUrl: r.imageUrl,
            fallbackIcon: Icons.directions_car_outlined,
            badge: r.category,
            badgeColor: const Color(0xFF0A4DF5),
            price: '${CategoryDemoData.formatLkr(r.pricePerDayLkr)} / day',
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
          items: ecoItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Activities',
          seeAllKey: const Key('see_all_activities'),
          routeName: '/category/activities',
          items: activityItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Local Guides',
          seeAllKey: const Key('see_all_guides'),
          routeName: '/category/guides',
          items: guideItems,
        ),
        const SizedBox(height: 14),
        _CategoryShowcaseSection(
          title: 'Rentals',
          seeAllKey: const Key('see_all_rentals'),
          routeName: '/category/rentals',
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
  final List<_ShowcaseCardItem> items;

  const _CategoryShowcaseSection({
    required this.title,
    required this.seeAllKey,
    required this.routeName,
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
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0.0 : 10.0,
                ),
                child: GestureDetector(
                  key: Key(item.keyName),
                  onTap: () => showCategoryDemoNotice(
                    context,
                    title: item.title,
                    subtitle: item.detailSubtitle,
                    description: item.description,
                    icon: item.fallbackIcon,
                  ),
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
                            accentColor:
                                item.badgeColor ?? const Color(0xFF0A4DF5),
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
                                    color:
                                        (item.badgeColor ??
                                                const Color(0xFF0A4DF5))
                                            .withAlpha(22),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          item.badgeColor ??
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

