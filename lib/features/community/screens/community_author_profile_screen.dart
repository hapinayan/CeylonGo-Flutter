import 'package:flutter/material.dart';

import '../models/community_author_model.dart';
import '../models/community_post_model.dart';
import '../services/community_demo_service.dart';
import '../widgets/community_post_card.dart';

/// Community Author Profile Screen
/// Displays the public community profile of a traveler or verified provider
/// with their bio, followers, follow action, and authored travel posts.
class CommunityAuthorProfileScreen extends StatefulWidget {
  final String authorId;

  const CommunityAuthorProfileScreen({
    super.key,
    required this.authorId,
  });

  @override
  State<CommunityAuthorProfileScreen> createState() => _CommunityAuthorProfileScreenState();
}

class _CommunityAuthorProfileScreenState extends State<CommunityAuthorProfileScreen> {
  final _demoService = CommunityDemoService();
  late CommunityAuthorModel? _author;
  late List<CommunityPostModel> _authorPosts;

  @override
  void initState() {
    super.initState();
    _loadAuthorData();
  }

  void _loadAuthorData() {
    setState(() {
      _author = _demoService.getAuthor(widget.authorId);
      _authorPosts = _demoService.getPostsByAuthor(widget.authorId);
    });
  }

  void _onToggleFollow() {
    if (_author == null) return;
    _demoService.toggleFollow(_author!.id);
    _loadAuthorData();
  }

  @override
  Widget build(BuildContext context) {
    if (_author == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Author Profile')),
        body: const Center(child: Text('Author not found')),
      );
    }

    final author = _author!;
    final isCurrentUser = author.id == CommunityDemoService.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('author_profile_back_btn'),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF082B5C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          author.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 16.5,
            color: Color(0xFF082B5C),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Profile Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEEF4FF),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        author.initials,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF073B91),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name & Handle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        author.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF082B5C),
                        ),
                      ),
                      if (author.isVerifiedProvider) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF073B91)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author.handle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF073B91)),
                      const SizedBox(width: 4),
                      Text(
                        author.location,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Bio
                  Text(
                    author.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Statistics Row (Posts, Followers, Following)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Posts', '${_authorPosts.length}'),
                      Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildStatColumn('Followers', '${author.followersCount}'),
                      Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildStatColumn('Following', '${author.followingCount}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Follow / Following Action Button
                  if (!isCurrentUser)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        key: const Key('author_follow_toggle_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: author.isFollowedByDemoUser
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF073B91),
                          foregroundColor: author.isFollowedByDemoUser
                              ? const Color(0xFF082B5C)
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _onToggleFollow,
                        child: Text(
                          author.isFollowedByDemoUser ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),

            // Posts Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF073B91)),
                  const SizedBox(width: 8),
                  Text(
                    'Posts (${_authorPosts.length})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF082B5C),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Author Posts List
            if (_authorPosts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Text(
                    'No posts shared yet.',
                    style: TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _authorPosts.length,
                itemBuilder: (context, index) {
                  final post = _authorPosts[index];
                  return CommunityPostCard(
                    post: post,
                    onLike: () {
                      _demoService.toggleLike(post.id);
                      _loadAuthorData();
                    },
                    onSave: () {
                      _demoService.toggleSave(post.id);
                      _loadAuthorData();
                    },
                    onComment: () {},
                    onShare: () {},
                    onAuthorTap: () {},
                    onMoreOptions: () {},
                    onWorkshopTap: () => Navigator.pushNamed(context, '/artisan'),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF082B5C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

