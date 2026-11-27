import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../models/vendor_models.dart';

/// Displays a vendor listing photo from in-memory bytes, a local file path,
/// or a network/asset path, with a consistent fallback placeholder.
class VendorListingImage extends StatelessWidget {
  final VendorListingPhoto? photo;
  final String fallbackImageUrl;
  final IconData fallbackIcon;
  final BoxFit fit;

  const VendorListingImage({
    super.key,
    this.photo,
    this.fallbackImageUrl = '',
    this.fallbackIcon = Icons.storefront_outlined,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final p = photo;
    if (p != null) {
      if (p.bytes != null) {
        return Image.memory(
          p.bytes!,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      }
      if (p.isLocalFile && !p.isNetworkUrl && !p.path.startsWith('assets/')) {
        return Image.file(
          File(p.path),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      }
      return CeylonGoNetworkImage(
        imageUrl: p.path,
        fit: fit,
        fallbackIcon: fallbackIcon,
      );
    }

    if (fallbackImageUrl.trim().isNotEmpty) {
      return CeylonGoNetworkImage(
        imageUrl: fallbackImageUrl.trim(),
        fit: fit,
        fallbackIcon: fallbackIcon,
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: AppTheme.primaryNavy.withAlpha(140),
        size: 28,
      ),
    );
  }
}

