import '../../../core/constants/api_constants.dart';

/// CeylonGo Travel Community Comment Model
/// Represents comments and replies within community post discussions.
class CommunityCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final String? authorAvatarUrl;
  final bool isVerified;
  final String text;
  final DateTime createdAt;
  final String? replyToCommentId;
  final String? replyToAuthorName;
  final int likesCount;
  final bool isLikedByDemoUser;
  final bool isDemoCreated;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    this.authorAvatarUrl,
    this.isVerified = false,
    required this.text,
    required this.createdAt,
    this.replyToCommentId,
    this.replyToAuthorName,
    this.likesCount = 0,
    this.isLikedByDemoUser = false,
    this.isDemoCreated = false,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  CommunityCommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorInitials,
    String? authorAvatarUrl,
    bool? isVerified,
    String? text,
    DateTime? createdAt,
    String? replyToCommentId,
    String? replyToAuthorName,
    int? likesCount,
    bool? isLikedByDemoUser,
    bool? isDemoCreated,
  }) {
    return CommunityCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorInitials: authorInitials ?? this.authorInitials,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isVerified: isVerified ?? this.isVerified,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      replyToCommentId: replyToCommentId ?? this.replyToCommentId,
      replyToAuthorName: replyToAuthorName ?? this.replyToAuthorName,
      likesCount: likesCount ?? this.likesCount,
      isLikedByDemoUser: isLikedByDemoUser ?? this.isLikedByDemoUser,
      isDemoCreated: isDemoCreated ?? this.isDemoCreated,
    );
  }

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final name = (authorMap['full_name'] ?? json['author_name'] ?? 'Traveler')
        .toString();
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts[0].isEmpty
        ? 'CG'
        : parts.length == 1
            ? parts[0][0].toUpperCase()
            : '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return CommunityCommentModel(
      id: '${json['id'] ?? ''}',
      postId: '${json['post_id'] ?? ''}',
      authorId: '${json['author_id'] ?? authorMap['id'] ?? ''}',
      authorName: name,
      authorInitials: initials,
      authorAvatarUrl: ApiConstants.resolveMediaUrl(
        authorMap['avatar_url']?.toString(),
      ),
      isVerified: authorMap['is_verified_provider'] == true,
      text: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

