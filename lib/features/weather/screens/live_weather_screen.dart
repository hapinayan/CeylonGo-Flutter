import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/weather_models.dart';
import '../services/weather_api_service.dart';

/// Reusable Live Weather screen for Sri Lankan destinations.
///
/// Integrates directly with:
/// - `GET /api/v1/weather/locations?q=...`
/// - `GET /api/v1/weather/current?lat=...&lon=...`
/// - `GET /api/v1/weather/forecast?lat=...&lon=...`
class LiveWeatherScreen extends StatefulWidget {
  final WeatherApiService? weatherService;
  final WeatherLocation? initialLocation;
  final Duration searchDebounceDuration;

  const LiveWeatherScreen({
    super.key,
    this.weatherService,
    this.initialLocation,
    this.searchDebounceDuration = const Duration(milliseconds: 350),
  });

  @override
  State<LiveWeatherScreen> createState() => _LiveWeatherScreenState();
}

class _LiveWeatherScreenState extends State<LiveWeatherScreen> {
  late final WeatherApiService _service;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  String _lastSearchedQuery = '';

  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;
  List<WeatherLocation> _searchResults = const [];

  WeatherLocation? _selectedLocation;
  bool _isLoadingWeather = false;
  String? _weatherError;
  CurrentWeatherData? _currentWeather;
  ForecastResponse? _forecast;

