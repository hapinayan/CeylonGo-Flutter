import '../../../core/constants/api_constants.dart';

/// CeylonGo Travel Community Author Model
/// Represents community authors (travelers, guides, verified artisan providers).
class CommunityAuthorModel {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;
  final String initials;
  final bool isVerifiedProvider;
  final String? providerBadgeLabel;
  final String bio;
  final String location;
  final int postCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowedByDemoUser;
  final String? artisanListingId;

  const CommunityAuthorModel({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
    required this.initials,
    this.isVerifiedProvider = false,
    this.providerBadgeLabel,
    required this.bio,
    required this.location,
    this.postCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowedByDemoUser = false,
    this.artisanListingId,
  });

  CommunityAuthorModel copyWith({
    String? id,
    String? name,
    String? handle,
    String? avatarUrl,
    String? initials,
    bool? isVerifiedProvider,
    String? providerBadgeLabel,
    String? bio,
    String? location,
    int? postCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowedByDemoUser,
    String? artisanListingId,
  }) {
    return CommunityAuthorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      isVerifiedProvider: isVerifiedProvider ?? this.isVerifiedProvider,
      providerBadgeLabel: providerBadgeLabel ?? this.providerBadgeLabel,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      postCount: postCount ?? this.postCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowedByDemoUser: isFollowedByDemoUser ?? this.isFollowedByDemoUser,
      artisanListingId: artisanListingId ?? this.artisanListingId,
    );
  }

  factory CommunityAuthorModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackName,
    int? fallbackId,
  }) {
    final fullName = (json['full_name'] ?? fallbackName ?? 'Traveler').toString();
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts[0].isEmpty
        ? 'CG'
        : parts.length == 1
            ? parts[0][0].toUpperCase()
            : '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final authorType = json['author_type']?.toString() ?? 'traveler';
    final business = json['provider_business_name']?.toString();
    final district = json['provider_district']?.toString();
    final isVerified = json['is_verified_provider'] == true;
    final idStr = (json['id'] ?? fallbackId ?? '').toString();
    final handleBase =
        fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    return CommunityAuthorModel(
      id: idStr,
      name: (business != null && business.isNotEmpty) ? business : fullName,
      handle: handleBase.isEmpty ? 'traveler$idStr' : handleBase,
      avatarUrl: ApiConstants.resolveMediaUrl(json['avatar_url']?.toString()),
      initials: initials,
      isVerifiedProvider: isVerified,
      providerBadgeLabel:
          isVerified ? 'Verified Partner' : (authorType == 'provider' ? 'Provider' : null),
      bio: (business != null && business.isNotEmpty)
          ? 'Local provider on CeylonGo'
          : 'CeylonGo community explorer',
      location: (district != null && district.isNotEmpty) ? district : 'Sri Lanka',
      artisanListingId: json['provider_profile_id']?.toString(),
    );
  }
}

