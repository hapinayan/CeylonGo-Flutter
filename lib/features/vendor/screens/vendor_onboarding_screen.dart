import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/auth_wave_decoration.dart';

/// Vendor Onboarding Swipe Screens
/// Three-page blue-and-white onboarding introduction shown once to first-time
/// Vendor users before reaching Vendor Sign In.
class VendorOnboardingScreen extends StatefulWidget {
  final SecureStorageService? storageService;
  final bool isReplay;

  const VendorOnboardingScreen({
    super.key,
    this.storageService,
    this.isReplay = false,
  });

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  late final PageController _pageController;
  late final SecureStorageService _storageService;

  int _currentPage = 0;
  bool _isFinishing = false;

  static const int _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _storageService = widget.storageService ?? SecureStorageService();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeAndContinue() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    await _storageService.setVendorOnboardingCompleted(completed: true);
    if (!mounted) return;

    if (widget.isReplay && Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, '/vendor/login');
  }

  Future<void> _onNext() async {
    if (_currentPage < _pageCount - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _completeAndContinue();
    }
  }

  void _onBackPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 360 ? 16.0 : (screenWidth < 430 ? 20.0 : 24.0);
    final isLastPage = _currentPage == _pageCount - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: _currentPage == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _currentPage > 0) {
            _onBackPressed();
          }
        },
        child: Scaffold(
          key: const Key('vendor_onboarding_screen'),
          backgroundColor: AppTheme.backgroundWhite,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight <= 720;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar: Back / Brand + Skip
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompact ? 8 : 12,
                        horizontalPadding,
                        4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            key: const Key('vendor_onboarding_back_btn'),
                            onPressed: _onBackPressed,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.primaryNavy,
                            ),
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/images/ceylongo_logo.png',
                            height: isCompact ? 30 : 34,
                            fit: BoxFit.contain,
                            semanticLabel: 'CeylonGo Logo',
                          ),
                          const Spacer(),
                          if (!isLastPage)
                            TextButton(
                              key: const Key('vendor_onboarding_skip_btn'),
                              onPressed:
                                  _isFinishing ? null : _completeAndContinue,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // Swipeable pages
                    Expanded(
                      child: PageView.builder(
                        key: const Key('vendor_onboarding_pageview'),
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        physics: const PageScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: _pageCount,
                        onPageChanged: (index) {
                          if (_currentPage != index) {
                            setState(() => _currentPage = index);
                          }
                        },
                        itemBuilder: (context, index) {
                          return _VendorOnboardingPageContent(
                            pageIndex: index,
                            horizontalPadding: horizontalPadding,
                            isCompact: isCompact,
                          );
                        },
                      ),
                    ),

                    // Pagination indicators & primary action
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        isCompact ? 12 : 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_pageCount, (index) {
                                  final isActive = index == _currentPage;
                                  return AnimatedContainer(
                                    key: Key(
                                      'vendor_onboarding_dot_$index',
                                    ),
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    height: 8,
                                    width: isActive ? 26 : 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppTheme.primaryNavy
                                          : AppTheme.borderSlate,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: isCompact ? 14 : 18),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  key: isLastPage
                                      ? const Key(
                                          'vendor_onboarding_get_started_btn',
                                        )
                                      : const Key(
                                          'vendor_onboarding_next_btn',
                                        ),
                                  onPressed: _isFinishing ? null : _onNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryNavy,
                                    foregroundColor: AppTheme.backgroundWhite,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isLastPage ? 'Get Started' : 'Next',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const AuthWaveDecoration(
                      upperWaveColor: Color(0xFF60C3FF),
                      lowerWaveColor: Color(0xFF082B5C),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorOnboardingPageContent extends StatelessWidget {
  final int pageIndex;
  final double horizontalPadding;
  final bool isCompact;

  const _VendorOnboardingPageContent({
    required this.pageIndex,
    required this.horizontalPadding,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, badge) = switch (pageIndex) {
      0 => (
          'Showcase Your Business',
          'Create and manage your homestays, tours, rentals, and local experiences in one place.',
          'Manage Your Listings',
        ),
      1 => (
          'Manage Bookings Easily',
          'Stay organized with booking requests, availability, and customer reservations.',
          'Manage Bookings',
        ),
      _ => (
          'Grow with CeylonGo',
          'View your earnings, track settlements, and manage your tourism business.',
          'Track Your Earnings',
        ),
    };

    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final allowVerticalScroll = pageConstraints.maxHeight < 430;
        return SingleChildScrollView(
          primary: false,
          physics: allowVerticalScroll
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isCompact ? 8 : 14,
          ),
          child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVisual(pageIndex, isCompact),
              SizedBox(height: isCompact ? 18 : 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySubtle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.primaryNavy.withAlpha(45),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 22 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 44,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A4DF5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildVisual(int index, bool isCompact) {
    final cardHeight = isCompact ? 200.0 : 230.0;

    if (index == 0) {
      return Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryNavy.withAlpha(35)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/tourist_sigiriya_header.png',
              fit: BoxFit.cover,
              semanticLabel: 'Sri Lankan hospitality and tourism destination',
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryNavy.withAlpha(205),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  _VisualChip(icon: Icons.home_work_outlined, label: 'Homestays'),
                  _VisualChip(icon: Icons.tour_outlined, label: 'Tours'),
                  _VisualChip(icon: Icons.directions_car_outlined, label: 'Rentals'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (index == 1) {
      return Container(
        constraints: BoxConstraints(minHeight: cardHeight),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF5FF),
              Color(0xFFDCEBFF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryNavy.withAlpha(45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const _VisualPreviewRow(
              icon: Icons.event_available_rounded,
              title: 'Availability Calendar',
              subtitle: 'Keep listing dates up to date',
            ),
            const SizedBox(height: 8),
            const _VisualPreviewRow(
              icon: Icons.book_online_outlined,
              title: 'Reservation Requests',
              subtitle: 'Respond to travelers on time',
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: cardHeight),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF082B5C),
            Color(0xFF0D47A1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(32),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const _DarkPreviewRow(
            icon: Icons.insights_rounded,
            title: 'Earnings Overview',
            subtitle: 'Track completed bookings and payouts',
          ),
          const SizedBox(height: 8),
          const _DarkPreviewRow(
            icon: Icons.verified_outlined,
            title: 'Trusted Partner Portal',
            subtitle: 'Built for Sri Lankan tourism vendors',
          ),
        ],
      ),
    );
  }
}

class _VisualChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _VisualChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryNavy),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualPreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _VisualPreviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryNavy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkPreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DarkPreviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.white.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

