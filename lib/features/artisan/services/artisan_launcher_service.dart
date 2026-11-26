import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Service providing external intent helpers, coordinate calculations,
/// and graceful clipboard fallback dialogs for seller contact and maps.
class ArtisanLauncherService {
  const ArtisanLauncherService();

  /// Calculate distance between two coordinates in kilometers using Haversine formula.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);

  /// Builds a Google Maps search/directions URL for given coordinates.
  static String buildGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Builds a WhatsApp chat link for a phone number.
  static String? buildWhatsAppUrl(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    // Normalize Sri Lankan local numbers (07X... -> 947X...)
    final normalized = digits.startsWith('0') ? '94${digits.substring(1)}' : digits;
    return 'https://wa.me/$normalized';
  }

  /// Builds a standard mailto: URI string.
  static String? buildMailtoUrl(String? email, String subject) {
    if (email == null || email.trim().isEmpty) return null;
    final encodedSubject = Uri.encodeComponent(subject);
    return 'mailto:${email.trim()}?subject=$encodedSubject';
  }

  /// Builds a public shareable URL.
  static String buildPublicShareUrl(String entityType, int id) {
    final base = ApiConstants.baseUrl;
    return '$base/artisan/$entityType/$id';
  }

  /// Copy text to system clipboard with a SnackBar notice.
  static Future<void> copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: AppTheme.primaryNavy,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Displays Contact Seller Modal Sheet with phone, WhatsApp, email, and copy options.
  static void showContactModal(
    BuildContext context, {
    required String title,
    String? phone,
    String? email,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final hasPhone = phone != null && phone.trim().isNotEmpty;
        final hasEmail = email != null && email.trim().isNotEmpty;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSlate,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact $title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reach out directly to the artisan for custom inquiries and workshop visits.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (hasPhone) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primarySubtle,
                      child: Icon(Icons.phone, color: AppTheme.primaryNavy),
                    ),
                    title: Text(phone),
                    subtitle: const Text('Call or copy phone number'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy Phone',
                      onPressed: () {
                        Navigator.pop(ctx);
                        copyToClipboard(context, phone, 'Phone number');
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      copyToClipboard(context, phone, 'Phone number');
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(Icons.chat, color: Color(0xFF16A34A)),
                    ),
                    title: const Text('WhatsApp'),
                    subtitle: Text(phone),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      final wa = buildWhatsAppUrl(phone);
                      if (wa != null) {
                        copyToClipboard(context, wa, 'WhatsApp link');
                      }
                    },
                  ),
                ],
                if (hasEmail)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primarySubtle,
                      child: Icon(Icons.email, color: AppTheme.primaryNavy),
                    ),
                    title: Text(email),
                    subtitle: const Text('Email the artisan'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy Email',
                      onPressed: () {
                        Navigator.pop(ctx);
                        copyToClipboard(context, email, 'Email address');
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      copyToClipboard(context, email, 'Email address');
                    },
                  ),
                if (!hasPhone && !hasEmail)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Direct contact information is not currently provided for this artisan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Displays Directions Dialog with coordinates and maps link.
  static void showDirectionsModal(
    BuildContext context, {
    required String title,
    required double latitude,
    required double longitude,
    String? address,
    String? city,
  }) {
    final mapsUrl = buildGoogleMapsUrl(latitude, longitude);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address != null && address.isNotEmpty) ...[
              Text(
                address,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
            ],
            if (city != null && city.isNotEmpty) ...[
              Text(
                'City: $city',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Coordinates: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              copyToClipboard(context, mapsUrl, 'Google Maps link');
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Copy Maps Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: AppTheme.backgroundWhite,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays public sharing dialog.
  static void showShareModal(
    BuildContext context, {
    required String title,
    required String shareUrl,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: AppTheme.primaryNavy),
            SizedBox(width: 8),
            Text(
              'Share Artisan Experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share "$title" with friends or fellow travelers:',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: SelectableText(
                shareUrl,
                style: const TextStyle(fontSize: 12, color: AppTheme.primaryNavy),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              copyToClipboard(context, shareUrl, 'Share link');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: AppTheme.backgroundWhite,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays Share Dialog for a specific product.
  static void showProductShareModal(
    BuildContext context, {
    required String productTitle,
    required int productId,
    required String workshopTitle,
  }) {
    final shareUrl = buildPublicShareUrl('product', productId);
    showShareModal(
      context,
      title: '$productTitle by $workshopTitle',
      shareUrl: shareUrl,
    );
  }
}
