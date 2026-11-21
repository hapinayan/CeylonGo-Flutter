import '../models/community_author_model.dart';
import '../models/community_comment_model.dart';
import '../models/community_notification_model.dart';
import '../models/community_post_model.dart';

/// In-Memory Community Demo Service
/// Manages deterministic sample data, interactive social interactions (likes, comments,
/// bookmarks, following, reporting, search, creation), without calling any backend or database.
class CommunityDemoService {
  static final CommunityDemoService _singleton = CommunityDemoService._internal();
  factory CommunityDemoService() => _singleton;
  CommunityDemoService._internal() {
    resetToDefaults();
  }

  static const String currentUserId = 'usr_demo';
  static const String currentUserName = 'Demo Traveler';
  static const String currentUserHandle = '@kamal_ceylon';

  late List<CommunityAuthorModel> _authors;
  late List<CommunityPostModel> _posts;
  late Set<String> _likedPostIds;
  late Set<String> _savedPostIds;
  late Set<String> _followedAuthorIds;
  late List<CommunityNotificationModel> _notifications;
  late List<Map<String, String>> _reports;

  static const List<String> trendingHashtags = [
    '#All',
    '#Jaffna',
    '#Ella',
    '#TravelSriLanka',
    '#BeachLife',
    '#Nature',
    '#SriLankanCrafts',
  ];

