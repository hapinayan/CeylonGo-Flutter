// Strongly typed models for CeylonGo FastAPI Interactive Map endpoints:
// - `GET /api/v1/map/locations`
// - `GET /api/v1/map/nearby`
// - `GET /api/v1/map/search`
// - `GET /api/v1/map/categories`
// - `POST /api/v1/map/route`

import 'package:latlong2/latlong.dart';

class MapCoordinates {
  final double latitude;
  final double longitude;

  const MapCoordinates({
    required this.latitude,
    required this.longitude,
  });

  static bool isValidLatLon(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    if (!lat.isFinite || !lon.isFinite) return false;
    return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0;
  }

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory MapCoordinates.fromJson(Map<String, dynamic> json) {
    final lat = _asDouble(json['latitude']);
    final lon = _asDouble(json['longitude']);
    if (!isValidLatLon(lat, lon)) {
      throw const FormatException('Invalid map coordinates.');
    }
    return MapCoordinates(latitude: lat!, longitude: lon!);
  }
}

class MapBounds {
  final double west;
  final double south;
  final double east;
  final double north;

  const MapBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  /// Default viewport covering Sri Lanka.
  static const MapBounds sriLanka = MapBounds(
    west: 79.4,
    south: 5.8,
    east: 82.1,
    north: 9.95,
  );

  static const LatLng sriLankaCenter = LatLng(7.8731, 80.7718);

  bool get isValid =>
      MapCoordinates.isValidLatLon(south, west) &&
      MapCoordinates.isValidLatLon(north, east) &&
      south <= north;
}

class MapCategoryItem {
  final String id;
  final String label;
  final bool available;
  final String? reason;

  const MapCategoryItem({
    required this.id,
    required this.label,
    required this.available,
    this.reason,
  });

  factory MapCategoryItem.fromJson(Map<String, dynamic> json) {
    final id = _asNonEmptyString(json['id']);
    final label = _asNonEmptyString(json['label']);
    if (id == null || label == null) {
      throw const FormatException('Invalid map category.');
    }
    return MapCategoryItem(
      id: id,
      label: label,
      available: json['available'] is bool ? json['available'] as bool : true,
      reason: _asNonEmptyString(json['reason']),
    );
  }
}

class MapLocationItem {
  final int listingId;
  final String moduleType;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? district;
  final String? imageUrl;
  final double? rating;
  final double? price;
  final String? currency;
  final String? detailPath;
  final double? distanceKm;

  const MapLocationItem({
    required this.listingId,
    required this.moduleType,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.district,
    this.imageUrl,
    this.rating,
    this.price,
    this.currency,
    this.detailPath,
    this.distanceKm,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  String get uniqueKey => '${moduleType}_$listingId';

  /// Returns an existing in-app Flutter route when supported (`artisan`),
  /// or `null` when no dedicated Flutter detail screen exists for `moduleType`.
  String? get supportedFlutterDetailRoute {
    if (moduleType == 'artisan' && listingId > 0) {
      return '/artisan/business?id=$listingId';
    }
    return null;
  }

  String get locationSubtitle {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (district != null &&
        district!.isNotEmpty &&
        district!.toLowerCase() != city?.toLowerCase()) {
      parts.add(district!);
    }
    if (parts.isEmpty && address != null && address!.isNotEmpty) {
      parts.add(address!);
    }
    return parts.join(', ');
  }

  /// Parses a [MapLocationItem], returning `null` if coordinates or required
  /// identifiers are missing/invalid instead of manufacturing `(0, 0)`.
  static MapLocationItem? tryFromJson(Map<String, dynamic> json) {
    final listingId = _asInt(json['listing_id']);
    final moduleType = _asNonEmptyString(json['module_type']);
    final name = _asNonEmptyString(json['name']);
    final category = _asNonEmptyString(json['category']);
    final lat = _asDouble(json['latitude']);
    final lon = _asDouble(json['longitude']);

    if (listingId == null ||
        listingId <= 0 ||
        moduleType == null ||
        name == null ||
        category == null ||
        !MapCoordinates.isValidLatLon(lat, lon)) {
      return null;
    }

    return MapLocationItem(
      listingId: listingId,
      moduleType: moduleType,
      name: name,
      category: category,
      latitude: lat!,
      longitude: lon!,
      address: _asNonEmptyString(json['address']),
      city: _asNonEmptyString(json['city']),
      district: _asNonEmptyString(json['district']),
      imageUrl: _asNonEmptyString(json['image_url']),
      rating: _asDouble(json['rating']),
      price: _asDouble(json['price']),
      currency: _asNonEmptyString(json['currency']),
      detailPath: _asNonEmptyString(json['detail_path']),
      distanceKm: _asDouble(json['distance_km']),
    );
  }
}

class MapPageResponse {
  final List<MapLocationItem> items;
  final int skippedInvalidCount;
  final int page;
  final int pageSize;
  final bool hasMore;
  final String? distanceType;

  const MapPageResponse({
    required this.items,
    required this.skippedInvalidCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.distanceType,
  });

  factory MapPageResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Missing items list in map response.');
    }

    final parsed = <MapLocationItem>[];
    var skipped = 0;
    for (final raw in rawItems) {
      if (raw is Map) {
        final item = MapLocationItem.tryFromJson(
          Map<String, dynamic>.from(raw),
        );
        if (item != null) {
          parsed.add(item);
        } else {
          skipped++;
        }
      } else {
        skipped++;
      }
    }

    return MapPageResponse(
      items: parsed,
      skippedInvalidCount: skipped,
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['page_size']) ?? 25,
      hasMore: json['has_more'] == true,
      distanceType: _asNonEmptyString(json['distance_type']),
    );
  }
}

