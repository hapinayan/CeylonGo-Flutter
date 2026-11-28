import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_trust_footer.dart';
import '../widgets/auth_wave_decoration.dart';

/// Role Selection Screen
/// Entry point when unauthenticated, allowing users to choose between
/// the Traveler experience and the Vendor / Provider portal.
class RoleSelectionScreen extends StatefulWidget {
  final SecureStorageService? storageService;

  const RoleSelectionScreen({super.key, this.storageService});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late final SecureStorageService _storageService;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? SecureStorageService();
  }

  Future<void> _onContinueAsVendor() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final completed = await _storageService.isVendorOnboardingCompleted();
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        completed ? '/vendor/login' : '/vendor/intro',
      );
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 360 ? 16.0 : (screenWidth < 430 ? 20.0 : 24.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const Key('role_selection_screen'),
        backgroundColor: AppTheme.backgroundWhite,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight <= 740;
              final showTrustFooter = constraints.maxHeight >= 540;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const AuthHeader(showBack: false),
                                SizedBox(height: isCompact ? 18 : 26),
                                const Text(
                                  'Welcome to CeylonGo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Select how you want to use CeylonGo today',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 18 : 24),
                                _RoleOptionCard(
                                  cardKey: const Key('role_card_traveler'),
                                  buttonKey:
                                      const Key('role_continue_traveler_btn'),
                                  icon: Icons.explore_outlined,
                                  title: "I'm a Traveler",
                                  description:
                                      'Explore destinations, artisans, community, personalized recommendations, maps, weather, and your profile.',
                                  buttonLabel: 'Continue as Traveler',
                                  isPrimary: true,
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                ),
                                const SizedBox(height: 14),
                                _RoleOptionCard(
                                  cardKey: const Key('role_card_vendor'),
                                  buttonKey:
                                      const Key('role_continue_vendor_btn'),
                                  icon: Icons.storefront_outlined,
                                  title: "I'm a Vendor",
                                  description:
                                      'Manage your business onboarding, dashboard, listings, bookings, availability, wallet, and profile.',
                                  buttonLabel: 'Continue as Vendor',
                                  isPrimary: false,
                                  onPressed: _onContinueAsVendor,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showTrustFooter)
                            AuthTrustFooter(isCompact: isCompact),
                          const AuthWaveDecoration(
                            upperWaveColor: Color(0xFF60C3FF),
                            lowerWaveColor: Color(0xFF082B5C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final Key cardKey;
  final Key buttonKey;
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _RoleOptionCard({
    required this.cardKey,
    required this.buttonKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primarySubtle : AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? AppTheme.primaryNavy.withAlpha(65)
              : AppTheme.borderSlate,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withAlpha(isPrimary ? 26 : 16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: isPrimary
                ? ElevatedButton(
                    key: buttonKey,
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: AppTheme.backgroundWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : OutlinedButton(
                    key: buttonKey,
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryNavy,
                      side: const BorderSide(
                        color: AppTheme.primaryNavy,
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