  /// Resets the in-memory repository to default demonstration state.
  void resetToDefaults() {
    _authors = [
      const CommunityAuthorModel(
        id: currentUserId,
        name: currentUserName,
        handle: currentUserHandle,
        initials: 'DT',
        bio: 'Passionate traveler exploring hidden gems, artisan workshops, and mountain trails in Sri Lanka.',
        location: 'Ella, Sri Lanka',
        postCount: 1,
        followersCount: 128,
        followingCount: 34,
        isFollowedByDemoUser: false,
      ),
      const CommunityAuthorModel(
        id: 'prov_ceylon_crafts',
        name: 'Ceylon Handcrafts',
        handle: '@ceylon_handcrafts',
        initials: 'CH',
        isVerifiedProvider: true,
        providerBadgeLabel: 'Verified Artisan',
        bio: 'Master brass-ware, woodcarving & handloom workshop preserving Sri Lankan heritage in Galle Fort.',
        location: 'Galle Fort, Sri Lanka',
        postCount: 14,
        followersCount: 1840,
        followingCount: 112,
        isFollowedByDemoUser: true,
        artisanListingId: 'art-001',
      ),
      const CommunityAuthorModel(
        id: 'usr_nuwan',
        name: 'Nuwan Silva',
        handle: '@nuwan_travels',
        initials: 'NS',
        bio: 'Landscape photographer & backpacker chasing sunrises across the central highlands.',
        location: 'Kandy, Sri Lanka',
        postCount: 22,
        followersCount: 950,
        followingCount: 210,
        isFollowedByDemoUser: false,
      ),
      const CommunityAuthorModel(
        id: 'usr_ananya',
        name: 'Ananya Sen',
        handle: '@ananya_wander',
        initials: 'AS',
        bio: 'Solo wanderer & coastal surfer. Sharing the best beach breaks and sunset spots.',
        location: 'Mirissa, Sri Lanka',
        postCount: 19,
        followersCount: 1420,
        followingCount: 180,
        isFollowedByDemoUser: false,
      ),
      const CommunityAuthorModel(
        id: 'prov_jaffna_crafts',
        name: 'Northern Heritage Crafts',
        handle: '@jaffna_heritage',
        initials: 'NH',
        isVerifiedProvider: true,
        providerBadgeLabel: 'Verified Artisan',
        bio: 'Authentic terracotta pottery & palm-leaf weaving cooperative in Chunnakam, Jaffna.',
        location: 'Jaffna, Sri Lanka',
        postCount: 8,
        followersCount: 760,
        followingCount: 45,
        isFollowedByDemoUser: false,
        artisanListingId: 'art-002',
      ),
    ];

    _followedAuthorIds = {'prov_ceylon_crafts'};
    _likedPostIds = {'post_001'};
    _savedPostIds = {'post_001', 'post_002'};
    _reports = [];

    _posts = [
      // Post 1 – Traveler (Demo Traveler)
      CommunityPostModel(
        id: 'post_001',
        author: _authors[0],
        caption: 'A beautiful morning in Ella! 🌿 The train, the mountains and the cool mist – a perfect Sri Lankan travel experience. 💙',
        hashtags: const ['#Ella', '#TravelSriLanka', '#TrainJourney', '#Nature'],
        location: 'Ella, Sri Lanka',
        imageUrl: 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=800',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likesCount: 142,
        commentsCount: 2,
        sharesCount: 18,
        isLikedByDemoUser: true,
        isSavedByDemoUser: true,
        comments: [
          CommunityCommentModel(
            id: 'cmt_001_1',
            postId: 'post_001',
            authorId: 'usr_nuwan',
            authorName: 'Nuwan Silva',
            authorInitials: 'NS',
            text: 'Stunning view! The mist looks ethereal between the tea hills.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            likesCount: 5,
          ),
          CommunityCommentModel(
            id: 'cmt_001_2',
            postId: 'post_001',
            authorId: 'usr_ananya',
            authorName: 'Ananya Sen',
            authorInitials: 'AS',
            text: 'Did you ride the blue train all the way from Kandy? Such a magical route! 🚂',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            likesCount: 3,
          ),
        ],
        isDemoCreated: false,
      ),

      // Post 2 – Verified Service Provider (Ceylon Handcrafts)
      CommunityPostModel(
        id: 'post_002',
        author: _authors[1],
        caption: 'Authentic Sri Lankan Handicrafts 🇱🇰 Explore handmade crafts created by local artisans using traditional techniques.',
        hashtags: const ['#SriLankanCrafts', '#Artisan', '#Galle'],
        location: 'Galle Fort, Sri Lanka',
        imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        likesCount: 98,
        commentsCount: 1,
        sharesCount: 24,
        isLikedByDemoUser: false,
        isSavedByDemoUser: true,
        comments: [
          CommunityCommentModel(
            id: 'cmt_002_1',
            postId: 'post_002',
            authorId: currentUserId,
            authorName: currentUserName,
            authorInitials: 'DT',
            text: 'I loved the hand-carved mask demonstration! Highly recommend visiting the workshop.',
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            likesCount: 2,
            isDemoCreated: true,
          ),
        ],
        isDemoCreated: false,
      ),

      // Post 3 – Traveler (Nuwan Silva)
      CommunityPostModel(
        id: 'post_003',
        author: _authors[2],
        caption: 'Golden hour view atop Sigiriya Rock Fortress. The climb at 5:30 AM is 100% worth every single step! 🌅🇱🇰',
        hashtags: const ['#Sigiriya', '#TravelSriLanka', '#Nature'],
        location: 'Sigiriya, Sri Lanka',
        imageUrl: 'https://images.unsplash.com/photo-1588598198321-9735fd52455b?w=800',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        likesCount: 215,
        commentsCount: 3,
        sharesCount: 35,
        isLikedByDemoUser: false,
        isSavedByDemoUser: false,
        comments: [
          CommunityCommentModel(
            id: 'cmt_003_1',
            postId: 'post_003',
            authorId: 'usr_ananya',
            authorName: 'Ananya Sen',
            authorInitials: 'AS',
            text: 'Breathtaking light! Did you see the water gardens below too?',
            createdAt: DateTime.now().subtract(const Duration(hours: 10)),
            likesCount: 4,
          ),
        ],
        isDemoCreated: false,
      ),

      // Post 4 – Traveler (Ananya Sen)
      CommunityPostModel(
        id: 'post_004',
        author: _authors[3],
        caption: 'Watching coconut palms sway against the pink dusk sky at Coconut Tree Hill. Sri Lankan sunsets hit different! 🌴🌊',
        hashtags: const ['#BeachLife', '#TravelSriLanka', '#Nature'],
        location: 'Mirissa, Sri Lanka',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likesCount: 180,
        commentsCount: 2,
        sharesCount: 19,
        isLikedByDemoUser: false,
        isSavedByDemoUser: false,
        comments: [],
        isDemoCreated: false,
      ),

      // Post 5 – Verified Service Provider (Northern Heritage Crafts)
      CommunityPostModel(
        id: 'post_005',
        author: _authors[4],
        caption: 'Traditional clay terracotta pottery molded by master potters in Chunnakam, Jaffna. Preserving centuries of heritage. 🏺',
        hashtags: const ['#Jaffna', '#SriLankanCrafts', '#Artisan'],
        location: 'Jaffna, Sri Lanka',
        imageUrl: 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=800',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likesCount: 87,
        commentsCount: 1,
        sharesCount: 14,
        isLikedByDemoUser: false,
        isSavedByDemoUser: false,
        comments: [],
        isDemoCreated: false,
      ),
    ];

    _notifications = [
      const CommunityNotificationModel(
        id: 'notif_001',
        actorName: 'Nuwan Silva',
        actorInitials: 'NS',
        type: CommunityNotificationType.like,
        message: 'liked your post: "A beautiful morning in Ella!"',
        timeAgo: '2h ago',
        postId: 'post_001',
      ),
      const CommunityNotificationModel(
        id: 'notif_002',
        actorName: 'Ananya Sen',
        actorInitials: 'AS',
        type: CommunityNotificationType.comment,
        message: 'commented: "Did you ride the blue train all the way from Kandy?"',
        timeAgo: '1h ago',
        postId: 'post_001',
      ),
      const CommunityNotificationModel(
        id: 'notif_003',
        actorName: 'Ceylon Handcrafts',
        actorInitials: 'CH',
        type: CommunityNotificationType.reply,
        message: 'replied to your review on Galle workshop carvings',
        timeAgo: '4h ago',
        postId: 'post_002',
      ),
      const CommunityNotificationModel(
        id: 'notif_004',
        actorName: 'Nuwan Silva',
        actorInitials: 'NS',
        type: CommunityNotificationType.follow,
        message: 'started following you',
        timeAgo: 'Yesterday',
      ),
    ];
  }

