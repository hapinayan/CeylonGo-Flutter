import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_location_service.dart';
import '../../auth/models/api_error.dart';
import '../models/map_models.dart';
import '../services/map_api_service.dart';

/// Reusable Interactive Sri Lanka Map screen powered by FastAPI `/api/v1/map/*`.
class InteractiveMapScreen extends StatefulWidget {
  final MapApiService? mapService;
  final ArtisanLocationService? locationService;
  final Future<bool> Function(Uri uri)? externalUrlLauncher;
  final Duration searchDebounceDuration;
  final bool showMapTiles;

  const InteractiveMapScreen({
    super.key,
    this.mapService,
    this.locationService,
    this.externalUrlLauncher,
    this.searchDebounceDuration = const Duration(milliseconds: 350),
    this.showMapTiles = true,
  });

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  static const String _envTileUrl = String.fromEnvironment('MAP_TILE_URL');
  static String get _tileUrlTemplate => _envTileUrl.isNotEmpty
      ? _envTileUrl
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  late final MapApiService _mapService;
  late final ArtisanLocationService _locationService;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  int _requestSeq = 0;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingRoute = false;
  bool _tileLoadWarning = false;
  String? _errorMessage;

  List<MapCategoryItem> _categories = const [];
  List<MapLocationItem> _allItems = const [];
  int _currentPage = 1;
  bool _hasMore = false;
  String? _distanceType;

  String? _selectedCategory;
  String? _selectedDistrict;
  String _activeSearchQuery = '';

  bool _nearbyActive = false;
  int _nearbyRadiusKm = 10;
  MapCoordinates? _userOrigin;