enum RouteTravelMode {
  driving('driving', 'Drive'),
  walking('walking', 'Walk'),
  cycling('cycling', 'Cycle');

  final String apiValue;
  final String label;

  const RouteTravelMode(this.apiValue, this.label);
}

class RouteInstructionItem {
  final String text;
  final double? distanceM;
  final double? durationSeconds;

  const RouteInstructionItem({
    required this.text,
    this.distanceM,
    this.durationSeconds,
  });

  factory RouteInstructionItem.fromJson(Map<String, dynamic> json) {
    return RouteInstructionItem(
      text: _asNonEmptyString(json['text']) ?? '',
      distanceM: _asDouble(json['distance_m']),
      durationSeconds: _asDouble(json['duration_seconds']),
    );
  }
}

class MapAttributionItem {
  final String label;
  final String url;

  const MapAttributionItem({required this.label, required this.url});

  factory MapAttributionItem.fromJson(Map<String, dynamic> json) {
    return MapAttributionItem(
      label: _asNonEmptyString(json['label']) ?? '',
      url: _asNonEmptyString(json['url']) ?? '',
    );
  }
}

class MapRouteResponse {
  final String mode;
  final List<List<LatLng>> lines;
  final double distanceM;
  final double distanceKm;
  final double durationSeconds;
  final double durationMinutes;
  final List<RouteInstructionItem> instructions;
  final List<MapAttributionItem> attribution;

  const MapRouteResponse({
    required this.mode,
    required this.lines,
    required this.distanceM,
    required this.distanceKm,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.instructions,
    required this.attribution,
  });

  factory MapRouteResponse.fromJson(Map<String, dynamic> json) {
    final rawGeometry = json['geometry'];
    if (rawGeometry is! Map) {
      throw const FormatException('Missing route geometry.');
    }
    final rawCoords = rawGeometry['coordinates'];
    if (rawCoords is! List || rawCoords.isEmpty) {
      throw const FormatException('Missing route coordinates.');
    }

    final lines = <List<LatLng>>[];
    for (final rawLine in rawCoords) {
      if (rawLine is! List) continue;
      final points = <LatLng>[];
      for (final rawPair in rawLine) {
        if (rawPair is List && rawPair.length >= 2) {
          final lon = _asDouble(rawPair[0]);
          final lat = _asDouble(rawPair[1]);
          if (MapCoordinates.isValidLatLon(lat, lon)) {
            points.add(LatLng(lat!, lon!));
          }
        }
      }
      if (points.length >= 2) {
        lines.add(points);
      }
    }

    if (lines.isEmpty) {
      throw const FormatException('No valid route line segments found.');
    }

    final instructions = <RouteInstructionItem>[];
    if (json['instructions'] is List) {
      for (final item in json['instructions'] as List) {
        if (item is Map) {
          final parsed = RouteInstructionItem.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed.text.isNotEmpty) instructions.add(parsed);
        }
      }
    }

    final attribution = <MapAttributionItem>[];
    if (json['attribution'] is List) {
      for (final item in json['attribution'] as List) {
        if (item is Map) {
          final parsed = MapAttributionItem.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed.label.isNotEmpty) attribution.add(parsed);
        }
      }
    }

    final distanceM = _asDouble(json['distance_m']) ?? 0;
    final durationS = _asDouble(json['duration_seconds']) ?? 0;

    return MapRouteResponse(
      mode: _asNonEmptyString(json['mode']) ?? 'driving',
      lines: lines,
      distanceM: distanceM,
      distanceKm: _asDouble(json['distance_km']) ?? (distanceM / 1000.0),
      durationSeconds: durationS,
      durationMinutes: _asDouble(json['duration_minutes']) ?? (durationS / 60.0),
      instructions: instructions,
      attribution: attribution,
    );
  }
}

/// Builds an external Google Maps directions URL using validated coordinates.
Uri buildGoogleMapsDirectionsUri({
  required double destinationLat,
  required double destinationLon,
  double? originLat,
  double? originLon,
  RouteTravelMode mode = RouteTravelMode.driving,
}) {
  if (!MapCoordinates.isValidLatLon(destinationLat, destinationLon)) {
    throw const FormatException('Invalid destination coordinates.');
  }
  final params = <String, String>{
    'api': '1',
    'destination':
        '${destinationLat.toStringAsFixed(6)},${destinationLon.toStringAsFixed(6)}',
    'travelmode': mode.apiValue,
  };
  if (MapCoordinates.isValidLatLon(originLat, originLon)) {
    params['origin'] =
        '${originLat!.toStringAsFixed(6)},${originLon!.toStringAsFixed(6)}';
  }
  return Uri.https('www.google.com', '/maps/dir/', params);
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

