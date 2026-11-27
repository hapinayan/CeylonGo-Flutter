import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/provider/models/provider_dashboard_data.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';

/// Development-Only Preview Entry Point for CeylonGo Service Provider Dashboard
///
/// Designed to preview and interact with the Phase 01 Provider Dashboard UI
/// directly on the Android Emulator or connected device without modifying
/// production authentication flows or traveler entry points.
///
/// Launch command:
///   flutter run -d emulator-5554 -t lib/main_provider_preview.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderDashboardPreviewApp());
}

/// Standalone Preview Application wrapper using production AppTheme
class ProviderDashboardPreviewApp extends StatefulWidget {
  const ProviderDashboardPreviewApp({super.key});

  @override
  State<ProviderDashboardPreviewApp> createState() =>
      _ProviderDashboardPreviewAppState();
}

class _ProviderDashboardPreviewAppState
    extends State<ProviderDashboardPreviewApp> {
  late ProviderDashboardData _dashboardData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dashboardData = ProviderDashboardData.fixture();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network latency for pull-to-refresh interaction
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _dashboardData = ProviderDashboardData.fixture();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CeylonGo Provider Dashboard Preview',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: ProviderDashboardScreen(
        data: _dashboardData,
        isLoading: _isLoading,
        onRefresh: _handleRefresh,
      ),
    );
  }
}
