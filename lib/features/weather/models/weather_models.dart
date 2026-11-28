// Strongly typed models for CeylonGo FastAPI Weather endpoints:
// - `GET /api/v1/weather/locations`
// - `GET /api/v1/weather/current`
// - `GET /api/v1/weather/forecast`

class WeatherCoordinates {
  final double latitude;
  final double longitude;

  const WeatherCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory WeatherCoordinates.fromJson(Map<String, dynamic> json) {
    final lat = _asDouble(json['latitude']);
    final lon = _asDouble(json['longitude']);
    if (lat == null || lon == null) {
      throw const FormatException('Missing valid weather coordinates.');
    }
    return WeatherCoordinates(latitude: lat, longitude: lon);
  }
}

class WeatherCondition {
  final int code;
  final String name;
  final String description;
  final String icon;

  const WeatherCondition({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WeatherCondition(
        code: 800,
        name: 'Unavailable',
        description: 'Condition unavailable',
        icon: '01d',
      );
    }
    return WeatherCondition(
      code: _asInt(json['code']) ?? 800,
      name: _asNonEmptyString(json['name']) ?? 'Weather',
      description: _asNonEmptyString(json['description']) ?? 'Current conditions',
      icon: _asNonEmptyString(json['icon']) ?? '01d',
    );
  }
}

class WeatherLocation {
  final String name;
  final String? region;
  final String country;
  final double latitude;
  final double longitude;

  const WeatherLocation({
    required this.name,
    this.region,
    this.country = 'LK',
    required this.latitude,
    required this.longitude,
  });

  String get displayLabel {
    final parts = <String>[name];
    final cleanRegion = region?.trim();
    if (cleanRegion != null &&
        cleanRegion.isNotEmpty &&
        cleanRegion.toLowerCase() != name.toLowerCase()) {
      parts.add(cleanRegion);
    }
    if (country.trim().isNotEmpty) {
      parts.add(country.trim());
    }
    return parts.join(', ');
  }

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    final name = _asNonEmptyString(json['name']);
    final lat = _asDouble(json['latitude']);
    final lon = _asDouble(json['longitude']);
    if (name == null || lat == null || lon == null) {
      throw const FormatException('Invalid location item in response.');
    }
    return WeatherLocation(
      name: name,
      region: _asNonEmptyString(json['region']),
      country: _asNonEmptyString(json['country']) ?? 'LK',
      latitude: lat,
      longitude: lon,
    );
  }
}

class WeatherLocationsResponse {
  final String source;
  final String sourceUrl;
  final DateTime? fetchedAt;
  final bool stale;
  final List<WeatherLocation> locations;

  const WeatherLocationsResponse({
    required this.source,
    required this.sourceUrl,
    required this.fetchedAt,
    required this.stale,
    required this.locations,
  });

  factory WeatherLocationsResponse.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    if (rawLocations is! List) {
      throw const FormatException('Missing locations list in weather response.');
    }
    final parsed = <WeatherLocation>[];
    for (final item in rawLocations) {
      if (item is Map<String, dynamic>) {
        parsed.add(WeatherLocation.fromJson(item));
      } else if (item is Map) {
        parsed.add(
          WeatherLocation.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return WeatherLocationsResponse(
      source: _asNonEmptyString(json['source']) ?? 'OpenWeather',
      sourceUrl:
          _asNonEmptyString(json['source_url']) ?? 'https://openweathermap.org/',
      fetchedAt: _parseDateTime(json['fetched_at']),
      stale: json['stale'] == true,
      locations: parsed,
    );
  }
}

class CurrentWeatherData {
  final String source;
  final String sourceUrl;
  final DateTime? fetchedAt;
  final bool stale;
  final WeatherCoordinates coordinates;
  final double? temperatureC;
  final double? feelsLikeC;
  final WeatherCondition condition;
  final int? humidityPercent;
  final double? windSpeedKmh;
  final int? windDirectionDegrees;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? observedAt;
  final String? observedAtRaw;
  final String? sunriseRaw;
  final String? sunsetRaw;

  const CurrentWeatherData({
    required this.source,
    required this.sourceUrl,
    required this.fetchedAt,
    required this.stale,
    required this.coordinates,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.condition,
    required this.humidityPercent,
    required this.windSpeedKmh,
    required this.windDirectionDegrees,
    required this.sunrise,
    required this.sunset,
    required this.observedAt,
    this.observedAtRaw,
    this.sunriseRaw,
    this.sunsetRaw,
  });

  factory CurrentWeatherData.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'];
    if (rawCoords is! Map) {
      throw const FormatException('Missing coordinates in current weather.');
    }
    final rawCondition = json['condition'];
    return CurrentWeatherData(
      source: _asNonEmptyString(json['source']) ?? 'OpenWeather',
      sourceUrl:
          _asNonEmptyString(json['source_url']) ?? 'https://openweathermap.org/',
      fetchedAt: _parseDateTime(json['fetched_at']),
      stale: json['stale'] == true,
      coordinates: WeatherCoordinates.fromJson(
        Map<String, dynamic>.from(rawCoords),
      ),
      temperatureC: _asDouble(json['temperature_c']),
      feelsLikeC: _asDouble(json['feels_like_c']),
      condition: WeatherCondition.fromJson(
        rawCondition is Map ? Map<String, dynamic>.from(rawCondition) : null,
      ),
      humidityPercent: _asInt(json['humidity_percent']),
      windSpeedKmh: _asDouble(json['wind_speed_kmh']),
      windDirectionDegrees: _asInt(json['wind_direction_degrees']),
      sunrise: _parseDateTime(json['sunrise']),
      sunset: _parseDateTime(json['sunset']),
      observedAt: _parseDateTime(json['observed_at']),
      observedAtRaw: _asNonEmptyString(json['observed_at']),
      sunriseRaw: _asNonEmptyString(json['sunrise']),
      sunsetRaw: _asNonEmptyString(json['sunset']),
    );
  }
}

class ForecastIntervalData {
  final DateTime? forecastAt;
  final String forecastAtRaw;
  final String localDateKey;
  final double? temperatureC;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final double? rainProbabilityPercent;
  final double? windSpeedKmh;
  final WeatherCondition condition;

