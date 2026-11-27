import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../services/account_service.dart';

/// Shows the live Traveler Notifications modal bottom sheet.
Future<void> showNotificationsSheet(
  BuildContext context, {
  AccountService? accountService,
  VoidCallback? onUpdated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _NotificationsSheetBody(
      service: accountService ?? AccountService(),
      onUpdated: onUpdated,
    ),
  );
}

class _NotificationsSheetBody extends StatefulWidget {
  final AccountService service;
  final VoidCallback? onUpdated;

  const _NotificationsSheetBody({
    required this.service,
    this.onUpdated,
  });

  @override
  State<_NotificationsSheetBody> createState() => _NotificationsSheetBodyState();
}

class _NotificationsSheetBodyState extends State<_NotificationsSheetBody> {
  bool _isLoading = true;
  bool _unreadOnly = false;
  bool _markingAll = false;
  String? _error;
  List<NotificationItemModel> _items = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await widget.service.getNotifications(
        unreadOnly: _unreadOnly ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _unreadCount = page.unreadCount;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load notifications. Please try again.';
      });
    }
  }

  Future<void> _markRead(NotificationItemModel item) async {
    if (item.isRead) return;
    try {
      final updated = await widget.service.markNotificationRead(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((n) => n.id == item.id ? updated : n).toList();
        if (_unreadCount > 0) _unreadCount--;
      });
      widget.onUpdated?.call();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _unreadCount == 0) return;
    setState(() => _markingAll = true);
    try {
      await widget.service.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _markingAll = false;
        _unreadCount = 0;
        _items = _items
            .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList();
      });
      widget.onUpdated?.call();
    } catch (_) {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'booking':
      case 'bookings':
        return Icons.calendar_today_rounded;
      case 'payment':
      case 'payments':
        return Icons.payments_outlined;
      case 'community':
        return Icons.forum_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.borderSlate,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markingAll ? null : _markAllRead,
                      child: Text(
                        _markingAll ? 'Updating...' : 'Mark all read',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FilterChip(
                    label: Text('All'),
                    selected: !_unreadOnly,
                    onSelected: (_) {
                      if (_unreadOnly) {
                        setState(() => _unreadOnly = false);
                        _load();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      _unreadCount > 0 ? 'Unread ($_unreadCount)' : 'Unread',
                    ),
                    selected: _unreadOnly,
                    onSelected: (_) {
                      if (!_unreadOnly) {
                        setState(() => _unreadOnly = true);
                        _load();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 44,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _unreadOnly
                                          ? 'No unread notifications'
                                          : 'No notifications yet',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Booking confirmations, payments, and updates will appear here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.separated(
                                  controller: controller,
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, index) {
                                    final item = _items[index];
                                    return ListTile(
                                      onTap: () => _markRead(item),
                                      tileColor: item.isRead
                                          ? Colors.transparent
                                          : AppTheme.primarySubtle,
                                      leading: CircleAvatar(
                                        backgroundColor: item.isRead
                                            ? Colors.grey.shade100
                                            : AppTheme.primaryNavy
                                                .withOpacity(0.1),
                                        child: Icon(
                                          _iconForCategory(item.category),
                                          size: 18,
                                          color: item.isRead
                                              ? AppTheme.textSecondary
                                              : AppTheme.primaryNavy,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: item.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                color: AppTheme.primaryNavy,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDate(item.createdAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          item.message,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
