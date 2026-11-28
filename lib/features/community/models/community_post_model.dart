import '../../../core/constants/api_constants.dart';
import 'community_author_model.dart';
import 'community_comment_model.dart';

/// CeylonGo Travel Community Post Model
/// Represents a travel post, story, artisan spotlight, or tip in the community feed.
class CommunityPostModel {
  final String id;
  final CommunityAuthorModel author;
  final String caption;
  final List<String> hashtags;
  final String location;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLikedByDemoUser;
  final bool isSavedByDemoUser;
  final List<CommunityCommentModel> comments;
  final bool isDemoCreated;

  const CommunityPostModel({
    required this.id,
    required this.author,
    required this.caption,
    required this.hashtags,
    required this.location,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLikedByDemoUser = false,
    this.isSavedByDemoUser = false,
    this.comments = const [],
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

  CommunityPostModel copyWith({
    String? id,
    CommunityAuthorModel? author,
    String? caption,
    List<String>? hashtags,
    String? location,
    String? imageUrl,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLikedByDemoUser,
    bool? isSavedByDemoUser,
    List<CommunityCommentModel>? comments,
    bool? isDemoCreated,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      author: author ?? this.author,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByDemoUser: isLikedByDemoUser ?? this.isLikedByDemoUser,
      isSavedByDemoUser: isSavedByDemoUser ?? this.isSavedByDemoUser,
      comments: comments ?? this.comments,
      isDemoCreated: isDemoCreated ?? this.isDemoCreated,
    );
  }

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final author = CommunityAuthorModel.fromJson(
      authorMap,
      fallbackName: json['author_name']?.toString(),
      fallbackId: json['author_id'] is int
          ? json['author_id'] as int
          : int.tryParse('${json['author_id']}'),
    );

    final body = json['body']?.toString() ?? '';
    final hashtags = RegExp(r'#[A-Za-z0-9_]+')
        .allMatches(body)
        .map((m) => m.group(0)!)
        .toSet()
        .toList();

    String? imageUrl;
    if (json['media'] is List && (json['media'] as List).isNotEmpty) {
      final first = (json['media'] as List).first;
      if (first is Map<String, dynamic>) {
        final resolved =
            ApiConstants.resolveMediaUrl(first['image_url']?.toString());
        if (resolved.isNotEmpty) imageUrl = resolved;
      }
    }

    return CommunityPostModel(
      id: '${json['id'] ?? ''}',
      author: author,
      caption: body,
      hashtags: hashtags,
      location: author.location,
      imageUrl: imageUrl,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      likesCount: json['likes_count'] is int
          ? json['likes_count'] as int
          : int.tryParse('${json['likes_count']}') ?? 0,
      commentsCount: json['comments_count'] is int
          ? json['comments_count'] as int
          : int.tryParse('${json['comments_count']}') ?? 0,
      isLikedByDemoUser: json['viewer_has_liked'] == true,
      isSavedByDemoUser: json['viewer_has_saved'] == true,
    );
  }
}

