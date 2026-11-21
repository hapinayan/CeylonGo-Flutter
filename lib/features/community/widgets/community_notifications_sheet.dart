import 'package:flutter/material.dart';

import '../models/community_notification_model.dart';
import '../services/community_demo_service.dart';

/// Community Notifications Bottom Sheet
/// Displays local demonstration notifications for likes, comments, replies, and followers.
class CommunityNotificationsSheet extends StatefulWidget {
  const CommunityNotificationsSheet({super.key});

  @override
  State<CommunityNotificationsSheet> createState() => _CommunityNotificationsSheetState();
}

class _CommunityNotificationsSheetState extends State<CommunityNotificationsSheet> {
  final _demoService = CommunityDemoService();
  late List<CommunityNotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _demoService.getNotifications();
    _demoService.markNotificationsRead();
  }

  IconData _getNotificationIcon(CommunityNotificationType type) {
    switch (type) {
      case CommunityNotificationType.like:
        return Icons.favorite_rounded;
      case CommunityNotificationType.comment:
        return Icons.chat_bubble_rounded;
      case CommunityNotificationType.reply:
        return Icons.reply_rounded;
      case CommunityNotificationType.follow:
        return Icons.person_add_rounded;
    }
  }

  Color _getNotificationColor(CommunityNotificationType type) {
    switch (type) {
      case CommunityNotificationType.like:
        return const Color(0xFFDC2626);
      case CommunityNotificationType.comment:
        return const Color(0xFF073B91);
      case CommunityNotificationType.reply:
        return const Color(0xFF2563EB);
      case CommunityNotificationType.follow:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Community Notifications',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF082B5C),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final icon = _getNotificationIcon(notif.type);
                      final color = _getNotificationColor(notif.type);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withAlpha(25),
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: notif.actorName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: ' ${notif.message}'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.timeAgo,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