  // --- Read Operations ---

  List<CommunityPostModel> getForYouPosts({String? hashtagFilter, String? searchQuery}) {
    return _filterPosts(_posts, hashtagFilter: hashtagFilter, searchQuery: searchQuery);
  }

  List<CommunityPostModel> getFollowingPosts({String? hashtagFilter, String? searchQuery}) {
    final following = _posts.where((p) => _followedAuthorIds.contains(p.author.id)).toList();
    return _filterPosts(following, hashtagFilter: hashtagFilter, searchQuery: searchQuery);
  }

  List<CommunityPostModel> getSavedPosts({String? hashtagFilter, String? searchQuery}) {
    final saved = _posts.where((p) => _savedPostIds.contains(p.id)).toList();
    return _filterPosts(saved, hashtagFilter: hashtagFilter, searchQuery: searchQuery);
  }

  List<CommunityPostModel> _filterPosts(
    List<CommunityPostModel> list, {
    String? hashtagFilter,
    String? searchQuery,
  }) {
    return list.where((p) {
      if (hashtagFilter != null && hashtagFilter.isNotEmpty && hashtagFilter != '#All') {
        final matchesHashtag = p.hashtags.any(
          (h) => h.toLowerCase() == hashtagFilter.toLowerCase(),
        );
        if (!matchesHashtag) return false;
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final inCaption = p.caption.toLowerCase().contains(q);
        final inAuthor = p.author.name.toLowerCase().contains(q) || p.author.handle.toLowerCase().contains(q);
        final inLocation = p.location.toLowerCase().contains(q);
        final inHashtags = p.hashtags.any((h) => h.toLowerCase().contains(q));
        if (!inCaption && !inAuthor && !inLocation && !inHashtags) return false;
      }

      return true;
    }).toList();
  }

  CommunityAuthorModel? getAuthor(String authorId) {
    try {
      final author = _authors.firstWhere((a) => a.id == authorId);
      final isFollowed = _followedAuthorIds.contains(authorId);
      return author.copyWith(isFollowedByDemoUser: isFollowed);
    } catch (_) {
      return null;
    }
  }

  List<CommunityPostModel> getPostsByAuthor(String authorId) {
    return _posts.where((p) => p.author.id == authorId).toList();
  }

  List<CommunityNotificationModel> getNotifications() {
    return List.unmodifiable(_notifications);
  }

  bool isFollowing(String authorId) {
    return _followedAuthorIds.contains(authorId);
  }

  bool isLiked(String postId) {
    return _likedPostIds.contains(postId);
  }

  bool isSaved(String postId) {
    return _savedPostIds.contains(postId);
  }

  // --- Interactive State Mutations ---

