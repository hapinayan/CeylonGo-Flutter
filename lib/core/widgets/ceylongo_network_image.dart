import 'package:flutter/material.dart';

/// Shared network image widget for CeylonGo listing and destination cards.
/// Ensures cards never render blank spaces by providing:
/// 1. A subtle gradient + CircularProgressIndicator while loading.
/// 2. A themed gradient + icon fallback if loading fails or URL is empty.
class CeylonGoNetworkImage extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final Color accentColor;
  final double iconSize;
  final BoxFit fit;

  const CeylonGoNetworkImage({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = Icons.image_outlined,
    this.accentColor = const Color(0xFF0A4DF5),
    this.iconSize = 28,
    this.fit = BoxFit.cover,
  });

  Widget _buildFallback({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withAlpha(24),
            accentColor.withAlpha(48),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
            : Icon(
                fallbackIcon,
                color: accentColor,
                size: iconSize,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _buildFallback();
    }

    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildFallback(isLoading: true);
      },
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }
}

