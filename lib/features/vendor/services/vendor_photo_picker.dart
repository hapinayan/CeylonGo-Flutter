import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/vendor_models.dart';

class VendorPhotoException implements Exception {
  final String message;

  const VendorPhotoException(this.message);

  @override
  String toString() => message;
}

/// Validates and picks local listing photos (Gallery / Camera) without
/// performing any network or backend upload.
abstract class VendorPhotoPicker {
  static const int maxPhotos = 5;
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> supportedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
  ];

  Future<List<VendorListingPhoto>> pickFromGallery({required int maxCount});
  Future<VendorListingPhoto?> captureFromCamera();

  static bool isSupportedFileName(String path, {String? mimeType}) {
    final cleanPath = path.split('?').first.trim().toLowerCase();
    if (supportedExtensions.any(cleanPath.endsWith)) {
      return true;
    }
    if (mimeType != null) {
      final mime = mimeType.trim().toLowerCase();
      return mime == 'image/jpeg' ||
          mime == 'image/jpg' ||
          mime == 'image/png' ||
          mime == 'image/webp' ||
          mime == 'image/heic' ||
          mime == 'image/heif';
    }
    return false;
  }

  static void validatePhoto({
    required String path,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
  }) {
    final candidatePath =
        (fileName != null && fileName.trim().isNotEmpty && !isSupportedFileName(path))
            ? fileName
            : path;
    if (candidatePath.trim().isEmpty ||
        !isSupportedFileName(candidatePath, mimeType: mimeType)) {
      throw const VendorPhotoException(
        'Unsupported image type. Please select JPG, PNG, WEBP, or HEIC photos.',
      );
    }
    if (sizeBytes != null && sizeBytes <= 0) {
      throw const VendorPhotoException(
        'Selected image file appears empty or unreadable.',
      );
    }
    if (sizeBytes != null && sizeBytes > maxFileSizeBytes) {
      throw const VendorPhotoException(
        'Image exceeds the 10 MB size limit. Please choose a smaller photo.',
      );
    }
  }
}

class ImagePickerVendorPhotoPicker implements VendorPhotoPicker {
  final ImagePicker _picker;

  ImagePickerVendorPhotoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<List<VendorListingPhoto>> pickFromGallery({
    required int maxCount,
  }) async {
    if (maxCount <= 0) return const [];
    try {
      final List<XFile> picked;
      if (maxCount == 1) {
        final single = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        picked = single != null ? [single] : const [];
      } else {
        picked = await _picker.pickMultiImage(
          limit: maxCount,
          imageQuality: 85,
        );
      }

      final result = <VendorListingPhoto>[];
      for (final file in picked.take(maxCount)) {
        final size = await _safeFileSize(file);
        VendorPhotoPicker.validatePhoto(
          path: file.path,
          fileName: file.name,
          mimeType: file.mimeType,
          sizeBytes: size,
        );
        result.add(
          VendorListingPhoto(
            id: 'photo_${DateTime.now().microsecondsSinceEpoch}_${result.length}',
            path: file.path,
            isLocalFile: true,
          ),
        );
      }
      return result;
    } on VendorPhotoException {
      rethrow;
    } on PlatformException catch (e) {
      throw VendorPhotoException(_mapPlatformError(e, isCamera: false));
    } catch (_) {
      throw const VendorPhotoException(
        'Unable to load selected gallery photo. Please try again.',
      );
    }
  }

  @override
  Future<VendorListingPhoto?> captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return null;

      final size = await _safeFileSize(photo);
      VendorPhotoPicker.validatePhoto(
        path: photo.path,
        fileName: photo.name,
        mimeType: photo.mimeType,
        sizeBytes: size,
      );

      return VendorListingPhoto(
        id: 'cam_${DateTime.now().microsecondsSinceEpoch}',
        path: photo.path,
        isLocalFile: true,
      );
    } on VendorPhotoException {
      rethrow;
    } on PlatformException catch (e) {
      throw VendorPhotoException(_mapPlatformError(e, isCamera: true));
    } catch (_) {
      throw const VendorPhotoException(
        'Unable to capture photo from camera. Please try again.',
      );
    }
  }

  Future<int?> _safeFileSize(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      try {
        final local = File(file.path);
        if (await local.exists()) {
          return await local.length();
        }
      } catch (_) {}
      return null;
    }
  }

  String _mapPlatformError(PlatformException e, {required bool isCamera}) {
    final code = e.code.toLowerCase();
    if (code.contains('already_active')) {
      return 'Photo picker is already open. Please finish or cancel the active selection.';
    }
    if (code.contains('denied') || code.contains('permission')) {
      return isCamera
          ? 'Camera permission was denied. Please allow camera access in device settings.'
          : 'Gallery permission was denied. Please allow photo access in device settings.';
    }
    return isCamera
        ? 'Camera is unavailable on this device.'
        : 'Unable to open photo gallery right now.';
  }
}

