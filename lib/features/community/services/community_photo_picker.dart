import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/community_api_models.dart';

/// Scoped device-gallery photo picker for Travel Community posts.
/// Uses Android Photo Picker / scoped `image_picker` without requesting broad
/// storage permissions, and validates files immediately on selection.
class CommunityPhotoPicker {
  final ImagePicker _picker;

  CommunityPhotoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  Future<({List<SelectedCommunityPhoto> accepted, List<String> warnings})>
      pickFromGallery({
    required int maxRemaining,
  }) async {
    if (maxRemaining <= 0) {
      return (
        accepted: const <SelectedCommunityPhoto>[],
        warnings: const ['Maximum of 10 photos per post reached.'],
      );
    }

    try {
      final files = await _picker.pickMultiImage(limit: maxRemaining);
      if (files.isEmpty) {
        return (
          accepted: const <SelectedCommunityPhoto>[],
          warnings: const <String>[],
        );
      }

      final accepted = <SelectedCommunityPhoto>[];
      final warnings = <String>[];

      for (final file in files.take(maxRemaining)) {
        final bytes = await file.readAsBytes();
        final safeName = _sanitizeFilename(file.name);
        try {
          final valid = CommunityMediaValidator.validate(
            bytes: bytes,
            filename: safeName,
            mimeType: file.mimeType,
          );
          accepted.add(
            SelectedCommunityPhoto(
              bytes: bytes,
              safeFilename: safeName,
              mimeType: valid.mimeType,
            ),
          );
        } on CommunityMediaValidationException catch (e) {
          warnings.add('$safeName: ${e.message}');
        }
      }

      if (files.length > maxRemaining) {
        warnings.add(
          'Only $maxRemaining more photo(s) can be added (max 10 per post).',
        );
      }

      return (accepted: accepted, warnings: warnings);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        throw const CommunityMediaValidationException(
          'Gallery access was denied. Enable photo access to attach images.',
        );
      }
      throw const CommunityMediaValidationException(
        'Could not open gallery picker. Please try again.',
      );
    }
  }

  Future<SelectedCommunityPhoto?> pickSingleReplacement() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final safeName = _sanitizeFilename(file.name);
      final valid = CommunityMediaValidator.validate(
        bytes: bytes,
        filename: safeName,
        mimeType: file.mimeType,
      );
      return SelectedCommunityPhoto(
        bytes: bytes,
        safeFilename: safeName,
        mimeType: valid.mimeType,
      );
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw const CommunityMediaValidationException(
          'Gallery access was denied. Enable photo access to replace the image.',
        );
      }
      throw const CommunityMediaValidationException(
        'Could not open gallery picker. Please try again.',
      );
    }
  }

  static String _sanitizeFilename(String raw) {
    final base = raw.split(RegExp(r'[/\\]')).last.trim();
    if (base.isEmpty) return 'community_photo.jpg';
    return base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}

