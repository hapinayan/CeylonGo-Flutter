import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../auth/models/api_error.dart';
import '../../auth/services/auth_service.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';
import '../models/community_api_models.dart';
import '../models/community_author_model.dart';
import '../models/community_post_model.dart';
import '../services/community_api_service.dart';
import '../services/community_demo_service.dart';
import '../services/community_photo_picker.dart';
import '../widgets/community_comments_sheet.dart';
import '../widgets/community_notifications_sheet.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_share_dialog.dart';
import '../widgets/create_community_post_sheet.dart';
import '../widgets/trending_hashtags_bar.dart';
import 'community_author_profile_screen.dart';
import 'community_search_screen.dart';

/// CeylonGo Travel Community & Social Feed Screen
/// Primary mobile community interface matching the approved reference design.
/// Features:
/// 1. White Header with CeylonGo branding, Community heading, Search, Notifications, Profile avatar
/// 2. Three Feed Tabs: For You, Following, Saved with royal blue pill selector
/// 3. Scrollable Trending Hashtags Bar (#Jaffna, #Ella, #TravelSriLanka, etc.)
/// 4. Rich Community Post Cards with offline likes, comments, bookmarks, and sharing
/// 5. Floating Royal-Blue Compose Button for creating demo posts
/// 6. Reused HomeBottomNavigationBar with Community tab (index 3) active
class CommunityFeedScreen extends StatefulWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;
  final CommunityApiService? apiService;
  final CommunityPhotoPicker? photoPicker;
  final String? realAuthToken;
  final bool showBottomNav;

  const CommunityFeedScreen({
    super.key,
    this.authService,
    this.storageService,
    this.apiService,
    this.photoPicker,
    this.realAuthToken,
    this.showBottomNav = true,
  });

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  final _demoService = CommunityDemoService();
  late final AnimationController _entranceController;

  int _selectedTabIndex = 0; // 0: For You, 1: Following, 2: Saved
  String _selectedHashtag = '#All';
  double _composeScale = 1.0;

  late final CommunityApiService _apiService;
  String? _activeAuthToken;
  bool _isLoadingRealFeed = false;
  String? _realFeedError;
  List<CommunityPostModel> _realPosts = const [];

  bool get _isRealMode {
    final t = _activeAuthToken?.trim();
    return t != null && t.isNotEmpty && !t.startsWith('demo-');
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CommunityApiService();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final initialToken = widget.realAuthToken?.trim();
    if (initialToken != null &&
        initialToken.isNotEmpty &&
        !initialToken.startsWith('demo-')) {
      _activeAuthToken = initialToken;
      _loadRealFeed();
    } else if (widget.storageService != null) {
      _resolveStoredTravelerSession();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (MediaQuery.of(context).disableAnimations) {
          _entranceController.value = 1.0;
        } else {
          _entranceController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _resolveStoredTravelerSession() async {
    try {
      final token = await widget.storageService!.getToken();
      final user = await widget.storageService!.getUser();
      if (!mounted) return;
      if (token != null &&
          token.trim().isNotEmpty &&
          !token.startsWith('demo-') &&
          user?.role != 'provider') {
        setState(() {
          _activeAuthToken = token.trim();
        });
        await _loadRealFeed();
      }
    } catch (_) {
      // Remain in Demo Community Mode if storage cannot be read.
    }
  }

  Future<void> _loadRealFeed() async {
    if (!_isRealMode) return;
    setState(() {
      _isLoadingRealFeed = true;
      _realFeedError = null;
    });
    try {
      final res = await _apiService.getFeed(
        authToken: _activeAuthToken,
        followingOnly: _selectedTabIndex == 1,
        hashtag: _selectedHashtag,
      );
      if (!mounted) return;
      setState(() {
        _isLoadingRealFeed = false;
        _realPosts = res.items.map(_mapApiPost).toList();
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRealFeed = false;
        _realFeedError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRealFeed = false;
        _realFeedError = 'Unable to load community feed right now.';
      });
    }
  }

  CommunityPostModel _mapApiPost(CommunityApiPost post) {
    final name = post.author.fullName;
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : 'T');

    return CommunityPostModel(
      id: post.id.toString(),
      author: CommunityAuthorModel(
        id: post.authorId.toString(),
        name: name,
        handle: name.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        initials: initials,
        isVerifiedProvider: post.author.isVerifiedProvider,
        providerBadgeLabel: post.author.businessName,
        bio: '',
        location: post.district ?? post.locationTag ?? 'Sri Lanka',
        followersCount: 0,
        followingCount: 0,
        postCount: 0,
      ),
      caption: post.content,
      hashtags: post.hashtags,
      location: post.locationTag ?? post.district ?? 'Sri Lanka',
      imageUrl: post.media.isNotEmpty ? post.media.first.resolvedUrl : null,
      createdAt: post.createdAt ?? DateTime.now(),
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      isLikedByDemoUser: post.isLiked,
      isSavedByDemoUser: post.isSaved,
    );
  }

  List<CommunityPostModel> _getCurrentFeedPosts() {
    if (_isRealMode) {
      return _realPosts;
    }
    switch (_selectedTabIndex) {
      case 0:
        return _demoService.getForYouPosts(hashtagFilter: _selectedHashtag);
      case 1:
        return _demoService.getFollowingPosts(hashtagFilter: _selectedHashtag);
      case 2:
        return _demoService.getSavedPosts(hashtagFilter: _selectedHashtag);
      default:
        return _demoService.getForYouPosts();
    }
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onHashtagSelected(String tag) {
    setState(() {
      if (_selectedHashtag.toLowerCase() == tag.toLowerCase() && tag != '#All') {
        _selectedHashtag = '#All';
      } else {
        _selectedHashtag = tag;
      }
    });
  }

  void _onOpenSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunitySearchScreen()),
    ).then((_) => setState(() {}));
  }

  void _onOpenNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommunityNotificationsSheet(),
    );
  }

  void _onOpenAuthorProfile(String authorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityAuthorProfileScreen(authorId: authorId),
      ),
    ).then((_) => setState(() {}));
  }

  void _onOpenComments(CommunityPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommunityCommentsSheet(
        postId: post.id,
        initialComments: post.comments,
        onCommentsCountChanged: (_) => setState(() {}),
      ),
    );
  }

  void _onOpenCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCommunityPostSheet(
        authToken: _activeAuthToken,
        apiService: _apiService,
        photoPicker: widget.photoPicker,
        onRealPostPublished: (_) {
          _loadRealFeed();
        },
        onPostPublished: () {
          setState(() {
            _selectedTabIndex = 0; // Switch to For You feed to see new post immediately
            _selectedHashtag = '#All';
          });
          if (_isRealMode) {
            _loadRealFeed();
          }
        },
      ),
    );
  }

  void _onPostMoreOptions(CommunityPostModel post) {
    final isOwnPost = post.author.id == CommunityDemoService.currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            if (isOwnPost) ...[
              ListTile(
                key: const Key('menu_edit_post'),
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF073B91)),
                title: const Text('Edit Caption', style: TextStyle(fontFamily: 'Inter')),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditCaptionDialog(post);
                },
              ),
              ListTile(
                key: const Key('menu_delete_post'),
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                title: const Text('Delete Post', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(post);
                },
              ),
            ] else ...[
              ListTile(
                key: const Key('menu_toggle_follow'),
                leading: Icon(
                  _demoService.isFollowing(post.author.id)
                      ? Icons.person_remove_outlined
                      : Icons.person_add_alt_1_outlined,
                  color: const Color(0xFF073B91),
                ),
                title: Text(
                  _demoService.isFollowing(post.author.id)
                      ? 'Unfollow @${post.author.handle}'
                      : 'Follow @${post.author.handle}',
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _demoService.toggleFollow(post.author.id);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _demoService.isFollowing(post.author.id)
                            ? 'Now following ${post.author.name}'
                            : 'Unfollowed ${post.author.name}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                key: const Key('menu_report_post'),
                leading: const Icon(Icons.flag_outlined, color: Color(0xFFDC2626)),
                title: const Text('Report Post', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog(post);
                },
              ),
              ListTile(
                key: const Key('menu_share_post'),
                leading: const Icon(Icons.share_outlined, color: Color(0xFF073B91)),
                title: const Text('Share Post', style: TextStyle(fontFamily: 'Inter')),
                onTap: () {
                  Navigator.pop(ctx);
                  CommunityShareDialog.show(context, post);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditCaptionDialog(CommunityPostModel post) {
    final controller = TextEditingController(text: post.caption);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Caption', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Update your post caption...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF073B91), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _demoService.editPost(post.id, controller.text);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post caption updated!'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePost(CommunityPostModel post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this travel post? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _demoService.deletePost(post.id);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted from demo feed.'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(CommunityPostModel post) {
    final reasons = ['Spam or misleading', 'Harassment or hate speech', 'Inappropriate imagery', 'False information'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Report Post', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        children: reasons
            .map(
              (r) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(ctx);
                  _demoService.reportPost(post.id, r);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you. This demo report has been recorded locally.'),
                      backgroundColor: Color(0xFF073B91),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(r, style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _onBottomNavSelected(int index) {
    if (index == 3) return; // Already on Community

    if (index == 0) {
      // Home
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } else if (index == 1) {
      // Explore -> /artisan
      Navigator.pushReplacementNamed(context, '/artisan');
    } else if (index == 2) {
      // AI Planner -> /ai-planner
      Navigator.pushReplacementNamed(context, '/ai-planner');
    } else if (index == 4) {
      // Profile
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _getCurrentFeedPosts();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 1. White Community Header
              _buildHeader(context),

              const SizedBox(height: 10),

              // 2. Feed Navigation Tabs (For You, Following, Saved)
              _buildFeedTabs(),

              const SizedBox(height: 12),

              // 3. Trending Hashtags Bar
              TrendingHashtagsBar(
                hashtags: CommunityDemoService.trendingHashtags,
                selectedHashtag: _selectedHashtag,
                onHashtagSelected: _onHashtagSelected,
              ),

              const SizedBox(height: 8),

              // 4. Community Posts Feed
              Expanded(
                child: _isRealMode && _isLoadingRealFeed && posts.isEmpty
                    ? const Center(
                        key: Key('community_real_loading'),
                        child: CircularProgressIndicator(
                          color: Color(0xFF073B91),
                        ),
                      )
                    : _isRealMode && _realFeedError != null && posts.isEmpty
                        ? Center(
                            key: const Key('community_real_error'),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _realFeedError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _loadRealFeed,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : posts.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  if (_isRealMode) {
                                    await _loadRealFeed();
                                  } else {
                                    setState(() {});
                                  }
                                },
                        color: const Color(0xFF073B91),
                        child: ListView.builder(
                          key: const Key('community_feed_list'),
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80.0),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return CommunityPostCard(
                              post: post,
                              onLike: () {
                                _demoService.toggleLike(post.id);
                                setState(() {});
                              },
                              onSave: () {
                                _demoService.toggleSave(post.id);
                                setState(() {});
                              },
                              onComment: () => _onOpenComments(post),
                              onShare: () => CommunityShareDialog.show(context, post),
                              onAuthorTap: () => _onOpenAuthorProfile(post.author.id),
                              onMoreOptions: () => _onPostMoreOptions(post),
                              onWorkshopTap: () => Navigator.pushNamed(context, '/artisan'),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),

        // 5. Floating Royal-Blue Compose Post Button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: AnimatedScale(
            scale: _composeScale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              key: const Key('community_create_post_btn'),
              onTapDown: (_) => setState(() => _composeScale = 0.90),
              onTapUp: (_) => setState(() => _composeScale = 1.0),
              onTapCancel: () => setState(() => _composeScale = 1.0),
              onTap: _onOpenCreatePost,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF073B91),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF073B91).withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // 6. Bottom Navigation Bar with Community tab highlighted (index 3)
        bottomNavigationBar: widget.showBottomNav
            ? HomeBottomNavigationBar(
                currentIndex: 3,
                onTabSelected: _onBottomNavSelected,
              )
            : null,
      ),
    );
  }

  /// White Community Header
  /// Left: CeylonGo brand text + divider + "Community" heading
  /// Right: Search, Notification bell with badge dot, and Profile avatar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Left: Brand + Community Title with auto scale-down for narrow viewports
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CeylonGo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF082B5C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 18,
                    width: 1.5,
                    color: const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Community',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073B91),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Controls: Search, Notification bell, Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Icon Button
              IconButton(
                key: const Key('community_search_btn'),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                icon: const Icon(Icons.search_rounded, color: Color(0xFF082B5C), size: 22),
                splashRadius: 20,
                onPressed: _onOpenSearch,
              ),

              // Notification Bell with Indicator Dot
              IconButton(
                key: const Key('community_notifications_btn'),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                splashRadius: 20,
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF082B5C),
                      size: 22,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF073B91),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: _onOpenNotifications,
              ),

              const SizedBox(width: 4),

              // Circular Profile Avatar -> /profile
              GestureDetector(
                key: const Key('community_profile_avatar'),
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEEF4FF),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'DT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF073B91),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Feed Navigation Tabs: For You, Following, Saved
  /// Selected tab styled as royal blue pill with white text
  Widget _buildFeedTabs() {
    final tabs = ['For You', 'Following', 'Saved'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            final keyName = index == 0
                ? 'tab_for_you'
                : index == 1
                    ? 'tab_following'
                    : 'tab_saved';

            return Expanded(
              child: GestureDetector(
                key: Key(keyName),
                onTap: () => _onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF073B91) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF073B91).withAlpha(40),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Empty State for Following / Saved when filtered or empty
  Widget _buildEmptyState() {
    String title = 'No posts found';
    String description = 'Try selecting another hashtag or check back later.';
    IconData icon = Icons.feed_outlined;

    if (_selectedTabIndex == 1) {
      title = 'No posts from followed accounts';
      description = 'Follow Sri Lankan travelers or verified artisan workshops to see their stories here!';
      icon = Icons.people_outline_rounded;
    } else if (_selectedTabIndex == 2) {
      title = 'No saved posts yet';
      description = 'Tap the bookmark icon on any community post to save travel tips and recommendations!';
      icon = Icons.bookmark_border_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF082B5C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (_selectedHashtag != '#All') ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => _onHashtagSelected('#All'),
                child: const Text('Clear Hashtag Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
