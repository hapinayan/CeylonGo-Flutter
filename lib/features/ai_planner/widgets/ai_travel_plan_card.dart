import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../models/ai_chat_message.dart';

/// Embedded 3-Day Travel Plan Card and Plan Action Buttons (Save Plan, Share, Customize)
class AiTravelPlanCard extends StatelessWidget {
  final TravelPlanCardData plan;
  final bool isSaved;
  final VoidCallback onSavePlan;
  final VoidCallback onSharePlan;
  final VoidCallback onCustomizePlan;

  const AiTravelPlanCard({
    super.key,
    required this.plan,
    required this.isSaved,
    required this.onSavePlan,
    required this.onSharePlan,
    required this.onCustomizePlan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Travel Plan Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading + Green Category Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plan.categoryBadge,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Itinerary Rows
              ...List.generate(plan.days.length, (index) {
                final day = plan.days[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == plan.days.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Image
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: day.fallbackColor.withAlpha(25),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CeylonGoNetworkImage(
                          imageUrl: day.imageUrl,
                          fallbackIcon: day.fallbackIcon,
                          accentColor: day.fallbackColor,
                          iconSize: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Center Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                day.dayLabel,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A4DF5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              day.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              day.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF475569),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Plan Action Buttons: Save Plan, Share, Customize
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _PlanActionPill(
              key: const Key('ai_plan_save_btn'),
              icon: isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: isSaved ? 'Saved' : 'Save Plan',
              onTap: onSavePlan,
            ),
            _PlanActionPill(
              key: const Key('ai_plan_share_btn'),
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: onSharePlan,
            ),
            _PlanActionPill(
              key: const Key('ai_plan_customize_btn'),
              icon: Icons.tune_rounded,
              label: 'Customize',
              onTap: onCustomizePlan,
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlanActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: const Color(0xFF0A4DF5)),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryNavy,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFDBEAFE), width: 1.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

