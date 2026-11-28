// Strongly typed models and client-side media validation for CeylonGo
// Travel Community FastAPI endpoints (`/api/v1/community/*`).

import 'dart:typed_data';

import '../../../core/constants/api_constants.dart';

class CommunityMediaValidationException implements Exception {
  final String message;
  const CommunityMediaValidationException(this.message);

  @override
  String toString() => message;
}

/// Validates community photos against verified backend limits:
/// - Max 10 photos per post (`DEFAULT_MAX_PHOTOS_PER_POST`)
/// - Max 5 MB per photo (`DEFAULT_MAX_MEDIA_BYTES`)
/// - Allowed formats: JPEG, PNG, WEBP (verified by extension/MIME + magic bytes)
class CommunityMediaValidator {
  static const int maxPhotosPerPost = 10;
  static const int maxFileBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const Set<String> allowedMimeTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  /// Validates bytes, extension/MIME, and magic-byte image signature.
  /// Returns canonical `(extension, mimeType)`.
  static ({String extension, String mimeType}) validate({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      throw const CommunityMediaValidationException(
        'Selected image file is empty.',
      );
    }
    if (bytes.length > maxFileBytes) {
      throw const CommunityMediaValidationException(
        'Image exceeds the 5 MB maximum upload size.',
      );
    }

    final detected = detectImageSignature(bytes);
    if (detected == null) {
      throw const CommunityMediaValidationException(
        'Unsupported or corrupted image. Use a valid JPEG, PNG, or WEBP photo.',
      );
    }

    final cleanName = filename.trim().toLowerCase();
    final dotIndex = cleanName.lastIndexOf('.');
    if (dotIndex != -1) {
      final ext = cleanName.substring(dotIndex);
      if (!allowedExtensions.contains(ext)) {
        throw const CommunityMediaValidationException(
          'Unsupported file extension. Use JPG, PNG, or WEBP.',
        );
      }
    }

    if (mimeType != null && mimeType.trim().isNotEmpty) {
      final normMime = mimeType.trim().toLowerCase();
      if (!allowedMimeTypes.contains(normMime)) {
        throw const CommunityMediaValidationException(
          'Unsupported image MIME type. Use JPEG, PNG, or WEBP.',
        );
      }
    }

    return detected;
  }

  /// Checks JPEG (`FF D8 FF`), PNG (`89 50 4E 47 0D 0A 1A 0A`),
  /// and WEBP (`RIFF....WEBP`) magic bytes without decompressing pixels.
  static ({String extension, String mimeType})? detectImageSignature(
    Uint8List bytes,
  ) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return (extension: '.jpg', mimeType: 'image/jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return (extension: '.png', mimeType: 'image/png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50) {
      // P
      return (extension: '.webp', mimeType: 'image/webp');
    }
    return null;
  }
}

/// Represents a gallery photo selected for upload (and its server-confirmed state).
class SelectedCommunityPhoto {
  final Uint8List bytes;
  final String safeFilename;
  final String mimeType;
  final CommunityApiMedia? uploadedMedia;
  final String? uploadError;

  const SelectedCommunityPhoto({
    required this.bytes,
    required this.safeFilename,
    required this.mimeType,
    this.uploadedMedia,
    this.uploadError,
  });

  bool get isUploaded => uploadedMedia != null;

  SelectedCommunityPhoto copyWith({
    CommunityApiMedia? uploadedMedia,
    String? uploadError,
    bool clearError = false,
  }) {
    return SelectedCommunityPhoto(
      bytes: bytes,
      safeFilename: safeFilename,
      mimeType: mimeType,
      uploadedMedia: uploadedMedia ?? this.uploadedMedia,
      uploadError: clearError ? null : (uploadError ?? this.uploadError),
    );
  }
}

/// Resolves relative backend media paths (e.g. `/api/v1/uploads/community/...`)
/// against [ApiConstants.baseUrl] while leaving absolute `http(s)` URLs intact.
String resolveCommunityMediaUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';
  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) {
    return trimmed;
  }
  final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$path';
}

class CommunityApiMedia {
  final int id;
  final int postId;
  final String mediaType;
  final String mediaUrl;
  final int displayOrder;
  final DateTime? createdAt;

