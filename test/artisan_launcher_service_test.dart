import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/artisan/services/artisan_launcher_service.dart';

void main() {
  group('ArtisanLauncherService Tests', () {
    test('calculateDistanceKm computes accurate distances between Sri Lankan coordinates', () {
      // Colombo (6.9271, 79.8612) to Kandy (7.2906, 80.6337) is approx 95-105 km
      final distKm = ArtisanLauncherService.calculateDistanceKm(
        6.9271,
        79.8612,
        7.2906,
        80.6337,
      );
      expect(distKm, greaterThan(90.0));
      expect(distKm, lessThan(115.0));

      // Same coordinate returns 0.0
      final zeroDist = ArtisanLauncherService.calculateDistanceKm(
        6.9271,
        79.8612,
        6.9271,
        79.8612,
      );
      expect(zeroDist, closeTo(0.0, 0.001));
    });

    test('buildGoogleMapsUrl creates valid query search string', () {
      final url = ArtisanLauncherService.buildGoogleMapsUrl(7.2906, 80.6337);
      expect(url, equals('https://www.google.com/maps/search/?api=1&query=7.2906,80.6337'));
    });

    test('buildWhatsAppUrl normalizes local and international numbers', () {
      expect(ArtisanLauncherService.buildWhatsAppUrl(null), isNull);
      expect(ArtisanLauncherService.buildWhatsAppUrl(''), isNull);
      // Local Sri Lankan format 0771234567 -> 94771234567
      expect(
        ArtisanLauncherService.buildWhatsAppUrl('0771234567'),
        equals('https://wa.me/94771234567'),
      );
      // International format +94771234567
      expect(
        ArtisanLauncherService.buildWhatsAppUrl('+94 77 123 4567'),
        equals('https://wa.me/94771234567'),
      );
    });

    test('buildMailtoUrl creates encoded mailto URI', () {
      expect(ArtisanLauncherService.buildMailtoUrl(null, 'Test'), isNull);
      final mailto = ArtisanLauncherService.buildMailtoUrl(
        'artisan@ceylongo.lk',
        'Inquiry: Mask Carving',
      );
      expect(mailto, equals('mailto:artisan@ceylongo.lk?subject=Inquiry%3A%20Mask%20Carving'));
    });

    test('buildPublicShareUrl creates standard shareable web links', () {
      final shareUrl = ArtisanLauncherService.buildPublicShareUrl('business', 42);
      expect(shareUrl, contains('/artisan/business/42'));
    });
  });
}

