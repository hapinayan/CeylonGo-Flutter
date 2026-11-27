// Strongly typed models for CeylonGo Personalized Travel Recommendations.
// Uses real public backend listings (`MapLocationItem`) and transparent
// client-side interest/district ranking.

import '../../map/models/map_models.dart';

enum TravelerInterest {
  natureEco(
    id: 'nature_eco',
    label: 'Nature & Eco Tourism',
    backendCategories: ['eco_tourism'],
    moduleTypes: ['eco_experience'],
  ),
  adventure(
    id: 'adventure',
    label: 'Adventure & Activities',
    backendCategories: ['adventure', 'local_activity', 'community_activity'],
    moduleTypes: ['activity'],
  ),
  cultural(
    id: 'cultural',
    label: 'Cultural Experiences',
    backendCategories: ['cultural'],
    moduleTypes: ['activity'],
  ),
  artisan(
    id: 'artisan',
    label: 'Local Crafts & Artisan',
    backendCategories: ['artisan'],
    moduleTypes: ['artisan'],
  ),
  homestays(
    id: 'homestays',
    label: 'Homestays',
    backendCategories: ['homestay'],
    moduleTypes: ['homestay'],
  ),
  tourGuides(
    id: 'tour_guides',
    label: 'Guided Tours',
    backendCategories: ['tour_guide'],
    moduleTypes: ['tour_guide'],
  ),
  rentals(
    id: 'rentals',
    label: 'Vehicle Rentals',
    backendCategories: ['bike_rental', 'bicycle_rental'],
    moduleTypes: ['rental'],
  );

  final String id;
  final String label;
  final List<String> backendCategories;
  final List<String> moduleTypes;

  const TravelerInterest({
    required this.id,
    required this.label,
    required this.backendCategories,
    required this.moduleTypes,
  });

  static TravelerInterest? fromId(String id) {
    for (final value in TravelerInterest.values) {
      if (value.id == id) return value;
    }
    return null;
  }

  bool matchesListing(MapLocationItem item) {
    return backendCategories.contains(item.category) ||
        moduleTypes.contains(item.moduleType);
  }
}

class TravelerPreferences {
  final Set<TravelerInterest> selectedInterests;
  final String? preferredDistrict;

  const TravelerPreferences({
    this.selectedInterests = const {},
    this.preferredDistrict,
  });

  bool get isEmpty =>
      selectedInterests.isEmpty &&
      (preferredDistrict == null || preferredDistrict!.trim().isEmpty);

  TravelerPreferences copyWith({
    Set<TravelerInterest>? selectedInterests,
    String? preferredDistrict,
    bool clearDistrict = false,
  }) {
    return TravelerPreferences(
      selectedInterests: selectedInterests ?? this.selectedInterests,
      preferredDistrict:
          clearDistrict ? null : (preferredDistrict ?? this.preferredDistrict),
    );
  }

  Map<String, dynamic> toJson() => {
        'interests': selectedInterests.map((e) => e.id).toList()..sort(),
        if (preferredDistrict != null && preferredDistrict!.trim().isNotEmpty)
          'district': preferredDistrict!.trim(),
      };

  factory TravelerPreferences.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'];
    final interests = <TravelerInterest>{};
    if (rawInterests is List) {
      for (final item in rawInterests) {
        if (item is String) {
          final parsed = TravelerInterest.fromId(item);
          if (parsed != null) interests.add(parsed);
        }
      }
    }
    final rawDist = json['district'];
    final dist =
        rawDist is String && rawDist.trim().isNotEmpty ? rawDist.trim() : null;
    return TravelerPreferences(
      selectedInterests: interests,
      preferredDistrict: dist,
    );
  }
}

class RankedRecommendation {
  final MapLocationItem item;
  final int score;
  final List<TravelerInterest> matchedInterests;
  final bool districtMatched;
  final List<String> reasons;

  const RankedRecommendation({
    required this.item,
    required this.score,
    required this.matchedInterests,
    required this.districtMatched,
    required this.reasons,
  });

  String get explanationText => reasons.isEmpty
      ? 'Approved public listing on CeylonGo'
      : 'Recommended because ${reasons.join(' • ')}';
}

class RecommendationResultSet {
  final List<RankedRecommendation> recommendations;
  final int totalFetched;
  final int skippedInvalidCount;
  final bool hasMore;
  final List<String> availableDistricts;

  const RecommendationResultSet({
    required this.recommendations,
    required this.totalFetched,
    required this.skippedInvalidCount,
    required this.hasMore,
    required this.availableDistricts,
  });
}

