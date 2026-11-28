import 'package:flutter/material.dart';

import '../../../core/widgets/ceylongo_network_image.dart';
import '../models/community_post_model.dart';
import '../../artisan/services/artisan_demo_service.dart';

/// Community Post Card Widget
/// Displays a modern, responsive travel post with author info, verified provider badges,
/// image with offline fallback, engagement controls (like, comment, save, share),
/// and workshop action for artisan partners.
class CommunityPostCard extends StatefulWidget {
  final CommunityPostModel post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAuthorTap;
  final VoidCallback onMoreOptions;
  final VoidCallback? onWorkshopTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
    required this.onAuthorTap,
    required this.onMoreOptions,
    this.onWorkshopTap,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  double _likeScale = 1.0;
  double _saveScale = 1.0;

  Widget _buildImageFallback() {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF082B5C).withAlpha(190),
            const Color(0xFF073B91).withAlpha(220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.landscape_rounded,
            color: Colors.white30,
            size: 64,
          ),
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.post.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: widget.onAuthorTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEEF4FF),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      post.author.initials,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF073B91),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Author Name, Badge, and Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: widget.onAuthorTap,
                            child: Text(
                              post.author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF082B5C),
                              ),
                            ),
                          ),
                        ),
                        if (post.author.isVerifiedProvider) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF3FC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded, size: 11, color: Color(0xFF073B91)),
                                SizedBox(width: 3),
                                Text(
                                  'Partner',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF073B91),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${post.location} • ${post.timeAgo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More Options Menu Button
              IconButton(
                key: Key('post_options_${post.id}'),
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
                splashRadius: 20,
                onPressed: widget.onMoreOptions,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Post Caption
          Text(
            post.caption,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),

          // Hashtags
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.hashtags.map((tag) {
                return Text(
                  tag,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF073B91),
                  ),
                );
              }).toList(),
            ),
          ],

          // 3. Post Image (only show demo fallback landscape in explicit demo mode)
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: CeylonGoNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ] else if (ArtisanDemoService.isDemoMode) ...[
            const SizedBox(height: 12),
            _buildImageFallback(),
          ],

          // 4. Verified Provider Workshop Callout (if linked to Artisan)
          if (post.author.isVerifiedProvider && post.author.artisanListingId != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF073B91)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF082B5C),
                          ),
                        ),
                        const Text(
                          'Authentic Sri Lankan Artisan Workshop',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    key: Key('view_workshop_${post.id}'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: const Color(0xFF073B91),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: widget.onWorkshopTap ??
                        () => Navigator.pushNamed(context, '/artisan'),
                    icon: const Icon(Icons.explore_rounded, size: 14),
                    label: const Text(
                      'View Workshop',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 5. Engagement Actions Row (Like, Comment, Save, Share)
          Row(
            children: [
              // Like Button
              AnimatedScale(
                scale: _likeScale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                child: GestureDetector(
                  key: Key('post_like_${post.id}'),
                  onTapDown: (_) => setState(() => _likeScale = 0.85),
                  onTapUp: (_) => setState(() => _likeScale = 1.0),
                  onTapCancel: () => setState(() => _likeScale = 1.0),
                  onTap: widget.onLike,
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByDemoUser ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 21,
                        color: post.isLikedByDemoUser ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: post.isLikedByDemoUser ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Comment Button
              GestureDetector(
                key: Key('post_comment_${post.id}'),
                onTap: widget.onComment,
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Save / Bookmark Button
              AnimatedScale(
                scale: _saveScale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                child: GestureDetector(
                  key: Key('post_save_${post.id}'),
                  onTapDown: (_) => setState(() => _saveScale = 0.85),
                  onTapUp: (_) => setState(() => _saveScale = 1.0),
                  onTapCancel: () => setState(() => _saveScale = 1.0),
                  onTap: widget.onSave,
                  child: Icon(
                    post.isSavedByDemoUser ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 22,
                    color: post.isSavedByDemoUser ? const Color(0xFF073B91) : const Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Share Button
              GestureDetector(
                key: Key('post_share_${post.id}'),
                onTap: widget.onShare,
                child: const Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
