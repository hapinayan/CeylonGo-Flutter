/// Types of community social notifications
enum CommunityNotificationType {
  like,
  comment,
  reply,
  follow,
}

/// CeylonGo Travel Community Notification Model
/// Represents local demo notifications for likes, comments, replies, and followers.
class CommunityNotificationModel {
  final String id;
  final String actorName;
  final String actorInitials;
  final CommunityNotificationType type;
  final String message;
  final String timeAgo;
  final String? postId;
  final bool isRead;

  const CommunityNotificationModel({
    required this.id,
    required this.actorName,
    required this.actorInitials,
    required this.type,
    required this.message,
    required this.timeAgo,
    this.postId,
    this.isRead = false,
  });

  CommunityNotificationModel copyWith({
    String? id,
    String? actorName,
    String? actorInitials,
    CommunityNotificationType? type,
    String? message,
    String? timeAgo,
    String? postId,
    bool? isRead,
  }) {
    return CommunityNotificationModel(
      id: id ?? this.id,
      actorName: actorName ?? this.actorName,
      actorInitials: actorInitials ?? this.actorInitials,
      type: type ?? this.type,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      postId: postId ?? this.postId,
      isRead: isRead ?? this.isRead,
    );
  }
}

