import 'package:flutter/material.dart';

import 'features/artisan/services/artisan_demo_service.dart';
import 'main.dart';

/// Entry point for running CeylonGo in 100% Offline Interactive Demo Mode.
/// Launch command: flutter run -t lib/main_demo.dart
///
/// Features:
/// - Strictly zero network calls and zero database traffic.
/// - Deterministic in-memory mock datasets for workshops, products, reservations, and reviews.
/// - Full interactive state transitions (creating reservations decrements stock, canceling restores stock).
void main() {
  ArtisanDemoService.isDemoMode = true;
  ArtisanDemoService.instance.resetToDefaults();
  runApp(
    const CeylonGoApp(
      initialRoute: '/artisan',
    ),
  );
}

