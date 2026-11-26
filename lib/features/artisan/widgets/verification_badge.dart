import 'package:flutter/material.dart';

/// Verification badge displayed strictly when the backend confirms
/// the artisan business is verified (is_verified == true).
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: size, color: const Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}