  MapLocationItem? _selectedLocation;
  MapRouteResponse? _activeRoute;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _mapService = widget.mapService ?? MapApiService();
    _locationService = widget.locationService ?? ArtisanLocationService();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchCategories(),
      _fetchLocations(page: 1, append: false),
    ]);
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await _mapService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
      });
    } catch (_) {
      // Categories remain optional if the catalog endpoint fails temporarily.
    }
  }

  Future<void> _fetchLocations({
    required int page,
    required bool append,
  }) async {
    final seq = ++_requestSeq;
    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      late final MapPageResponse pageRes;
      if (_nearbyActive && _userOrigin != null) {
        pageRes = await _mapService.getNearby(
          latitude: _userOrigin!.latitude,
          longitude: _userOrigin!.longitude,
          radiusKm: _nearbyRadiusKm,
          category: _selectedCategory,
          page: page,
        );
      } else if (_activeSearchQuery.isNotEmpty) {
        pageRes = await _mapService.searchLocations(
          query: _activeSearchQuery,
          category: _selectedCategory,
          page: page,
        );
      } else {
        pageRes = await _mapService.getLocations(
          bounds: MapBounds.sriLanka,
          category: _selectedCategory,
          page: page,
        );
      }

      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _currentPage = pageRes.page;
        _hasMore = pageRes.hasMore;
        _distanceType = pageRes.distanceType;
        _allItems =
            append ? [..._allItems, ...pageRes.items] : pageRes.items;
        if (_selectedLocation != null &&
            !_allItems.any((e) => e.uniqueKey == _selectedLocation!.uniqueKey)) {
          _selectedLocation = null;
          _activeRoute = null;
          _routeError = null;
        }
      });
    } on ApiError catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Unable to load map locations right now.';
      });
    }
  }

  List<String> get _availableDistricts {
    final districts = _allItems
        .map((e) => e.district?.trim())
        .whereType<String>()
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return districts;
  }

  List<MapLocationItem> get _visibleItems {
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      return _allItems;
    }
    return _allItems
        .where(
          (e) =>
              e.district?.trim().toLowerCase() ==
              _selectedDistrict!.toLowerCase(),
        )
        .toList();
  }

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      if (_activeSearchQuery.isNotEmpty) {
        setState(() {
          _activeSearchQuery = '';
        });
        _fetchLocations(page: 1, append: false);
      }
      return;
    }
    if (trimmed.length < 2) return;
    _searchDebounce = Timer(widget.searchDebounceDuration, () {
      _submitSearch(trimmed);
    });
  }

  void _submitSearch(String raw) {
    _searchDebounce?.cancel();
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      _clearSearch();
      return;
    }
    setState(() {
      _activeSearchQuery = normalized;
      _nearbyActive = false;
      _selectedLocation = null;
      _activeRoute = null;
      _routeError = null;
    });
    _fetchLocations(page: 1, append: false);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _activeSearchQuery = '';
    });
    _fetchLocations(page: 1, append: false);
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _selectedLocation = null;
      _activeRoute = null;
      _routeError = null;
    });
    _fetchLocations(page: 1, append: false);
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDistrict = null;
      _activeSearchQuery = '';
      _nearbyActive = false;
      _selectedLocation = null;
      _activeRoute = null;
      _routeError = null;
    });
    _fetchLocations(page: 1, append: false);
  }

  void _recenterSriLanka() {
    _mapController.move(MapBounds.sriLankaCenter, 7.5);
  }

  void _zoomToFitVisible() {
    final items = _visibleItems;
    if (items.isEmpty) {
      _recenterSriLanka();
      return;
    }
    if (items.length == 1) {
      _mapController.move(items.first.latLng, 13.0);
      return;
    }
    final bounds = LatLngBounds.fromPoints(
      items.map((e) => e.latLng).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Future<void> _onNearbyPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('map_nearby_consent_dialog'),
        title: const Text('Find Nearby Services'),
        content: const Text(
          'CeylonGo needs your device location to discover tourism services near you. Your location is used only for this search.',
        ),
        actions: [
          TextButton(
            key: const Key('map_nearby_cancel_btn'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            key: const Key('map_nearby_allow_btn'),
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Allow & Search'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('map_location_error_snackbar'),
          content: Text(
            result.errorMessage ?? 'Location access is unavailable.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _userOrigin = MapCoordinates(
        latitude: result.latitude!,
        longitude: result.longitude!,
      );
      _nearbyActive = true;
      _activeSearchQuery = '';
      _searchController.clear();
      _selectedLocation = null;
      _activeRoute = null;
      _routeError = null;
    });
    _mapController.move(_userOrigin!.toLatLng(), 12.5);
    await _fetchLocations(page: 1, append: false);
  }

  Future<void> _openGoogleMapsDirections(MapLocationItem item) async {
    final uri = buildGoogleMapsDirectionsUri(
      destinationLat: item.latitude,
      destinationLon: item.longitude,
      originLat: _userOrigin?.latitude,
      originLon: _userOrigin?.longitude,
    );
    try {
      final launched = widget.externalUrlLauncher != null
          ? await widget.externalUrlLauncher!(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Maps or a browser for directions.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Maps is unavailable on this device.',
          ),
        ),
      );
    }
  }

  Future<void> _requestInAppRoute(MapLocationItem item) async {
    var origin = _userOrigin;
    if (origin == null) {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      if (!result.isSuccess) {
        setState(() {
          _routeError = result.errorMessage ??
              'Location permission is required to calculate an in-app route.';
        });
        return;
      }
      origin = MapCoordinates(
        latitude: result.latitude!,
        longitude: result.longitude!,
      );
      setState(() {
        _userOrigin = origin;
      });
    }

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    try {
      final route = await _mapService.getRoute(
        origin: origin,
        destination: MapCoordinates(
          latitude: item.latitude,
          longitude: item.longitude,
        ),
      );
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
        _activeRoute = route;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
        _routeError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
        _routeError = 'Unable to calculate route right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    final hasAnyFilter = _selectedCategory != null ||
        _selectedDistrict != null ||
        _activeSearchQuery.isNotEmpty ||
        _nearbyActive;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Interactive Sri Lanka Map',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('map_refresh_btn'),
            tooltip: 'Refresh locations',
            onPressed: () => _fetchLocations(page: 1, append: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopControls(hasAnyFilter),
            if (_errorMessage != null) _buildErrorBanner(),
            if (_selectedDistrict != null && _hasMore) _buildPartialFilterNote(),
            if (_tileLoadWarning) _buildTileWarningBanner(),
            Expanded(
              child: Stack(
                children: [
                  _buildMapCanvas(visible),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _MapControlFab(
                          key: const Key('map_recenter_btn'),
                          icon: Icons.center_focus_strong_rounded,
                          tooltip: 'Recenter Sri Lanka',
                          onPressed: _recenterSriLanka,
                        ),
                        const SizedBox(height: 8),
                        _MapControlFab(
                          key: const Key('map_zoom_fit_btn'),
                          icon: Icons.fit_screen_rounded,
                          tooltip: 'Zoom to fit results',
                          onPressed: _zoomToFitVisible,
                        ),
                        const SizedBox(height: 8),
                        _MapControlFab(
                          key: const Key('map_nearby_btn'),
                          icon: Icons.my_location_rounded,
                          tooltip: 'Nearby services',
                          highlighted: _nearbyActive,
                          onPressed: _onNearbyPressed,
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      key: const Key('map_loading_indicator'),
                      color: Colors.white.withValues(alpha: 0.65),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  if (!_isLoading && _errorMessage == null && visible.isEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildEmptyState(hasAnyFilter),
                    ),
                  if (_hasMore && _selectedLocation == null && visible.isNotEmpty)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: ElevatedButton.icon(
                        key: const Key('map_load_more_btn'),
                        onPressed: _isLoadingMore
                            ? null
                            : () => _fetchLocations(
                                  page: _currentPage + 1,
                                  append: true,
                                ),
                        icon: _isLoadingMore
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Load More'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 40),
                        ),
                      ),
                    ),
                  if (_selectedLocation != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _buildSelectedDetailCard(_selectedLocation!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(bool hasAnyFilter) {
    final availableCategories = _categories.where((c) => c.available).toList();
    final districts = _availableDistricts;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderSlate)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('map_search_input'),
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: _submitSearch,
                  decoration: InputDecoration(
                    hintText: 'Search services, cities, districts...',
                    isDense: true,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryNavy,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            key: const Key('map_search_clear_btn'),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  key: const Key('map_search_submit_btn'),
                  onPressed: () => _submitSearch(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('map_cat_all'),
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => _selectCategory(null),
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedCategory == null
                        ? Colors.white
                        : AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 6),
                ...availableCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      key: Key('map_cat_${cat.id}'),
                      label: Text(cat.label),
                      selected: _selectedCategory == cat.id,
                      onSelected: (_) => _selectCategory(cat.id),
                      selectedColor: AppTheme.primaryNavy,
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategory == cat.id
                            ? Colors.white
                            : AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                ),
                if (districts.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    key: const Key('map_district_filter_btn'),
                    onSelected: (value) {
                      setState(() {
                        _selectedDistrict = value == '__all__' ? null : value;
                      });
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: '__all__',
                        child: Text('All Districts'),
                      ),
                      ...districts.map(
                        (d) => PopupMenuItem(
                          value: d,
                          child: Text(d),
                        ),
                      ),
                    ],
                    child: Chip(
                      avatar: const Icon(
                        Icons.location_city_outlined,
                        size: 16,
                        color: AppTheme.primaryNavy,
                      ),
                      label: Text(
                        _selectedDistrict ?? 'District',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_nearbyActive) ...[
                  const SizedBox(width: 6),
                  PopupMenuButton<int>(
                    key: const Key('map_radius_btn'),
                    onSelected: (r) {
                      setState(() {
                        _nearbyRadiusKm = r;
                      });
                      _fetchLocations(page: 1, append: false);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 5, child: Text('5 km')),
                      PopupMenuItem(value: 10, child: Text('10 km')),
                      PopupMenuItem(value: 25, child: Text('25 km')),
                      PopupMenuItem(value: 50, child: Text('50 km')),
                    ],
                    child: Chip(
                      backgroundColor: AppTheme.primarySubtle,
                      label: Text(
                        'Within $_nearbyRadiusKm km',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasAnyFilter) ...[
                  const SizedBox(width: 6),
                  ActionChip(
                    key: const Key('map_clear_filters_btn'),
                    label: const Text('Clear'),
                    onPressed: _clearAllFilters,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCanvas(List<MapLocationItem> visible) {
    return FlutterMap(
      key: const Key('sri_lanka_flutter_map'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: MapBounds.sriLankaCenter,
        initialZoom: 7.5,
        minZoom: 5.5,
        maxZoom: 18.0,
        onTap: (_, _) {
          if (_selectedLocation != null) {
            setState(() {
              _selectedLocation = null;
              _activeRoute = null;
              _routeError = null;
            });
          }
        },
      ),
      children: [
        if (widget.showMapTiles)
          TileLayer(
            urlTemplate: _tileUrlTemplate,
            userAgentPackageName: 'com.ceylongo.ceylongo',
            errorTileCallback: (_, _, _) {
              if (mounted && !_tileLoadWarning) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _tileLoadWarning = true);
                  }
                });
              }
            },
          ),
        if (_activeRoute != null)
          PolylineLayer(
            polylines: _activeRoute!.lines
                .map(
                  (line) => Polyline(
                    points: line,
                    strokeWidth: 4.5,
                    color: AppTheme.primaryNavy,
                  ),
                )
                .toList(),
          ),
        MarkerLayer(
          markers: [
            if (_userOrigin != null)
              Marker(
                point: _userOrigin!.toLatLng(),
                width: 34,
                height: 34,
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppTheme.accentOrange,
                  size: 32,
                ),
              ),
            ...visible.map((item) {
              final isSelected = _selectedLocation?.uniqueKey == item.uniqueKey;
              return Marker(
                point: item.latLng,
                width: isSelected ? 44 : 36,
                height: isSelected ? 44 : 36,
                child: GestureDetector(
                  key: Key('map_marker_${item.uniqueKey}'),
                  onTap: () {
                    setState(() {
                      _selectedLocation = item;
                      _activeRoute = null;
                      _routeError = null;
                    });
                    _mapController.move(item.latLng, 13.0);
                  },
                  child: Icon(
                    Icons.location_on_rounded,
                    size: isSelected ? 42 : 34,
                    color: isSelected
                        ? AppTheme.accentOrange
                        : AppTheme.primaryNavy,
                  ),
                ),
              );
            }),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            const TextSourceAttribution('OpenStreetMap contributors'),
            if (_activeRoute != null)
              const TextSourceAttribution('Routing powered by Geoapify'),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      key: const Key('map_error_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFFEF2F2),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          TextButton(
            key: const Key('map_retry_btn'),
            onPressed: () => _fetchLocations(page: 1, append: false),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialFilterNote() {
    return Container(
      key: const Key('map_partial_filter_note'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFFFFFBEB),
      child: const Text(
        'District filter applies to currently loaded results only. Tap Load More for additional listings.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          color: Color(0xFF92400E),
        ),
      ),
    );
  }

  Widget _buildTileWarningBanner() {
    return Container(
      key: const Key('map_tile_warning_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppTheme.primarySubtle,
      child: const Text(
        'Map tiles could not load completely. Service markers remain active.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasAnyFilter) {
    return Material(
      key: const Key('map_empty_state'),
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: AppTheme.backgroundWhite,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppTheme.primaryNavy),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No tourism services match the current map filters.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            if (hasAnyFilter)
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Reset'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDetailCard(MapLocationItem item) {
    final detailRoute = item.supportedFlutterDetailRoute;
    return Material(
      key: const Key('map_detail_card'),
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: AppTheme.backgroundWhite,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.category.replaceAll('_', ' ')}'
                        '${item.locationSubtitle.isNotEmpty ? ' • ${item.locationSubtitle}' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('map_detail_close_btn'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _selectedLocation = null;
                      _activeRoute = null;
                      _routeError = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            if (item.address != null) ...[
              const SizedBox(height: 4),
              Text(
                item.address!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                if (item.price != null)
                  Text(
                    '${item.currency ?? 'LKR'} ${item.price!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                if (item.rating != null)
                  Text(
                    '★ ${item.rating!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                if (_distanceType == 'straight_line' && item.distanceKm != null)
                  Text(
                    '${item.distanceKm!.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
            if (_activeRoute != null) ...[
              const SizedBox(height: 8),
              Container(
                key: const Key('map_route_summary'),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Route (${_activeRoute!.mode}): ${_activeRoute!.distanceKm.toStringAsFixed(1)} km • ${_activeRoute!.durationMinutes.toStringAsFixed(0)} min',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
            if (_routeError != null) ...[
              const SizedBox(height: 8),
              Text(
                _routeError!,
                key: const Key('map_route_error'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.errorRed,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  key: const Key('map_google_directions_btn'),
                  onPressed: () => _openGoogleMapsDirections(item),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Open Directions in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('map_in_app_route_btn'),
                  onPressed:
                      _isLoadingRoute ? null : () => _requestInAppRoute(item),
                  icon: _isLoadingRoute
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.alt_route_rounded, size: 18),
                  label: const Text('In-App Route'),
                ),
                if (detailRoute != null)
                  OutlinedButton.icon(
                    key: const Key('map_view_details_btn'),
                    onPressed: () => Navigator.pushNamed(context, detailRoute),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('View Details'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  const _MapControlFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: highlighted ? AppTheme.primaryNavy : AppTheme.backgroundWhite,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: highlighted ? Colors.white : AppTheme.primaryNavy,
          size: 20,
        ),
      ),
    );
  }
}
