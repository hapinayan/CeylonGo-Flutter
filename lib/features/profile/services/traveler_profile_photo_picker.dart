import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/traveler_profile_photo_models.dart';

class PickedTravelerPhoto {
  final Uint8List bytes;
  final String extension;
  final String mimeType;

  const PickedTravelerPhoto({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });
}

/// Scoped gallery & camera picker for Traveler profile photos.
class TravelerProfilePhotoPicker {
  final ImagePicker _picker;

  TravelerProfilePhotoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  Future<PickedTravelerPhoto?> pickFromGallery() =>
      _pick(ImageSource.gallery);

  Future<PickedTravelerPhoto?> captureFromCamera() =>
      _pick(ImageSource.camera);

  Future<PickedTravelerPhoto?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null) return null; // User cancelled

      final bytes = await file.readAsBytes();
      final valid = TravelerProfilePhotoValidator.validate(
        bytes: bytes,
        filename: file.name,
        mimeType: file.mimeType,
      );
      return PickedTravelerPhoto(
        bytes: bytes,
        extension: valid.extension,
        mimeType: valid.mimeType,
      );
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        throw TravelerPhotoValidationException(
          source == ImageSource.camera
              ? 'Camera permission was denied. Enable camera access to take a profile photo.'
              : 'Photo access was denied. Enable gallery access to select a profile photo.',
        );
      }
      throw const TravelerPhotoValidationException(
        'Could not access device photos or camera. Please try again.',
      );
    }
  }
}