  const CommunityApiMedia({
    required this.id,
    required this.postId,
    required this.mediaType,
    required this.mediaUrl,
    required this.displayOrder,
    this.createdAt,
  });

  String get resolvedUrl => resolveCommunityMediaUrl(mediaUrl);

  factory CommunityApiMedia.fromJson(Map<String, dynamic> json) {
    return CommunityApiMedia(
      id: (json['id'] as num?)?.toInt() ?? 0,
      postId: (json['post_id'] as num?)?.toInt() ?? 0,
      mediaType: (json['media_type'] as String?) ?? 'image',
      mediaUrl: (json['image_url'] as String?) ?? (json['media_url'] as String?) ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class CommunityApiAuthor {
  final int id;
  final String fullName;
  final String role;
  final bool isVerifiedProvider;
  final String? businessName;

  const CommunityApiAuthor({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isVerifiedProvider,
    this.businessName,
  });

  factory CommunityApiAuthor.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CommunityApiAuthor(
        id: 0,
        fullName: 'CeylonGo Traveler',
        role: 'traveler',
        isVerifiedProvider: false,
      );
    }
    return CommunityApiAuthor(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true
          ? (json['full_name'] as String).trim()
          : 'CeylonGo Traveler',
      role: (json['role'] as String?) ?? 'traveler',
      isVerifiedProvider: json['is_verified_provider'] == true,
      businessName: json['business_name'] as String?,
    );
  }
}

class CommunityApiPost {
  final int id;
  final int authorId;
  final CommunityApiAuthor author;
  final String content;
  final String? locationTag;
  final String? district;
  final int likesCount;
  final int commentsCount;
  final bool isPublished;
  final bool isPromotional;
  final bool isFeatured;
  final bool isLiked;
  final bool isSaved;
  final List<CommunityApiMedia> media;
  final List<String> hashtags;
  final DateTime? createdAt;

  const CommunityApiPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.content,
    this.locationTag,
    this.district,
    required this.likesCount,
    required this.commentsCount,
    required this.isPublished,
    required this.isPromotional,
    required this.isFeatured,
    required this.isLiked,
    required this.isSaved,
    required this.media,
    required this.hashtags,
    this.createdAt,
  });

  factory CommunityApiPost.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    if (id == null || id <= 0) {
      throw const FormatException('Missing valid community post ID.');
    }

    final rawMedia = json['media'];
    final mediaList = <CommunityApiMedia>[];
    if (rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map) {
          mediaList.add(
            CommunityApiMedia.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawTags = json['hashtags'];
    final tagsList = <String>[];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is Map && item['tag'] is String) {
          final t = (item['tag'] as String).trim();
          if (t.isNotEmpty) tagsList.add(t.startsWith('#') ? t : '#$t');
        } else if (item is String && item.trim().isNotEmpty) {
          final t = item.trim();
          tagsList.add(t.startsWith('#') ? t : '#$t');
        }
      }
    }

    final rawAuthor = json['author'];
    return CommunityApiPost(
      id: id,
      authorId: (json['author_id'] as num?)?.toInt() ?? 0,
      author: CommunityApiAuthor.fromJson(
        rawAuthor is Map ? Map<String, dynamic>.from(rawAuthor) : null,
      ),
      content: (json['body'] as String?) ?? (json['content'] as String?) ?? '',
      locationTag: json['location_tag'] as String?,
      district: json['district'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isPublished: json['is_published'] != false,
      isPromotional: json['is_promotional'] == true,
      isFeatured: json['is_featured'] == true,
      isLiked: json['is_liked'] == true,
      isSaved: json['is_saved'] == true,
      media: mediaList,
      hashtags: tagsList,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class CommunityApiFeedResponse {
  final List<CommunityApiPost> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasNext;

  const CommunityApiFeedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  factory CommunityApiFeedResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Missing items in community feed response.');
    }
    final items = rawItems
        .whereType<Map>()
        .map((e) => CommunityApiPost.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return CommunityApiFeedResponse(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      hasNext: json['has_next'] == true,
    );
  }
}

