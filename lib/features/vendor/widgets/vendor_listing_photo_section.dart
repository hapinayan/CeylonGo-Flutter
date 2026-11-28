import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/vendor_models.dart';
import '../services/vendor_photo_picker.dart';
import 'vendor_listing_image.dart';

/// Reusable local photo selector & preview grid for Vendor Add/Edit Listing.
/// Supports up to 5 photos from Gallery or Camera, cover selection, and removal.
class VendorListingPhotoSection extends StatelessWidget {
  final List<VendorListingPhoto> photos;
  final int coverPhotoIndex;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onPickGallery;
  final VoidCallback onCaptureCamera;
  final ValueChanged<int> onSelectCover;
  final ValueChanged<int> onRemovePhoto;

  const VendorListingPhotoSection({
    super.key,
    required this.photos,
    required this.coverPhotoIndex,
    required this.onPickGallery,
    required this.onCaptureCamera,
    required this.onSelectCover,
    required this.onRemovePhoto,
    this.isBusy = false,
    this.errorMessage,
  });

  static const Color _royalBlue = Color(0xFF0A4DF5);

  @override
  Widget build(BuildContext context) {
    final canAddMore = !isBusy && photos.length < VendorPhotoPicker.maxPhotos;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing Photos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Up to 5 local photos (JPG, PNG, WEBP, HEIC • max 10 MB)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${photos.length} / ${VendorPhotoPicker.maxPhotos}',
                  key: const Key('listing_photo_count'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('pick_gallery_photo_btn'),
                  onPressed: canAddMore ? onPickGallery : null,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text(
                    'Gallery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryNavy,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('capture_camera_photo_btn'),
                  onPressed: canAddMore ? onCaptureCamera : null,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text(
                    'Camera',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryNavy,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('listing_photo_error'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (photos.isEmpty)
            Container(
              key: const Key('listing_photo_placeholder'),
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No photos selected yet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Add photos from Gallery or Camera to showcase your listing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                final isCover = index == coverPhotoIndex;
                return Container(
                  key: Key('photo_thumb_$index'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCover ? _royalBlue : const Color(0xFFCBD5E1),
                      width: isCover ? 2.2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VendorListingImage(photo: photo),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            key: Key('remove_photo_$index'),
                            onTap: () => onRemovePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 4,
                          right: 4,
                          bottom: 4,
                          child: InkWell(
                            key: Key('set_cover_photo_$index'),
                            onTap: isCover ? null : () => onSelectCover(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isCover ? _royalBlue : Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCover ? 'Cover' : 'Set Cover',
                                key: isCover ? Key('cover_badge_$index') : null,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

