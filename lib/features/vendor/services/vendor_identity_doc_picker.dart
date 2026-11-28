import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/provider_identity_models.dart';

enum IdentityPickSource { gallery, camera }

/// Abstraction for picking identity verification photos (selfie, NIC front,
/// NIC back) strictly in memory, with backend-aligned validation.
abstract class VendorIdentityDocPicker {
  Future<IdentityDocumentFile?> pickDocument({
    required IdentityDocKind kind,
    required IdentityPickSource source,
  });
}

class ImagePickerVendorIdentityDocPicker implements VendorIdentityDocPicker {
  final ImagePicker _picker;

  ImagePickerVendorIdentityDocPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<IdentityDocumentFile?> pickDocument({
    required IdentityDocKind kind,
    required IdentityPickSource source,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source == IdentityPickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        preferredCameraDevice: kind == IdentityDocKind.selfie
            ? CameraDevice.front
            : CameraDevice.rear,
        imageQuality: 90,
      );
      if (file == null) return null;

      if (file.path.isNotEmpty) {
        final local = File(file.path);
        if (await local.exists()) {
          final len = await local.length();
          if (len > IdentityDocumentValidator.maxFileSizeBytes) {
            throw IdentityValidationException(
              '${kind.label} exceeds the 5 MB maximum upload size.',
            );
          }
        }
      }

      final bytes = await file.readAsBytes();
      final validatedMime = IdentityDocumentValidator.validate(
        kind: kind,
        bytes: bytes,
        filename: file.name.isNotEmpty ? file.name : file.path,
        mimeType: file.mimeType,
      );
      final ext = IdentityDocumentValidator.extensionForMime(validatedMime);

      return IdentityDocumentFile(
        kind: kind,
        safeFilename: '${kind.fieldName}$ext',
        mimeType: validatedMime,
        bytes: bytes,
      );
    } on IdentityValidationException {
      rethrow;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('already_active')) {
        throw const IdentityValidationException(
          'Document picker is already open.',
        );
      }
      if (code.contains('denied') || code.contains('permission')) {
        throw IdentityValidationException(
          source == IdentityPickSource.camera
              ? 'Camera permission was denied. Enable camera access in settings.'
              : 'Gallery permission was denied. Enable photo access in settings.',
        );
      }
      throw IdentityValidationException(
        source == IdentityPickSource.camera
            ? 'Camera is unavailable on this device.'
            : 'Unable to open gallery on this device.',
      );
    } catch (_) {
      throw IdentityValidationException(
        'Could not read ${kind.label} image. Please try another file.',
      );
    }
  }
}

