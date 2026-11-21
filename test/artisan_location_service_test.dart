import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/artisan/services/artisan_location_service.dart';

void main() {
  group('ArtisanLocationService Unit Tests', () {
    late ArtisanLocationService service;

    setUp(() {
      service = ArtisanLocationService();
    });

    test('validateCoordinates correctly verifies geographic latitude and longitude bounds', () {
      // Valid coordinates (Sri Lanka)
      expect(service.validateCoordinates(7.2906, 80.6337), isTrue); // Kandy
      expect(service.validateCoordinates(6.9271, 79.8612), isTrue); // Colombo
      expect(service.validateCoordinates(6.0535, 80.2210), isTrue); // Galle

      // Valid boundary values
      expect(service.validateCoordinates(90.0, 180.0), isTrue);
      expect(service.validateCoordinates(-90.0, -180.0), isTrue);
      expect(service.validateCoordinates(0.0, 0.0), isTrue);

      // Invalid latitude bounds (> 90 or < -90)
      expect(service.validateCoordinates(90.001, 80.0), isFalse);
      expect(service.validateCoordinates(-90.001, 80.0), isFalse);

      // Invalid longitude bounds (> 180 or < -180)
      expect(service.validateCoordinates(7.0, 180.001), isFalse);
      expect(service.validateCoordinates(7.0, -180.001), isFalse);
    });

    test('ArtisanLocationResult reports correct isSuccess status', () {
      // Successful result
      const success = ArtisanLocationResult(
        latitude: 7.2906,
        longitude: 80.6337,
        status: LocationPermissionStatus.granted,
      );
      expect(success.isSuccess, isTrue);
      expect(success.latitude, equals(7.2906));
      expect(success.longitude, equals(80.6337));

      // Denied result
      final denied = ArtisanLocationResult.fromStatus(
        LocationPermissionStatus.denied,
        'Permission denied',
      );
      expect(denied.isSuccess, isFalse);
      expect(denied.latitude, isNull);
      expect(denied.errorMessage, equals('Permission denied'));

      // Service disabled result
      final disabled = ArtisanLocationResult.fromStatus(
        LocationPermissionStatus.serviceDisabled,
        'GPS turned off',
      );
      expect(disabled.isSuccess, isFalse);
      expect(disabled.status, equals(LocationPermissionStatus.serviceDisabled));

      // Denied forever result
      final deniedForever = ArtisanLocationResult.fromStatus(
        LocationPermissionStatus.deniedForever,
      );
      expect(deniedForever.isSuccess, isFalse);
      expect(deniedForever.status, equals(LocationPermissionStatus.deniedForever));
    });

    test('ArtisanLocationResult.success factory populates coordinates cleanly', () {
      final res = ArtisanLocationResult.success(6.0535, 80.2210);
      expect(res.isSuccess, isTrue);
      expect(res.status, equals(LocationPermissionStatus.granted));
      expect(res.latitude, equals(6.0535));
      expect(res.longitude, equals(80.2210));
      expect(res.errorMessage, isNull);
    });
  });
}
