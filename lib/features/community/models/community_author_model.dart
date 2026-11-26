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
}

