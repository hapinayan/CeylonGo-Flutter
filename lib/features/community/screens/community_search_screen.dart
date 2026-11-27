import 'package:flutter/material.dart';

import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../models/community_post_model.dart';
import '../services/community_demo_service.dart';
import '../services/community_service.dart';
import '../widgets/community_comments_sheet.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_share_dialog.dart';
import 'community_author_profile_screen.dart';

/// Community Search Screen
class CommunitySearchScreen extends StatefulWidget {
  final CommunityService? communityService;

  const CommunitySearchScreen({super.key, this.communityService});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final _searchController = TextEditingController();
  final _demoService = CommunityDemoService();
  late final CommunityService _service;
  List<CommunityPostModel> _searchResults = [];
  String _activeQuery = '';
  bool _isLoading = false;
  String? _error;

  static const List<String> _suggestedChips = [
    'Ella',
    'Galle',
    'Sigiriya',
    '#Artisan',
    '#Nature',
    '#BeachLife',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    _activeQuery = query;
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        _searchResults = _demoService.getForYouPosts(searchQuery: query);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _service.getFeed(search: query.trim());
      if (!mounted) return;
      setState(() {
        _searchResults = list;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Search failed. Please try again.';
      });
    }
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
        onCommentsCountChanged: (count) {
          setState(() {
            _searchResults = _searchResults
                .map((p) => p.id == post.id ? p.copyWith(commentsCount: count) : p)
                .toList();
          });
        },
      ),
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
    ).then((_) => _performSearch(_activeQuery));
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    if (ArtisanDemoService.isDemoMode) {
      _demoService.toggleLike(post.id);
      _performSearch(_activeQuery);
      return;
    }
    final idInt = int.tryParse(post.id);
    if (idInt == null) return;
    try {
      final res = await _service.toggleLike(idInt);
      if (!mounted) return;
      setState(() {
        _searchResults = _searchResults
            .map(
              (p) => p.id == post.id
                  ? p.copyWith(
                      isLikedByDemoUser: res.liked,
                      likesCount: res.likesCount,
                    )
                  : p,
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _toggleSave(CommunityPostModel post) async {
    if (ArtisanDemoService.isDemoMode) {
      _demoService.toggleSave(post.id);
      _performSearch(_activeQuery);
      return;
    }
    final idInt = int.tryParse(post.id);
    if (idInt == null) return;
    try {
      final next = await _service.setSaved(idInt, save: !post.isSavedByDemoUser);
      if (!mounted) return;
      setState(() {
        _searchResults = _searchResults
            .map(
              (p) => p.id == post.id ? p.copyWith(isSavedByDemoUser: next) : p,
            )
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('community_search_back_btn'),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF082B5C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            key: const Key('community_search_input'),
            controller: _searchController,
            autofocus: true,
            onChanged: _performSearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF073B91), size: 20),
              suffixIcon: _activeQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              hintText: 'Search posts, places, or hashtags...',
              hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggested search chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _suggestedChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    key: Key('search_chip_${chip.replaceAll('#', '').toLowerCase()}'),
                    label: Text(chip, style: const TextStyle(fontSize: 12, color: Color(0xFF073B91))),
                    backgroundColor: const Color(0xFFEEF4FF),
                    onPressed: () {
                      _searchController.text = chip;
                      _performSearch(chip);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Search results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _performSearch(_activeQuery),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(
                                  'No results found for "$_activeQuery"',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try searching for Ella, Galle, Sigiriya, or #Artisan',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final post = _searchResults[index];
                              return CommunityPostCard(
                                post: post,
                                onLike: () => _toggleLike(post),
                                onSave: () => _toggleSave(post),
                                onComment: () => _onOpenComments(post),
                                onShare: () => CommunityShareDialog.show(context, post),
                                onAuthorTap: () => _onOpenAuthorProfile(post),
                                onMoreOptions: () {},
                                onWorkshopTap: () => Navigator.pushNamed(context, '/artisan'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