  @override
  void initState() {
    super.initState();
    _service = widget.weatherService ?? WeatherApiService();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _loadWeatherForLocation(widget.initialLocation!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      setState(() {
        _lastSearchedQuery = '';
        _isSearching = false;
        _hasSearched = false;
        _searchError = null;
        _searchResults = const [];
      });
      return;
    }
    if (trimmed.length < 2) {
      setState(() {
        _isSearching = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(widget.searchDebounceDuration, () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String rawQuery, {bool force = false}) async {
    final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    if (!force && query == _lastSearchedQuery && _hasSearched) return;

    _debounce?.cancel();
    setState(() {
      _lastSearchedQuery = query;
      _isSearching = true;
      _searchError = null;
    });

    try {
      final response = await _service.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _searchResults = response.locations;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _searchError = e.message;
        _searchResults = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _searchError = 'Unable to search destinations right now.';
        _searchResults = const [];
      });
    }
  }

  Future<void> _selectLocation(WeatherLocation location) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = location;
      _searchResults = const [];
      _hasSearched = false;
      _searchError = null;
    });
    await _loadWeatherForLocation(location);
  }

  Future<void> _loadWeatherForLocation(WeatherLocation location) async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
      _currentWeather = null;
      _forecast = null;
    });

    try {
      final results = await Future.wait([
        _service.getCurrentWeather(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
        _service.getForecast(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _currentWeather = results[0] as CurrentWeatherData;
        _forecast = results[1] as ForecastResponse;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _weatherError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _weatherError =
            'Unable to load weather information. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Live Weather',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildSearchFeedback(),
            if (_selectedLocation == null && !_hasSearched && !_isSearching)
              _buildEmptyInitialState(),
            if (_selectedLocation != null) ...[
              const SizedBox(height: 8),
              _buildWeatherContent(_selectedLocation!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('weather_search_input'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (value) => _performSearch(value, force: true),
            decoration: InputDecoration(
              hintText: 'Search Sri Lankan city (e.g., Kandy, Galle)',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primaryNavy,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      key: const Key('weather_search_clear_btn'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            key: const Key('weather_search_submit_btn'),
            onPressed: _isSearching
                ? null
                : () => _performSearch(_searchController.text, force: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size(52, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFeedback() {
    if (_isSearching) {
      return const Padding(
        key: Key('weather_search_loading'),
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryNavy,
            ),
          ),
        ),
      );
    }

    if (_searchError != null) {
      return Container(
        key: const Key('weather_search_error'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _searchError!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            TextButton(
              key: const Key('weather_search_retry_btn'),
              onPressed: () =>
                  _performSearch(_searchController.text, force: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _searchResults.isEmpty) {
      return Container(
        key: const Key('weather_no_results'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSlate),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: AppTheme.textSecondary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No matching Sri Lankan destinations found. Try another city or town.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return Material(
        key: const Key('weather_search_results'),
        color: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDBEAFE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(_searchResults.length, (index) {
            final loc = _searchResults[index];
            return Column(
              children: [
                ListTile(
                  key: Key('weather_location_item_$index'),
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primaryNavy,
                  ),
                  title: Text(
                    loc.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  subtitle: Text(
                    '${loc.displayLabel} (${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
                  onTap: () => _selectLocation(loc),
                ),
                if (index < _searchResults.length - 1)
                  const Divider(height: 1, color: AppTheme.borderSlate),
              ],
            );
          }),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyInitialState() {
    return Container(
      key: const Key('weather_empty_prompt'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 42,
            color: AppTheme.primaryNavy,
          ),
          SizedBox(height: 12),
          Text(
            'Check Sri Lanka Live Weather',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Search for a Sri Lankan destination above to view live weather conditions, a 5-day forecast, and travel weather advisories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherLocation location) {
    if (_isLoadingWeather) {
      return Container(
        key: const Key('weather_data_loading'),
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryNavy),
            SizedBox(height: 12),
            Text(
              'Loading live weather & forecast...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_weatherError != null) {
      return Container(
        key: const Key('weather_data_error'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Could not load weather for ${location.name}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _weatherError!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              key: const Key('weather_data_retry_btn'),
              onPressed: () => _loadWeatherForLocation(location),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final current = _currentWeather;
    final forecast = _forecast;
    if (current == null && forecast == null) {
      return const SizedBox.shrink();
    }

    final isStale = (current?.stale ?? false) || (forecast?.stale ?? false);
    final advisory = TravelWeatherAdvisory.fromWeather(
      forecast: forecast,
      current: current,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isStale) ...[
          _buildStaleBanner(),
          const SizedBox(height: 12),
        ],
        if (current != null) ...[
          _buildCurrentWeatherCard(location, current),
          const SizedBox(height: 16),
        ],
        if (forecast != null) ...[
          _buildForecastSection(forecast),
          const SizedBox(height: 16),
        ],
        _buildAdvisorySection(advisory),
      ],
    );
  }

  Widget _buildStaleBanner() {
    return Container(
      key: const Key('weather_stale_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.history_toggle_off_rounded, color: Color(0xFFB45309)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing cached weather data (stale). Live provider refresh was unavailable.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(
    WeatherLocation location,
    CurrentWeatherData current,
  ) {
    final tempText = current.temperatureC != null
        ? '${current.temperatureC!.toStringAsFixed(1)}°C'
        : '--°C';
    final feelsText = current.feelsLikeC != null
        ? '${current.feelsLikeC!.toStringAsFixed(1)}°C'
        : '--';
    final humidityText = current.humidityPercent != null
        ? '${current.humidityPercent}%'
        : '--';
    final windText = current.windSpeedKmh != null
        ? '${current.windSpeedKmh!.toStringAsFixed(1)} km/h'
        : '--';

    return Container(
      key: const Key('weather_current_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      key: const Key('weather_selected_destination'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    Text(
                      location.displayLabel,
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
                key: const Key('weather_refresh_btn'),
                tooltip: 'Refresh weather',
                onPressed: () => _loadWeatherForLocation(location),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Icon(
                  _iconForCondition(current.condition),
                  size: 34,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tempText,
                      key: const Key('weather_current_temp'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    Text(
                      '${current.condition.name} — ${_capitalize(current.condition.description)}',
                      key: const Key('weather_current_condition'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: Icons.thermostat_outlined,
                label: 'Feels like',
                value: feelsText,
              ),
              _MetricChip(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: humidityText,
              ),
              _MetricChip(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: windText,
              ),
              if (current.sunriseRaw != null)
                _MetricChip(
                  icon: Icons.wb_twilight_rounded,
                  label: 'Sunrise',
                  value: _formatTimeOnly(current.sunriseRaw!),
                ),
              if (current.sunsetRaw != null)
                _MetricChip(
                  icon: Icons.nights_stay_outlined,
                  label: 'Sunset',
                  value: _formatTimeOnly(current.sunsetRaw!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Source: ${current.source}${current.fetchedAt != null ? ' • Updated ${_formatTimestamp(current.fetchedAt!)}' : ''}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(ForecastResponse forecast) {
    return Container(
      key: const Key('weather_forecast_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppTheme.primaryNavy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forecast (${forecast.days.length} ${forecast.days.length == 1 ? 'Day' : 'Days'})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              Text(
                forecast.timezone,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (forecast.days.isEmpty)
            const Text(
              'No forecast days were returned by the server.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            )
          else
            Column(
              children: List.generate(forecast.days.length, (index) {
                final day = forecast.days[index];
                final minT = day.minTemperatureC != null
                    ? '${day.minTemperatureC!.toStringAsFixed(0)}°'
                    : '--';
                final maxT = day.maxTemperatureC != null
                    ? '${day.maxTemperatureC!.toStringAsFixed(0)}°'
                    : '--';
                final rain = day.rainProbabilityPercent != null
                    ? '${day.rainProbabilityPercent!.toStringAsFixed(0)}% rain'
                    : null;

                return Container(
                  key: Key('weather_forecast_day_$index'),
                  margin: EdgeInsets.only(
                    bottom: index < forecast.days.length - 1 ? 10 : 0,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconForCondition(day.condition),
                        size: 26,
                        color: AppTheme.primaryNavy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatDateLabel(day.dateKey),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                                if (day.partial)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Partial',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_capitalize(day.condition.description)}${rain != null ? ' • $rain' : ''}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$minT / $maxT C',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvisorySection(TravelWeatherAdvisory advisory) {
    if (!advisory.hasSufficientData) {
      return Container(
        key: const Key('weather_advisory_unavailable'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSlate),
        ),
        child: const Text(
          'Travel weather advisories are currently unavailable due to insufficient forecast data.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return Container(
      key: const Key('weather_advisory_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                size: 18,
                color: AppTheme.primaryNavy,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Travel Weather Advisories',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primarySubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  advisory.isBackendDerived ? 'API Guidance' : 'Measured',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          if (advisory.cautions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Cautions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
            const SizedBox(height: 6),
            ...advisory.cautions.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (advisory.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Recommendations',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            ...advisory.recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            advisory.notice,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForCondition(WeatherCondition condition) {
    final group = condition.code ~/ 100;
    switch (group) {
      case 2:
        return Icons.thunderstorm_outlined;
      case 3:
      case 5:
        return Icons.umbrella_outlined;
      case 6:
        return Icons.ac_unit_rounded;
      case 7:
        return Icons.foggy;
      case 8:
        if (condition.code == 800) {
          return condition.icon.endsWith('n')
              ? Icons.nights_stay_outlined
              : Icons.wb_sunny_outlined;
        }
        return Icons.cloud_outlined;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _formatTimeOnly(String rawIso) {
    final match = RegExp(r'T(\d{2}:\d{2})').firstMatch(rawIso);
    if (match != null) return match.group(1)!;
    return rawIso;
  }

  static String _formatTimestamp(DateTime dt) {
    final sl = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final h = sl.hour.toString().padLeft(2, '0');
    final m = sl.minute.toString().padLeft(2, '0');
    return '$h:$m IST';
  }

  static String _formatDateLabel(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) return dateKey;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final wd = weekdays[parsed.weekday - 1];
    final mo = months[parsed.month - 1];
    return '$wd, $mo ${parsed.day}';
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryNavy),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}
