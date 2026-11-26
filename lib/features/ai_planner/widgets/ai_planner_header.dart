import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Pure-White Upper Header & Title Area for AI Travel Planner Chatbot
/// Features navy back arrow, bold dark-navy "CeylonGo" text,
/// circular History & Bookmark buttons, and the AI Travel Planner title block.
class AiPlannerHeader extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onBookmarkTap;
  final bool hasSavedPlans;

  const AiPlannerHeader({
    super.key,
    required this.onBackTap,
    required this.onHistoryTap,
    required this.onBookmarkTap,
    this.hasSavedPlans = false,
  });

  static const Color _darkNavy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 14.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Back arrow, bold navy CeylonGo text, History & Bookmark buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    key: const Key('ai_planner_back_btn'),
                    onPressed: onBackTap,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.primaryNavy,
                      size: 23,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'CeylonGo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _darkNavy,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderCircleButton(
                    key: const Key('ai_planner_history_btn'),
                    icon: Icons.history_rounded,
                    tooltip: 'Chat History',
                    onTap: onHistoryTap,
                  ),
                  const SizedBox(width: 8),
                  _HeaderCircleButton(
                    key: const Key('ai_planner_bookmark_btn'),
                    icon: hasSavedPlans
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: 'Saved Plans',
                    onTap: onBookmarkTap,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // AI Chatbot Title Block
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'AI Travel Planner',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryNavy,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.smart_toy_rounded,
                          color: Color(0xFF0A4DF5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'AI Chatbot',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Chat with our AI and plan your perfect Sri Lanka trip.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryNavy,
            size: 19,
          ),
        ),
      ),
    );
  }
}
