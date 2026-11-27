import '../../map/models/map_models.dart';
import '../models/recommendation_models.dart';

/// Deterministic, transparent client-side recommendation engine.
///
/// Ranking weights (no fabricated ratings, popularity, or ML claims):
/// - Matched selected interest: +50 points per interest match
/// - Matched preferred district/city: +30 points
/// - Public listing completeness: +5 each for address, city/district, imageUrl, price
/// - Backend-verified rating (only if non-null): +(rating * 2).round()
///
/// Tie-breaking: score DESC -> name ASC -> moduleType ASC -> listingId ASC.
class RecommendationEngine {
  static const int interestMatchWeight = 50;
  static const int districtMatchWeight = 30;
  static const int completenessWeight = 5;

  const RecommendationEngine();

  RecommendationResultSet rank({
    required List<MapLocationItem> candidates,
    required TravelerPreferences preferences,
    int skippedInvalidCount = 0,
    bool hasMore = false,
  }) {
    // 1. Deduplicate by uniqueKey (moduleType_listingId)
    final deduped = <String, MapLocationItem>{};
    for (final item in candidates) {
      deduped.putIfAbsent(item.uniqueKey, () => item);
    }

    final availableDistricts = deduped.values
        .map((e) => e.district?.trim())
        .whereType<String>()
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final prefDistrict = preferences.preferredDistrict?.trim().toLowerCase();
    final hasInterests = preferences.selectedInterests.isNotEmpty;

    final ranked = <RankedRecommendation>[];
    for (final item in deduped.values) {
      final matchedInterests = preferences.selectedInterests
          .where((interest) => interest.matchesListing(item))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      // If user selected interests, filter out non-matching items.
      if (hasInterests && matchedInterests.isEmpty) {
        continue;
      }

      final districtMatched = prefDistrict != null &&
          prefDistrict.isNotEmpty &&
          ((item.district?.trim().toLowerCase() == prefDistrict) ||
              (item.city?.trim().toLowerCase() == prefDistrict));

      if (prefDistrict != null &&
          prefDistrict.isNotEmpty &&
          !hasInterests &&
          !districtMatched) {
        continue;
      }

      var score = 0;
      final reasons = <String>[];

      if (matchedInterests.isNotEmpty) {
        score += matchedInterests.length * interestMatchWeight;
        reasons.add(
          'it matches ${matchedInterests.map((e) => e.label).join(', ')}',
        );
      }

      if (districtMatched) {
        score += districtMatchWeight;
        reasons.add('it is in ${item.district ?? item.city}');
      }

      if (item.address != null && item.address!.isNotEmpty) {
        score += completenessWeight;
      }
      if (item.locationSubtitle.isNotEmpty) {
        score += completenessWeight;
      }
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        score += completenessWeight;
      }
      if (item.price != null) {
        score += completenessWeight;
      }
      if (item.rating != null && item.rating! > 0) {
        score += (item.rating! * 2).round();
        reasons.add('verified rating ${item.rating!.toStringAsFixed(1)}★');
      }

      ranked.add(
        RankedRecommendation(
          item: item,
          score: score,
          matchedInterests: matchedInterests,
          districtMatched: districtMatched,
          reasons: reasons,
        ),
      );
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byName =
          a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
      if (byName != 0) return byName;
      final byModule = a.item.moduleType.compareTo(b.item.moduleType);
      if (byModule != 0) return byModule;
      return a.item.listingId.compareTo(b.item.listingId);
    });

    return RecommendationResultSet(
      recommendations: ranked,
      totalFetched: deduped.length,
      skippedInvalidCount: skippedInvalidCount,
      hasMore: hasMore,
      availableDistricts: availableDistricts,
    );
  }
}

