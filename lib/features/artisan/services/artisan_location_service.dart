import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Represents the status of the device location request.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

/// Structured result containing acquired device coordinates or error status.
class ArtisanLocationResult {
  final double? latitude;
  final double? longitude;
  final LocationPermissionStatus status;
  final String? errorMessage;

  const ArtisanLocationResult({
    this.latitude,
    this.longitude,
    required this.status,
    this.errorMessage,
  });

  bool get isSuccess =>
      status == LocationPermissionStatus.granted &&
      latitude != null &&
      longitude != null;

  /// Helper factory for permission errors.
  factory ArtisanLocationResult.fromStatus(LocationPermissionStatus status, [String? message]) {
    return ArtisanLocationResult(status: status, errorMessage: message);
  }

  /// Helper factory for successful location acquisition.
  factory ArtisanLocationResult.success(double latitude, double longitude) {
    return ArtisanLocationResult(
      latitude: latitude,
      longitude: longitude,
      status: LocationPermissionStatus.granted,
    );
  }
}

/// Service handling device GPS hardware acquisition and runtime OS permissions.
class ArtisanLocationService {
  /// Checks whether GPS / Location services are enabled at the device system level.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Checks the current OS location permission.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Requests runtime OS location permission from the traveler.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Validates that geographic coordinates are within legitimate spherical bounds.
  bool validateCoordinates(double lat, double lon) {
    return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0;
  }

  /// Requests permissions and retrieves the real-time position from device hardware.
  /// Never returns hardcoded coordinates.
  Future<ArtisanLocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Verify device location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return ArtisanLocationResult.fromStatus(
          LocationPermissionStatus.serviceDisabled,
          'Location services are disabled on your device. Please enable GPS in device settings.',
        );
      }

      // 2. Check current OS permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return ArtisanLocationResult.fromStatus(
            LocationPermissionStatus.denied,
            'Location permission denied. Showing all workshops by district.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return ArtisanLocationResult.fromStatus(
          LocationPermissionStatus.deniedForever,
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // 3. Obtain real device coordinates with timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      // 4. Validate coordinates
      if (!validateCoordinates(position.latitude, position.longitude)) {
        return ArtisanLocationResult.fromStatus(
          LocationPermissionStatus.error,
          'Acquired coordinates are invalid.',
        );
      }

      return ArtisanLocationResult.success(position.latitude, position.longitude);
    } on TimeoutException {
      return ArtisanLocationResult.fromStatus(
        LocationPermissionStatus.error,
        'Location request timed out. Please check your GPS signal.',
      );
    } catch (e) {
      return ArtisanLocationResult.fromStatus(
        LocationPermissionStatus.error,
        'Failed to obtain device location: ${e.toString()}',
      );
    }
  }
}

