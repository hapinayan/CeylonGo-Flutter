import 'package:flutter/material.dart';

import '../../auth/models/user_model.dart';

/// Section A: CeylonGo Premium Navy Blue Animated Header
/// Inspired by the latest approved reference design.
/// Features a full-width deep-blue background (#073B91), pure-white CeylonGo brand typography,
/// and white outlined circular notification & profile buttons with micro-interactions.
class HomeHeader extends StatefulWidget {
  final Animation<double> animation;
  final UserModel? user;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.animation,
    this.user,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  double _notifScale = 1.0;
  double _profileScale = 1.0;

  static const Color headerBlue = Color(0xFF073B91);

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    return Container(
      width: double.infinity,
      color: headerBlue,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Pure White CeylonGo Brand Title (No subtitle)
                  const Expanded(
                    child: Text(
                      'CeylonGo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),

                  // Right: White Outlined Circular Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification Bell with Active Cyan Indicator Dot
                      AnimatedScale(
                        scale: _notifScale,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        child: GestureDetector(
                          key: const Key('home_notifications_btn'),
                          onTapDown: (_) => setState(() => _notifScale = 0.92),
                          onTapUp: (_) => setState(() => _notifScale = 1.0),
                          onTapCancel: () => setState(() => _notifScale = 1.0),
                          onTap: widget.onNotificationTap,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(200),
                                width: 1.3,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                Positioned(
                                  top: 9,
                                  right: 10,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF38BDF8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Profile Icon Action
                      AnimatedScale(
                        scale: _profileScale,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        child: GestureDetector(
                          key: const Key('home_profile_btn'),
                          onTapDown: (_) => setState(() => _profileScale = 0.92),
                          onTapUp: (_) => setState(() => _profileScale = 1.0),
                          onTapCancel: () => setState(() => _profileScale = 1.0),
                          onTap: widget.onProfileTap,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(200),
                                width: 1.3,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
