import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';
import '../../profile/services/account_service.dart';
import '../../profile/widgets/notifications_sheet.dart';
import '../models/community_post_model.dart';
import '../services/community_demo_service.dart';
import '../services/community_service.dart';
import '../widgets/community_comments_sheet.dart';
import '../widgets/community_notifications_sheet.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_share_dialog.dart';
import '../widgets/create_community_post_sheet.dart';
import '../widgets/trending_hashtags_bar.dart';
import 'community_author_profile_screen.dart';
import 'community_search_screen.dart';

/// CeylonGo Travel Community & Social Feed Screen
class CommunityFeedScreen extends StatefulWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;
  final CommunityService? communityService;
  final AccountService? accountService;
  final bool showBottomNav;

  const CommunityFeedScreen({
    super.key,
    this.authService,
    this.storageService,
    this.communityService,
    this.accountService,
    this.showBottomNav = true,
  });

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  final _demoService = CommunityDemoService();
  late final SecureStorageService _storageService;
  late final CommunityService _service;
  late final AccountService _accountService;
  late final AnimationController _entranceController;

  UserModel? _currentUser;
  List<CommunityPostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadNotifications = 0;

  int _selectedTabIndex = 0; // 0: For You, 1: My Posts/Following, 2: Saved
  String _selectedHashtag = '#All';
  double _composeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? SecureStorageService();
    _service = widget.communityService ?? CommunityService();
    _accountService = widget.accountService ?? AccountService(storageService: _storageService);
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadInitialData();

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

  Future<void> _loadInitialData() async {
    try {
      final user = await _storageService.getUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (_) {}

    if (!ArtisanDemoService.isDemoMode) {
      await Future.wait([
        _loadPosts(),
        _loadUnreadNotifications(),
      ]);
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final hasToken = await _storageService.hasToken();
      if (!hasToken) return;
      final count = await _accountService.getUnreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _loadPosts() async {
    if (ArtisanDemoService.isDemoMode) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<CommunityPostModel> fetched;
      if (_selectedTabIndex == 1) {
        fetched = await _service.getMyPosts();
      } else if (_selectedTabIndex == 2) {
        fetched = await _service.getSavedPosts();
      } else {
        fetched = await _service.getFeed();
      }
      if (!mounted) return;
      setState(() {
        _posts = fetched;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load community posts. Please try again.';
      });
    }
  }

  List<CommunityPostModel> _getCurrentFeedPosts() {
    if (ArtisanDemoService.isDemoMode) {
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

    if (_selectedHashtag == '#All') {
      return _posts;
    }
    final q = _selectedHashtag.toLowerCase();
    return _posts.where((p) {
      final inTags = p.hashtags.any((t) => t.toLowerCase() == q);
      final inBody = p.caption.toLowerCase().contains(q);
      return inTags || inBody;
    }).toList();
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
    if (!ArtisanDemoService.isDemoMode) {
      _loadPosts();
    }
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
      MaterialPageRoute(
        builder: (_) => CommunitySearchScreen(communityService: _service),
      ),
    ).then((_) {
      if (ArtisanDemoService.isDemoMode) {
        setState(() {});
      } else {
        _loadPosts();
      }
    });
  }

  Future<void> _onOpenNotifications() async {
    if (ArtisanDemoService.isDemoMode) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CommunityNotificationsSheet(),
      );
      return;
    }

    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view notifications.')),
        );
      }
      return;
    }
    if (!mounted) return;
    await showNotificationsSheet(
      context,
      accountService: _accountService,
      onUpdated: _loadUnreadNotifications,
    );
  }

  void _onOpenAuthorProfile(CommunityPostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityAuthorProfileScreen(
          authorId: post.author.id,
          initialAuthor: post.author,
          communityService: _service,
        ),
      ),
    ).then((_) {
      if (ArtisanDemoService.isDemoMode) {
        setState(() {});
      } else {
        _loadPosts();
      }
    });
  }

  void _onOpenComments(CommunityPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommunityCommentsSheet(
        postId: post.id,
        initialComments: post.comments,
        communityService: _service,
        currentUserId: _currentUser?.id,
        onCommentsCountChanged: (count) {
          setState(() {
            _posts = _posts
                .map((p) => p.id == post.id ? p.copyWith(commentsCount: count) : p)
                .toList();
          });
        },
      ),
    );
  }

  Future<void> _onOpenCreatePost() async {
    if (!ArtisanDemoService.isDemoMode) {
      final hasToken = await _storageService.hasToken();
      if (!hasToken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to publish a post.')),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCommunityPostSheet(
        communityService: _service,
        currentUser: _currentUser,
        onPostPublished: () {
          setState(() {
            _selectedTabIndex = 0;
            _selectedHashtag = '#All';
          });
          if (!ArtisanDemoService.isDemoMode) {
            _loadPosts();
          }
        },
      ),
    );
  }

  void _onPostMoreOptions(CommunityPostModel post) {
    final isOwnPost = ArtisanDemoService.isDemoMode
        ? post.author.id == CommunityDemoService.currentUserId
        : (_currentUser != null && _currentUser!.id == post.author.id);

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
              if (ArtisanDemoService.isDemoMode)
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
            onPressed: () async {
              final nextBody = controller.text.trim();
              Navigator.pop(ctx);
              if (nextBody.isEmpty) return;
              if (ArtisanDemoService.isDemoMode) {
                _demoService.editPost(post.id, nextBody);
                setState(() {});
                return;
              }
              final idInt = int.tryParse(post.id);
              if (idInt == null) return;
              try {
                final updated = await _service.updatePost(idInt, body: nextBody);
                if (!mounted) return;
                setState(() {
                  _posts = _posts.map((p) => p.id == post.id ? updated : p).toList();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated!'), duration: Duration(seconds: 2)),
                );
              } on ApiError catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
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
            onPressed: () async {
              Navigator.pop(ctx);
              if (ArtisanDemoService.isDemoMode) {
                _demoService.deletePost(post.id);
                setState(() {});
                return;
              }
              final idInt = int.tryParse(post.id);
              if (idInt == null) return;
              try {
                await _service.deletePost(idInt);
                if (!mounted) return;
                setState(() {
                  _posts.removeWhere((p) => p.id == post.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted.'), duration: Duration(seconds: 2)),
                );
              } on ApiError catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (ArtisanDemoService.isDemoMode) {
                    _demoService.reportPost(post.id, r);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you. This demo report has been recorded locally.'),
                        backgroundColor: Color(0xFF073B91),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  final idInt = int.tryParse(post.id);
                  if (idInt == null) return;
                  try {
                    await _service.reportPost(postId: idInt, reason: r);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted for moderation review.'),
                        backgroundColor: Color(0xFF073B91),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } on ApiError catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_errorMessage!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _loadPosts,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : posts.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  if (ArtisanDemoService.isDemoMode) {
                                    setState(() {});
                                  } else {
                                    await _loadPosts();
                                  }
                                },
                                color: const Color(0xFF073B91),
                                child: ListView.builder(
                                  key: const Key('community_feed_list'),
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.only(bottom: 80.0),
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    final post = posts[index];
                                    return CommunityPostCard(
                                      post: post,
                                      onLike: () async {
                                        if (ArtisanDemoService.isDemoMode) {
                                          _demoService.toggleLike(post.id);
                                          setState(() {});
                                          return;
                                        }
                                        final idInt = int.tryParse(post.id);
                                        if (idInt == null) return;
                                        try {
                                          final res = await _service.toggleLike(idInt);
                                          if (!mounted) return;
                                          setState(() {
                                            _posts = _posts
                                                .map((p) => p.id == post.id
                                                    ? p.copyWith(
                                                        isLikedByDemoUser: res.liked,
                                                        likesCount: res.likesCount,
                                                      )
                                                    : p)
                                                .toList();
                                          });
                                        } on ApiError catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.message)),
                                          );
                                        }
                                      },
                                      onSave: () async {
                                        if (ArtisanDemoService.isDemoMode) {
                                          _demoService.toggleSave(post.id);
                                          setState(() {});
                                          return;
                                        }
                                        final idInt = int.tryParse(post.id);
                                        if (idInt == null) return;
                                        try {
                                          final nextSaved = await _service.setSaved(
                                            idInt,
                                            save: !post.isSavedByDemoUser,
                                          );
                                          if (!mounted) return;
                                          setState(() {
                                            if (_selectedTabIndex == 2 && !nextSaved) {
                                              _posts.removeWhere((p) => p.id == post.id);
                                            } else {
                                              _posts = _posts
                                                  .map((p) => p.id == post.id
                                                      ? p.copyWith(
                                                          isSavedByDemoUser: nextSaved,
                                                        )
                                                      : p)
                                                  .toList();
                                            }
                                          });
                                        } on ApiError catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.message)),
                                          );
                                        }
                                      },
                                      onComment: () => _onOpenComments(post),
                                      onShare: () => CommunityShareDialog.show(context, post),
                                      onAuthorTap: () => _onOpenAuthorProfile(post),
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
                    if (_unreadNotifications > 0 || ArtisanDemoService.isDemoMode)
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
                  child: Center(
                    child: Text(
                      ArtisanDemoService.isDemoMode
                          ? 'DT'
                          : (_currentUser != null &&
                                  _currentUser!.fullName.trim().isNotEmpty
                              ? _currentUser!.fullName
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .take(2)
                                  .map((p) => p[0].toUpperCase())
                                  .join()
                              : 'CG'),
                      style: const TextStyle(
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

  /// Feed Navigation Tabs: For You, My Posts (Following in Demo), Saved
  Widget _buildFeedTabs() {
    final tabs = ArtisanDemoService.isDemoMode
        ? ['For You', 'Following', 'Saved']
        : ['For You', 'My Posts', 'Saved'];

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
      title = ArtisanDemoService.isDemoMode
          ? 'No posts from followed accounts'
          : 'You have not published any posts yet';
      description = ArtisanDemoService.isDemoMode
          ? 'Follow Sri Lankan travelers or verified artisan workshops to see their stories here!'
          : 'Tap the compose button below to share your Sri Lankan travel tips with the community!';
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
