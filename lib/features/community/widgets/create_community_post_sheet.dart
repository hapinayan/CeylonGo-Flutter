import 'package:flutter/material.dart';

import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../../auth/models/user_model.dart';
import '../services/community_demo_service.dart';
import '../services/community_service.dart';

/// Create Community Post Modal Bottom Sheet
class CreateCommunityPostSheet extends StatefulWidget {
  final VoidCallback onPostPublished;
  final CommunityService? communityService;
  final UserModel? currentUser;

  const CreateCommunityPostSheet({
    super.key,
    required this.onPostPublished,
    this.communityService,
    this.currentUser,
  });

  @override
  State<CreateCommunityPostSheet> createState() => _CreateCommunityPostSheetState();
}

class _CreateCommunityPostSheetState extends State<CreateCommunityPostSheet> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController(text: 'Ella, Sri Lanka');
  final _demoService = CommunityDemoService();
  late final CommunityService _service;
  bool _isPublishing = false;

  static const List<Map<String, String>> _presetPhotos = [
    {
      'label': 'Ella Train Bridge',
      'url': 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=800',
    },
    {
      'label': 'Galle Fort Artisan',
      'url': 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800',
    },
    {
      'label': 'Sigiriya Sunrise',
      'url': 'https://images.unsplash.com/photo-1588598198321-9735fd52455b?w=800',
    },
    {
      'label': 'Mirissa Coconut Hill',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    },
    {
      'label': 'Jaffna Heritage',
      'url': 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=800',
    },
  ];

  late String _selectedImageUrl;
  final List<String> _selectedHashtags = ['#TravelSriLanka', '#Ella'];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _selectedImageUrl = _presetPhotos[0]['url']!;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onAddHashtag(String tag) {
    if (!_selectedHashtags.contains(tag)) {
      setState(() {
        _selectedHashtags.add(tag);
      });
    }
  }

  void _onRemoveHashtag(String tag) {
    setState(() {
      _selectedHashtags.remove(tag);
    });
  }

  Future<void> _onPublish() async {
    if (_isPublishing) return;
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a caption for your travel post.';
      });
      return;
    }

    if (caption.length > 500) {
      setState(() {
        _errorMessage = 'Caption cannot exceed 500 characters.';
      });
      return;
    }

    if (ArtisanDemoService.isDemoMode) {
      _demoService.addPost(
        caption: caption,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : 'Sri Lanka',
        hashtags: _selectedHashtags,
        imageUrl: _selectedImageUrl,
      );

      widget.onPostPublished();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo post published to For You feed!'),
          backgroundColor: Color(0xFF073B91),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final missingTags = _selectedHashtags
        .where((t) => !caption.toLowerCase().contains(t.toLowerCase()))
        .toList();
    final fullBody =
        missingTags.isEmpty ? caption : '$caption\n${missingTags.join(' ')}';

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    try {
      await _service.createPost(body: fullBody);
      if (!mounted) return;
      widget.onPostPublished();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published to Community feed!'),
          backgroundColor: Color(0xFF073B91),
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _errorMessage = 'Unable to publish post. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Create Community Post',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF082B5C),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info Row
                  Builder(
                    builder: (context) {
                      final isDemo = ArtisanDemoService.isDemoMode;
                      final displayName = isDemo
                          ? 'Demo Traveler'
                          : (widget.currentUser?.fullName ?? 'CeylonGo Traveler');
                      final initials = isDemo
                          ? 'DT'
                          : (displayName.trim().isNotEmpty
                              ? displayName
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .take(2)
                                  .map((p) => p[0].toUpperCase())
                                  .join()
                              : 'CG');
                      return Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEEF4FF),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF073B91),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF082B5C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isDemo
                                      ? 'Sharing to CeylonGo Community (Demo)'
                                      : 'Publishing to live CeylonGo Community',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Caption Input Field
                  TextField(
                    key: const Key('create_post_caption_field'),
                    controller: _captionController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share your Sri Lankan travel story, tips, or experiences...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  if (ArtisanDemoService.isDemoMode) ...[
                    // Location Input Field
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF082B5C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('create_post_location_field'),
                      controller: _locationController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF073B91), size: 20),
                        hintText: 'e.g. Ella, Sri Lanka',
                        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Travel Photo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF082B5C),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (ArtisanDemoService.isDemoMode)
                    SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _presetPhotos.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final photo = _presetPhotos[index];
                        final isSelected = photo['url'] == _selectedImageUrl;

                        return GestureDetector(
                          key: Key('preset_photo_$index'),
                          onTap: () => setState(() => _selectedImageUrl = photo['url']!),
                          child: Container(
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF073B91) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    photo['url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF082B5C),
                                      child: const Icon(Icons.image, color: Colors.white54, size: 24),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      color: const Color(0xFF073B91).withAlpha(80),
                                      child: const Center(
                                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hashtag Tags
                  const Text(
                    'Hashtags',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF082B5C),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._selectedHashtags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 11.5, color: Color(0xFF073B91))),
                            backgroundColor: const Color(0xFFEEF4FF),
                            deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF073B91)),
                            onDeleted: () => _onRemoveHashtag(tag),
                            padding: EdgeInsets.zero,
                          )),
                      ActionChip(
                        label: const Text('+ #Nature', style: TextStyle(fontSize: 11.5)),
                        onPressed: () => _onAddHashtag('#Nature'),
                      ),
                      ActionChip(
                        label: const Text('+ #BeachLife', style: TextStyle(fontSize: 11.5)),
                        onPressed: () => _onAddHashtag('#BeachLife'),
                      ),
                      ActionChip(
                        label: const Text('+ #SriLankanCrafts', style: TextStyle(fontSize: 11.5)),
                        onPressed: () => _onAddHashtag('#SriLankanCrafts'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Publish Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('create_post_publish_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF073B91),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isPublishing ? null : _onPublish,
                      child: _isPublishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Publish Post',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
