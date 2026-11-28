import 'package:flutter/material.dart';

import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../models/community_api_models.dart';
import '../services/community_api_service.dart';
import '../services/community_demo_service.dart';
import '../services/community_photo_picker.dart';

/// Create Community Post Modal Bottom Sheet.
///
/// Supports two cleanly isolated modes:
/// 1. **Real Community Mode** (`authToken` is a real non-demo JWT):
///    Uses device gallery selection, magic-byte/size validation, real
///    `POST /api/v1/community/posts`, and sequential multipart uploads to
///    `POST /api/v1/community/posts/{post_id}/media` with partial-success
///    recovery and retry without duplicate post creation.
/// 2. **Demo Community Mode** (no real JWT):
///    Preserves existing `CommunityDemoService` offline demo posting.
class CreateCommunityPostSheet extends StatefulWidget {
  final VoidCallback onPostPublished;
  final String? authToken;
  final CommunityApiService? apiService;
  final CommunityPhotoPicker? photoPicker;
  final void Function(CommunityApiPost createdPost)? onRealPostPublished;

  const CreateCommunityPostSheet({
    super.key,
    required this.onPostPublished,
    this.authToken,
    this.apiService,
    this.photoPicker,
    this.onRealPostPublished,
  });

  @override
  State<CreateCommunityPostSheet> createState() =>
      _CreateCommunityPostSheetState();
}

