import '../../map/models/map_models.dart';
import '../../map/services/map_api_service.dart';
import '../models/recommendation_models.dart';
import 'recommendation_engine.dart';

/// Fetches real, approved/public backend listings via verified read-only
/// FastAPI endpoints (`GET /api/v1/map/locations`, `GET /api/v1/map/search`)
/// and applies deterministic client-side interest ranking.
///
/// Never invents fallback listings when the backend fails.
class RecommendationApiService {
  final MapApiService _mapApiService;
  final RecommendationEngine _engine;

  RecommendationApiService({
    MapApiService? mapApiService,
    RecommendationEngine? engine,
  })  : _mapApiService = mapApiService ?? MapApiService(),
        _engine = engine ?? const RecommendationEngine();

  Future<RecommendationResultSet> fetchRecommendations({
    required TravelerPreferences preferences,
    int page = 1,
    int pageSize = 50,
  }) async {
    final district = preferences.preferredDistrict?.trim();
    final interests = preferences.selectedInterests;

    // If exactly 1 interest with 1 backend category is chosen and no district search
    // is needed, query that category directly for sharper pagination.
    String? singleCategory;
    if (interests.length == 1 && interests.first.backendCategories.length == 1) {
      singleCategory = interests.first.backendCategories.first;
    }

    final MapPageResponse response;
    if (district != null && district.length >= 2) {
      response = await _mapApiService.searchLocations(
        query: district,
        category: singleCategory,
        page: page,
        pageSize: pageSize,
      );
    } else {
      response = await _mapApiService.getLocations(
        bounds: MapBounds.sriLanka,
        category: singleCategory,
        page: page,
        pageSize: pageSize,
      );
    }

    return _engine.rank(
      candidates: response.items,
      preferences: preferences,
      skippedInvalidCount: response.skippedInvalidCount,
      hasMore: response.hasMore,
    );
  }
}

