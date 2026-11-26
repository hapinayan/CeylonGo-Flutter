import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/showcase_item_model.dart';
import 'stock_badge.dart';

class ArtisanProductCard extends StatelessWidget {
  final ShowcaseItemSummary product;
  final VoidCallback? onTap;

  const ArtisanProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fullImageUrl;

    return Card(
      elevation: 0,
      color: AppTheme.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSlate),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppTheme.backgroundLight,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : _buildPlaceholder(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.isProduct
                          ? const Color(0xFFE0E7FF)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.isProduct ? 'Product' : 'Workshop',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.isProduct
                            ? const Color(0xFF3730A3)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StockBadge(
                        stockQuantity: product.stockQuantity,
                        isAvailable: product.isAvailable,
                        isActive: product.isActive,
                        approvalStatus: product.approvalStatus,
                      ),
                      if (product.isCustomOrderAvailable)
                        const Tooltip(
                          message: 'Custom commissions accepted',
                          child: Icon(Icons.handyman_outlined, size: 14, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.primarySubtle,
      child: Center(
        child: Icon(
          product.isProduct ? Icons.shopping_bag_outlined : Icons.brush_outlined,
          size: 32,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }
}