class _CreateCommunityPostSheetState extends State<CreateCommunityPostSheet> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _demoService = CommunityDemoService();

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

  // Real Community Mode state
  late final CommunityApiService _apiService;
  late final CommunityPhotoPicker _photoPicker;
  final List<SelectedCommunityPhoto> _selectedPhotos = [];
  List<String> _pickerWarnings = const [];
  bool _isSubmitting = false;
  int? _createdPostId;
  String? _partialSuccessMessage;

  bool get _isRealMode {
    final token = widget.authToken?.trim();
    return token != null && token.isNotEmpty && !token.startsWith('demo-');
  }

  @override
  void initState() {
    super.initState();
    if (!_isRealMode) _locationController.text = 'Ella, Sri Lanka';
    _selectedImageUrl = _presetPhotos[0]['url']!;
    _apiService = widget.apiService ?? CommunityApiService();
    _photoPicker = widget.photoPicker ?? CommunityPhotoPicker();
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

  Future<void> _pickGalleryPhotos() async {
    if (_isSubmitting) return;
    final remaining =
        CommunityMediaValidator.maxPhotosPerPost - _selectedPhotos.length;
    if (remaining <= 0) {
      setState(() {
        _pickerWarnings = const ['Maximum of 10 photos per post reached.'];
      });
      return;
    }

    try {
      final result = await _photoPicker.pickFromGallery(maxRemaining: remaining);
      if (!mounted) return;
      setState(() {
        _selectedPhotos.addAll(result.accepted);
        _pickerWarnings = result.warnings;
        _errorMessage = null;
      });
    } on CommunityMediaValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _pickerWarnings = [e.message];
      });
    }
  }

  Future<void> _replacePhoto(int index) async {
    if (_isSubmitting || _selectedPhotos[index].isUploaded) return;
    try {
      final replacement = await _photoPicker.pickSingleReplacement();
      if (!mounted || replacement == null) return;
      setState(() {
        _selectedPhotos[index] = replacement;
        _pickerWarnings = const [];
      });
    } on CommunityMediaValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _pickerWarnings = [e.message];
      });
    }
  }

  void _removePhoto(int index) {
    if (_isSubmitting || _selectedPhotos[index].isUploaded) return;
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _previewPhoto(SelectedCommunityPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        key: const Key('community_photo_preview_dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.memory(
                photo.bytes,
                fit: BoxFit.contain,
                height: 300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      photo.safeFilename,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF082B5C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPublish() {
    if (_isRealMode) {
      _onPublishReal();
      return;
    }

    if (!ArtisanDemoService.isDemoMode) {
      setState(() => _errorMessage = 'Please sign in to publish a post.');
      return;
    }

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
  }

  Future<void> _onPublishReal() async {
    if (_isSubmitting) return;

    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a caption for your travel post.';
      });
      return;
    }
    if (caption.length > 2000) {
      setState(() {
        _errorMessage = 'Caption cannot exceed 2000 characters.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _partialSuccessMessage = null;
    });

    final token = widget.authToken!.trim();

    try {
      // Step 1: Create post only if not already created during this flow.
      CommunityApiPost? latestPost;
      if (_createdPostId == null) {
        final created = await _apiService.createPost(
          authToken: token,
          content: caption,
          locationTag: _locationController.text.trim(),
          hashtags: _selectedHashtags,
        );
        if (!mounted) return;
        _createdPostId = created.id;
        latestPost = created;
      }

      // Step 2: Upload any remaining un-uploaded photos sequentially.
      for (var i = 0; i < _selectedPhotos.length; i++) {
        final photo = _selectedPhotos[i];
        if (photo.isUploaded) continue;

        try {
          final uploaded = await _apiService.uploadPostMedia(
            authToken: token,
            postId: _createdPostId!,
            photo: photo,
          );
          if (!mounted) return;
          setState(() {
            _selectedPhotos[i] = photo.copyWith(
              uploadedMedia: uploaded,
              clearError: true,
            );
          });
        } on ApiError catch (e) {
          if (!mounted) return;
          setState(() {
            _selectedPhotos[i] = photo.copyWith(uploadError: e.message);
            _isSubmitting = false;
            _partialSuccessMessage =
                'Post #$_createdPostId was created, but photo upload failed (${e.message}). Retry failed uploads without creating a duplicate post.';
          });
          return;
        }
      }

      // Step 3: Fetch confirmed post state when possible.
      try {
        latestPost = await _apiService.getPost(
          postId: _createdPostId!,
          authToken: token,
        );
      } catch (_) {
        // Fallback to created post if refresh fails after successful upload.
      }

      if (!mounted) return;
      if (latestPost != null) {
        widget.onRealPostPublished?.call(latestPost);
      }
      widget.onPostPublished();
      Navigator.pop(context);

      final uploadedCount =
          _selectedPhotos.where((p) => p.isUploaded).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadedCount > 0
                ? 'Post published with $uploadedCount photo(s)!'
                : 'Post published to CeylonGo Community!',
          ),
          backgroundColor: const Color(0xFF073B91),
          duration: const Duration(seconds: 2),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Unable to publish post right now. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: (screenHeight * 0.85).clamp(320.0, screenHeight * 0.92),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('create_post_scroll_view'),
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            _isRealMode ? 'TR' : 'DT',
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
                              _isRealMode ? 'Traveler Account' : 'Demo Traveler',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF082B5C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isRealMode
                                  ? 'Sharing to CeylonGo Community'
                                  : 'Sharing to CeylonGo Community (Demo)',
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('create_post_caption_field'),
                    controller: _captionController,
                    enabled: _createdPostId == null && !_isSubmitting,
                    maxLines: 4,
                    maxLength: _isRealMode ? 2000 : 500,
                    decoration: InputDecoration(
                      hintText:
                          'Share your Sri Lankan travel story, tips, or experiences...',
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
                      key: const Key('community_post_error_text'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  if (_partialSuccessMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const Key('community_partial_success_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _partialSuccessMessage!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: const Key('community_retry_uploads_btn'),
                            onPressed: _isSubmitting ? null : _onPublishReal,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Failed Uploads'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
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
                    enabled: _createdPostId == null && !_isSubmitting,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF073B91),
                        size: 20,
                      ),
                      hintText: 'e.g. Ella, Sri Lanka',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                  if (_isRealMode)
                    _buildRealGallerySection()
                  else
                    _buildDemoPresetSection(),
                  const SizedBox(height: 16),
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
                      ..._selectedHashtags.map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF073B91),
                            ),
                          ),
                          backgroundColor: const Color(0xFFEEF4FF),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF073B91),
                          ),
                          onDeleted: () => _onRemoveHashtag(tag),
                          padding: EdgeInsets.zero,
                        ),
                      ),
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('create_post_publish_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF073B91),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _onPublish,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _createdPostId != null
                            ? 'Retry Failed Uploads'
                            : 'Publish Post',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attach Photos',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF082B5C),
              ),
            ),
            Text(
              '${_selectedPhotos.length}/${CommunityMediaValidator.maxPhotosPerPost} photos',
              key: const Key('community_photo_count'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('community_gallery_pick_btn'),
          onPressed: _isSubmitting ? null : _pickGalleryPhotos,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Add Photos from Gallery (JPG, PNG, WEBP • max 5 MB)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF073B91),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_pickerWarnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('community_photo_warning_banner'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _pickerWarnings
                  .map(
                    (w) => Text(
                      w,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_selectedPhotos.isEmpty)
          Container(
            key: const Key('community_photo_empty_placeholder'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'No photos selected. Tap "Add Photos from Gallery" to attach up to 10 images.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = _selectedPhotos[index];
                return SizedBox(
                  width: 104,
                  child: Stack(
                    children: [
                      GestureDetector(
                        key: Key('community_photo_preview_$index'),
                        onTap: () => _previewPhoto(photo),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: photo.uploadError != null
                                  ? const Color(0xFFEF4444)
                                  : photo.isUploaded
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFBFDBFE),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              photo.bytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (!photo.isUploaded)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            key: Key('community_photo_remove_$index'),
                            onTap: () => _removePhoto(index),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black87,
                              child: Icon(
                                Icons.close,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (!photo.isUploaded)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: InkWell(
                            key: Key('community_photo_replace_$index'),
                            onTap: () => _replacePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Replace',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (photo.isUploaded)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: Color(0xFF10B981),
                            child: Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDemoPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      color: isSelected
                          ? const Color(0xFF073B91)
                          : const Color(0xFFE2E8F0),
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
                            child: const Icon(
                              Icons.image,
                              color: Colors.white54,
                              size: 24,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            color: const Color(0xFF073B91).withAlpha(80),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
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
      ],
    );
  }
}