  const ForecastIntervalData({
    required this.forecastAt,
    required this.forecastAtRaw,
    required this.localDateKey,
    required this.temperatureC,
    required this.minTemperatureC,
    required this.maxTemperatureC,
    required this.rainProbabilityPercent,
    required this.windSpeedKmh,
    required this.condition,
  });

  factory ForecastIntervalData.fromJson(Map<String, dynamic> json) {
    final rawTime = _asNonEmptyString(json['forecast_at']) ?? '';
    final parsed = _parseDateTime(rawTime);
    final rawCond = json['condition'];
    final temp = _asDouble(json['temperature_c']);
    return ForecastIntervalData(
      forecastAt: parsed,
      forecastAtRaw: rawTime,
      localDateKey: extractSriLankaDateKey(rawTime, parsed),
      temperatureC: temp,
      minTemperatureC: _asDouble(json['min_temperature_c']) ?? temp,
      maxTemperatureC: _asDouble(json['max_temperature_c']) ?? temp,
      rainProbabilityPercent: _asDouble(json['rain_probability_percent']),
      windSpeedKmh: _asDouble(json['wind_speed_kmh']),
      condition: WeatherCondition.fromJson(
        rawCond is Map ? Map<String, dynamic>.from(rawCond) : null,
      ),
    );
  }
}

class DailyForecastData {
  final String dateKey;
  final int intervalCount;
  final bool partial;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final double? rainProbabilityPercent;
  final WeatherCondition condition;
  final List<String> recommendations;
  final List<String> cautions;

  const DailyForecastData({
    required this.dateKey,
    required this.intervalCount,
    required this.partial,
    required this.minTemperatureC,
    required this.maxTemperatureC,
    required this.rainProbabilityPercent,
    required this.condition,
    required this.recommendations,
    required this.cautions,
  });

  factory DailyForecastData.fromJson(Map<String, dynamic> json) {
    final dateKey = _asNonEmptyString(json['date']);
    if (dateKey == null) {
      throw const FormatException('Missing date in daily forecast.');
    }
    final rawCond = json['condition'];
    return DailyForecastData(
      dateKey: dateKey,
      intervalCount: _asInt(json['interval_count']) ?? 0,
      partial: json['partial'] == true,
      minTemperatureC: _asDouble(json['min_temperature_c']),
      maxTemperatureC: _asDouble(json['max_temperature_c']),
      rainProbabilityPercent: _asDouble(json['rain_probability_percent']),
      condition: WeatherCondition.fromJson(
        rawCond is Map ? Map<String, dynamic>.from(rawCond) : null,
      ),
      recommendations: _asStringList(json['recommendations']),
      cautions: _asStringList(json['cautions']),
    );
  }
}

class ForecastResponse {
  final String source;
  final String sourceUrl;
  final DateTime? fetchedAt;
  final bool stale;
  final WeatherCoordinates coordinates;
  final String timezone;
  final List<ForecastIntervalData> intervals;
  final List<DailyForecastData> days;
  final String advisoryNotice;

