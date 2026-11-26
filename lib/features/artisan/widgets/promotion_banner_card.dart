import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/artisan_promotion_model.dart';
import '../services/artisan_launcher_service.dart';

/// Distinctive promotion discount card for active artisan promotions.
class PromotionBannerCard extends StatelessWidget {
  final ArtisanPromotionModel promotion;

  const PromotionBannerCard({
    super.key,
    required this.promotion,
  });

  @override
  Widget build(BuildContext context) {
    final endDateFormatted =
        '${promotion.endDate.year}-${promotion.endDate.month.toString().padLeft(2, '0')}-${promotion.endDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Warm light amber
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      promotion.discountBadge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Valid until $endDateFormatted',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promotion.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
          if (promotion.description != null && promotion.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              promotion.description!,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Promo Code: ',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              InkWell(
                onTap: () => ArtisanLauncherService.copyToClipboard(
                  context,
                  promotion.promoCode,
                  'Promo code',
                ),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        promotion.promoCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 12, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

