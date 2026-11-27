import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/community_comment_model.dart';
import '../models/community_post_model.dart';

class CommunityLikeResult {
  final int postId;
  final bool liked;
  final int likesCount;

  const CommunityLikeResult({
    required this.postId,
    required this.liked,
    required this.likesCount,
  });
}

/// Service connecting Community Feed, Posts, Likes, Comments, Saved Posts & Reports
/// to the CeylonGo Academic MVP FastAPI backend.
class CommunityService {
  final ApiClient _api;

  CommunityService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  List<CommunityPostModel> _parsePosts(dynamic data) {
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CommunityPostModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<CommunityPostModel>> getFeed({
    String? search,
    int? authorId,
    String? authorType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (authorId != null) 'author_id': authorId.toString(),
      if (authorType != null && authorType.isNotEmpty) 'author_type': authorType,
    };
    final data = await _api.get(
      ApiConstants.communityFeedEndpoint,
      queryParameters: params,
    );
    return _parsePosts(data);
  }

  Future<List<CommunityPostModel>> getMyPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _api.get(
      ApiConstants.myCommunityPostsEndpoint,
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    return _parsePosts(data);
  }

  Future<List<CommunityPostModel>> getSavedPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _api.get(
      ApiConstants.savedCommunityPostsEndpoint,
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    return _parsePosts(data);
  }

  Future<CommunityPostModel> createPost({required String body}) async {
    final data = await _api.post(
      ApiConstants.communityPostsEndpoint,
      body: {'body': body.trim()},
    );
    return CommunityPostModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CommunityPostModel> updatePost(
    int postId, {
    required String body,
  }) async {
    final data = await _api.patch(
      '${ApiConstants.communityPostsEndpoint}/$postId',
      body: {'body': body.trim()},
    );
    return CommunityPostModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePost(int postId) async {
    await _api.delete('${ApiConstants.communityPostsEndpoint}/$postId');
  }

  Future<CommunityLikeResult> toggleLike(int postId) async {
    final data =
        await _api.post('${ApiConstants.communityPostsEndpoint}/$postId/like');
    final map = data as Map<String, dynamic>;
    return CommunityLikeResult(
      postId: map['post_id'] is int
          ? map['post_id'] as int
          : int.tryParse('${map['post_id']}') ?? postId,
      liked: map['liked'] == true,
      likesCount: map['likes_count'] is int
          ? map['likes_count'] as int
          : int.tryParse('${map['likes_count']}') ?? 0,
    );
  }

  Future<bool> setSaved(int postId, {required bool save}) async {
    final url = '${ApiConstants.communityPostsEndpoint}/$postId/save';
    final data = save ? await _api.put(url) : await _api.delete(url);
    if (data is Map<String, dynamic> && data.containsKey('saved')) {
      return data['saved'] == true;
    }
    return save;
  }

  Future<List<CommunityCommentModel>> getComments(
    int postId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final data = await _api.get(
      '${ApiConstants.communityPostsEndpoint}/$postId/comments',
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CommunityCommentModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<CommunityCommentModel> createComment(
    int postId, {
    required String body,
  }) async {
    final data = await _api.post(
      '${ApiConstants.communityPostsEndpoint}/$postId/comments',
      body: {'body': body.trim()},
    );
    return CommunityCommentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteComment(int commentId) async {
    await _api.delete('${ApiConstants.apiV1}/community/comments/$commentId');
  }

  Future<void> reportPost({
    required int postId,
    required String reason,
    String? description,
  }) async {
    await _api.post(
      ApiConstants.communityReportsEndpoint,
      body: {
        'entity_type': 'post',
        'entity_id': postId,
        'reason': reason,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
  }
}
