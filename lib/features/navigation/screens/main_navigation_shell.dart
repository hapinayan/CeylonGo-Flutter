import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../ai_planner/screens/ai_planner_screen.dart';
import '../../artisan/screens/artisan_discovery_screen.dart';
import '../../artisan/services/artisan_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../community/screens/community_feed_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';
import '../../profile/screens/profile_screen.dart';

/// Shared 5-Tab Instagram-Style Horizontal Swipe Navigation Shell
/// Hosts Home (0), Explore (1), AI Planner (2), Community (3), and Profile (4)
/// inside a PageView with a single fixed HomeBottomNavigationBar.
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  final UserModel? initialUser;
  final AuthService? authService;
  final SecureStorageService? storageService;
  final ArtisanService? artisanService;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.initialUser,
    this.authService,
    this.storageService,
    this.artisanService,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final PageController _pageController;
  late int _currentIndex;
  int? _programmaticTargetIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onTabSelected(int index) async {
    if (index < 0 || index > 4 || index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      _programmaticTargetIndex = index;
    });

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );

    if (mounted && _programmaticTargetIndex == index) {
      _programmaticTargetIndex = null;
    }
  }

  void _onPageChanged(int index) {
    if (_programmaticTargetIndex != null && index != _programmaticTargetIndex) {
      return;
    }
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          _onTabSelected(0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PageView(
          key: const Key('main_navigation_page_view'),
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            _KeepAlivePage(
              child: HomeScreen(
                initialUser: widget.initialUser,
                authService: widget.authService,
                storageService: widget.storageService,
                showBottomNav: false,
              ),
            ),
            _KeepAlivePage(
              child: ArtisanDiscoveryScreen(
                artisanService: widget.artisanService,
                showBottomNav: false,
              ),
            ),
            const _KeepAlivePage(
              child: AiPlannerScreen(showBottomNav: false),
            ),
            _KeepAlivePage(
              child: CommunityFeedScreen(
                authService: widget.authService,
                storageService: widget.storageService,
                showBottomNav: false,
              ),
            ),
            _KeepAlivePage(
              child: ProfileScreen(
                initialUser: widget.initialUser,
                authService: widget.authService,
                storageService: widget.storageService,
                showBottomNav: false,
              ),
            ),
          ],
        ),
        bottomNavigationBar: HomeBottomNavigationBar(
          currentIndex: _currentIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