  const ForecastResponse({
    required this.source,
    required this.sourceUrl,
    required this.fetchedAt,
    required this.stale,
    required this.coordinates,
    required this.timezone,
    required this.intervals,
    required this.days,
    required this.advisoryNotice,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'];
    if (rawCoords is! Map) {
      throw const FormatException('Missing coordinates in forecast response.');
    }

    final intervals = <ForecastIntervalData>[];
    final rawIntervals = json['intervals'];
    if (rawIntervals is List) {
      for (final item in rawIntervals) {
        if (item is Map) {
          intervals.add(
            ForecastIntervalData.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final days = <DailyForecastData>[];
    final rawDays = json['days'];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is Map) {
          days.add(DailyForecastData.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final resolvedDays =
        days.isNotEmpty ? days : groupIntervalsByDay(intervals);

    return ForecastResponse(
      source: _asNonEmptyString(json['source']) ?? 'OpenWeather',
      sourceUrl:
          _asNonEmptyString(json['source_url']) ?? 'https://openweathermap.org/',
      fetchedAt: _parseDateTime(json['fetched_at']),
      stale: json['stale'] == true,
      coordinates: WeatherCoordinates.fromJson(
        Map<String, dynamic>.from(rawCoords),
      ),
      timezone: _asNonEmptyString(json['timezone']) ?? 'Asia/Colombo',
      intervals: intervals,
      days: resolvedDays,
      advisoryNotice:
          _asNonEmptyString(json['advisory_notice']) ??
          'Travel guidance is advisory. Check official warnings and local conditions.',
    );
  }

  /// Groups 3-hour forecast intervals by Sri Lanka date (`YYYY-MM-DD`) without
  /// fabricating missing days or values.
  static List<DailyForecastData> groupIntervalsByDay(
    List<ForecastIntervalData> intervals,
  ) {
    if (intervals.isEmpty) return const [];
    final grouped = <String, List<ForecastIntervalData>>{};
    for (final interval in intervals) {
      if (interval.localDateKey.isEmpty) continue;
      grouped.putIfAbsent(interval.localDateKey, () => []).add(interval);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((dateKey) {
      final dayIntervals = grouped[dateKey]!;
      final mins = dayIntervals
          .map((e) => e.minTemperatureC)
          .whereType<double>()
          .toList();
      final maxs = dayIntervals
          .map((e) => e.maxTemperatureC)
          .whereType<double>()
          .toList();
      final probs = dayIntervals
          .map((e) => e.rainProbabilityPercent)
          .whereType<double>()
          .toList();

      final wet = dayIntervals
          .where((e) => {2, 3, 5}.contains(e.condition.code ~/ 100))
          .toList();
      final storms =
          wet.where((e) => e.condition.code ~/ 100 == 2).toList();
      final candidates =
          storms.isNotEmpty ? storms : (wet.isNotEmpty ? wet : dayIntervals);

      ForecastIntervalData representative = candidates.first;
      int bestDistance = 1 << 30;
      for (final item in candidates) {
        final minutes = _extractMinutesOfDay(item.forecastAtRaw, item.forecastAt);
        final dist = (minutes - 720).abs();
        if (dist < bestDistance) {
          bestDistance = dist;
          representative = item;
        }
      }

      return DailyForecastData(
        dateKey: dateKey,
        intervalCount: dayIntervals.length,
        partial: dayIntervals.length < 8,
        minTemperatureC:
            mins.isEmpty ? null : mins.reduce((a, b) => a < b ? a : b),
        maxTemperatureC:
            maxs.isEmpty ? null : maxs.reduce((a, b) => a > b ? a : b),
        rainProbabilityPercent:
            probs.isEmpty ? null : probs.reduce((a, b) => a > b ? a : b),
        condition: representative.condition,
        recommendations: const [],
        cautions: const [],
      );
    }).toList();
  }
}

class TravelWeatherAdvisory {
  final List<String> cautions;
  final List<String> recommendations;
  final String notice;
  final bool isBackendDerived;
  final bool hasSufficientData;

  const TravelWeatherAdvisory({
    required this.cautions,
    required this.recommendations,
    required this.notice,
    required this.isBackendDerived,
    required this.hasSufficientData,
  });

  static const String defaultNotice =
      'Travel guidance is advisory. Check official warnings and local conditions.';

  /// Uses verified backend `days` advisories when present; otherwise derives
  /// conservative, clearly labeled guidance from actual returned metrics.
  factory TravelWeatherAdvisory.fromWeather({
    ForecastResponse? forecast,
    CurrentWeatherData? current,
  }) {
    if (forecast != null && forecast.days.isNotEmpty) {
      final cautions = <String>[];
      final recommendations = <String>[];
      for (final day in forecast.days) {
        for (final c in day.cautions) {
          if (!cautions.contains(c)) cautions.add(c);
        }
        for (final r in day.recommendations) {
          if (!recommendations.contains(r)) recommendations.add(r);
        }
      }
      if (cautions.isNotEmpty || recommendations.isNotEmpty) {
        return TravelWeatherAdvisory(
          cautions: cautions,
          recommendations: recommendations,
          notice: forecast.advisoryNotice,
          isBackendDerived: true,
          hasSufficientData: true,
        );
      }
    }

    // Conservative client-side fallback from actual measurements only.
    final cautions = <String>[];
    final recommendations = <String>[];

    final codes = <int>{};
    double maxTemp = -999;
    double maxWind = -1;
    double maxRainProb = -1;
    bool hasAnyMetric = false;

    if (current != null) {
      hasAnyMetric = true;
      codes.add(current.condition.code ~/ 100);
      if (current.temperatureC != null && current.temperatureC! > maxTemp) {
        maxTemp = current.temperatureC!;
      }
      if (current.windSpeedKmh != null && current.windSpeedKmh! > maxWind) {
        maxWind = current.windSpeedKmh!;
      }
    }

    if (forecast != null) {
      for (final interval in forecast.intervals) {
        hasAnyMetric = true;
        codes.add(interval.condition.code ~/ 100);
        final hi = interval.maxTemperatureC ?? interval.temperatureC;
        if (hi != null && hi > maxTemp) maxTemp = hi;
        if (interval.windSpeedKmh != null && interval.windSpeedKmh! > maxWind) {
          maxWind = interval.windSpeedKmh!;
        }
        if (interval.rainProbabilityPercent != null &&
            interval.rainProbabilityPercent! > maxRainProb) {
          maxRainProb = interval.rainProbabilityPercent!;
        }
      }
    }

    if (!hasAnyMetric) {
      return const TravelWeatherAdvisory(
        cautions: [],
        recommendations: [],
        notice: defaultNotice,
        isBackendDerived: false,
        hasSufficientData: false,
      );
    }

    if (codes.contains(2)) {
      cautions.add(
        'Thunderstorms are possible. Consider postponing exposed hikes.',
      );
    }
    if (codes.contains(3) || codes.contains(5) || maxRainProb >= 60) {
      cautions.add('Rain is possible. Trails and steps may be slippery.');
      recommendations.add(
        'Pack rain gear and check trail conditions with your guide.',
      );
    }
    if (maxWind >= 40) {
      cautions.add(
        'Strong winds are possible. Check with boat and activity operators.',
      );
    }
    if (maxTemp >= 35) {
      cautions.add(
        'High temperatures are possible. Plan shade and water breaks.',
      );
      recommendations.add(
        'Consider early morning outings and carry drinking water.',
      );
    }
    if (codes.contains(7)) {
      cautions.add(
        'Mist or reduced visibility may occur. Allow extra travel time.',
      );
    }

    if (cautions.isNotEmpty) {
      recommendations.add(
        'Keep a museum, gallery or indoor workshop as an alternative.',
      );
    } else {
      recommendations.add(
        'Conditions appear generally favorable for outdoor outings; recheck before departing.',
      );
    }

    return TravelWeatherAdvisory(
      cautions: cautions,
      recommendations: recommendations,
      notice: forecast?.advisoryNotice ?? defaultNotice,
      isBackendDerived: false,
      hasSufficientData: true,
    );
  }
}

/// Extracts `YYYY-MM-DD` in Sri Lanka time (`Asia/Colombo`, UTC+05:30).
String extractSriLankaDateKey(String rawIso, DateTime? parsed) {
  final offsetMatch = RegExp(r'^(\d{4}-\d{2}-\d{2})T.*[+-]\d{2}:\d{2}$')
      .firstMatch(rawIso.trim());
  if (offsetMatch != null && rawIso.contains('+05:30')) {
    return offsetMatch.group(1)!;
  }
  if (parsed != null) {
    final sl = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    final y = sl.year.toString().padLeft(4, '0');
    final m = sl.month.toString().padLeft(2, '0');
    final d = sl.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
  return '';
}

int _extractMinutesOfDay(String rawIso, DateTime? parsed) {
  if (rawIso.contains('+05:30')) {
    final m = RegExp(r'T(\d{2}):(\d{2})').firstMatch(rawIso);
    if (m != null) {
      return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    }
  }
  if (parsed != null) {
    final sl = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    return sl.hour * 60 + sl.minute;
  }
  return 720;
}

double? _asDouble(dynamic value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _asNonEmptyString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