  void toggleLike(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
      _posts[index] = post.copyWith(
        isLikedByDemoUser: false,
        likesCount: (post.likesCount - 1).clamp(0, 999999),
      );
    } else {
      _likedPostIds.add(postId);
      _posts[index] = post.copyWith(
        isLikedByDemoUser: true,
        likesCount: post.likesCount + 1,
      );
    }
  }

  void toggleSave(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    if (_savedPostIds.contains(postId)) {
      _savedPostIds.remove(postId);
      _posts[index] = post.copyWith(isSavedByDemoUser: false);
    } else {
      _savedPostIds.add(postId);
      _posts[index] = post.copyWith(isSavedByDemoUser: true);
    }
  }

  void toggleFollow(String authorId) {
    if (authorId == currentUserId) return; // Cannot follow self

    final authorIdx = _authors.indexWhere((a) => a.id == authorId);
    if (authorIdx == -1) return;

    final author = _authors[authorIdx];
    final wasFollowing = _followedAuthorIds.contains(authorId);

    if (wasFollowing) {
      _followedAuthorIds.remove(authorId);
      _authors[authorIdx] = author.copyWith(
        isFollowedByDemoUser: false,
        followersCount: (author.followersCount - 1).clamp(0, 999999),
      );
    } else {
      _followedAuthorIds.add(authorId);
      _authors[authorIdx] = author.copyWith(
        isFollowedByDemoUser: true,
        followersCount: author.followersCount + 1,
      );
    }

    // Update author copies inside posts
    for (int i = 0; i < _posts.length; i++) {
      if (_posts[i].author.id == authorId) {
        _posts[i] = _posts[i].copyWith(
          author: _authors[authorIdx],
        );
      }
    }
  }

  CommunityPostModel addPost({
    required String caption,
    required String location,
    required List<String> hashtags,
    String? imageUrl,
  }) {
    final newId = 'post_demo_${DateTime.now().millisecondsSinceEpoch}';
    final demoAuthor = _authors.firstWhere((a) => a.id == currentUserId);

    final cleanHashtags = hashtags.map((h) {
      final trimmed = h.trim();
      return trimmed.startsWith('#') ? trimmed : '#$trimmed';
    }).where((h) => h.length > 1).toList();

    final newPost = CommunityPostModel(
      id: newId,
      author: demoAuthor,
      caption: caption.trim(),
      hashtags: cleanHashtags.isNotEmpty ? cleanHashtags : ['#TravelSriLanka'],
      location: location.trim().isNotEmpty ? location.trim() : 'Sri Lanka',
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isLikedByDemoUser: false,
      isSavedByDemoUser: false,
      comments: const [],
      isDemoCreated: true,
    );

    _posts.insert(0, newPost);

    // Update demo traveler's post count
    final authorIdx = _authors.indexWhere((a) => a.id == currentUserId);
    if (authorIdx != -1) {
      _authors[authorIdx] = demoAuthor.copyWith(postCount: demoAuthor.postCount + 1);
    }

    return newPost;
  }

  bool editPost(String postId, String newCaption) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    // Only allow editing demo user's own posts
    if (_posts[index].author.id != currentUserId) return false;

    _posts[index] = _posts[index].copyWith(caption: newCaption.trim());
    return true;
  }

  bool deletePost(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    // Only allow deleting demo user's own posts
    if (_posts[index].author.id != currentUserId) return false;

    _posts.removeAt(index);
    _likedPostIds.remove(postId);
    _savedPostIds.remove(postId);

    final authorIdx = _authors.indexWhere((a) => a.id == currentUserId);
    if (authorIdx != -1) {
      final a = _authors[authorIdx];
      _authors[authorIdx] = a.copyWith(postCount: (a.postCount - 1).clamp(0, 999999));
    }
    return true;
  }

  CommunityCommentModel addComment({
    required String postId,
    required String text,
    String? replyToCommentId,
  }) {
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    final newCommentId = 'cmt_demo_${DateTime.now().millisecondsSinceEpoch}';

    String? replyAuthorName;
    if (replyToCommentId != null && postIdx != -1) {
      final existingComment = _posts[postIdx].comments.where((c) => c.id == replyToCommentId).firstOrNull;
      replyAuthorName = existingComment?.authorName;
    }

    final comment = CommunityCommentModel(
      id: newCommentId,
      postId: postId,
      authorId: currentUserId,
      authorName: currentUserName,
      authorInitials: 'DT',
      text: text.trim(),
      createdAt: DateTime.now(),
      replyToCommentId: replyToCommentId,
      replyToAuthorName: replyAuthorName,
      likesCount: 0,
      isLikedByDemoUser: false,
      isDemoCreated: true,
    );

    if (postIdx != -1) {
      final post = _posts[postIdx];
      final updatedComments = List<CommunityCommentModel>.from(post.comments)..add(comment);
      _posts[postIdx] = post.copyWith(
        comments: updatedComments,
        commentsCount: updatedComments.length,
      );
    }

    return comment;
  }

  bool deleteComment(String postId, String commentId) {
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return false;

    final post = _posts[postIdx];
    final commentIdx = post.comments.indexWhere((c) => c.id == commentId);
    if (commentIdx == -1) return false;

    // Only allow deleting comments created by the demo user
    if (post.comments[commentIdx].authorId != currentUserId) return false;

    final updatedComments = List<CommunityCommentModel>.from(post.comments)..removeAt(commentIdx);
    _posts[postIdx] = post.copyWith(
      comments: updatedComments,
      commentsCount: updatedComments.length,
    );
    return true;
  }

  void reportPost(String postId, String reason) {
    _reports.add({
      'postId': postId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void markNotificationsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
  }
}

