import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/traveler_profile_photo_models.dart';
import '../services/traveler_profile_photo_picker.dart';
import '../services/traveler_profile_photo_storage.dart';

/// Blue-and-white modal bottom sheet for selecting, previewing, updating,
/// and removing a local-only Traveler profile photo.
class TravelerPhotoEditorSheet extends StatefulWidget {
  final String accountKey;
  final String initials;
  final TravelerProfilePhotoData? currentPhoto;
  final TravelerProfilePhotoStore photoStore;
  final TravelerProfilePhotoPicker photoPicker;
  final void Function(TravelerProfilePhotoData? updatedPhoto) onPhotoChanged;

  const TravelerPhotoEditorSheet({
    super.key,
    required this.accountKey,
    required this.initials,
    required this.currentPhoto,
    required this.photoStore,
    required this.photoPicker,
    required this.onPhotoChanged,
  });

  @override
  State<TravelerPhotoEditorSheet> createState() =>
      _TravelerPhotoEditorSheetState();
}

class _TravelerPhotoEditorSheetState extends State<TravelerPhotoEditorSheet> {
  PickedTravelerPhoto? _pendingPick;
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> _pick(bool fromCamera) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final picked = fromCamera
          ? await widget.photoPicker.captureFromCamera()
          : await widget.photoPicker.pickFromGallery();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        if (picked != null) {
          _pendingPick = picked;
        }
      });
    } on TravelerPhotoValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = 'Could not load selected photo. Please try again.';
      });
    }
  }

  Future<void> _savePending() async {
    final pending = _pendingPick;
    if (pending == null || _isBusy) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final saved = await widget.photoStore.saveForAccount(
        accountKey: widget.accountKey,
        bytes: pending.bytes,
        extension: pending.extension,
        mimeType: pending.mimeType,
      );
      if (!mounted) return;
      widget.onPhotoChanged(saved);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile photo saved on this device only.',
          ),
          backgroundColor: Color(0xFF073B91),
        ),
      );
    } on TravelerPhotoStorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = 'Failed to save profile photo locally.';
      });
    }
  }

  Future<void> _removeExisting() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.photoStore.removeForAccount(widget.accountKey);
      if (!mounted) return;
      widget.onPhotoChanged(null);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed from this device.'),
          backgroundColor: Color(0xFF082B5C),
        ),
      );
    } on TravelerPhotoStorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = 'Could not remove stored profile photo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? previewBytes =
        _pendingPick?.bytes ?? widget.currentPhoto?.bytes;
    final hasExisting = widget.currentPhoto != null;

    return SafeArea(
      child: Padding(
        key: const Key('traveler_photo_editor_sheet'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('traveler_photo_close_btn'),
                    onPressed: _isBusy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                key: const Key('traveler_photo_local_only_notice'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primarySubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Text(
                  'Profile photo saved on this device only. Cloud sync is not available yet.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  key: const Key('traveler_photo_preview_circle'),
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEEF4FF),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 2.5,
                    ),
                  ),
                  child: previewBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            previewBytes,
                            fit: BoxFit.cover,
                            width: 104,
                            height: 104,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                widget.initials,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.initials,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('traveler_photo_error_banner'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('traveler_photo_gallery_btn'),
                      onPressed: _isBusy ? null : () => _pick(false),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('traveler_photo_camera_btn'),
                      onPressed: _isBusy ? null : () => _pick(true),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              if (_pendingPick != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: const Key('traveler_photo_save_btn'),
                  onPressed: _isBusy ? null : _savePending,
                  icon: _isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(hasExisting ? 'Update Photo' : 'Save Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF073B91),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              if (hasExisting) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  key: const Key('traveler_photo_remove_btn'),
                  onPressed: _isBusy ? null : _removeExisting,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.errorRed,
                    size: 18,
                  ),
                  label: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

